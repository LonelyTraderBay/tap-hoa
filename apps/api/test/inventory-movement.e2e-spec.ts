import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcrypt';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * P2.3 — báo cáo nhập-xuất-tồn theo kỳ/điểm (`GET /reports/inventory-movement`).
 *
 * Kỳ test cố định `2026-02` (quá khứ, không phải "now") để hoàn toàn tự chủ
 * biên [from, to] mà không phụ thuộc thời điểm chạy test — và để không đụng
 * độ với các test khác dùng periodYm suy từ `new Date()` (luôn là kỳ thật
 * hiện tại của máy chạy test). Sản phẩm test dùng SKU ngẫu nhiên duy nhất
 * nên không thể va chạm dữ liệu với bất kỳ file test nào khác dù chạy theo
 * thứ tự nào (bài học rút ra từ P1.4: Jest không đảm bảo thứ tự file).
 */
describe('P2.3 inventory movement report e2e', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let ownerToken: string;
  let ownerId: string;
  let storeCh1: string;
  let storeCh2: string;
  let supplierId: string;
  let shiftId: string;

  let productMoveId: string;
  let productStaticId: string;
  let receiptOpeningId: string;
  let receiptInPeriodId: string;
  let receiptAfterPeriodId: string;
  let saleId: string;
  let wastageId: string;

  const PERIOD_YM = '2026-02';
  // Biên kỳ UTC+7 tương ứng '2026-02' — dùng để đặt mốc "trước kỳ"/"trong kỳ"
  // rõ ràng, khớp đúng công thức periodBoundsIct trong reports.service.ts.
  const BEFORE_PERIOD = '2026-01-15T03:00:00.000Z';
  const IN_PERIOD_1 = '2026-02-05T03:00:00.000Z';
  const IN_PERIOD_2 = '2026-02-10T03:00:00.000Z';
  const IN_PERIOD_3 = '2026-02-15T03:00:00.000Z';
  const AFTER_PERIOD = '2026-03-05T03:00:00.000Z';

  async function login(phone: string, password = '123456') {
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone, password })
      .expect(201);
    return {
      accessToken: res.body.accessToken as string,
      user: res.body.user as { id: string },
    };
  }

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    prisma = moduleRef.get(PrismaService);
    await app.init();

    const ch1 = await prisma.store.findFirstOrThrow({ where: { code: 'CH1' } });
    const ch2 = await prisma.store.findFirstOrThrow({ where: { code: 'CH2' } });
    storeCh1 = ch1.id;
    storeCh2 = ch2.id;

    const owner = await login('0900000001');
    ownerToken = owner.accessToken;
    ownerId = owner.user.id;

    const supplier = await prisma.supplier.create({
      data: { id: randomUUID(), name: `P2.3 NCC ${randomUUID().slice(0, 8)}` },
    });
    supplierId = supplier.id;

    const suffix = randomUUID().slice(0, 8);
    const productMove = await prisma.product.create({
      data: {
        sku: `P23-MOVE-${suffix}`,
        name: `P2.3 SP di chuyen ${suffix}`,
        unit: 'cai',
        basePriceVnd: 15000,
        costVnd: 8000,
        active: true,
      },
    });
    productMoveId = productMove.id;

    const productStatic = await prisma.product.create({
      data: {
        sku: `P23-STATIC-${suffix}`,
        name: `P2.3 SP dung im ${suffix}`,
        unit: 'hop',
        basePriceVnd: 20000,
        costVnd: 10000,
        active: true,
      },
    });
    productStaticId = productStatic.id;

    // Ca đã đóng, cửa mở trước kỳ và đóng sau kỳ — đủ điều kiện ghi nhận
    // sale trong kỳ (shift_not_open_at_sale) mà KHÔNG bao giờ va chạm với
    // ràng buộc "chỉ 1 ca mở/user/điểm bán" (partial unique index chỉ áp
    // dụng khi closedAt IS NULL — ca này closedAt luôn có giá trị).
    const shift = await prisma.shift.create({
      data: {
        id: randomUUID(),
        storeId: storeCh1,
        userId: ownerId,
        openedAt: new Date(BEFORE_PERIOD),
        closedAt: new Date(AFTER_PERIOD),
        openingCash: 0,
      },
    });
    shiftId = shift.id;

    // --- Dựng lịch sử StockMovement theo đúng thứ tự thời gian thật ---
    // (server tính balanceAfter theo thứ tự XỬ LÝ, không tự sắp lại theo
    // clientCreatedAt — nên phải push tuần tự đúng trình tự thời gian).

    // 1) Trước kỳ (Jan): nhập cả 2 sản phẩm — đây là "tồn đầu kỳ" của Feb.
    receiptOpeningId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        deviceId: 'p23-dev',
        sales: [],
        purchaseReceipts: [
          {
            id: receiptOpeningId,
            storeId: storeCh1,
            supplierId,
            supplierName: 'P2.3 NCC',
            clientCreatedAt: BEFORE_PERIOD,
            lines: [
              { id: randomUUID(), productId: productMoveId, qty: '50' },
              { id: randomUUID(), productId: productStaticId, qty: '30' },
            ],
          },
        ],
      })
      .expect(201);

    // 2) Trong kỳ: nhập thêm 30 cho productMove (docType=purchase, +30).
    receiptInPeriodId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        deviceId: 'p23-dev',
        sales: [],
        purchaseReceipts: [
          {
            id: receiptInPeriodId,
            storeId: storeCh1,
            supplierId,
            supplierName: 'P2.3 NCC',
            clientCreatedAt: IN_PERIOD_1,
            lines: [{ id: randomUUID(), productId: productMoveId, qty: '30' }],
          },
        ],
      })
      .expect(201);

    // 3) Trong kỳ: bán 12 (docType=sale, -12).
    saleId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        deviceId: 'p23-dev',
        sales: [
          {
            id: saleId,
            storeId: storeCh1,
            shiftId,
            soldById: ownerId,
            paymentMethod: 'cash',
            cashAmount: 12 * 15000,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 12 * 15000,
            customerId: null,
            clientCreatedAt: IN_PERIOD_2,
            lines: [
              {
                productId: productMoveId,
                qty: '12',
                unitPrice: 15000,
                lineTotal: 12 * 15000,
              },
            ],
          },
        ],
      })
      .expect(201);

    // 4) Trong kỳ: hủy 5 (docType=wastage, -5).
    wastageId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        deviceId: 'p23-dev',
        sales: [],
        wastages: [
          {
            id: wastageId,
            storeId: storeCh1,
            reasonCode: 'spoilage',
            clientCreatedAt: IN_PERIOD_3,
            lines: [{ productId: productMoveId, qty: '5' }],
          },
        ],
      })
      .expect(201);

    // 5) Sau kỳ (Mar): nhập thêm — KHÔNG được lọt vào báo cáo kỳ Feb.
    receiptAfterPeriodId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        deviceId: 'p23-dev',
        sales: [],
        purchaseReceipts: [
          {
            id: receiptAfterPeriodId,
            storeId: storeCh1,
            supplierId,
            supplierName: 'P2.3 NCC',
            clientCreatedAt: AFTER_PERIOD,
            lines: [{ id: randomUUID(), productId: productMoveId, qty: '99' }],
          },
        ],
      })
      .expect(201);
  });

  afterAll(async () => {
    // Dọn đúng những gì test này tạo ra — theo docId cụ thể, không đụng dữ
    // liệu của file khác (xem bài học rò rỉ state ở P1.4/P2.2).
    const docIds = [
      receiptOpeningId,
      receiptInPeriodId,
      receiptAfterPeriodId,
      saleId,
      wastageId,
    ];
    await prisma.journalLine.deleteMany({
      where: { entry: { sourceId: { in: docIds } } },
    });
    await prisma.journalEntry.deleteMany({
      where: { sourceId: { in: docIds } },
    });
    await prisma.stockMovement.deleteMany({
      where: { productId: { in: [productMoveId, productStaticId] } },
    });
    await prisma.saleLine.deleteMany({ where: { saleId } });
    await prisma.sale.deleteMany({ where: { id: saleId } });
    await prisma.wastageVoucherLine.deleteMany({ where: { wastageId } });
    await prisma.wastageVoucher.deleteMany({ where: { id: wastageId } });
    await prisma.supplierPayable.deleteMany({
      where: { purchaseReceiptId: { in: docIds } },
    });
    await prisma.purchaseReceiptLine.deleteMany({
      where: { receiptId: { in: docIds } },
    });
    await prisma.purchaseReceipt.deleteMany({ where: { id: { in: docIds } } });
    await prisma.productStoreStock.deleteMany({
      where: { productId: { in: [productMoveId, productStaticId] } },
    });
    await prisma.shift.deleteMany({ where: { id: shiftId } });
    await prisma.product.deleteMany({
      where: { id: { in: [productMoveId, productStaticId] } },
    });
    await prisma.supplier.deleteMany({ where: { id: supplierId } });
    await app.close();
  });

  it('validate periodYm dạng YYYY-MM và storeId bắt buộc', async () => {
    await request(app.getHttpServer())
      .get('/reports/inventory-movement')
      .query({ periodYm: PERIOD_YM })
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(400);

    await request(app.getHttpServer())
      .get('/reports/inventory-movement')
      .query({ storeId: storeCh1, periodYm: '2026-2' })
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(400);

    await request(app.getHttpServer())
      .get('/reports/inventory-movement')
      .query({ storeId: storeCh1, periodYm: PERIOD_YM })
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
  });

  it('tồn đầu kỳ, nhập/xuất theo docType, và tồn cuối kỳ đúng cho sản phẩm có biến động', async () => {
    const res = await request(app.getHttpServer())
      .get('/reports/inventory-movement')
      .query({ storeId: storeCh1, periodYm: PERIOD_YM })
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);

    expect(res.body.storeId).toBe(storeCh1);
    expect(res.body.periodYm).toBe(PERIOD_YM);

    const item = (res.body.items as any[]).find(
      (i) => i.productId === productMoveId,
    );
    expect(item).toBeDefined();
    expect(item.sku).toMatch(/^P23-MOVE-/);
    expect(item.unit).toBe('cai');

    // Tồn đầu kỳ = 50 (nhập Jan) — bất chấp việc nhập/bán/hủy diễn ra sau đó.
    expect(item.openingQty).toBe(50);
    // Nhập trong kỳ: +30 (purchase). Nhập tháng 3 (99) KHÔNG được tính.
    expect(item.inQty).toBe(30);
    expect(item.inByDocType).toEqual({ purchase: 30 });
    // Xuất trong kỳ: 12 (sale) + 5 (wastage) = 17.
    expect(item.outQty).toBe(17);
    expect(item.outByDocType).toEqual({ sale: 12, wastage: 5 });
    // Tồn cuối kỳ = 50 + 30 - 17 = 63.
    expect(item.closingQty).toBe(63);

    // Bất biến nội tại: closing == opening + in - out.
    expect(item.closingQty).toBe(item.openingQty + item.inQty - item.outQty);

    // Đối chiếu trực tiếp DB: closingQty phải khớp balanceAfter của dòng
    // StockMovement cuối cùng TRONG kỳ (không tính dòng tháng 3 sau kỳ) —
    // dùng đúng biên ICT [from, to] của periodBoundsIct('2026-02'), KHÔNG
    // phải mốc UTC ngây thơ (Feb 1 00:00 UTC lệch 7h so với Feb 1 00:00 ICT).
    const periodFromIct = new Date('2026-01-31T17:00:00.000Z');
    const periodToIct = new Date('2026-02-28T16:59:59.999Z');
    const lastInPeriod = await prisma.stockMovement.findFirst({
      where: {
        storeId: storeCh1,
        productId: productMoveId,
        clientCreatedAt: { gte: periodFromIct, lte: periodToIct },
      },
      orderBy: { clientCreatedAt: 'desc' },
    });
    expect(lastInPeriod?.clientCreatedAt.toISOString()).toBe(IN_PERIOD_3);
    expect(Number(lastInPeriod?.balanceAfter)).toBe(item.closingQty);
  });

  it('sản phẩm không có biến động trong kỳ vẫn hiện (opening == closing, nhập/xuất = 0)', async () => {
    const res = await request(app.getHttpServer())
      .get('/reports/inventory-movement')
      .query({ storeId: storeCh1, periodYm: PERIOD_YM })
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);

    const item = (res.body.items as any[]).find(
      (i) => i.productId === productStaticId,
    );
    expect(item).toBeDefined();
    expect(item.openingQty).toBe(30);
    expect(item.inQty).toBe(0);
    expect(item.outQty).toBe(0);
    expect(item.closingQty).toBe(30);
    expect(item.inByDocType).toEqual({});
    expect(item.outByDocType).toEqual({});
  });

  it('sản phẩm ngưng bán (active=false) vẫn hiện trong báo cáo của kỳ nó còn biến động', async () => {
    await prisma.product.update({
      where: { id: productMoveId },
      data: { active: false },
    });
    try {
      const res = await request(app.getHttpServer())
        .get('/reports/inventory-movement')
        .query({ storeId: storeCh1, periodYm: PERIOD_YM })
        .set('Authorization', `Bearer ${ownerToken}`)
        .expect(200);
      const item = (res.body.items as any[]).find(
        (i) => i.productId === productMoveId,
      );
      expect(item).toBeDefined();
      expect(item.closingQty).toBe(63);
    } finally {
      await prisma.product.update({
        where: { id: productMoveId },
        data: { active: true },
      });
    }
  });

  it('không cho xem tồn kho của điểm bán mình không thuộc về', async () => {
    const passwordHash = await bcrypt.hash('123456', 10);
    const scoped = await prisma.user.upsert({
      where: { phone: '0900000174' },
      update: {
        name: 'P2.3 QL CH1',
        role: 'store_manager',
        passwordHash,
        active: true,
        canLedger: false,
      },
      create: {
        phone: '0900000174',
        name: 'P2.3 QL CH1',
        role: 'store_manager',
        passwordHash,
        active: true,
        canLedger: false,
      },
    });
    await prisma.userStore.upsert({
      where: { userId_storeId: { userId: scoped.id, storeId: storeCh1 } },
      update: {},
      create: { userId: scoped.id, storeId: storeCh1 },
    });
    await prisma.userStore.deleteMany({
      where: { userId: scoped.id, storeId: { not: storeCh1 } },
    });
    try {
      const scopedLogin = await login('0900000174');
      await request(app.getHttpServer())
        .get('/reports/inventory-movement')
        .query({ storeId: storeCh1, periodYm: PERIOD_YM })
        .set('Authorization', `Bearer ${scopedLogin.accessToken}`)
        .expect(200);
      await request(app.getHttpServer())
        .get('/reports/inventory-movement')
        .query({ storeId: storeCh2, periodYm: PERIOD_YM })
        .set('Authorization', `Bearer ${scopedLogin.accessToken}`)
        .expect(403);
    } finally {
      await prisma.userStore.deleteMany({ where: { userId: scoped.id } });
      await prisma.user.deleteMany({ where: { id: scoped.id } });
    }
  });

  it('nhóm VẬN HÀNH — không đòi canLedger (khác nhóm kế toán)', async () => {
    const passwordHash = await bcrypt.hash('123456', 10);
    const cashier = await prisma.user.upsert({
      where: { phone: '0900000175' },
      update: {
        name: 'P2.3 Thu ngan',
        role: 'cashier',
        passwordHash,
        active: true,
        canLedger: false,
      },
      create: {
        phone: '0900000175',
        name: 'P2.3 Thu ngan',
        role: 'cashier',
        passwordHash,
        active: true,
        canLedger: false,
      },
    });
    await prisma.userStore.upsert({
      where: { userId_storeId: { userId: cashier.id, storeId: storeCh1 } },
      update: {},
      create: { userId: cashier.id, storeId: storeCh1 },
    });
    try {
      const cashierLogin = await login('0900000175');
      await request(app.getHttpServer())
        .get('/reports/inventory-movement')
        .query({ storeId: storeCh1, periodYm: PERIOD_YM })
        .set('Authorization', `Bearer ${cashierLogin.accessToken}`)
        .expect(200);
    } finally {
      await prisma.userStore.deleteMany({ where: { userId: cashier.id } });
      await prisma.user.deleteMany({ where: { id: cashier.id } });
    }
  });

  it('CSV export trả đúng dòng của sản phẩm có biến động', async () => {
    const res = await request(app.getHttpServer())
      .get('/reports/inventory-movement.csv')
      .query({ storeId: storeCh1, periodYm: PERIOD_YM })
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);

    expect(res.body.storeId).toBe(storeCh1);
    expect(res.body.periodYm).toBe(PERIOD_YM);
    const csv = res.body.csv as string;
    expect(csv.split('\n')[0]).toBe(
      'productId,sku,name,unit,openingQty,inQty,outQty,closingQty',
    );
    const row = csv.split('\n').find((line) => line.startsWith(productMoveId));
    expect(row).toBeDefined();
    expect(row).toContain(`P23-MOVE-`);
    expect(row).toContain('cai,50,30,17,63');
  });
});
