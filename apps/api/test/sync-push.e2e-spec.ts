import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

async function loginAsOwner(app: INestApplication) {
  const res = await request(app.getHttpServer())
    .post('/auth/login')
    .send({ phone: '0900000001', password: '123456' })
    .expect(201);
  return {
    accessToken: res.body.accessToken as string,
    user: res.body.user as { id: string },
  };
}

function makeSaleDto(
  saleId: string,
  opts: {
    storeId: string;
    shiftId: string;
    soldById: string;
    productId: string;
    qty?: string;
    totalVnd?: number;
    clientCreatedAt?: string;
  },
) {
  const qty = opts.qty ?? '2';
  const unitPrice = 10000;
  const totalVnd = opts.totalVnd ?? Number(qty) * unitPrice;
  return {
    id: saleId,
    storeId: opts.storeId,
    shiftId: opts.shiftId,
    soldById: opts.soldById,
    paymentMethod: 'cash',
    cashAmount: totalVnd,
    transferAmount: 0,
    debtAmount: 0,
    discountVnd: 0,
    totalVnd,
    customerId: null,
    clientCreatedAt: opts.clientCreatedAt ?? new Date().toISOString(),
    lines: [
      {
        productId: opts.productId,
        qty,
        unitPrice,
        discountVnd: 0,
        lineTotal: totalVnd,
      },
    ],
  };
}

