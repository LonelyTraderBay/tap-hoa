import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcrypt';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Customer debt adjustment e2e', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let storeId: string;
  let passwordHash: string;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    prisma = moduleRef.get(PrismaService);
    await app.init();

    storeId = (await prisma.store.findFirst({ where: { code: 'CH1' } }))!.id;
    passwordHash = await bcrypt.hash('123456', 10);
  });

  afterAll(async () => {
    await app.close();
  });

  async function login(phone: string) {
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone, password: '123456' })
      .expect(201);
    return {
      accessToken: res.body.accessToken as string,
      userId: res.body.user.id as string,
    };
  }

  async function upsertStoreUser(input: {
    phone: string;
    name: string;
    role: 'store_manager' | 'cashier';
  }) {
    const user = await prisma.user.upsert({
      where: { phone: input.phone },
      update: {
        name: input.name,
        role: input.role,
        passwordHash,
        active: true,
        canLedger: false,
        canEinvoice: false,
      },
      create: {
        phone: input.phone,
        name: input.name,
        role: input.role,
        passwordHash,
        active: true,
        canLedger: false,
        canEinvoice: false,
      },
    });
    await prisma.userStore.upsert({
      where: { userId_storeId: { userId: user.id, storeId } },
      update: {},
      create: { userId: user.id, storeId },
    });
    return user;
  }

  it('lets owner and manager post signed debt adjustments with ledger and audit', async () => {
    await prisma.auditLog.deleteMany({ where: { action: 'debt_adjust' } });
    const owner = await login('0900000001');
    await upsertStoreUser({
      phone: '0900000195',
      name: 'QL dieu chinh no',
      role: 'store_manager',
    });
    const manager = await login('0900000195');
    const customerId = randomUUID();
    await prisma.customer.create({
      data: {
        id: customerId,
        storeId,
        name: 'Khach dieu chinh',
      },
    });

    const increase = await request(app.getHttpServer())
      .post(`/customers/${customerId}/debt-adjust`)
      .set('Authorization', `Bearer ${owner.accessToken}`)
      .send({ amountVnd: 25000, reason: 'So du dau ky' })
      .expect(201);
    expect(increase.body.balanceVnd).toBe(25000);
    expect(increase.body.debtLedgerEntryId).toEqual(expect.any(String));

    const decrease = await request(app.getHttpServer())
      .post(`/customers/${customerId}/debt-adjust`)
      .set('Authorization', `Bearer ${manager.accessToken}`)
      .send({ amountVnd: -5000, reason: 'Giam tru chot cong no' })
      .expect(201);
    expect(decrease.body.balanceVnd).toBe(20000);

    const ledger = await prisma.debtLedgerEntry.findMany({
      where: { customerId, type: 'debt_adjust' },
      orderBy: { clientCreatedAt: 'asc' },
    });
    expect(ledger).toHaveLength(2);
    expect(ledger.map((entry) => entry.amountVnd)).toEqual([25000, -5000]);
    expect(ledger.map((entry) => entry.balanceAfterVnd)).toEqual([25000, 20000]);
    expect(ledger.map((entry) => entry.recordedById)).toEqual([
      owner.userId,
      manager.userId,
    ]);

    const audits = await prisma.auditLog.findMany({
      where: { action: 'debt_adjust', entityId: customerId },
      orderBy: { at: 'asc' },
    });
    expect(audits).toHaveLength(2);
    expect(audits[0]).toMatchObject({
      actorUserId: owner.userId,
      entityType: 'customer',
    });
    expect(JSON.parse(audits[0].detailJson ?? '{}')).toMatchObject({
      amountVnd: 25000,
      reason: 'So du dau ky',
      balanceBeforeVnd: 0,
      balanceAfterVnd: 25000,
      debtLedgerEntryId: increase.body.debtLedgerEntryId,
    });

    // G2 (docs/superpowers/plans/2026-07-28-va-gap-audit-spec.md): 'debt_adjust'
    // phai co trong defaultAuditActions de man "So . Nhat ky" tren Flutter
    // (ledger_page.dart, goi listAudit KHONG truyen `action`) thay duoc log
    // nay. Goi thang GET /ledger/audit khong truyen `action` (giong het cach
    // client that goi) roi tim ban ghi theo entityId - neu allowlist thieu
    // 'debt_adjust' thi mang tra ve se rong va assertion duoi day se fail.
    const auditApi = await request(app.getHttpServer())
      .get('/ledger/audit')
      .set('Authorization', `Bearer ${owner.accessToken}`)
      .expect(200);
    const auditEntriesViaHttp = (
      auditApi.body as Array<{
        action: string;
        entityId: string | null;
        actorUserId: string | null;
        entityType: string;
        detailJson: string | null;
      }>
    ).filter(
      (row) => row.action === 'debt_adjust' && row.entityId === customerId,
    );
    expect(auditEntriesViaHttp).toHaveLength(2);
    // GET /ledger/audit sap xep moi nhat truoc (orderBy at desc) nen phan tu
    // dau la lan dieu chinh giam (-5000, do manager thuc hien).
    expect(auditEntriesViaHttp[0]).toMatchObject({
      actorUserId: manager.userId,
      entityType: 'customer',
    });
    expect(JSON.parse(auditEntriesViaHttp[0].detailJson ?? '{}')).toMatchObject({
      amountVnd: -5000,
      reason: 'Giam tru chot cong no',
      balanceBeforeVnd: 25000,
      balanceAfterVnd: 20000,
    });
    expect(auditEntriesViaHttp[1]).toMatchObject({
      actorUserId: owner.userId,
      entityType: 'customer',
    });
  });

  it('rejects cashier access, zero amount, missing reason, and negative balances', async () => {
    const owner = await login('0900000001');
    await upsertStoreUser({
      phone: '0900000196',
      name: 'Thu ngan dieu chinh no',
      role: 'cashier',
    });
    const cashier = await login('0900000196');
    const customerId = randomUUID();
    await prisma.customer.create({
      data: {
        id: customerId,
        storeId,
        name: 'Khach chan dieu chinh',
        balanceVnd: 1000,
      },
    });

    await request(app.getHttpServer())
      .post(`/customers/${customerId}/debt-adjust`)
      .set('Authorization', `Bearer ${cashier.accessToken}`)
      .send({ amountVnd: 1000, reason: 'Khong du quyen' })
      .expect(403);

    await request(app.getHttpServer())
      .post(`/customers/${customerId}/debt-adjust`)
      .set('Authorization', `Bearer ${owner.accessToken}`)
      .send({ amountVnd: 0, reason: 'Sai so tien' })
      .expect(400);

    await request(app.getHttpServer())
      .post(`/customers/${customerId}/debt-adjust`)
      .set('Authorization', `Bearer ${owner.accessToken}`)
      .send({ amountVnd: 1000 })
      .expect(400);

    await request(app.getHttpServer())
      .post(`/customers/${customerId}/debt-adjust`)
      .set('Authorization', `Bearer ${owner.accessToken}`)
      .send({ amountVnd: -2000, reason: 'Khong am cong no' })
      .expect(400);
  });
});
