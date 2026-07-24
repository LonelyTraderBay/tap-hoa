import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import { Role } from '@prisma/client';
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
    totalVnd: number;
    clientCreatedAt: string;
  },
) {
  return {
    id: saleId,
    storeId: opts.storeId,
    shiftId: opts.shiftId,
    soldById: opts.soldById,
    paymentMethod: 'cash',
    cashAmount: opts.totalVnd,
    transferAmount: 0,
    debtAmount: 0,
    discountVnd: 0,
    totalVnd: opts.totalVnd,
    customerId: null,
    clientCreatedAt: opts.clientCreatedAt,
    lines: [
      {
        productId: opts.productId,
        qty: '1',
        unitPrice: opts.totalVnd,
        lineTotal: opts.totalVnd,
      },
    ],
  };
}

function makeSaleDtoWithLines(
  saleId: string,
  opts: {
    storeId: string;
    shiftId: string;
    soldById: string;
    clientCreatedAt: string;
    lines: Array<{
      productId: string;
      qty: string;
      unitPrice: number;
      lineTotal: number;
    }>;
  },
) {
  const totalVnd = opts.lines.reduce((sum, line) => sum + line.lineTotal, 0);
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
    clientCreatedAt: opts.clientCreatedAt,
    lines: opts.lines,
  };
}

describe('Reports day', () => {
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
    await prisma.saleLine.deleteMany();
    await prisma.sale.deleteMany();
    await prisma.shift.updateMany({
      where: { closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
    });
    const product = await prisma.product.findUnique({
      where: { sku: 'STING-330' },
    });
    const stores = await prisma.store.findMany({
      where: { code: { in: ['CH1', 'CH2'] } },
    });
    if (product) {
      for (const store of stores) {
        await prisma.productStoreStock.update({
          where: {
            productId_storeId: { productId: product.id, storeId: store.id },
          },
          data: { qty: 100 },
        });
      }
    }
  });

  afterAll(() => app.close());

  it('GET /reports/day aggregates sales across two stores for owner', async () => {
    const login = await loginAsOwner(app);
    const storesRes = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const ch1 = storesRes.body.find(
      (store: { code: string }) => store.code === 'CH1',
    );
    const ch2 = storesRes.body.find(
      (store: { code: string }) => store.code === 'CH2',
    );
    if (!ch1 || !ch2) {
      throw new Error('Seed stores CH1/CH2 not found');
    }

    const product = await prisma.product.findUnique({
      where: { sku: 'STING-330' },
    });
    if (!product) {
      throw new Error('Seed product STING-330 not found');
    }

    const reportDate = '2026-07-23';
    const clientCreatedAt = `${reportDate}T10:00:00.000Z`;

    const shift1Id = randomUUID();
    const shift2Id = randomUUID();

    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev1',
        shiftOpens: [
          {
            id: shift1Id,
            storeId: ch1.id,
            openingCash: 500000,
            openedAt: `${reportDate}T00:00:00.000Z`,
          },
          {
            id: shift2Id,
            storeId: ch2.id,
            openingCash: 500000,
            openedAt: `${reportDate}T00:00:00.000Z`,
          },
        ],
        sales: [
          makeSaleDto(randomUUID(), {
            storeId: ch1.id,
            shiftId: shift1Id,
            soldById: login.user.id,
            productId: product.id,
            totalVnd: 20000,
            clientCreatedAt,
          }),
          makeSaleDto(randomUUID(), {
            storeId: ch2.id,
            shiftId: shift2Id,
            soldById: login.user.id,
            productId: product.id,
            totalVnd: 30000,
            clientCreatedAt,
          }),
        ],
      })
      .expect(201);

    const report = await request(app.getHttpServer())
      .get(`/reports/day?date=${reportDate}`)
      .set('Authorization', `Bearer ${login.accessToken}`)
      .expect(200);

    expect(report.body.totalRevenueVnd).toBe(50000);
    expect(report.body.byStore).toHaveLength(2);
  });

  it('GET /reports/day uses Asia/Ho_Chi_Minh day boundaries', async () => {
    const login = await loginAsOwner(app);
    const storesRes = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const ch1 = storesRes.body.find(
      (store: { code: string }) => store.code === 'CH1',
    );
    if (!ch1) {
      throw new Error('Seed store CH1 not found');
    }

    const product = await prisma.product.findUnique({
      where: { sku: 'STING-330' },
    });
    if (!product) {
      throw new Error('Seed product STING-330 not found');
    }

    const reportDate = '2026-07-23';
    const shiftId = randomUUID();

    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-ict',
        shiftOpens: [
          {
            id: shiftId,
            storeId: ch1.id,
            openingCash: 500000,
            openedAt: '2026-07-22T17:00:00.000Z',
          },
        ],
        sales: [
          makeSaleDto(randomUUID(), {
            storeId: ch1.id,
            shiftId,
            soldById: login.user.id,
            productId: product.id,
            totalVnd: 11000,
            clientCreatedAt: '2026-07-22T17:30:00.000Z',
          }),
          makeSaleDto(randomUUID(), {
            storeId: ch1.id,
            shiftId,
            soldById: login.user.id,
            productId: product.id,
            totalVnd: 22000,
            clientCreatedAt: '2026-07-23T16:30:00.000Z',
          }),
          makeSaleDto(randomUUID(), {
            storeId: ch1.id,
            shiftId,
            soldById: login.user.id,
            productId: product.id,
            totalVnd: 33000,
            clientCreatedAt: '2026-07-23T17:30:00.000Z',
          }),
        ],
      })
      .expect(201);

    const report = await request(app.getHttpServer())
      .get(`/reports/day?date=${reportDate}&storeId=${ch1.id}`)
      .set('Authorization', `Bearer ${login.accessToken}`)
      .expect(200);

    expect(report.body.totalRevenueVnd).toBe(33000);
    expect(report.body.byStore).toHaveLength(1);
    expect(report.body.byStore[0].orderCount).toBe(2);
  });
});

