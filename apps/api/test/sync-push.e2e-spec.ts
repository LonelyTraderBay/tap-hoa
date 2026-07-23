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
    qty?: string;
    totalVnd?: number;
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
    clientCreatedAt: new Date().toISOString(),
    lines: [
      {
        productId: opts.productId,
        qty,
        unitPrice,
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

  it('POST /sync/push rejects sale when stock insufficient', async () => {
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

    const saleId = randomUUID();
    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev1',
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
      .expect(201);

    expect(res.body.acceptedIds).toEqual([]);
    expect(res.body.rejected).toEqual([
      { id: saleId, reason: 'insufficient_stock' },
    ]);

    await request(app.getHttpServer())
      .post(`/shifts/${shiftId}/close`)
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ closingCash: 100000 })
      .expect(201);
  });
});
