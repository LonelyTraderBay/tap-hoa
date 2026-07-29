import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Phase 2 period reports e2e', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;
  let userId: string;
  let storeId: string;
  let productId: string;
  let periodYm: string;

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
    token = login.body.accessToken;
    userId = login.body.user.id;
    storeId = (await prisma.store.findFirst({ where: { code: 'CH1' } }))!.id;
    productId = (await prisma.product.findUnique({ where: { sku: 'STING-330' } }))!
      .id;
    const now = new Date();
    const ict = new Date(now.getTime() + 7 * 3600_000);
    periodYm = `${ict.getUTCFullYear()}-${String(ict.getUTCMonth() + 1).padStart(2, '0')}`;
  });

  afterAll(async () => {
    await app.close();
  });

  it('pnl matches ledger trial for sample period', async () => {
    await prisma.periodLock.deleteMany({ where: { periodYm } });
    await prisma.journalLine.deleteMany();
    await prisma.journalEntry.deleteMany();
    await prisma.shift.updateMany({
      where: { storeId, closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
    });
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId } },
      create: {
        productId,
        storeId,
        qty: 30,
        minQty: 0,
        avgCostVnd: 9000,
      },
      update: { qty: 30, avgCostVnd: 9000 },
    });
    const shift = await prisma.shift.create({
      data: {
        id: randomUUID(),
        storeId,
        userId,
        openedAt: new Date(),
        openingCash: 0,
      },
    });
    const saleId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'e2e-period',
        sales: [
          {
            id: saleId,
            storeId,
            shiftId: shift.id,
            paymentMethod: 'cash',
            cashAmount: 15000,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 15000,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                id: randomUUID(),
                productId,
                qty: '1',
                unitPrice: 15000,
                lineTotal: 15000,
              },
            ],
          },
        ],
      })
      .expect(201);

    const tb = await request(app.getHttpServer())
      .get('/reports/period/trial-balance')
      .query({ periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    const ledgerTb = await request(app.getHttpServer())
      .get('/ledger/trial-balance')
      .query({ periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(tb.body.rows).toEqual(ledgerTb.body.rows);

    const pnl = await request(app.getHttpServer())
      .get('/reports/period/pnl')
      .query({ periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(pnl.body.revenueVnd).toBe(15000);
    expect(pnl.body.cogsVnd).toBe(9000);
    expect(pnl.body.grossProfitVnd).toBe(6000);

    const exp = await request(app.getHttpServer())
      .get('/reports/period/export.csv')
      .query({ periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(exp.body.csv).toContain('trial_balance');
    expect(exp.body.csv).toContain('net_income');
  });

  /**
   * H3: owner xem "Tổng hợp" (storeId=null) trên màn `ledger_page.dart` —
   * tab "Cân đối phát sinh" gọi `/ledger/trial-balance`, tab "Báo cáo kỳ"
   * gọi `/reports/period/*`. Cả hai PHẢI cùng gồm (hoặc cùng không gồm) sổ
   * sách lịch sử của một điểm bán đã bị đánh dấu `active=false` — dựng lại
   * đúng kịch bản: bán hàng thật (còn active) rồi mới ngừng hoạt động, xác
   * nhận không phát sinh 2 con số khác nhau giữa 2 tab.
   *
   * Dùng delta (trước/sau) thay vì so số tuyệt đối để không phụ thuộc vào
   * trạng thái để lại bởi các spec khác chạy trước trong cùng phiên
   * `--runInBand` (nhiều spec kế toán khác tự wipe journal trước khi assert
   * — xem "Ghi chú review H3" trong plan doc — nhưng bài test này không cần
   * dựa vào giả định đó).
   */
  it('H3: inactive store historical journal stays consistent between /ledger/trial-balance and /reports/period/*', async () => {
    const row511 = (rows: Array<{ accountCode: string; creditVnd: number }>) =>
      rows.find((r) => r.accountCode === '511')?.creditVnd ?? 0;

    const baselineLedgerTb = await request(app.getHttpServer())
      .get('/ledger/trial-balance')
      .query({ periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    const baselinePeriodTb = await request(app.getHttpServer())
      .get('/reports/period/trial-balance')
      .query({ periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    const baselinePnl = await request(app.getHttpServer())
      .get('/reports/period/pnl')
      .query({ periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    const baselineLedger511 = row511(baselineLedgerTb.body.rows);
    const baselinePeriod511 = row511(baselinePeriodTb.body.rows);

    // Hiện chưa có endpoint nào set Store.active=false (xem
    // stores.service.ts::StoreMutationData) — set thẳng qua Prisma, đúng
    // trình tự thật: bán hàng khi CÒN active, rồi mới đánh dấu ngừng hoạt
    // động sau đó (không phải đóng cửa rồi mới có bút toán).
    const inactiveStore = await prisma.store.create({
      data: {
        code: `H3INACT${Date.now().toString().slice(-8)}`,
        name: 'H3 inactive store (e2e)',
      },
    });
    const REVENUE_VND = 77_000;

    await prisma.productStoreStock.create({
      data: {
        productId,
        storeId: inactiveStore.id,
        qty: 10,
        minQty: 0,
        avgCostVnd: 9000,
      },
    });
    const shift = await prisma.shift.create({
      data: {
        id: randomUUID(),
        storeId: inactiveStore.id,
        userId,
        openedAt: new Date(),
        openingCash: 0,
      },
    });
    const saleId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'e2e-h3-inactive-store',
        sales: [
          {
            id: saleId,
            storeId: inactiveStore.id,
            shiftId: shift.id,
            paymentMethod: 'cash',
            cashAmount: REVENUE_VND,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: REVENUE_VND,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                id: randomUUID(),
                productId,
                qty: '1',
                unitPrice: REVENUE_VND,
                lineTotal: REVENUE_VND,
              },
            ],
          },
        ],
      })
      .expect(201);

    const postedEntry = await prisma.journalEntry.findUnique({
      where: { sourceType_sourceId: { sourceType: 'sale', sourceId: saleId } },
    });
    // Sanity: bút toán thật đã lên sổ TRƯỚC KHI điểm bán bị đánh dấu ngừng
    // hoạt động — nếu bước này fail thì phần dưới vô nghĩa (test giả).
    expect(postedEntry).toBeTruthy();

    try {
      await prisma.store.update({
        where: { id: inactiveStore.id },
        data: { active: false },
      });

      const ledgerTb = await request(app.getHttpServer())
        .get('/ledger/trial-balance')
        .query({ periodYm })
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      const periodTb = await request(app.getHttpServer())
        .get('/reports/period/trial-balance')
        .query({ periodYm })
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      const pnl = await request(app.getHttpServer())
        .get('/reports/period/pnl')
        .query({ periodYm })
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      // (1) DoD cốt lõi của H3: 2 API dùng chung 1 màn hình phải khớp
      // TUYỆT ĐỐI (không chỉ "tương tự") khi cùng storeId=null.
      expect(periodTb.body.rows).toEqual(ledgerTb.body.rows);

      // (2) Quyết định thiết kế đã chọn = "Tổng hợp" CÓ gồm sổ sách lịch sử
      // của store vừa ngừng hoạt động (không chỉ nhất quán-với-nhau — 2 bên
      // có thể "nhất quán" nhưng cùng sai nếu cả hai cùng loại trừ). Xác
      // nhận doanh thu tăng ĐÚNG BẰNG giá trị đơn hàng vừa bán, ở cả 3 nơi.
      expect(row511(ledgerTb.body.rows) - baselineLedger511).toBe(
        REVENUE_VND,
      );
      expect(row511(periodTb.body.rows) - baselinePeriod511).toBe(
        REVENUE_VND,
      );
      expect(pnl.body.revenueVnd - baselinePnl.body.revenueVnd).toBe(
        REVENUE_VND,
      );
      expect(periodTb.body.storeIds).toContain(inactiveStore.id);
    } finally {
      // Dọn bút toán của store tạm — tránh rò rỉ số liệu "Tổng hợp" sang
      // các spec kế toán khác chạy sau trong cùng phiên --runInBand (đa số
      // đã tự wipe journal trước khi assert số tuyệt đối, nhưng dọn ở đây
      // để không phải dựa vào giả định đó — xem ledger.e2e-spec.ts, cùng
      // triết lý dọn periodLock để không rò rỉ sang spec khác).
      await prisma.journalLine.deleteMany({
        where: { entry: { storeId: inactiveStore.id } },
      });
      await prisma.journalEntry.deleteMany({
        where: { storeId: inactiveStore.id },
      });
    }
  });
});
