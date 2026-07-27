import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
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

describe('Debt payments ledger', () => {
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
    await prisma.debtLedgerEntry.deleteMany();
    await prisma.eInvoice.deleteMany();
    await prisma.saleReturnLine.deleteMany();
    await prisma.saleReturn.deleteMany();
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

  it('push debt sale writes sale_debt ledger and rejects over credit limit', async () => {
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
      .send({
        id: customerId,
        storeId,
        name: 'Limit Anh',
        creditLimitVnd: 15000,
      })
      .expect(201);

    const shiftId = randomUUID();
    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 500000, clientId: shiftId })
      .expect(201);

    const okSaleId = randomUUID();
    const okSale = {
      id: okSaleId,
      storeId,
      shiftId,
      soldById: login.user.id,
      paymentMethod: 'debt',
      cashAmount: 0,
      transferAmount: 0,
      debtAmount: 10000,
      discountVnd: 0,
      totalVnd: 10000,
      customerId,
      clientCreatedAt: new Date().toISOString(),
      lines: [
        {
          productId: product.id,
          qty: '1',
          unitPrice: 10000,
          lineTotal: 10000,
        },
      ],
    };

    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ deviceId: 'dev-ledger', sales: [okSale] })
      .expect(201)
      .expect((res) => {
        expect(res.body.acceptedIds).toContain(okSaleId);
      });

    const ledger = await prisma.debtLedgerEntry.findFirst({
      where: { saleId: okSaleId },
    });
    expect(ledger?.type).toBe('sale_debt');
    expect(ledger?.amountVnd).toBe(10000);
    expect(ledger?.balanceAfterVnd).toBe(10000);

    const overSaleId = randomUUID();
    const overSale = {
      ...okSale,
      id: overSaleId,
      debtAmount: 10000,
      totalVnd: 10000,
      clientCreatedAt: new Date().toISOString(),
    };
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ deviceId: 'dev-ledger', sales: [overSale] })
      .expect(201)
      .expect((res) => {
        expect(res.body.rejected).toEqual(
          expect.arrayContaining([
            { id: overSaleId, reason: 'credit_limit_exceeded' },
          ]),
        );
      });
  });

  it('push debt payment is idempotent and rejects over balance; pull returns ledger', async () => {
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
      .send({
        id: customerId,
        storeId,
        name: 'Debt Anh',
      })
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
        deviceId: 'dev-pay-setup',
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

    const paymentId = randomUUID();
    const payment = {
      id: paymentId,
      storeId,
      customerId,
      amountVnd: 5000,
      paymentMethod: 'cash',
      note: 'tra mot phan',
      shiftId,
      clientCreatedAt: new Date().toISOString(),
    };

    const pushOnce = () =>
      request(app.getHttpServer())
        .post('/sync/push')
        .set('Authorization', `Bearer ${login.accessToken}`)
        .send({ deviceId: 'dev-pay', sales: [], debtPayments: [payment] })
        .expect(201);

    const first = await pushOnce();
    expect(first.body.acceptedDebtPaymentIds).toContain(paymentId);
    const second = await pushOnce();
    expect(second.body.acceptedDebtPaymentIds).toContain(paymentId);

    const customer = await prisma.customer.findUnique({ where: { id: customerId } });
    expect(customer?.balanceVnd).toBe(15000);

    const overId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'dev-pay',
        sales: [],
        debtPayments: [
          {
            ...payment,
            id: overId,
            amountVnd: 999999,
            clientCreatedAt: new Date().toISOString(),
          },
        ],
      })
      .expect(201)
      .expect((res) => {
        expect(res.body.rejectedDebtPayments).toEqual(
          expect.arrayContaining([
            { id: overId, reason: 'payment_exceeds_balance' },
          ]),
        );
      });

    const pull = await request(app.getHttpServer())
      .get('/sync/pull')
      .query({ storeId, since: new Date(0).toISOString() })
      .set('Authorization', `Bearer ${login.accessToken}`)
      .expect(200);
    expect(pull.body.customers.some((c: { id: string }) => c.id === customerId)).toBe(
      true,
    );
    expect(
      pull.body.debtLedger.some((e: { id: string }) => e.id === paymentId),
    ).toBe(true);
  });

  it('rejects a store-forbidden debt payment as a per-item entry without failing the rest of the batch', async () => {
    const store1Id = (await prisma.store.findFirst({ where: { code: 'CH1' } }))!
      .id;
    const store2Id = (await prisma.store.findFirst({ where: { code: 'CH2' } }))!
      .id;

    // Manager scoped to CH2 only — has no access to CH1.
    const managerPhone = '0900000197';
    const passwordHash = await bcrypt.hash('123456', 10);
    const manager = await prisma.user.upsert({
      where: { phone: managerPhone },
      update: { active: true, role: 'store_manager', passwordHash },
      create: {
        phone: managerPhone,
        name: 'QL CH2 sync forbidden',
        passwordHash,
        role: 'store_manager',
      },
    });
    await prisma.userStore.upsert({
      where: { userId_storeId: { userId: manager.id, storeId: store2Id } },
      update: {},
      create: { userId: manager.id, storeId: store2Id },
    });
    await prisma.userStore.deleteMany({
      where: { userId: manager.id, storeId: { not: store2Id } },
    });
    const managerLogin = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: managerPhone, password: '123456' })
      .expect(201);
    const managerToken = managerLogin.body.accessToken as string;

    // Customer in the manager's own store (CH2), with a balance the manager CAN pay against.
    const allowedCustomerId = randomUUID();
    await prisma.customer.create({
      data: {
        id: allowedCustomerId,
        storeId: store2Id,
        name: 'Khach CH2 hop le',
        balanceVnd: 20000,
      },
    });

    const forbiddenPaymentId = randomUUID();
    const allowedPaymentId = randomUUID();

    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${managerToken}`)
      .send({
        deviceId: 'dev-store-forbidden',
        sales: [],
        debtPayments: [
          {
            id: forbiddenPaymentId,
            storeId: store1Id,
            customerId: randomUUID(),
            amountVnd: 5000,
            paymentMethod: 'cash',
            clientCreatedAt: new Date().toISOString(),
          },
          {
            id: allowedPaymentId,
            storeId: store2Id,
            customerId: allowedCustomerId,
            amountVnd: 5000,
            paymentMethod: 'cash',
            clientCreatedAt: new Date().toISOString(),
          },
        ],
      });

    // The whole batch must still succeed (not the 403 the un-caught
    // assertStoreAccess used to raise for the entire /sync/push request).
    expect(res.status).toBeLessThan(300);
    expect(res.body.rejectedDebtPayments).toEqual(
      expect.arrayContaining([
        { id: forbiddenPaymentId, reason: 'store_forbidden' },
      ]),
    );
    expect(res.body.acceptedDebtPaymentIds).toContain(allowedPaymentId);

    const customer = await prisma.customer.findUnique({
      where: { id: allowedCustomerId },
    });
    expect(customer?.balanceVnd).toBe(15000);
  });
});
