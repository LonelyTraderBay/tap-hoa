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

describe('Customers debt sync', () => {
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
    await prisma.customer.deleteMany();
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

  it('POST /sync/push upserts offline customer embedded in debt sale', async () => {
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

    const customerId = randomUUID();
    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 500000, clientId: shiftId })
      .expect(201);

    const saleId = randomUUID();
    const debtAmount = 20000;
    const sale = {
      id: saleId,
      storeId,
      shiftId,
      soldById: login.user.id,
      paymentMethod: 'debt',
      cashAmount: 0,
      transferAmount: 0,
      debtAmount,
      discountVnd: 0,
      totalVnd: debtAmount,
      customerId,
      customer: { id: customerId, name: 'Offline Anh', phone: '0900999888' },
      clientCreatedAt: new Date().toISOString(),
      lines: [
        {
          productId: product.id,
          qty: '2',
          unitPrice: 10000,
          lineTotal: debtAmount,
        },
      ],
    };

    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ deviceId: 'dev-offline-customer', sales: [sale] })
      .expect(201);
    expect(res.body.acceptedIds).toEqual([saleId]);

    const customer = await prisma.customer.findUnique({
      where: { id: customerId },
    });
    expect(customer?.name).toBe('Offline Anh');
    expect(customer?.phone).toBe('0900999888');
    expect(customer?.balanceVnd).toBe(debtAmount);

    await request(app.getHttpServer())
      .post(`/shifts/${shiftId}/close`)
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ closingCash: 500000 })
      .expect(201);
  });

  it('POST /sync/push increases customer balance idempotently for debt sales', async () => {
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

    const customerId = randomUUID();
    await request(app.getHttpServer())
      .post('/customers')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ id: customerId, name: 'Anh Ba', phone: '0900111222' })
      .expect(201);

    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 500000, clientId: shiftId })
      .expect(201);

    const saleId = randomUUID();
    const debtAmount = 20000;
    const sale = {
      id: saleId,
      storeId,
      shiftId,
      soldById: login.user.id,
      paymentMethod: 'debt',
      cashAmount: 0,
      transferAmount: 0,
      debtAmount,
      discountVnd: 0,
      totalVnd: debtAmount,
      customerId,
      clientCreatedAt: new Date().toISOString(),
      lines: [
        {
          productId: product.id,
          qty: '2',
          unitPrice: 10000,
          lineTotal: debtAmount,
        },
      ],
    };

    const first = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ deviceId: 'dev-debt', sales: [sale] })
      .expect(201);
    expect(first.body.acceptedIds).toEqual([saleId]);

    const second = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ deviceId: 'dev-debt', sales: [sale] })
      .expect(201);
    expect(second.body.acceptedIds).toEqual([saleId]);

    const customer = await prisma.customer.findUnique({
      where: { id: customerId },
    });
    expect(customer?.balanceVnd).toBe(debtAmount);

    await request(app.getHttpServer())
      .post(`/shifts/${shiftId}/close`)
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ closingCash: 500000 })
      .expect(201);
  });

  it('POST /sync/push rejects debt sale without customerId', async () => {
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
      .send({ storeId, openingCash: 100000, clientId: shiftId })
      .expect(201);

    const saleId = randomUUID();
    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-debt',
        sales: [
          {
            id: saleId,
            storeId,
            shiftId,
            soldById: login.user.id,
            paymentMethod: 'debt',
            cashAmount: 0,
            transferAmount: 0,
            debtAmount: 20000,
            discountVnd: 0,
            totalVnd: 20000,
            customerId: null,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                productId: product.id,
                qty: '2',
                unitPrice: 10000,
                lineTotal: 20000,
              },
            ],
          },
        ],
      })
      .expect(201);

    expect(res.body.rejected).toEqual([
      { id: saleId, reason: 'customer_required' },
    ]);

    await request(app.getHttpServer())
      .post(`/shifts/${shiftId}/close`)
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ closingCash: 100000 })
      .expect(201);
  });
});
