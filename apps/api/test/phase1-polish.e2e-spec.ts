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

async function loginAsCashier(app: INestApplication, phone: string) {
  const res = await request(app.getHttpServer())
    .post('/auth/login')
    .send({ phone, password: '123456' })
    .expect(201);
  return {
    accessToken: res.body.accessToken as string,
    user: res.body.user as { id: string },
  };
}

describe('Phase1 polish sync: product groups + sale returns', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let storeCh1: string;
  let cashierPhone: string;
  let productId: string;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    prisma = moduleRef.get(PrismaService);
    await app.init();

    const ch1 = await prisma.store.findFirstOrThrow({ where: { code: 'CH1' } });
    storeCh1 = ch1.id;

    cashierPhone = '0900000199';
    const passwordHash = await bcrypt.hash('123456', 10);
    await prisma.user.upsert({
      where: { phone: cashierPhone },
      update: {},
      create: {
        phone: cashierPhone,
        name: 'Polish cashier',
        passwordHash,
        role: Role.cashier,
        stores: { create: [{ storeId: storeCh1 }] },
      },
    });

    const product = await prisma.product.findFirst({
      where: { active: true },
    });
    if (!product) {
      throw new Error('seed product required');
    }
    productId = product.id;
  });

  afterAll(() => app.close());

  it('accepts product_group_upsert for owner', async () => {
    const login = await loginAsOwner(app);
    const id = randomUUID();
    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'polish-group-1',
        sales: [],
        productGroupUpserts: [
          { id, name: `Nhom-${id.slice(0, 6)}`, sortOrder: 3, active: true },
        ],
      })
      .expect(201);

    expect(res.body.acceptedProductGroupUpsertIds).toContain(id);
    const group = await prisma.productGroup.findUniqueOrThrow({ where: { id } });
    expect(group.active).toBe(true);
    expect(group.sortOrder).toBe(3);
  });

  it('rejects product_group_upsert for cashier', async () => {
    const login = await loginAsCashier(app, cashierPhone);
    const id = randomUUID();
    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'polish-group-2',
        sales: [],
        productGroupUpserts: [
          { id, name: `NhomCash-${id.slice(0, 6)}`, sortOrder: 1, active: true },
        ],
      })
      .expect(201);

    expect(res.body.rejectedProductGroupUpserts).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ id, reason: 'role_forbidden' }),
      ]),
    );
  });

  it('rejects sale_return when not same ICT day', async () => {
    const login = await loginAsOwner(app);

    await prisma.shift.updateMany({
      where: { storeId: storeCh1, closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
    });

    const shift = await prisma.shift.create({
      data: {
        id: randomUUID(),
        storeId: storeCh1,
        userId: login.user.id,
        openingCash: 100000,
        openedAt: new Date(),
      },
    });

    const saleId = randomUUID();
    const yesterday = new Date(Date.now() - 36 * 60 * 60 * 1000);
    await prisma.sale.create({
      data: {
        id: saleId,
        storeId: storeCh1,
        shiftId: shift.id,
        soldById: login.user.id,
        paymentMethod: 'cash',
        cashAmount: 10000,
        transferAmount: 0,
        debtAmount: 0,
        discountVnd: 0,
        totalVnd: 10000,
        clientCreatedAt: yesterday,
        lines: {
          create: [
            {
              id: randomUUID(),
              productId,
              qty: '1',
              unitPrice: 10000,
              lineTotal: 10000,
            },
          ],
        },
      },
    });

    const returnId = randomUUID();
    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'polish-return-1',
        sales: [],
        saleReturns: [
          {
            id: returnId,
            storeId: storeCh1,
            originalSaleId: saleId,
            shiftId: shift.id,
            cashRefundVnd: 10000,
            transferRefundVnd: 0,
            debtCreditVnd: 0,
            totalRefundVnd: 10000,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                productId,
                qty: '1',
                unitPrice: 10000,
                lineRefundVnd: 10000,
              },
            ],
          },
        ],
      })
      .expect(201);

    expect(res.body.rejectedSaleReturns).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          id: returnId,
          reason: 'return_not_same_day',
        }),
      ]),
    );
  });
});
