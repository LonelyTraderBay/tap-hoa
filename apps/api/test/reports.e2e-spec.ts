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
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId: ch1.id, openingCash: 500000, clientId: shift1Id })
      .expect(201);
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId: ch2.id, openingCash: 500000, clientId: shift2Id })
      .expect(201);

    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev1',
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
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId: ch1.id, openingCash: 500000, clientId: shiftId })
      .expect(201);

    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-ict',
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
