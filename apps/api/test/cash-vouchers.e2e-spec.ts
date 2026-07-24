import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

const CATEGORY_OTHER_IN = 'a1000000-0000-4000-8000-000000000001';
const CATEGORY_ELECTRICITY = 'a1000000-0000-4000-8000-000000000002';

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

describe('Cash vouchers sync', () => {
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
    await prisma.cashVoucher.deleteMany();
    await prisma.debtLedgerEntry.deleteMany();
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

  it('push voucher twice is idempotent (one row)', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id as string;

    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 500000, clientId: shiftId })
      .expect(201);

    const voucherId = randomUUID();
    const voucher = {
      id: voucherId,
      storeId,
      shiftId,
      categoryId: CATEGORY_OTHER_IN,
      direction: 'in' as const,
      channel: 'cash' as const,
      amountVnd: 25000,
      note: 'thu le',
      clientCreatedAt: new Date().toISOString(),
    };

    const pushOnce = () =>
      request(app.getHttpServer())
        .post('/sync/push')
        .set('Authorization', `Bearer ${login.accessToken}`)
        .send({ deviceId: 'dev-voucher', sales: [], cashVouchers: [voucher] })
        .expect(201);

    const first = await pushOnce();
    expect(first.body.acceptedCashVoucherIds).toContain(voucherId);
    const second = await pushOnce();
    expect(second.body.acceptedCashVoucherIds).toContain(voucherId);

    const rows = await prisma.cashVoucher.findMany({ where: { id: voucherId } });
    expect(rows).toHaveLength(1);
    expect(rows[0]?.amountVnd).toBe(25000);
  });

  it('rejects voucher when category direction mismatches', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id as string;

    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 100000, clientId: shiftId })
      .expect(201);

    const voucherId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-voucher',
        sales: [],
        cashVouchers: [
          {
            id: voucherId,
            storeId,
            shiftId,
            categoryId: CATEGORY_ELECTRICITY,
            direction: 'in',
            channel: 'cash',
            amountVnd: 10000,
            clientCreatedAt: new Date().toISOString(),
          },
        ],
      })
      .expect(201)
      .expect((res) => {
        expect(res.body.rejectedCashVouchers).toEqual(
          expect.arrayContaining([
            { id: voucherId, reason: 'category_direction_mismatch' },
          ]),
        );
      });
  });

  it('rejects voucher when shift is closed', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id as string;

    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 100000, clientId: shiftId })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/shifts/${shiftId}/close`)
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ closingCash: 100000 })
      .expect(201);

    const voucherId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-voucher',
        sales: [],
        cashVouchers: [
          {
            id: voucherId,
            storeId,
            shiftId,
            categoryId: CATEGORY_OTHER_IN,
            direction: 'in',
            channel: 'cash',
            amountVnd: 5000,
            clientCreatedAt: new Date().toISOString(),
          },
        ],
      })
      .expect(201)
      .expect((res) => {
        expect(res.body.rejectedCashVouchers).toEqual(
          expect.arrayContaining([{ id: voucherId, reason: 'shift_not_open' }]),
        );
      });
  });

  it('rejects voucher when shift belongs to a different store', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    expect(stores.body.length).toBeGreaterThanOrEqual(2);
    const storeA = stores.body[0].id as string;
    const storeB = stores.body[1].id as string;

    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId: storeA, openingCash: 100000, clientId: shiftId })
      .expect(201);

    const voucherId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-voucher',
        sales: [],
        cashVouchers: [
          {
            id: voucherId,
            storeId: storeB,
            shiftId,
            categoryId: CATEGORY_OTHER_IN,
            direction: 'in',
            channel: 'cash',
            amountVnd: 5000,
            clientCreatedAt: new Date().toISOString(),
          },
        ],
      })
      .expect(201)
      .expect((res) => {
        expect(res.body.rejectedCashVouchers).toEqual(
          expect.arrayContaining([
            { id: voucherId, reason: 'store_forbidden' },
          ]),
        );
      });
  });

  it('close shift computes expected, variance, and transfer snapshot', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id as string;
    const product = await prisma.product.findUnique({ where: { sku: 'STING-330' } });
    if (!product) throw new Error('missing seed product');

    const customerId = randomUUID();
    await request(app.getHttpServer())
      .post('/customers')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ id: customerId, storeId, name: 'Debt Anh' })
      .expect(201);

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
        deviceId: 'dev-close',
        sales: [
          {
            id: saleId,
            storeId,
            shiftId,
            soldById: login.user.id,
            paymentMethod: 'cash',
            cashAmount: 10000,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 10000,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                productId: product.id,
                qty: '1',
                unitPrice: 10000,
                lineTotal: 10000,
              },
            ],
          },
        ],
      })
      .expect(201);

    const debtSaleId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-close',
        sales: [
          {
            id: debtSaleId,
            storeId,
            shiftId,
            soldById: login.user.id,
            paymentMethod: 'debt',
            cashAmount: 0,
            transferAmount: 0,
            debtAmount: 20000,
            discountVnd: 0,
            totalVnd: 20000,
            customerId,
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

    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-close',
        sales: [],
        debtPayments: [
          {
            id: randomUUID(),
            storeId,
            customerId,
            amountVnd: 5000,
            paymentMethod: 'cash',
            shiftId,
            clientCreatedAt: new Date().toISOString(),
          },
        ],
      })
      .expect(201);

    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-close',
        sales: [],
        cashVouchers: [
          {
            id: randomUUID(),
            storeId,
            shiftId,
            categoryId: CATEGORY_OTHER_IN,
            direction: 'in',
            channel: 'cash',
            amountVnd: 50000,
            clientCreatedAt: new Date().toISOString(),
          },
          {
            id: randomUUID(),
            storeId,
            shiftId,
            categoryId: CATEGORY_ELECTRICITY,
            direction: 'out',
            channel: 'cash',
            amountVnd: 300000,
            clientCreatedAt: new Date().toISOString(),
          },
          {
            id: randomUUID(),
            storeId,
            shiftId,
            categoryId: CATEGORY_OTHER_IN,
            direction: 'in',
            channel: 'transfer',
            amountVnd: 30000,
            clientCreatedAt: new Date().toISOString(),
          },
        ],
      })
      .expect(201);

    const closingCash = 265000;
    const closed = await request(app.getHttpServer())
      .post(`/shifts/${shiftId}/close`)
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ closingCash, note: 'End shift' })
      .expect(201);

    expect(closed.body.expectedCashVnd).toBe(265000);
    expect(closed.body.transferInShiftVnd).toBe(30000);
    expect(closed.body.varianceVnd).toBe(0);
    expect(closed.body.closingCash).toBe(closingCash);
  });

  it('same-push debt payment and close includes payment in expectedCash', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id as string;
    const product = await prisma.product.findUnique({ where: { sku: 'STING-330' } });
    if (!product) throw new Error('missing seed product');

    const customerId = randomUUID();
    await request(app.getHttpServer())
      .post('/customers')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ id: customerId, storeId, name: 'Debt Same Push' })
      .expect(201);

    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 500000, clientId: shiftId })
      .expect(201);

    const debtSaleId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-single-push',
        sales: [
          {
            id: debtSaleId,
            storeId,
            shiftId,
            soldById: login.user.id,
            paymentMethod: 'debt',
            cashAmount: 0,
            transferAmount: 0,
            debtAmount: 100000,
            discountVnd: 0,
            totalVnd: 100000,
            customerId,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                productId: product.id,
                qty: '10',
                unitPrice: 10000,
                lineTotal: 100000,
              },
            ],
          },
        ],
      })
      .expect(201);

    const paymentId = randomUUID();
    const closingCash = 550000;
    const push = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-single-push',
        sales: [],
        shiftCloses: [
          {
            id: shiftId,
            closingCash,
            closedAt: new Date().toISOString(),
          },
        ],
        debtPayments: [
          {
            id: paymentId,
            storeId,
            customerId,
            amountVnd: 50000,
            paymentMethod: 'cash',
            shiftId,
            clientCreatedAt: new Date().toISOString(),
          },
        ],
      })
      .expect(201);

    expect(push.body.acceptedShiftCloseIds).toContain(shiftId);
    expect(push.body.acceptedDebtPaymentIds).toContain(paymentId);
    expect(push.body.closedShifts).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          id: shiftId,
          expectedCashVnd: 550000,
          varianceVnd: 0,
          closingCash,
        }),
      ]),
    );

    const shift = await prisma.shift.findUniqueOrThrow({ where: { id: shiftId } });
    expect(shift.expectedCashVnd).toBe(550000);
    expect(shift.varianceVnd).toBe(0);
    expect(shift.closingCash).toBe(closingCash);
  });

  it('records voucher attributed to JWT user, not client payload', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id as string;

    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 100000, clientId: shiftId })
      .expect(201);

    const voucherId = randomUUID();
    const fakeUserId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-voucher',
        sales: [],
        cashVouchers: [
          {
            id: voucherId,
            storeId,
            shiftId,
            categoryId: CATEGORY_OTHER_IN,
            direction: 'in',
            channel: 'cash',
            amountVnd: 10000,
            recordedById: fakeUserId,
            clientCreatedAt: new Date().toISOString(),
          },
        ],
      })
      .expect(201);

    const row = await prisma.cashVoucher.findUniqueOrThrow({
      where: { id: voucherId },
    });
    expect(row.recordedById).toBe(login.user.id);
    expect(row.recordedById).not.toBe(fakeUserId);
  });

  it('pull returns seeded categories and pushed vouchers', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id as string;

    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 100000, clientId: shiftId })
      .expect(201);

    const voucherId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-pull',
        sales: [],
        cashVouchers: [
          {
            id: voucherId,
            storeId,
            shiftId,
            categoryId: CATEGORY_OTHER_IN,
            direction: 'in',
            channel: 'cash',
            amountVnd: 15000,
            clientCreatedAt: new Date().toISOString(),
          },
        ],
      })
      .expect(201);

    const pull = await request(app.getHttpServer())
      .get('/sync/pull')
      .query({ storeId, since: new Date(0).toISOString() })
      .set('Authorization', `Bearer ${login.accessToken}`)
      .expect(200);

    expect(pull.body.cashCategories.length).toBeGreaterThanOrEqual(5);
    expect(
      pull.body.cashCategories.some(
        (c: { code: string }) => c.code === 'electricity',
      ),
    ).toBe(true);
    expect(
      pull.body.cashVouchers.some((v: { id: string }) => v.id === voucherId),
    ).toBe(true);
  });
});
