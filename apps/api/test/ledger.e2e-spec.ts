import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Phase 2 ledger e2e', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;
  let userId: string;
  let storeId: string;
  let productId: string;

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
    const store = await prisma.store.findFirst({ where: { code: 'CH1' } });
    const product = await prisma.product.findUnique({
      where: { sku: 'STING-330' },
    });
    storeId = store!.id;
    productId = product!.id;
  });

  afterAll(async () => {
    await app.close();
  });

  it('posts balanced sale journal; idempotent; period lock blocks', async () => {
    await prisma.journalLine.deleteMany();
    await prisma.journalEntry.deleteMany();
    await prisma.auditLog.deleteMany();
    await prisma.periodLock.deleteMany();
    await prisma.eInvoice.deleteMany({
      where: { sale: { storeId } },
    });
    await prisma.saleReturnLine.deleteMany({
      where: { saleReturn: { storeId } },
    });
    await prisma.saleReturn.deleteMany({ where: { storeId } });
    await prisma.saleLine.deleteMany({ where: { sale: { storeId } } });
    await prisma.sale.deleteMany({ where: { storeId } });
    await prisma.shift.updateMany({
      where: { storeId, closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
    });

    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId } },
      create: {
        productId,
        storeId,
        qty: 50,
        minQty: 0,
        avgCostVnd: 9000,
      },
      update: { qty: 50, avgCostVnd: 9000 },
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
    const push = () =>
      request(app.getHttpServer())
        .post('/sync/push')
        .set('Authorization', `Bearer ${token}`)
        .send({
          deviceId: 'ledger-1',
          sales: [
            {
              id: saleId,
              storeId,
              shiftId: shift.id,
              soldById: userId,
              paymentMethod: 'cash',
              cashAmount: 10000,
              transferAmount: 0,
              debtAmount: 0,
              discountVnd: 0,
              totalVnd: 10000,
              customerId: null,
              clientCreatedAt: new Date().toISOString(),
              lines: [
                {
                  productId,
                  qty: '1',
                  unitPrice: 10000,
                  lineTotal: 10000,
                },
              ],
            },
          ],
        })
        .expect(201);

    await push();
    const entry = await prisma.journalEntry.findUnique({
      where: { sourceType_sourceId: { sourceType: 'sale', sourceId: saleId } },
      include: { lines: true },
    });
    expect(entry).toBeTruthy();
    const debit = entry!.lines.reduce((s, l) => s + l.debitVnd, 0);
    const credit = entry!.lines.reduce((s, l) => s + l.creditVnd, 0);
    expect(debit).toBe(credit);
    expect(debit).toBe(19000);

    await push();
    const count = await prisma.journalEntry.count({
      where: { sourceType: 'sale', sourceId: saleId },
    });
    expect(count).toBe(1);

    const periodYm = entry!.periodYm;
    await request(app.getHttpServer())
      .post('/ledger/period-locks')
      .set('Authorization', `Bearer ${token}`)
      .send({ periodYm })
      .expect(201);

    const saleId2 = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'ledger-1',
        sales: [
          {
            id: saleId2,
            storeId,
            shiftId: shift.id,
            soldById: userId,
            paymentMethod: 'cash',
            cashAmount: 10000,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 10000,
            customerId: null,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                productId,
                qty: '1',
                unitPrice: 10000,
                lineTotal: 10000,
              },
            ],
          },
        ],
      })
      .expect(201);

    const blocked = await prisma.journalEntry.findUnique({
      where: {
        sourceType_sourceId: { sourceType: 'sale', sourceId: saleId2 },
      },
    });
    expect(blocked).toBeNull();
    const audits = await prisma.auditLog.findMany({
      where: { action: 'journal_blocked_period_lock', entityId: saleId2 },
    });
    expect(audits.length).toBeGreaterThan(0);

    const tb = await request(app.getHttpServer())
      .get(`/ledger/trial-balance?periodYm=${periodYm}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    const row511 = tb.body.rows.find(
      (r: { accountCode: string }) => r.accountCode === '511',
    );
    expect(row511.creditVnd).toBeGreaterThanOrEqual(10000);
  });
});
