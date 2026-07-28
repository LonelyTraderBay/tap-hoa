import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Phase 2 closeout: return + stocktake journals', () => {
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
    storeId = (await prisma.store.findFirst({ where: { code: 'CH1' } }))!.id;
    productId = (await prisma.product.findUnique({ where: { sku: 'STING-330' } }))!
      .id;
  });

  afterAll(async () => {
    await prisma.saleReturnLine.deleteMany({
      where: { saleReturn: { storeId } },
    });
    await prisma.saleReturn.deleteMany({ where: { storeId } });
    await prisma.periodLock.deleteMany();
    await app.close();
  });

  it('sale return posts reverse revenue/COGS; idempotent', async () => {
    await prisma.periodLock.deleteMany();
    await prisma.journalLine.deleteMany({
      where: { entry: { sourceType: 'sale_return' } },
    });
    await prisma.journalEntry.deleteMany({
      where: { sourceType: 'sale_return' },
    });
    await prisma.eInvoice.deleteMany({ where: { sale: { storeId } } });
    await prisma.saleReturnLine.deleteMany({
      where: { saleReturn: { storeId } },
    });
    await prisma.saleReturn.deleteMany({ where: { storeId } });
    await prisma.saleLine.deleteMany({ where: { sale: { storeId } } });
    await prisma.sale.deleteMany({ where: { storeId } });
    await prisma.auditLog.deleteMany({
      where: { action: 'sale_return_create' },
    });
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
    const now = new Date().toISOString();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'closeout-return-sale',
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
            clientCreatedAt: now,
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

    const returnId = randomUUID();
    const pushReturn = () =>
      request(app.getHttpServer())
        .post('/sync/push')
        .set('Authorization', `Bearer ${token}`)
        .send({
          deviceId: 'closeout-return',
          sales: [],
          saleReturns: [
            {
              id: returnId,
              storeId,
              originalSaleId: saleId,
              shiftId: shift.id,
              cashRefundVnd: 15000,
              transferRefundVnd: 0,
              debtCreditVnd: 0,
              totalRefundVnd: 15000,
              note: 'Khach doi y, tra lai hang',
              clientCreatedAt: now,
              lines: [
                {
                  id: randomUUID(),
                  productId,
                  qty: '1',
                  unitPrice: 15000,
                  lineRefundVnd: 15000,
                },
              ],
            },
          ],
        })
        .expect(201);

    const res1 = await pushReturn();
    expect(res1.body.acceptedSaleReturnIds).toContain(returnId);
    const res2 = await pushReturn();
    expect(res2.body.acceptedSaleReturnIds).toContain(returnId);

    const entries = await prisma.journalEntry.findMany({
      where: { sourceType: 'sale_return', sourceId: returnId },
      include: { lines: true },
    });
    expect(entries).toHaveLength(1);
    expect(entries[0].lines.find((l) => l.accountCode === '511')?.debitVnd).toBe(
      15000,
    );
    expect(entries[0].lines.find((l) => l.accountCode === '111')?.creditVnd).toBe(
      15000,
    );
    expect(entries[0].lines.find((l) => l.accountCode === '156')?.debitVnd).toBe(
      9000,
    );
    expect(entries[0].lines.find((l) => l.accountCode === '632')?.creditVnd).toBe(
      9000,
    );

    // §5.7: trả hàng phải để lại nhật ký kiểm soát, thấy được qua GET
    // /ledger/audit ngay cả khi client không truyền `action` (allowlist mặc
    // định phải chứa 'sale_return_create' — xem defaultAuditActions).
    const auditRows = await prisma.auditLog.findMany({
      where: { action: 'sale_return_create', entityId: returnId },
    });
    expect(auditRows).toHaveLength(1);

    const auditApi = await request(app.getHttpServer())
      .get('/ledger/audit')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    const auditEntry = auditApi.body.find(
      (row: { action: string; entityId: string | null }) =>
        row.action === 'sale_return_create' && row.entityId === returnId,
    );
    expect(auditEntry).toMatchObject({
      actorUserId: userId,
      entityType: 'sale_return',
      entityId: returnId,
    });
    expect(JSON.parse(auditEntry.detailJson)).toMatchObject({
      saleId,
      storeId,
      totalVnd: 15000,
      cashRefundVnd: 15000,
      transferRefundVnd: 0,
      debtCreditVnd: 0,
      reason: 'Khach doi y, tra lai hang',
    });
  });

  it('stocktake decrease posts Dr 642 Cr 156; period lock blocks', async () => {
    await prisma.periodLock.deleteMany();
    await prisma.journalLine.deleteMany({
      where: { entry: { sourceType: 'stocktake' } },
    });
    await prisma.journalEntry.deleteMany({
      where: { sourceType: 'stocktake' },
    });
    await prisma.auditLog.deleteMany({
      where: { action: 'journal_blocked_period_lock' },
    });

    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId } },
      create: {
        productId,
        storeId,
        qty: 50,
        minQty: 0,
        avgCostVnd: 8000,
      },
      update: { qty: 50, avgCostVnd: 8000 },
    });

    const stocktakeId = randomUUID();
    const at = new Date();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'closeout-stocktake',
        sales: [],
        stocktakes: [
          {
            id: stocktakeId,
            storeId,
            clientCreatedAt: at.toISOString(),
            lines: [
              {
                id: randomUUID(),
                productId,
                systemQty: '50',
                countedQty: '48',
                varianceQty: '-2',
                reason: 'decrease',
              },
            ],
          },
        ],
      })
      .expect(201);

    const journal = await prisma.journalEntry.findUnique({
      where: {
        sourceType_sourceId: {
          sourceType: 'stocktake',
          sourceId: stocktakeId,
        },
      },
      include: { lines: true },
    });
    expect(journal).toBeTruthy();
    expect(journal!.lines.find((l) => l.accountCode === '642')?.debitVnd).toBe(
      16000,
    );
    expect(journal!.lines.find((l) => l.accountCode === '156')?.creditVnd).toBe(
      16000,
    );

    const ict = new Date(at.getTime() + 7 * 3600_000);
    const periodYm = `${ict.getUTCFullYear()}-${String(ict.getUTCMonth() + 1).padStart(2, '0')}`;
    await request(app.getHttpServer())
      .post('/ledger/period-locks')
      .set('Authorization', `Bearer ${token}`)
      .send({ periodYm })
      .expect(201);

    const blockedId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'closeout-stocktake-lock',
        sales: [],
        stocktakes: [
          {
            id: blockedId,
            storeId,
            clientCreatedAt: at.toISOString(),
            lines: [
              {
                id: randomUUID(),
                productId,
                systemQty: '48',
                countedQty: '47',
                varianceQty: '-1',
                reason: 'decrease',
              },
            ],
          },
        ],
      })
      .expect(201);

    const blocked = await prisma.journalEntry.findUnique({
      where: {
        sourceType_sourceId: {
          sourceType: 'stocktake',
          sourceId: blockedId,
        },
      },
    });
    expect(blocked).toBeNull();
    const audit = await prisma.auditLog.findFirst({
      where: {
        action: 'journal_blocked_period_lock',
        entityId: blockedId,
      },
    });
    expect(audit).toBeTruthy();
    await prisma.periodLock.deleteMany({ where: { periodYm } });
  });
});
