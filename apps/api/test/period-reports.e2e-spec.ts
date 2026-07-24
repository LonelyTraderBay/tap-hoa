import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Phase 2 period reports e2e', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;
  let userId: string;
  let storeId: string;
  let productId: string;
  let periodYm: string;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    prisma = moduleRef.get(PrismaService);
    await app.init();
    await seedChartOfAccounts(prisma);

    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: '0900000001', password: '123456' })
      .expect(201);
    token = login.body.accessToken;
    userId = login.body.user.id;
    storeId = (await prisma.store.findFirst({ where: { code: 'CH1' } }))!.id;
    productId = (await prisma.product.findUnique({ where: { sku: 'STING-330' } }))!
      .id;
    const now = new Date();
    const ict = new Date(now.getTime() + 7 * 3600_000);
    periodYm = `${ict.getUTCFullYear()}-${String(ict.getUTCMonth() + 1).padStart(2, '0')}`;
  });

  afterAll(async () => {
    await app.close();
  });

  it('pnl matches ledger trial for sample period', async () => {
    await prisma.periodLock.deleteMany({ where: { periodYm } });
    await prisma.journalLine.deleteMany();
    await prisma.journalEntry.deleteMany();
    await prisma.shift.updateMany({
      where: { storeId, closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
    });
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId } },
      create: {
        productId,
        storeId,
        qty: 30,
        minQty: 0,
        avgCostVnd: 9000,
      },
      update: { qty: 30, avgCostVnd: 9000 },
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
    const saleId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'e2e-period',
        sales: [
          {
            id: saleId,
            storeId,
            shiftId: shift.id,
            paymentMethod: 'cash',
            cashAmount: 15000,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 15000,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                id: randomUUID(),
                productId,
                qty: '1',
                unitPrice: 15000,
                lineTotal: 15000,
              },
            ],
          },
        ],
      })
      .expect(201);

    const tb = await request(app.getHttpServer())
      .get('/reports/period/trial-balance')
      .query({ periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    const ledgerTb = await request(app.getHttpServer())
      .get('/ledger/trial-balance')
      .query({ periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(tb.body.rows).toEqual(ledgerTb.body.rows);

    const pnl = await request(app.getHttpServer())
      .get('/reports/period/pnl')
      .query({ periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(pnl.body.revenueVnd).toBe(15000);
    expect(pnl.body.cogsVnd).toBe(9000);
    expect(pnl.body.grossProfitVnd).toBe(6000);

    const exp = await request(app.getHttpServer())
      .get('/reports/period/export.csv')
      .query({ periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(exp.body.csv).toContain('trial_balance');
    expect(exp.body.csv).toContain('net_income');
  });
});