describe('Reports top-skus', () => {
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
    await prisma.saleLine.deleteMany();
    await prisma.sale.deleteMany();
    await prisma.shift.updateMany({
      where: { closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
    });
    await prisma.stockMovement.deleteMany({
      where: { product: { sku: { in: ['TOP-SKU-A', 'TOP-SKU-B'] } } },
    });
    await prisma.productStoreStock.deleteMany({
      where: { product: { sku: { in: ['TOP-SKU-A', 'TOP-SKU-B'] } } },
    });
    await prisma.product.deleteMany({
      where: { sku: { in: ['TOP-SKU-A', 'TOP-SKU-B'] } },
    });
  });

  afterAll(async () => {
    await app.close();
  });

  async function seedTopSkuProducts(storeId: string) {
    const productA = await prisma.product.create({
      data: {
        sku: 'TOP-SKU-A',
        name: 'Top Product A',
        unit: 'chai',
        basePriceVnd: 10000,
        costVnd: 5000,
      },
    });
    const productB = await prisma.product.create({
      data: {
        sku: 'TOP-SKU-B',
        name: 'Top Product B',
        unit: 'chai',
        basePriceVnd: 8000,
        costVnd: 2000,
      },
    });
    for (const product of [productA, productB]) {
      await prisma.productStoreStock.create({
        data: {
          productId: product.id,
          storeId,
          qty: 100,
          minQty: 10,
        },
      });
    }
    return { productA, productB };
  }

  it('GET /reports/top-skus ranks by qty and computes estimatedGrossVnd', async () => {
    const login = await loginAsOwner(app);
    const storesRes = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const ch1 = storesRes.body.find(
      (store: { code: string }) => store.code === 'CH1',
    );
    if (!ch1) {
      throw new Error('Seed store CH1 not found');
    }

    const { productA, productB } = await seedTopSkuProducts(ch1.id);

    const reportDate = '2026-07-24';
    const clientCreatedAt = `${reportDate}T10:00:00.000Z`;
    const shiftId = randomUUID();

    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-top-sku',
        shiftOpens: [
          {
            id: shiftId,
            storeId: ch1.id,
            openingCash: 500000,
            openedAt: `${reportDate}T00:00:00.000Z`,
          },
        ],
        sales: [
          makeSaleDtoWithLines(randomUUID(), {
            storeId: ch1.id,
            shiftId,
            soldById: login.user.id,
            clientCreatedAt,
            lines: [
              {
                productId: productB.id,
                qty: '3',
                unitPrice: 8000,
                lineTotal: 24000,
              },
            ],
          }),
          makeSaleDtoWithLines(randomUUID(), {
            storeId: ch1.id,
            shiftId,
            soldById: login.user.id,
            clientCreatedAt,
            lines: [
              {
                productId: productB.id,
                qty: '2',
                unitPrice: 8000,
                lineTotal: 16000,
              },
            ],
          }),
          makeSaleDtoWithLines(randomUUID(), {
            storeId: ch1.id,
            shiftId,
            soldById: login.user.id,
            clientCreatedAt,
            lines: [
              {
                productId: productA.id,
                qty: '3',
                unitPrice: 10000,
                lineTotal: 30000,
              },
            ],
          }),
        ],
      })
      .expect(201);

    const report = await request(app.getHttpServer())
      .get(`/reports/top-skus?date=${reportDate}&storeId=${ch1.id}`)
      .set('Authorization', `Bearer ${login.accessToken}`)
      .expect(200);

    expect(report.body.date).toBe(reportDate);
    expect(report.body.items).toHaveLength(2);
    expect(report.body.items[0].productId).toBe(productB.id);
    expect(report.body.items[0].qty).toBe(5);
    expect(report.body.items[0].revenueVnd).toBe(40000);
    expect(report.body.items[0].estimatedGrossVnd).toBe(30000);
    expect(report.body.items[1].productId).toBe(productA.id);
    expect(report.body.items[1].qty).toBe(3);
    expect(report.body.items[1].revenueVnd).toBe(30000);
    expect(report.body.items[1].estimatedGrossVnd).toBe(15000);
  });
});

