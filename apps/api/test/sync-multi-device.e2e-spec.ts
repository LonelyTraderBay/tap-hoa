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

describe('Sync multi-device', () => {
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

  it('device B pull sees stock 98 after device A pushes sale qty 2', async () => {
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

    const since = new Date().toISOString();

    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 500000, clientId: shiftId })
      .expect(201);

    const saleId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'device-a',
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

    const pull = await request(app.getHttpServer())
      .get('/sync/pull')
      .query({ since, storeId })
      .set('Authorization', `Bearer ${login.accessToken}`)
      .expect(200);

    const stock = (pull.body.stocks as { productId: string; qty: string }[]).find(
      (row) => row.productId === product.id,
    );
    expect(stock?.qty).toBe('98');

    await request(app.getHttpServer())
      .post(`/shifts/${shiftId}/close`)
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ closingCash: 500000 })
      .expect(201);
  });
});
