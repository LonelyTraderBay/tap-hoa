import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { weightedAverageCost } from '../src/inventory/weighted-average-cost';
import { PrismaService } from '../src/prisma/prisma.service';

describe('weightedAverageCost (pure)', () => {
  it('blends WAC', () => {
    expect(weightedAverageCost(10, 10000, 10, 8000)).toBe(9000);
  });
});

describe('Phase 2 COGS WAC e2e', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;
  let userId: string;
  let storeId: string;
  let productId: string;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    prisma = moduleRef.get(PrismaService);
    await app.init();

    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: '0900000001', password: '123456' })
      .expect(201);
    token = login.body.accessToken;
    userId = login.body.user.id;
    const store = await prisma.store.findFirst({ where: { code: 'CH1' } });
    const product = await prisma.product.findUnique({
      where: { sku: 'STING-330' },
    });
    storeId = store!.id;
    productId = product!.id;
  });

  afterAll(async () => {
    await app.close();
  });

  it('purchase updates avgCostVnd and sale snapshots unitCostVnd', async () => {
    await prisma.saleLine.deleteMany({
      where: { sale: { storeId } },
    });
    await prisma.sale.deleteMany({ where: { storeId } });
    await prisma.shift.updateMany({
      where: { storeId, closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
    });

    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId } },
      create: {
        productId,
        storeId,
        qty: 10,
        minQty: 0,
        avgCostVnd: 10000,
      },
      update: { qty: 10, avgCostVnd: 10000 },
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

    const receiptId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'cogs-wac-1',
        sales: [],
        purchaseReceipts: [
          {
            id: receiptId,
            storeId,
            supplierName: 'NCC Test',
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                id: randomUUID(),
                productId,
                qty: '10',
                unitCostVnd: 8000,
              },
            ],
          },
        ],
      })
      .expect(201);

    const stock = await prisma.productStoreStock.findUniqueOrThrow({
      where: { productId_storeId: { productId, storeId } },
    });
    expect(Number(stock.qty)).toBe(20);
    expect(stock.avgCostVnd).toBe(9000);

    const saleId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'cogs-wac-1',
        sales: [
          {
            id: saleId,
            storeId,
            shiftId: shift.id,
            soldById: userId,
            paymentMethod: 'cash',
            cashAmount: 10000,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 10000,
            customerId: null,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                productId,
                qty: '1',
                unitPrice: 10000,
                lineTotal: 10000,
              },
            ],
          },
        ],
      })
      .expect(201);

    const line = await prisma.saleLine.findFirst({ where: { saleId } });
    expect(line?.unitCostVnd).toBe(9000);

    const ict = new Date();
    const y = ict.toLocaleString('en-CA', {
      timeZone: 'Asia/Ho_Chi_Minh',
      year: 'numeric',
    });
    const m = ict.toLocaleString('en-CA', {
      timeZone: 'Asia/Ho_Chi_Minh',
      month: '2-digit',
    });
    const d = ict.toLocaleString('en-CA', {
      timeZone: 'Asia/Ho_Chi_Minh',
      day: '2-digit',
    });
    const date = `${y}-${m}-${d}`;

    const top = await request(app.getHttpServer())
      .get(`/reports/top-skus?date=${date}&storeId=${storeId}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    const item = top.body.items.find(
      (row: { productId: string }) => row.productId === productId,
    );
    expect(item).toBeTruthy();
    expect(item.estimatedGrossVnd).toBe(10000 - 9000);
  });
});
