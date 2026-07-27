import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

const CATEGORY_ELECTRICITY = 'a1000000-0000-4000-8000-000000000002';
const CATEGORY_RENT = 'a1000000-0000-4000-8000-000000000003';
const TEST_ACCOUNT_CODE = '6421';
const TEST_INACTIVE_ACCOUNT_CODE = '6499';

/** P2.2: CashCategory.accountCode map danh mục chi/thu → TK sổ cái. */
describe('P2.2 cash category → account mapping', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let ownerToken: string;
  let storeId: string;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    prisma = moduleRef.get(PrismaService);
    await app.init();
    await seedChartOfAccounts(prisma);

    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: '0900000001', password: '123456' })
      .expect(201);
    ownerToken = login.body.accessToken;
    storeId = (await prisma.store.findFirst({ where: { code: 'CH1' } }))!.id;

    await prisma.account.upsert({
      where: { code: TEST_ACCOUNT_CODE },
      update: { active: true },
      create: {
        code: TEST_ACCOUNT_CODE,
        name: 'Chi phi dien (test)',
        type: 'expense',
      },
    });
    await prisma.account.upsert({
      where: { code: TEST_INACTIVE_ACCOUNT_CODE },
      update: { active: false },
      create: {
        code: TEST_INACTIVE_ACCOUNT_CODE,
        name: 'TK vo hieu hoa (test)',
        type: 'expense',
        active: false,
      },
    });
  });

  afterAll(async () => {
    // Trả CATEGORY_ELECTRICITY về null để không rò rỉ mapping sang spec khác.
    await prisma.cashCategory.update({
      where: { id: CATEGORY_ELECTRICITY },
      data: { accountCode: null },
    });
    await prisma.account.deleteMany({
      where: { code: { in: [TEST_ACCOUNT_CODE, TEST_INACTIVE_ACCOUNT_CODE] } },
    });
    await app.close();
  });

  async function resetElectricityMapping() {
    await prisma.cashCategory.update({
      where: { id: CATEGORY_ELECTRICITY },
      data: { accountCode: null },
    });
  }

  async function createManager(phone: string, canLedger: boolean) {
    await request(app.getHttpServer())
      .post('/users')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        phone,
        name: 'QL map danh muc',
        password: '123456',
        role: 'store_manager',
        storeIds: [storeId],
        canLedger,
      })
      .expect(201);
    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone, password: '123456' })
      .expect(201);
    return {
      token: login.body.accessToken as string,
      userId: login.body.user.id as string,
    };
  }

  async function cleanupUser(userId: string) {
    await prisma.userStore.deleteMany({ where: { userId } });
    await prisma.user.deleteMany({ where: { id: userId } });
  }

  it('GET /ledger/cash-categories liệt kê danh mục kèm accountCode hiện tại (null mặc định)', async () => {
    await resetElectricityMapping();
    const res = await request(app.getHttpServer())
      .get('/ledger/cash-categories')
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    const electricity = res.body.find(
      (c: { id: string }) => c.id === CATEGORY_ELECTRICITY,
    );
    expect(electricity).toMatchObject({
      code: 'electricity',
      direction: 'out',
      accountCode: null,
    });
  });

  it('POST /ledger/cash-categories/:id/account — chỉ owner được đổi, từ chối TK không tồn tại/không active', async () => {
    await resetElectricityMapping();
    const manager = await createManager('0950300001', true);

    // store_manager có canLedger vẫn không được đổi map — đây là cấu hình
    // kế toán áp dụng toàn hệ thống, không phải theo điểm bán của họ.
    await request(app.getHttpServer())
      .post(`/ledger/cash-categories/${CATEGORY_ELECTRICITY}/account`)
      .set('Authorization', `Bearer ${manager.token}`)
      .send({ accountCode: TEST_ACCOUNT_CODE })
      .expect(403);

    // TK không tồn tại.
    await request(app.getHttpServer())
      .post(`/ledger/cash-categories/${CATEGORY_ELECTRICITY}/account`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ accountCode: 'ZZZZ-NOPE' })
      .expect(400);

    // TK tồn tại nhưng đã bị vô hiệu hoá.
    await request(app.getHttpServer())
      .post(`/ledger/cash-categories/${CATEGORY_ELECTRICITY}/account`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ accountCode: TEST_INACTIVE_ACCOUNT_CODE })
      .expect(400);

    const unchanged = await prisma.cashCategory.findUnique({
      where: { id: CATEGORY_ELECTRICITY },
    });
    expect(unchanged?.accountCode).toBeNull();

    // Owner + TK hợp lệ + active ⇒ 200 và lưu lại.
    const ok = await request(app.getHttpServer())
      .post(`/ledger/cash-categories/${CATEGORY_ELECTRICITY}/account`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ accountCode: TEST_ACCOUNT_CODE })
      .expect(200);
    expect(ok.body.accountCode).toBe(TEST_ACCOUNT_CODE);

    const listed = await request(app.getHttpServer())
      .get('/ledger/cash-categories')
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    expect(
      listed.body.find((c: { id: string }) => c.id === CATEGORY_ELECTRICITY)
        .accountCode,
    ).toBe(TEST_ACCOUNT_CODE);

    // Owner có thể gỡ map (accountCode: null) — quay lại fallback cứng cũ.
    const cleared = await request(app.getHttpServer())
      .post(`/ledger/cash-categories/${CATEGORY_ELECTRICITY}/account`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ accountCode: null })
      .expect(200);
    expect(cleared.body.accountCode).toBeNull();

    await cleanupUser(manager.userId);
  });

  it('bút toán phiếu chi dùng TK đã map thay vì 642; danh mục chưa map vẫn theo fallback cứng cũ', async () => {
    await resetElectricityMapping();
    await request(app.getHttpServer())
      .post(`/ledger/cash-categories/${CATEGORY_ELECTRICITY}/account`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ accountCode: TEST_ACCOUNT_CODE })
      .expect(200);

    await prisma.shift.updateMany({
      where: { storeId, closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
    });
    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ storeId, openingCash: 200_000, clientId: shiftId })
      .expect(201);

    const mappedVoucherId = randomUUID();
    const unmappedVoucherId = randomUUID();
    const nowIso = new Date().toISOString();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        deviceId: 'cash-category-mapping',
        sales: [],
        cashVouchers: [
          {
            id: mappedVoucherId,
            storeId,
            shiftId,
            categoryId: CATEGORY_ELECTRICITY, // đã map -> TEST_ACCOUNT_CODE
            direction: 'out',
            channel: 'cash',
            amountVnd: 40_000,
            clientCreatedAt: nowIso,
          },
          {
            id: unmappedVoucherId,
            storeId,
            shiftId,
            categoryId: CATEGORY_RENT, // chưa map -> fallback 642
            direction: 'out',
            channel: 'cash',
            amountVnd: 25_000,
            clientCreatedAt: nowIso,
          },
        ],
      })
      .expect(201)
      .expect((res) => {
        expect(res.body.rejectedCashVouchers ?? []).toHaveLength(0);
      });

    const mappedEntry = await prisma.journalEntry.findUnique({
      where: {
        sourceType_sourceId: {
          sourceType: 'cash_voucher',
          sourceId: mappedVoucherId,
        },
      },
      include: { lines: true },
    });
    expect(mappedEntry).toBeTruthy();
    const mappedDebit = mappedEntry!.lines.find((l) => l.debitVnd > 0);
    const mappedCredit = mappedEntry!.lines.find((l) => l.creditVnd > 0);
    expect(mappedDebit?.accountCode).toBe(TEST_ACCOUNT_CODE);
    expect(mappedDebit?.debitVnd).toBe(40_000);
    expect(mappedCredit?.accountCode).toBe('111');

    const unmappedEntry = await prisma.journalEntry.findUnique({
      where: {
        sourceType_sourceId: {
          sourceType: 'cash_voucher',
          sourceId: unmappedVoucherId,
        },
      },
      include: { lines: true },
    });
    expect(unmappedEntry).toBeTruthy();
    const unmappedDebit = unmappedEntry!.lines.find((l) => l.debitVnd > 0);
    expect(unmappedDebit?.accountCode).toBe('642');
    expect(unmappedDebit?.debitVnd).toBe(25_000);

    // Dọn 2 chứng từ vừa tạo — tránh rò rỉ vào các test sổ quỹ/trial-balance khác.
    await prisma.journalLine.deleteMany({
      where: {
        entryId: { in: [mappedEntry!.id, unmappedEntry!.id] },
      },
    });
    await prisma.journalEntry.deleteMany({
      where: { id: { in: [mappedEntry!.id, unmappedEntry!.id] } },
    });
    await prisma.cashVoucher.deleteMany({
      where: { id: { in: [mappedVoucherId, unmappedVoucherId] } },
    });
  });
});
