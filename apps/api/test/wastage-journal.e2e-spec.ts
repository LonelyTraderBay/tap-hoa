import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { StockDocType } from '@prisma/client';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { periodYmFromDate } from '../src/ledger/journal-builders';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Wastage journals', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;
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
    storeId = (await prisma.store.findFirst({ where: { code: 'CH1' } }))!.id;
    productId = (await prisma.product.findUnique({ where: { sku: 'STING-330' } }))!
      .id;
  });

  beforeEach(async () => {
    await prisma.periodLock.deleteMany();
    await prisma.journalLine.deleteMany({
      where: { entry: { sourceType: 'wastage' } },
    });
    await prisma.journalEntry.deleteMany({
      where: { sourceType: 'wastage' },
    });
    await prisma.auditLog.deleteMany({
      where: { action: 'journal_blocked_period_lock', entityType: 'wastage' },
    });
    await prisma.stockMovement.deleteMany({
      where: { storeId, docType: StockDocType.wastage },
    });
    await prisma.wastageVoucherLine.deleteMany({
      where: { wastage: { storeId } },
    });
    await prisma.wastageVoucher.deleteMany({ where: { storeId } });
  });

  afterAll(async () => {
    await prisma.journalLine.deleteMany({
      where: { entry: { sourceType: 'wastage' } },
    });
    await prisma.journalEntry.deleteMany({
      where: { sourceType: 'wastage' },
    });
    await prisma.stockMovement.deleteMany({
      where: { storeId, docType: StockDocType.wastage },
    });
    await prisma.wastageVoucherLine.deleteMany({
      where: { wastage: { storeId } },
    });
    await prisma.wastageVoucher.deleteMany({ where: { storeId } });
    await prisma.periodLock.deleteMany();
    await app.close();
  });

  it('posts Dr 642 Cr 156 at WAC and remains idempotent', async () => {
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId } },
      create: { productId, storeId, qty: 20, minQty: 0, avgCostVnd: 8000 },
      update: { qty: 20, avgCostVnd: 8000 },
    });

    const wastageId = randomUUID();
    const at = new Date();
    const push = () =>
      request(app.getHttpServer())
        .post('/sync/push')
        .set('Authorization', `Bearer ${token}`)
        .send({
          deviceId: 'wastage-journal',
          sales: [],
          wastages: [
            {
              id: wastageId,
              storeId,
              reasonCode: 'damage',
              clientCreatedAt: at.toISOString(),
              lines: [{ id: randomUUID(), productId, qty: '2' }],
            },
          ],
        })
        .expect(201);

    expect((await push()).body.acceptedWastageIds).toContain(wastageId);
    expect((await push()).body.acceptedWastageIds).toContain(wastageId);

    const journal = await prisma.journalEntry.findUnique({
      where: {
        sourceType_sourceId: {
          sourceType: 'wastage',
          sourceId: wastageId,
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
    expect(
      await prisma.journalEntry.count({
        where: { sourceType: 'wastage', sourceId: wastageId },
      }),
    ).toBe(1);
  });

  it('accepts wastage but blocks posting in a locked period', async () => {
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId } },
      create: { productId, storeId, qty: 20, minQty: 0, avgCostVnd: 8000 },
      update: { qty: 20, avgCostVnd: 8000 },
    });

    const wastageId = randomUUID();
    const at = new Date();
    const periodYm = periodYmFromDate(at);
    await request(app.getHttpServer())
      .post('/ledger/period-locks')
      .set('Authorization', `Bearer ${token}`)
      .send({ periodYm })
      .expect(201);

    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'wastage-journal-lock',
        sales: [],
        wastages: [
          {
            id: wastageId,
            storeId,
            reasonCode: 'damage',
            clientCreatedAt: at.toISOString(),
            lines: [{ id: randomUUID(), productId, qty: '1' }],
          },
        ],
      })
      .expect(201);

    expect(res.body.acceptedWastageIds).toContain(wastageId);
    expect(
      await prisma.journalEntry.findUnique({
        where: {
          sourceType_sourceId: {
            sourceType: 'wastage',
            sourceId: wastageId,
          },
        },
      }),
    ).toBeNull();
    expect(
      await prisma.auditLog.findFirst({
        where: {
          action: 'journal_blocked_period_lock',
          entityType: 'wastage',
          entityId: wastageId,
        },
      }),
    ).toBeTruthy();

    await prisma.periodLock.deleteMany({ where: { periodYm } });
  });

  it('accepts wastage without posting when stock has no cost', async () => {
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId } },
      create: { productId, storeId, qty: 20, minQty: 0, avgCostVnd: 0 },
      update: { qty: 20, avgCostVnd: 0 },
    });

    const wastageId = randomUUID();
    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'wastage-journal-no-cost',
        sales: [],
        wastages: [
          {
            id: wastageId,
            storeId,
            reasonCode: 'damage',
            clientCreatedAt: new Date().toISOString(),
            lines: [{ id: randomUUID(), productId, qty: '1' }],
          },
        ],
      })
      .expect(201);

    expect(res.body.acceptedWastageIds).toContain(wastageId);
    expect(
      await prisma.journalEntry.findUnique({
        where: {
          sourceType_sourceId: {
            sourceType: 'wastage',
            sourceId: wastageId,
          },
        },
      }),
    ).toBeNull();
  });
});