describe('Reports stock-on-hand', () => {
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
    await prisma.productStoreStock.deleteMany({
      where: { product: { sku: { in: ['SOH-A', 'SOH-B', 'SOH-INACTIVE'] } } },
    });
    await prisma.product.deleteMany({
      where: { sku: { in: ['SOH-A', 'SOH-B', 'SOH-INACTIVE'] } },
    });
  });

  afterAll(async () => {
    await app.close();
  });

  async function seedStockOnHandProducts(storeId: string) {
    const productBelowMin = await prisma.product.create({
      data: {
        sku: 'SOH-A',
        name: 'Sản phẩm An',
        unit: 'chai',
        basePriceVnd: 10000,
        costVnd: 7000,
      },
    });
    const productAboveMin = await prisma.product.create({
      data: {
        sku: 'SOH-B',
        name: 'Sản phẩm Bình',
        unit: 'thùng',
        basePriceVnd: 12000,
        costVnd: 4000,
      },
    });
    const inactiveProduct = await prisma.product.create({
      data: {
        sku: 'SOH-INACTIVE',
        name: 'Sản phẩm Ngưng',
        unit: 'chai',
        basePriceVnd: 5000,
        costVnd: 3000,
        active: false,
      },
    });

    await prisma.productStoreStock.create({
      data: {
        productId: productBelowMin.id,
        storeId,
        qty: 3,
        minQty: 10,
      },
    });
    await prisma.productStoreStock.create({
      data: {
        productId: productAboveMin.id,
        storeId,
        qty: 50,
        minQty: 10,
      },
    });
    await prisma.productStoreStock.create({
      data: {
        productId: inactiveProduct.id,
        storeId,
        qty: 100,
        minQty: 0,
      },
    });

    return { productBelowMin, productAboveMin, inactiveProduct };
  }

  it('GET /reports/stock-on-hand returns values, belowMin, and sort order', async () => {
    const login = await loginAsOwner(app);
    const storesRes = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const ch1 = storesRes.body.find(
      (store: { code: string }) => store.code === 'CH1',
    );
    if (!ch1) {
      throw new Error('Seed store CH1 not found');
    }

    const { productBelowMin, productAboveMin } =
      await seedStockOnHandProducts(ch1.id);

    const report = await request(app.getHttpServer())
      .get(`/reports/stock-on-hand?storeId=${ch1.id}`)
      .set('Authorization', `Bearer ${login.accessToken}`)
      .expect(200);

    expect(report.body.storeId).toBe(ch1.id);

    const itemA = report.body.items.find(
      (item: { sku: string }) => item.sku === 'SOH-A',
    );
    const itemB = report.body.items.find(
      (item: { sku: string }) => item.sku === 'SOH-B',
    );
    expect(itemA).toBeDefined();
    expect(itemB).toBeDefined();
    expect(
      report.body.items.find(
        (item: { sku: string }) => item.sku === 'SOH-INACTIVE',
      ),
    ).toBeUndefined();

    const indexA = report.body.items.findIndex(
      (item: { sku: string }) => item.sku === 'SOH-A',
    );
    const indexB = report.body.items.findIndex(
      (item: { sku: string }) => item.sku === 'SOH-B',
    );
    expect(indexA).toBeLessThan(indexB);

    expect(itemA.productId).toBe(productBelowMin.id);
    expect(itemA.sku).toBe('SOH-A');
    expect(itemA.name).toBe('Sản phẩm An');
    expect(itemA.unit).toBe('chai');
    expect(itemA.qty).toBe(3);
    expect(itemA.minQty).toBe(10);
    expect(itemA.costVnd).toBe(7000);
    expect(itemA.estimatedValueVnd).toBe(21000);
    expect(itemA.belowMin).toBe(true);

    expect(itemB.productId).toBe(productAboveMin.id);
    expect(itemB.sku).toBe('SOH-B');
    expect(itemB.name).toBe('Sản phẩm Bình');
    expect(itemB.unit).toBe('thùng');
    expect(itemB.qty).toBe(50);
    expect(itemB.minQty).toBe(10);
    expect(itemB.costVnd).toBe(4000);
    expect(itemB.estimatedValueVnd).toBe(200000);
    expect(itemB.belowMin).toBe(false);

    const computedTotal = report.body.items.reduce(
      (sum: number, item: { estimatedValueVnd: number }) =>
        sum + item.estimatedValueVnd,
      0,
    );
    expect(report.body.totalEstimatedValueVnd).toBe(computedTotal);
  });

  it('GET /reports/stock-on-hand requires storeId', async () => {
    const login = await loginAsOwner(app);

    await request(app.getHttpServer())
      .get('/reports/stock-on-hand')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .expect(400);
  });

  it('GET /reports/stock-on-hand rejects forbidden store for cashier', async () => {
    const login = await loginAsOwner(app);
    const storesRes = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const ch1 = storesRes.body.find(
      (store: { code: string }) => store.code === 'CH1',
    );
    const ch2 = storesRes.body.find(
      (store: { code: string }) => store.code === 'CH2',
    );
    if (!ch1 || !ch2) {
      throw new Error('Seed stores CH1/CH2 not found');
    }

    const passwordHash = await import('bcrypt').then((m) =>
      m.hash('123456', 10),
    );
    await prisma.user.upsert({
      where: { phone: '0900000099' },
      update: {},
      create: {
        phone: '0900000099',
        name: 'Cashier SOH',
        passwordHash,
        role: Role.cashier,
        stores: { create: [{ storeId: ch1.id }] },
      },
    });

    const cashierRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: '0900000099', password: '123456' })
      .expect(201);

    await request(app.getHttpServer())
      .get(`/reports/stock-on-hand?storeId=${ch2.id}`)
      .set('Authorization', `Bearer ${cashierRes.body.accessToken}`)
      .expect(403);
  });
});
