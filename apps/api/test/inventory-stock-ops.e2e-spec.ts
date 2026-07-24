import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
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

describe('Inventory stock ops sync', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let productId: string;
  let storeCh1: string;
  let storeCh2: string;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    prisma = moduleRef.get(PrismaService);
    await app.init();

    const product = await prisma.product.findUniqueOrThrow({
      where: { sku: 'STING-330' },
    });
    productId = product.id;
    const ch1 = await prisma.store.findFirstOrThrow({ where: { code: 'CH1' } });
    const ch2 = await prisma.store.findFirstOrThrow({ where: { code: 'CH2' } });
    storeCh1 = ch1.id;
    storeCh2 = ch2.id;
  });

  beforeEach(async () => {
    await prisma.stockMovement.deleteMany();
    await prisma.stockTransferLine.deleteMany();
    await prisma.stockTransfer.deleteMany();
    await prisma.stocktakeLine.deleteMany();
    await prisma.stocktake.deleteMany();
    await prisma.purchaseReceiptLine.deleteMany();
    await prisma.purchaseReceipt.deleteMany();
    await prisma.wastageVoucherLine.deleteMany();
    await prisma.wastageVoucher.deleteMany();
    await prisma.debtLedgerEntry.deleteMany();
    await prisma.saleLine.deleteMany();
    await prisma.sale.deleteMany();

    await prisma.productStoreStock.upsert({
      where: {
        productId_storeId: { productId, storeId: storeCh1 },
      },
      update: { qty: 100 },
      create: { productId, storeId: storeCh1, qty: 100, minQty: 0 },
    });
    await prisma.productStoreStock.upsert({
      where: {
        productId_storeId: { productId, storeId: storeCh2 },
      },
      update: { qty: 10 },
      create: { productId, storeId: storeCh2, qty: 10, minQty: 0 },
    });
  });

  afterAll(() => app.close());

  it('purchase receipt increases stock and is idempotent', async () => {
    const login = await loginAsOwner(app);
    const receiptId = randomUUID();
    const payload = {
      id: receiptId,
      storeId: storeCh1,
      supplierName: 'NCC A',
      supplierPhone: '0909111222',
      clientCreatedAt: new Date().toISOString(),
      lines: [{ id: randomUUID(), productId, qty: '5', unitCostVnd: 8000 }],
    };

    const push = () =>
      request(app.getHttpServer())
        .post('/sync/push')
        .set('Authorization', `Bearer ${login.accessToken}`)
        .send({ deviceId: 'inv-1', sales: [], purchaseReceipts: [payload] })
        .expect(201);

    const first = await push();
    expect(first.body.acceptedPurchaseReceiptIds).toContain(receiptId);
    const second = await push();
    expect(second.body.acceptedPurchaseReceiptIds).toContain(receiptId);

    const stock = await prisma.productStoreStock.findUniqueOrThrow({
      where: { productId_storeId: { productId, storeId: storeCh1 } },
    });
    expect(stock.qty.toString()).toBe('105');
    const movements = await prisma.stockMovement.findMany({
      where: { docId: receiptId },
    });
    expect(movements).toHaveLength(1);
    expect(movements[0]?.qtyDelta.toString()).toBe('5');
  });

  it('wastage rejects insufficient stock', async () => {
    const login = await loginAsOwner(app);
    const wastageId = randomUUID();
    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'inv-2',
        sales: [],
        wastages: [
          {
            id: wastageId,
            storeId: storeCh1,
            reasonCode: 'spoilage',
            clientCreatedAt: new Date().toISOString(),
            lines: [{ productId, qty: '200' }],
          },
        ],
      })
      .expect(201);

    expect(res.body.rejectedWastages).toEqual([
      { id: wastageId, reason: 'insufficient_stock' },
    ]);
  });

  it('transfer create → approve → receive adjusts both stores', async () => {
    const login = await loginAsOwner(app);
    const transferId = randomUUID();
    const lineId = randomUUID();

    const create = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'inv-3',
        sales: [],
        stockTransferCreates: [
          {
            id: transferId,
            fromStoreId: storeCh1,
            toStoreId: storeCh2,
            clientCreatedAt: new Date().toISOString(),
            lines: [{ id: lineId, productId, qty: '7' }],
          },
        ],
      })
      .expect(201);
    expect(create.body.acceptedStockTransferCreateIds).toContain(transferId);

    let stock1 = await prisma.productStoreStock.findUniqueOrThrow({
      where: { productId_storeId: { productId, storeId: storeCh1 } },
    });
    expect(stock1.qty.toString()).toBe('100');

    const approve = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'inv-3',
        sales: [],
        stockTransferApproves: [{ id: transferId }],
      })
      .expect(201);
    expect(approve.body.acceptedStockTransferApproveIds).toContain(transferId);

    stock1 = await prisma.productStoreStock.findUniqueOrThrow({
      where: { productId_storeId: { productId, storeId: storeCh1 } },
    });
    expect(stock1.qty.toString()).toBe('93');

    const receive = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'inv-3',
        sales: [],
        stockTransferReceives: [{ id: transferId }],
      })
      .expect(201);
    expect(receive.body.acceptedStockTransferReceiveIds).toContain(transferId);

    const stock2 = await prisma.productStoreStock.findUniqueOrThrow({
      where: { productId_storeId: { productId, storeId: storeCh2 } },
    });
    expect(stock2.qty.toString()).toBe('17');

    const transfer = await prisma.stockTransfer.findUniqueOrThrow({
      where: { id: transferId },
    });
    expect(transfer.status).toBe('received');
  });

  it('stocktake sets absolute qty and writes movement', async () => {
    const login = await loginAsOwner(app);
    const stocktakeId = randomUUID();
    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'inv-4',
        sales: [],
        stocktakes: [
          {
            id: stocktakeId,
            storeId: storeCh1,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                productId,
                systemQty: '100',
                countedQty: '95',
                varianceQty: '-5',
                reason: 'decrease',
                reasonNote: 'mat hang',
              },
            ],
          },
        ],
      })
      .expect(201);

    expect(res.body.acceptedStocktakeIds).toContain(stocktakeId);
    const stock = await prisma.productStoreStock.findUniqueOrThrow({
      where: { productId_storeId: { productId, storeId: storeCh1 } },
    });
    expect(stock.qty.toString()).toBe('95');
  });

  it('pull returns inventory documents for store', async () => {
    const login = await loginAsOwner(app);
    const receiptId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'inv-5',
        sales: [],
        purchaseReceipts: [
          {
            id: receiptId,
            storeId: storeCh1,
            supplierName: 'NCC B',
            clientCreatedAt: new Date().toISOString(),
            lines: [{ productId, qty: '1' }],
          },
        ],
      })
      .expect(201);

    const pull = await request(app.getHttpServer())
      .get('/sync/pull')
      .query({ storeId: storeCh1, since: new Date(0).toISOString() })
      .set('Authorization', `Bearer ${login.accessToken}`)
      .expect(200);

    expect(
      (pull.body.purchaseReceipts as { id: string }[]).some(
        (r) => r.id === receiptId,
      ),
    ).toBe(true);
    expect((pull.body.stockMovements as unknown[]).length).toBeGreaterThan(0);
  });
});
