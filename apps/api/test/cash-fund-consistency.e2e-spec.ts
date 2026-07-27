import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

const CATEGORY_OTHER_IN = 'a1000000-0000-4000-8000-000000000001';
const CATEGORY_ELECTRICITY = 'a1000000-0000-4000-8000-000000000002';

/** Kỳ ICT (UTC+7) của một mốc thời gian + khoảng from/to phủ trọn kỳ đó. */
function ictPeriodRange(at: Date) {
  const ict = new Date(at.getTime() + 7 * 3600_000);
  const y = ict.getUTCFullYear();
  const m = ict.getUTCMonth() + 1;
  const periodYm = `${y}-${String(m).padStart(2, '0')}`;
  const from = new Date(Date.UTC(y, m - 1, 1) - 7 * 3600_000);
  const to = new Date(Date.UTC(y, m, 1) - 7 * 3600_000 - 1);
  return { periodYm, from: from.toISOString(), to: to.toISOString() };
}

describe('Sổ quỹ khớp sổ cái TK 111', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;
  let userId: string;
  let storeId: string;
  let storeId2: string;
  let productId: string;

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
    storeId2 = (await prisma.store.findFirst({ where: { code: 'CH2' } }))!.id;
    productId = (await prisma.product.findUnique({
      where: { sku: 'STING-330' },
    }))!.id;
  });

  afterAll(async () => {
    await app.close();
  });

  /** Xoá mọi chứng từ + bút toán của điểm bán để test không lẫn dữ liệu spec khác. */
  async function resetStoreData() {
    await prisma.periodLock.deleteMany();
    await prisma.journalLine.deleteMany({ where: { entry: { storeId } } });
    await prisma.journalEntry.deleteMany({ where: { storeId } });
    await prisma.supplierPayment.deleteMany({ where: { storeId } });
    await prisma.supplierPayable.deleteMany({ where: { storeId } });
    await prisma.purchaseReceiptLine.deleteMany({
      where: { receipt: { storeId } },
    });
    await prisma.purchaseReceipt.deleteMany({ where: { storeId } });
    await prisma.cashVoucher.deleteMany({ where: { storeId } });
    await prisma.debtLedgerEntry.deleteMany({ where: { storeId } });
    await prisma.eInvoice.deleteMany({ where: { sale: { storeId } } });
    await prisma.saleReturnLine.deleteMany({
      where: { saleReturn: { storeId } },
    });
    await prisma.saleReturn.deleteMany({ where: { storeId } });
    await prisma.saleLine.deleteMany({ where: { sale: { storeId } } });
    await prisma.sale.deleteMany({ where: { storeId } });
    await prisma.customer.deleteMany({ where: { storeId } });
    await prisma.shift.updateMany({
      where: { storeId, closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
    });
  }

  it('netCashVnd của /reports/cash-fund bằng số dư TK 111 cùng kỳ/điểm bán', async () => {
    await resetStoreData();

    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId } },
      create: { productId, storeId, qty: 500, minQty: 0, avgCostVnd: 9000 },
      update: { qty: 500, avgCostVnd: 9000 },
    });

    // ---- mở ca ----
    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${token}`)
      .send({ storeId, openingCash: 500_000, clientId: shiftId })
      .expect(201);

    // Chứng từ phải có clientCreatedAt >= shift.openedAt (sync.service.ts
    // kiểm tra 'shift_not_open_at_sale'), nên lấy mốc thời gian SAU khi mở ca.
    const at = new Date();
    const nowIso = at.toISOString();
    const { periodYm, from, to } = ictPeriodRange(at);

    // ---- khách nợ ----
    const customerId = randomUUID();
    await request(app.getHttpServer())
      .post('/customers')
      .set('Authorization', `Bearer ${token}`)
      .send({ id: customerId, storeId, name: 'Khach So Quy' })
      .expect(201);

    // ---- bán tiền mặt + bán chuyển khoản + bán nợ ----
    const cashSaleId = randomUUID();
    const transferSaleId = randomUUID();
    const debtSaleId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'cash-fund-consistency',
        sales: [
          {
            id: cashSaleId,
            storeId,
            shiftId,
            soldById: userId,
            paymentMethod: 'cash',
            cashAmount: 100_000,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 100_000,
            clientCreatedAt: nowIso,
            lines: [
              {
                id: randomUUID(),
                productId,
                qty: '2',
                unitPrice: 50_000,
                lineTotal: 100_000,
              },
            ],
          },
          {
            id: transferSaleId,
            storeId,
            shiftId,
            soldById: userId,
            paymentMethod: 'transfer',
            cashAmount: 0,
            transferAmount: 40_000,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 40_000,
            clientCreatedAt: nowIso,
            lines: [
              {
                id: randomUUID(),
                productId,
                qty: '1',
                unitPrice: 40_000,
                lineTotal: 40_000,
              },
            ],
          },
          {
            id: debtSaleId,
            storeId,
            shiftId,
            soldById: userId,
            paymentMethod: 'debt',
            cashAmount: 0,
            transferAmount: 0,
            debtAmount: 200_000,
            discountVnd: 0,
            totalVnd: 200_000,
            customerId,
            clientCreatedAt: nowIso,
            lines: [
              {
                id: randomUUID(),
                productId,
                qty: '4',
                unitPrice: 50_000,
                lineTotal: 200_000,
              },
            ],
          },
        ],
      })
      .expect(201)
      .expect((res) => {
        expect(res.body.rejected ?? []).toHaveLength(0);
        expect(res.body.acceptedIds).toHaveLength(3);
      });

    // ---- thu nợ tiền mặt + thu nợ chuyển khoản ----
    const debtPayCashId = randomUUID();
    const debtPayTransferId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'cash-fund-consistency',
        sales: [],
        debtPayments: [
          {
            id: debtPayCashId,
            storeId,
            customerId,
            amountVnd: 60_000,
            paymentMethod: 'cash',
            shiftId,
            clientCreatedAt: nowIso,
          },
          {
            id: debtPayTransferId,
            storeId,
            customerId,
            amountVnd: 25_000,
            paymentMethod: 'transfer',
            shiftId,
            clientCreatedAt: nowIso,
          },
        ],
      })
      .expect(201)
      .expect((res) => {
        expect(res.body.rejectedDebtPayments ?? []).toHaveLength(0);
      });

    // ---- phiếu thu / phiếu chi (tiền mặt + chuyển khoản) ----
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'cash-fund-consistency',
        sales: [],
        cashVouchers: [
          {
            id: randomUUID(),
            storeId,
            shiftId,
            categoryId: CATEGORY_OTHER_IN,
            direction: 'in',
            channel: 'cash',
            amountVnd: 50_000,
            clientCreatedAt: nowIso,
          },
          {
            id: randomUUID(),
            storeId,
            shiftId,
            categoryId: CATEGORY_ELECTRICITY,
            direction: 'out',
            channel: 'cash',
            amountVnd: 30_000,
            clientCreatedAt: nowIso,
          },
          {
            id: randomUUID(),
            storeId,
            shiftId,
            categoryId: CATEGORY_OTHER_IN,
            direction: 'in',
            channel: 'transfer',
            amountVnd: 11_000,
            clientCreatedAt: nowIso,
          },
        ],
      })
      .expect(201)
      .expect((res) => {
        expect(res.body.rejectedCashVouchers ?? []).toHaveLength(0);
      });

    // ---- nhập hàng NCC để có công nợ phải trả ----
    const receiptId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'cash-fund-consistency',
        sales: [],
        purchaseReceipts: [
          {
            id: receiptId,
            storeId,
            supplierName: 'NCC So Quy',
            clientCreatedAt: nowIso,
            lines: [
              {
                id: randomUUID(),
                productId,
                qty: '10',
                unitCostVnd: 9_000,
              },
            ],
          },
        ],
      })
      .expect(201);

    const payable = await prisma.supplierPayable.findFirstOrThrow({
      where: { purchaseReceiptId: receiptId },
    });

    // ---- chi trả NCC tiền mặt + chuyển khoản ----
    await request(app.getHttpServer())
      .post(`/suppliers/${payable.supplierId}/payments`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        storeId,
        amountVnd: 25_000,
        channel: 'cash',
        clientCreatedAt: nowIso,
      })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/suppliers/${payable.supplierId}/payments`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        storeId,
        amountVnd: 9_000,
        channel: 'transfer',
        clientCreatedAt: nowIso,
      })
      .expect(201);

    // ---- trả hàng bán, hoàn tiền mặt ----
    const returnId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'cash-fund-consistency',
        sales: [],
        saleReturns: [
          {
            id: returnId,
            storeId,
            originalSaleId: cashSaleId,
            shiftId,
            cashRefundVnd: 50_000,
            transferRefundVnd: 0,
            debtCreditVnd: 0,
            totalRefundVnd: 50_000,
            clientCreatedAt: nowIso,
            lines: [
              {
                id: randomUUID(),
                productId,
                qty: '1',
                unitPrice: 50_000,
                lineRefundVnd: 50_000,
              },
            ],
          },
        ],
      })
      .expect(201)
      .expect((res) => {
        expect(res.body.acceptedSaleReturnIds).toContain(returnId);
      });

    // ---- sổ quỹ ----
    const fund = await request(app.getHttpServer())
      .get('/reports/cash-fund')
      .query({ storeId, from, to })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    // 100.000 (bán TM) + 60.000 (thu nợ TM) + 50.000 (phiếu thu)
    // − 30.000 (phiếu chi) − 25.000 (chi NCC TM) − 50.000 (hoàn trả hàng)
    expect(fund.body.netCashVnd).toBe(105_000);
    expect(fund.body.saleCashVnd).toBe(100_000);
    expect(fund.body.saleTransferVnd).toBe(40_000);
    expect(fund.body.voucherInVnd).toBe(50_000);
    expect(fund.body.voucherOutVnd).toBe(30_000);
    expect(fund.body.debtPaymentCashVnd).toBe(60_000);
    expect(fund.body.supplierPaymentCashVnd).toBe(25_000);
    expect(fund.body.saleReturnCashVnd).toBe(50_000);
    // 40.000 + 25.000 + 11.000 − 9.000
    expect(fund.body.netTransferVnd).toBe(67_000);

    // ---- BẤT BIẾN: sổ quỹ == sổ cái TK 111 ----
    const tb = await request(app.getHttpServer())
      .get('/ledger/trial-balance')
      .query({ periodYm, storeId })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    const row111 = tb.body.rows.find(
      (r: { accountCode: string }) => r.accountCode === '111',
    );
    expect(row111).toBeTruthy();
    expect(fund.body.netCashVnd).toBe(row111.balanceVnd);
    expect(fund.body.ledgerNetCashVnd).toBe(row111.balanceVnd);
    expect(fund.body.ledgerDiffVnd).toBe(0);

    const row112 = tb.body.rows.find(
      (r: { accountCode: string }) => r.accountCode === '112',
    );
    expect(fund.body.netTransferVnd).toBe(row112.balanceVnd);

    // Đối chiếu thêm qua sổ chi tiết TK 111 (phát sinh trong kỳ)
    const ledger111 = await request(app.getHttpServer())
      .get('/ledger/account-ledger')
      .query({ accountCode: '111', periodYm, storeId })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(
      ledger111.body.closingBalance - ledger111.body.openingBalance,
    ).toBe(fund.body.netCashVnd);
  });

  it('chứng từ bị khoá kỳ làm lệch sổ quỹ ↔ sổ cái và ledgerDiffVnd chỉ ra điều đó', async () => {
    await resetStoreData();

    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${token}`)
      .send({ storeId, openingCash: 0, clientId: shiftId })
      .expect(201);

    const at = new Date();
    const nowIso = at.toISOString();
    const { periodYm, from, to } = ictPeriodRange(at);

    await request(app.getHttpServer())
      .post('/ledger/period-locks')
      .set('Authorization', `Bearer ${token}`)
      .send({ periodYm })
      .expect(201);

    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'cash-fund-locked',
        sales: [],
        cashVouchers: [
          {
            id: randomUUID(),
            storeId,
            shiftId,
            categoryId: CATEGORY_OTHER_IN,
            direction: 'in',
            channel: 'cash',
            amountVnd: 70_000,
            clientCreatedAt: nowIso,
          },
        ],
      })
      .expect(201);

    const fund = await request(app.getHttpServer())
      .get('/reports/cash-fund')
      .query({ storeId, from, to })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    // Chứng từ có, bút toán bị chặn ⇒ lệch hợp lệ và phải hiện ra ở ledgerDiffVnd
    expect(fund.body.netCashVnd).toBe(70_000);
    expect(fund.body.ledgerNetCashVnd).toBe(0);
    expect(fund.body.ledgerDiffVnd).toBe(70_000);

    await prisma.periodLock.deleteMany({ where: { periodYm } });
  });

  it('P2.2: GET /reports/cash-fund không kèm storeId gộp theo scope role — owner thấy mọi điểm bán kèm byStore, store_manager chỉ thấy điểm của mình', async () => {
    const at = new Date();
    const nowIso = at.toISOString();
    const { from, to } = ictPeriodRange(at);

    await prisma.shift.updateMany({
      where: { storeId: { in: [storeId, storeId2] }, closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
    });
    const shift1Id = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${token}`)
      .send({ storeId, openingCash: 0, clientId: shift1Id })
      .expect(201);
    const shift2Id = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${token}`)
      .send({ storeId: storeId2, openingCash: 0, clientId: shift2Id })
      .expect(201);

    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'cash-fund-aggregate',
        sales: [],
        cashVouchers: [
          {
            id: randomUUID(),
            storeId,
            shiftId: shift1Id,
            categoryId: CATEGORY_OTHER_IN,
            direction: 'in',
            channel: 'cash',
            amountVnd: 77_000,
            clientCreatedAt: nowIso,
          },
          {
            id: randomUUID(),
            storeId: storeId2,
            shiftId: shift2Id,
            categoryId: CATEGORY_OTHER_IN,
            direction: 'in',
            channel: 'cash',
            amountVnd: 33_000,
            clientCreatedAt: nowIso,
          },
        ],
      })
      .expect(201)
      .expect((res) => {
        expect(res.body.rejectedCashVouchers ?? []).toHaveLength(0);
      });

    const store1Only = await request(app.getHttpServer())
      .get('/reports/cash-fund')
      .query({ storeId, from, to })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    const store2Only = await request(app.getHttpServer())
      .get('/reports/cash-fund')
      .query({ storeId: storeId2, from, to })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    // Backward-compat: storeId truyền vào vẫn trả shape cũ, chỉ thêm byStore.
    expect(store1Only.body.storeId).toBe(storeId);
    expect(store1Only.body.byStore).toHaveLength(1);
    expect(store1Only.body.byStore[0]).toMatchObject({
      storeId,
      netCashVnd: store1Only.body.netCashVnd,
    });

    // ---- owner: không truyền storeId ⇒ gộp mọi điểm bán active ----
    const aggregate = await request(app.getHttpServer())
      .get('/reports/cash-fund')
      .query({ from, to })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(aggregate.body.storeId).toBeNull();
    expect(aggregate.body.scope).toBe('aggregate');
    expect([...aggregate.body.storeIds].sort()).toEqual(
      [storeId, storeId2].sort(),
    );
    expect(aggregate.body.netCashVnd).toBe(
      store1Only.body.netCashVnd + store2Only.body.netCashVnd,
    );
    const byStoreMap: Record<string, { netCashVnd: number }> =
      Object.fromEntries(
        aggregate.body.byStore.map((s: { storeId: string }) => [
          s.storeId,
          s,
        ]),
      );
    expect(byStoreMap[storeId].netCashVnd).toBe(store1Only.body.netCashVnd);
    expect(byStoreMap[storeId2].netCashVnd).toBe(store2Only.body.netCashVnd);

    // ---- store_manager chỉ gán CH1: không truyền storeId ⇒ chỉ thấy CH1 ----
    const managerPhone = '0950200001';
    await request(app.getHttpServer())
      .post('/users')
      .set('Authorization', `Bearer ${token}`)
      .send({
        phone: managerPhone,
        name: 'QL so quy tong',
        password: '123456',
        role: 'store_manager',
        storeIds: [storeId],
        canLedger: true,
      })
      .expect(201);
    const managerLogin = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: managerPhone, password: '123456' })
      .expect(201);
    const managerToken = managerLogin.body.accessToken as string;
    const managerUserId = managerLogin.body.user.id as string;

    const managerAggregate = await request(app.getHttpServer())
      .get('/reports/cash-fund')
      .query({ from, to })
      .set('Authorization', `Bearer ${managerToken}`)
      .expect(200);
    expect(managerAggregate.body.scope).toBe('aggregate');
    expect(managerAggregate.body.storeIds).toEqual([storeId]);
    expect(managerAggregate.body.netCashVnd).toBe(store1Only.body.netCashVnd);
    expect(managerAggregate.body.byStore).toHaveLength(1);
    expect(managerAggregate.body.byStore[0].storeId).toBe(storeId);

    // store_manager không được thấy điểm bán mình không thuộc.
    await request(app.getHttpServer())
      .get('/reports/cash-fund')
      .query({ storeId: storeId2, from, to })
      .set('Authorization', `Bearer ${managerToken}`)
      .expect(403);

    await prisma.userStore.deleteMany({ where: { userId: managerUserId } });
    await prisma.user.deleteMany({ where: { id: managerUserId } });
  });
});
