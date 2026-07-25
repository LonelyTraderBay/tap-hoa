import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Phase 3 bank recon e2e', () => {
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
    productId = (
      await prisma.product.findUnique({ where: { sku: 'STING-330' } })
    )!.id;
    const now = new Date();
    const ict = new Date(now.getTime() + 7 * 3600_000);
    periodYm = `${ict.getUTCFullYear()}-${String(ict.getUTCMonth() + 1).padStart(2, '0')}`;
  });

  afterAll(async () => {
    await app.close();
  });

  it('imports statement, matches sale transfer, locks period', async () => {
    await prisma.bankReconLock.deleteMany({ where: { storeId, periodYm } });
    await prisma.bankStatementLine.deleteMany({ where: { storeId, periodYm } });
    await prisma.shift.updateMany({
      where: { storeId, closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
    });
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId } },
      create: {
        productId,
        storeId,
        qty: 20,
        minQty: 0,
        avgCostVnd: 9000,
      },
      update: { qty: 20, avgCostVnd: 9000 },
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
        deviceId: 'bank-recon-1',
        sales: [
          {
            id: saleId,
            storeId,
            shiftId: shift.id,
            paymentMethod: 'transfer',
            cashAmount: 0,
            transferAmount: 50_000,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 50_000,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                productId,
                qty: '1',
                unitPrice: 50_000,
                lineTotal: 50_000,
              },
            ],
          },
        ],
      })
      .expect(201);

    const day = periodYm + '-15';
    const imp = await request(app.getHttpServer())
      .post('/reports/bank-recon/import')
      .set('Authorization', `Bearer ${token}`)
      .send({
        storeId,
        periodYm,
        csv: `date,amountVnd,memo\n${day},50000,CK ban`,
      })
      .expect(201);
    expect(imp.body.imported).toBe(1);

    const summary = await request(app.getHttpServer())
      .get('/reports/bank-recon')
      .query({ storeId, periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(summary.body.bookTotalVnd).toBe(50_000);
    expect(summary.body.statementTotalVnd).toBe(50_000);
    expect(summary.body.varianceVnd).toBe(0);
    expect(summary.body.matchedCount).toBe(1);

    await request(app.getHttpServer())
      .post('/reports/bank-recon/lock')
      .set('Authorization', `Bearer ${token}`)
      .send({ storeId, periodYm })
      .expect(201);

    await request(app.getHttpServer())
      .post('/reports/bank-recon/import')
      .set('Authorization', `Bearer ${token}`)
      .send({
        storeId,
        periodYm,
        csv: `${day},1000,x`,
      })
      .expect(400);
  });
});