describe('Sync push', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    prisma = moduleRef.get(PrismaService);
    await app.init();
  });

  beforeEach(async () => {
    await prisma.eInvoice.deleteMany();
    await prisma.saleReturnLine.deleteMany();
    await prisma.saleReturn.deleteMany();
    await prisma.saleLine.deleteMany();
    await prisma.sale.deleteMany();
    await prisma.shift.updateMany({
      where: { closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
    });
    const product = await prisma.product.findUnique({
      where: { sku: 'STING-330' },
    });
    const store = await prisma.store.findFirst({ where: { code: 'CH1' } });
    if (product && store) {
      await prisma.productStoreStock.update({
        where: {
          productId_storeId: { productId: product.id, storeId: store.id },
        },
        data: { qty: 100 },
      });
    }
  });

  afterAll(() => app.close());

  it('POST /sync/push accepts sale idempotently and decrements stock once', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id as string;
    const product = await prisma.product.findUnique({
      where: { sku: 'STING-330' },
    });
    if (!product) {
      throw new Error('Seed product STING-330 not found');
    }

    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 500000, clientId: shiftId })
      .expect(201);

    const saleId = '22222222-2222-2222-2222-222222222222';
    const sale = makeSaleDto(saleId, {
      storeId,
      shiftId,
      soldById: login.user.id,
      productId: product.id,
    });

    const first = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ deviceId: 'dev1', sales: [sale] })
      .expect(201);

    expect(first.body.acceptedIds).toEqual([saleId]);
    expect(first.body.rejected).toEqual([]);

    const second = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ deviceId: 'dev1', sales: [sale] })
      .expect(201);

    expect(second.body.acceptedIds).toEqual([saleId]);
    expect(second.body.rejected).toEqual([]);

    const stock = await prisma.productStoreStock.findUnique({
      where: {
        productId_storeId: { productId: product.id, storeId },
      },
    });
    expect(stock?.qty.toString()).toBe('98');

    await request(app.getHttpServer())
      .post(`/shifts/${shiftId}/close`)
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ closingCash: 500000 })
      .expect(201);
  });

  it('POST /sync/push opens an outbox shift before accepting its sale', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id as string;
    const product = await prisma.product.findUnique({
      where: { sku: 'STING-330' },
    });
    if (!product) {
      throw new Error('Seed product STING-330 not found');
    }

    const shiftId = randomUUID();
    const saleId = randomUUID();
    const openedAt = new Date().toISOString();
    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-shift-outbox',
        shiftOpens: [
          {
            id: shiftId,
            storeId,
            userId: login.user.id,
            openingCash: 100000,
            openedAt,
          },
        ],
        sales: [
          makeSaleDto(saleId, {
            storeId,
            shiftId,
            soldById: 'untrusted-client-user',
            productId: product.id,
            clientCreatedAt: openedAt,
          }),
        ],
      })
      .expect(201);

    expect(res.body.acceptedShiftIds).toEqual([shiftId]);
    expect(res.body.acceptedIds).toEqual([saleId]);
    const sale = await prisma.sale.findUnique({ where: { id: saleId } });
    expect(sale?.soldById).toBe(login.user.id);
  });

  it('POST /sync/push accepts weighted line totals rounded half-up to VND', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id as string;
    const product = await prisma.product.findUnique({
      where: { sku: 'STING-330' },
    });
    if (!product) {
      throw new Error('Seed product STING-330 not found');
    }

    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 0, clientId: shiftId })
      .expect(201);

    const saleId = randomUUID();
    const unitPrice = 15500;
    const lineTotal = 5162;
    const sale = {
      id: saleId,
      storeId,
      shiftId,
      soldById: login.user.id,
      paymentMethod: 'cash',
      cashAmount: lineTotal,
      transferAmount: 0,
      debtAmount: 0,
      discountVnd: 0,
      totalVnd: lineTotal,
      customerId: null,
      clientCreatedAt: new Date().toISOString(),
      lines: [
        {
          productId: product.id,
          qty: '0.333',
          unitPrice,
          lineTotal,
        },
      ],
    };

    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ deviceId: 'dev-weighted', sales: [sale] })
      .expect(201);

    expect(res.body.acceptedIds).toEqual([saleId]);
    expect(res.body.rejected).toEqual([]);
  });

  it('POST /sync/push accepts sale line discounts before invoice discount', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id as string;
    const product = await prisma.product.findUnique({
      where: { sku: 'STING-330' },
    });
    if (!product) {
      throw new Error('Seed product STING-330 not found');
    }

    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 0, clientId: shiftId })
      .expect(201);

    const saleId = randomUUID();
    const sale = {
      id: saleId,
      storeId,
      shiftId,
      soldById: login.user.id,
      paymentMethod: 'cash',
      cashAmount: 17000,
      transferAmount: 0,
      debtAmount: 0,
      discountVnd: 1000,
      totalVnd: 17000,
      customerId: null,
      clientCreatedAt: new Date().toISOString(),
      lines: [
        {
          productId: product.id,
          qty: '2',
          unitPrice: 10000,
          discountVnd: 2000,
          lineTotal: 18000,
        },
      ],
    };

    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ deviceId: 'dev-line-discount', sales: [sale] })
      .expect(201);

    expect(res.body.acceptedIds).toEqual([saleId]);
    expect(res.body.rejected).toEqual([]);
    const storedLine = await prisma.saleLine.findFirst({
      where: { saleId },
    });
    expect(storedLine?.discountVnd).toBe(2000);
    expect(storedLine?.lineTotal).toBe(18000);
  });

  it('POST /sync/push processes purchase receipts before same-push sales', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id as string;
    const product = await prisma.product.findUnique({
      where: { sku: 'STING-330' },
    });
    if (!product) {
      throw new Error('Seed product STING-330 not found');
    }
    await prisma.productStoreStock.upsert({
      where: {
        productId_storeId: { productId: product.id, storeId },
      },
      create: {
        productId: product.id,
        storeId,
        qty: 0,
        minQty: 0,
        avgCostVnd: 0,
      },
      update: { qty: 0, avgCostVnd: 0 },
    });

    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 0, clientId: shiftId })
      .expect(201);

    const receiptId = randomUUID();
    const saleId = randomUUID();
    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-receive-then-sell',
        purchaseReceipts: [
          {
            id: receiptId,
            storeId,
            supplierName: 'NCC Receive Then Sell',
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                id: randomUUID(),
                productId: product.id,
                qty: '2',
                unitCostVnd: 6000,
              },
            ],
          },
        ],
        sales: [
          makeSaleDto(saleId, {
            storeId,
            shiftId,
            soldById: login.user.id,
            productId: product.id,
            qty: '1',
            totalVnd: 10000,
          }),
        ],
      })
      .expect(201);

    expect(res.body.acceptedPurchaseReceiptIds).toContain(receiptId);
    expect(res.body.acceptedIds).toContain(saleId);
    const saleLine = await prisma.saleLine.findFirstOrThrow({
      where: { saleId },
    });
    expect(saleLine.unitCostVnd).toBe(6000);
    const stock = await prisma.productStoreStock.findUniqueOrThrow({
      where: { productId_storeId: { productId: product.id, storeId } },
    });
    expect(stock.qty.toString()).toBe('1');
  });

  // H6 (docs/superpowers/plans/2026-07-28-h1-h6-deep-audit-fixes.md): spec
  // (§3.5 inventory-stock-ops-design.md) mô tả thứ tự sau `sales`, nhưng
  // commit ab65fcc ("đã harden ... thứ tự sync kho→bán") đã CỐ Ý đảo
  // `pushInventory()` lên trước `pushSales()` — xác nhận bằng test phía
  // trên ("processes purchase receipts before same-push sales"). Test này
  // xác nhận vế còn lại (kho GIẢM tồn, không phải TĂNG).
  //
  // Lưu ý quan trọng phát hiện khi viết test này: sale dòng hàng THƯỜNG
  // (không phải combo) KHÔNG có điều kiện `qty - delta >= 0` trong câu UPDATE
  // thô (processSale, nhánh else) — server LUÔN chấp nhận sale kể cả khi âm
  // tồn (xem test có sẵn cùng file 'accepts concurrent offline sales and
  // allows negative stock', dòng ~495). Vì vậy "kết quả kiểm tra tồn kho
  // (insufficient_stock) phụ thuộc thứ tự" không thể hiện qua việc SALE bị
  // từ chối — mà hiện qua việc WASTAGE (có `requireNonNegative: true`) có bị
  // từ chối hay không, tuỳ thuộc quy trình xử lý wastage TRƯỚC hay SAU sale
  // (sale không tự giới hạn nên có thể "ăn" hết tồn trước khi wastage kịp
  // trừ). Test dưới đây dựng đúng kịch bản đó: tồn gốc 5, sale bán 3 (luôn
  // được chấp nhận), wastage hủy 3 CÙNG request — nếu kho xử lý TRƯỚC (thứ
  // tự hiện tại, giữ nguyên): wastage trừ trên tồn gốc 5 → còn 2, được chấp
  // nhận; sale trừ tiếp không giới hạn (2-3) → tồn cuối -1. Nếu đảo thứ tự
  // (sale trước): sale trừ trước (5-3=2, luôn được chấp nhận), wastage trừ
  // trên tồn còn 2 → âm (2-3=-1) → bị từ chối `insufficient_stock`, tồn cuối
  // giữ 2 (chỉ sale áp dụng). Test này khoá đúng nhánh THỨ NHẤT (thứ tự hiện
  // tại) làm bằng chứng chạy được cho quyết định giữ nguyên trong "Ghi chú
  // review H6".
  it('POST /sync/push processes wastage before same-push sale — giữ nguyên thứ tự kho→bán (H6)', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id as string;
    const product = await prisma.product.findUnique({
      where: { sku: 'STING-330' },
    });
    if (!product) {
      throw new Error('Seed product STING-330 not found');
    }
    // Tồn gốc 5: đủ cho wastage 3 nếu xét trên tồn gốc (kho xử lý trước,
    // đúng thứ tự hiện tại), KHÔNG đủ nếu sale 3 (luôn được chấp nhận,
    // không tự giới hạn) đã trừ tồn trước xuống còn 2 (5-3=2, thiếu 1 so
    // với 3 mà wastage cần).
    await prisma.productStoreStock.upsert({
      where: {
        productId_storeId: { productId: product.id, storeId },
      },
      create: { productId: product.id, storeId, qty: 5, minQty: 0 },
      update: { qty: 5 },
    });

    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 0, clientId: shiftId })
      .expect(201);

    const wastageId = randomUUID();
    const saleId = randomUUID();
    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-wastage-then-sell',
        wastages: [
          {
            id: wastageId,
            storeId,
            reasonCode: 'spoilage',
            clientCreatedAt: new Date().toISOString(),
            lines: [{ productId: product.id, qty: '3' }],
          },
        ],
        sales: [
          makeSaleDto(saleId, {
            storeId,
            shiftId,
            soldById: login.user.id,
            productId: product.id,
            qty: '3',
          }),
        ],
      })
      .expect(201);

    // Wastage được xử lý TRƯỚC (trên tồn gốc 5) nên được chấp nhận.
    expect(res.body.acceptedWastageIds).toContain(wastageId);
    expect(res.body.rejectedWastages).toEqual([]);
    // Sale luôn được chấp nhận (không giới hạn tồn cho dòng hàng thường).
    expect(res.body.acceptedIds).toContain(saleId);
    expect(res.body.rejected).toEqual([]);

    const stock = await prisma.productStoreStock.findUniqueOrThrow({
      where: { productId_storeId: { productId: product.id, storeId } },
    });
    // 5 − 3 (wastage) − 3 (sale) = −1: cả hai đều áp dụng, đúng thứ tự
    // kho→bán hiện tại (wastage trừ trên tồn gốc, sale trừ tiếp không giới
    // hạn). Nếu đảo thứ tự, wastage sẽ bị từ chối và tồn cuối sẽ là 2 (5−3
    // sale, wastage không áp dụng) thay vì −1.
    expect(stock.qty.toString()).toBe('-1');
  });

  it('POST /sync/push rejects invalid quantities and client money mismatches', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id as string;
    const product = await prisma.product.findUnique({
      where: { sku: 'STING-330' },
    });
    if (!product) {
      throw new Error('Seed product STING-330 not found');
    }
    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 0, clientId: shiftId })
      .expect(201);

    const invalidQty = makeSaleDto(randomUUID(), {
      storeId,
      shiftId,
      soldById: login.user.id,
      productId: product.id,
      qty: '0',
      totalVnd: 0,
    });
    const badLine = makeSaleDto(randomUUID(), {
      storeId,
      shiftId,
      soldById: login.user.id,
      productId: product.id,
    });
    badLine.lines[0].lineTotal = 1;
    const badTotal = makeSaleDto(randomUUID(), {
      storeId,
      shiftId,
      soldById: login.user.id,
      productId: product.id,
    });
    badTotal.discountVnd = 1000;
    const negativeMoney = makeSaleDto(randomUUID(), {
      storeId,
      shiftId,
      soldById: login.user.id,
      productId: product.id,
    });
    negativeMoney.discountVnd = -1;
    const negativeLineDiscount = makeSaleDto(randomUUID(), {
      storeId,
      shiftId,
      soldById: login.user.id,
      productId: product.id,
    });
    negativeLineDiscount.lines[0].discountVnd = -1;
    const excessiveLineDiscount = makeSaleDto(randomUUID(), {
      storeId,
      shiftId,
      soldById: login.user.id,
      productId: product.id,
    });
    excessiveLineDiscount.lines[0].discountVnd = 25000;
    excessiveLineDiscount.lines[0].lineTotal = 0;

    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-invalid-money',
        sales: [
          invalidQty,
          badLine,
          badTotal,
          negativeMoney,
          negativeLineDiscount,
          excessiveLineDiscount,
        ],
      })
      .expect(201);

    expect(res.body.rejected).toEqual([
      { id: invalidQty.id, reason: 'invalid_quantity' },
      { id: badLine.id, reason: 'line_total_mismatch' },
      { id: badTotal.id, reason: 'sale_total_mismatch' },
      { id: negativeMoney.id, reason: 'invalid_money' },
      { id: negativeLineDiscount.id, reason: 'invalid_money' },
      { id: excessiveLineDiscount.id, reason: 'line_total_mismatch' },
    ]);
  });

  it('POST /sync/push accepts concurrent offline sales and allows negative stock', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id as string;
    const product = await prisma.product.findUnique({
      where: { sku: 'STING-330' },
    });
    if (!product) {
      throw new Error('Seed product STING-330 not found');
    }

    await prisma.productStoreStock.update({
      where: {
        productId_storeId: { productId: product.id, storeId },
      },
      data: { qty: 1 },
    });

    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 100000, clientId: shiftId })
      .expect(201);

    const saleIds = [randomUUID(), randomUUID()];
    const responses = await Promise.all(
      saleIds.map((saleId, index) =>
        request(app.getHttpServer())
          .post('/sync/push')
          .set('Authorization', `Bearer ${login.accessToken}`)
          .send({
            deviceId: `dev-offline-${index}`,
            sales: [
              makeSaleDto(saleId, {
                storeId,
                shiftId,
                soldById: login.user.id,
                productId: product.id,
                qty: '2',
              }),
            ],
          })
          .expect(201),
      ),
    );

    expect(responses.flatMap((response) => response.body.acceptedIds).sort()).toEqual(
      [...saleIds].sort(),
    );
    const stock = await prisma.productStoreStock.findUnique({
      where: {
        productId_storeId: { productId: product.id, storeId },
      },
    });
    expect(stock?.qty.toString()).toBe('-3');
  });

  it('POST /sync/push rejects a shift owned by another user', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id as string;
    const product = await prisma.product.findUnique({
      where: { sku: 'STING-330' },
    });
    const otherUser = await prisma.user.create({
      data: {
        phone: `09${Date.now()}`,
        name: 'Other cashier',
        passwordHash: await bcrypt.hash('123456', 4),
        role: Role.cashier,
      },
    });
    if (!product) {
      throw new Error('Seed product not found');
    }
    const shiftId = randomUUID();
    await prisma.shift.create({
      data: {
        id: shiftId,
        storeId,
        userId: otherUser.id,
        openedAt: new Date(),
        openingCash: 0,
      },
    });
    const saleId = randomUUID();

    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-wrong-shift-user',
        sales: [
          makeSaleDto(saleId, {
            storeId,
            shiftId,
            soldById: login.user.id,
            productId: product.id,
          }),
        ],
      })
      .expect(201);

    expect(res.body.acceptedIds).toEqual([]);
    expect(res.body.rejected).toEqual([
      { id: saleId, reason: 'shift_forbidden' },
    ]);
  });
});
