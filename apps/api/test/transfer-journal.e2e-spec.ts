import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { periodYmFromDate } from '../src/ledger/journal-builders';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Transfer journals', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;
  let storeCh1: string;
  let storeCh2: string;
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
    storeCh1 = (await prisma.store.findFirst({ where: { code: 'CH1' } }))!.id;
    storeCh2 = (await prisma.store.findFirst({ where: { code: 'CH2' } }))!.id;
    productId = (
      await prisma.product.findUnique({ where: { sku: 'STING-330' } })
    )!.id;
  });

  beforeEach(async () => {
    await prisma.periodLock.deleteMany();
    await prisma.journalLine.deleteMany({
      where: {
        entry: {
          sourceType: {
            in: ['stock_transfer', 'stock_transfer_out', 'stock_transfer_in'],
          },
        },
      },
    });
    await prisma.journalEntry.deleteMany({
      where: {
        sourceType: {
          in: ['stock_transfer', 'stock_transfer_out', 'stock_transfer_in'],
        },
      },
    });
    await prisma.auditLog.deleteMany({
      where: { action: 'journal_blocked_period_lock' },
    });
    await prisma.stockMovement.deleteMany({
      where: { docType: 'transfer' },
    });
    await prisma.stockTransferLine.deleteMany();
    await prisma.stockTransfer.deleteMany();
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId: storeCh1 } },
      create: {
        productId,
        storeId: storeCh1,
        qty: 20,
        minQty: 0,
        avgCostVnd: 7000,
      },
      update: { qty: 20, minQty: 0, avgCostVnd: 7000 },
    });
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId: storeCh2 } },
      create: {
        productId,
        storeId: storeCh2,
        qty: 5,
        minQty: 0,
        avgCostVnd: 3000,
      },
      update: { qty: 5, minQty: 0, avgCostVnd: 3000 },
    });
  });

  afterAll(async () => {
    await prisma.periodLock.deleteMany();
    await app.close();
  });

  async function pushTransfer(input: {
    transferId: string;
    lineId: string;
    qty: string;
    receiveAt?: Date;
    sourceCostAfterApprove?: number;
  }) {
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'transfer-journal',
        sales: [],
        stockTransferCreates: [
          {
            id: input.transferId,
            fromStoreId: storeCh1,
            toStoreId: storeCh2,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              { id: input.lineId, productId, qty: input.qty },
            ],
          },
        ],
      })
      .expect(201)
      .expect(({ body }) => {
        expect(body.acceptedStockTransferCreateIds).toContain(input.transferId);
      });

    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'transfer-journal',
        sales: [],
        stockTransferApproves: [{ id: input.transferId }],
      })
      .expect(201)
      .expect(({ body }) => {
        expect(body.acceptedStockTransferApproveIds).toContain(input.transferId);
      });

    if (input.sourceCostAfterApprove != null) {
      await prisma.productStoreStock.update({
        where: { productId_storeId: { productId, storeId: storeCh1 } },
        data: { avgCostVnd: input.sourceCostAfterApprove },
      });
    }

    return request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'transfer-journal',
        sales: [],
        stockTransferReceives: [
          {
            id: input.transferId,
            ...(input.receiveAt ? { actionAt: input.receiveAt.toISOString() } : {}),
          },
        ],
      })
      .expect(201)
      .expect(({ body }) => {
        expect(body.acceptedStockTransferReceiveIds).toContain(input.transferId);
      });
  }

  it('posts store-scoped transfer journals from the approval cost snapshot', async () => {
    const transferId = randomUUID();
    const lineId = randomUUID();
    await pushTransfer({
      transferId,
      lineId,
      qty: '2.5',
      sourceCostAfterApprove: 11000,
    });

    const journals = await prisma.journalEntry.findMany({
      where: {
        sourceType: { in: ['stock_transfer_out', 'stock_transfer_in'] },
        sourceId: transferId,
      },
      include: { lines: true },
      orderBy: { sourceType: 'asc' },
    });
    expect(journals).toHaveLength(2);
    const source = journals.find((j) => j.sourceType === 'stock_transfer_out')!;
    const destination = journals.find((j) => j.sourceType === 'stock_transfer_in')!;
    expect(source.storeId).toBe(storeCh1);
    expect(destination.storeId).toBe(storeCh2);
    expect(source.lines.find((l) => l.accountCode === '151')?.debitVnd).toBe(17500);
    expect(source.lines.find((l) => l.accountCode === '156')?.creditVnd).toBe(17500);
    expect(destination.lines.find((l) => l.accountCode === '156')?.debitVnd).toBe(17500);
    expect(destination.lines.find((l) => l.accountCode === '151')?.creditVnd).toBe(17500);
    expect(
      journals.flatMap((j) => j.lines).some((l) => l.accountCode === '632'),
    ).toBe(false);
    await expect(
      prisma.productStoreStock.findUnique({
        where: { productId_storeId: { productId, storeId: storeCh2 } },
      }),
    ).resolves.toMatchObject({ avgCostVnd: 4333 });

    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'transfer-journal',
        sales: [],
        stockTransferReceives: [{ id: transferId }],
      })
      .expect(201)
      .expect(({ body }) => {
        expect(body.acceptedStockTransferReceiveIds).toContain(transferId);
      });
    await expect(
      prisma.journalEntry.count({
        where: {
          sourceType: { in: ['stock_transfer_out', 'stock_transfer_in'] },
          sourceId: transferId,
        },
      }),
    ).resolves.toBe(2);
    await expect(
      prisma.productStoreStock.findUnique({
        where: { productId_storeId: { productId, storeId: storeCh2 } },
      }),
    ).resolves.toMatchObject({ avgCostVnd: 4333 });
  });

  it('blocks receive journal in a locked period and replays it on unlock', async () => {
    const transferId = randomUUID();
    const receiveAt = new Date();
    const periodYm = periodYmFromDate(receiveAt);
    await request(app.getHttpServer())
      .post('/ledger/period-locks')
      .set('Authorization', `Bearer ${token}`)
      .send({ periodYm })
      .expect(201);

    await pushTransfer({
      transferId,
      lineId: randomUUID(),
      qty: '1',
      receiveAt,
    });

    await expect(
      prisma.journalEntry.count({
        where: {
          sourceType: { in: ['stock_transfer_out', 'stock_transfer_in'] },
          sourceId: transferId,
        },
      }),
    ).resolves.toBe(0);
    expect(
      await prisma.auditLog.findFirst({
        where: {
          action: 'journal_blocked_period_lock',
          entityType: 'stock_transfer',
          entityId: transferId,
        },
      }),
    ).toBeTruthy();

    await request(app.getHttpServer())
      .post(`/ledger/period-locks/${periodYm}/unlock`)
      .set('Authorization', `Bearer ${token}`)
      .send({ reason: 'replay stock transfer journal' })
      .expect(200)
      .expect(({ body }) => {
        expect(body).toEqual({ unlocked: true, periodYm, replayed: 1 });
      });

    const replayed = await prisma.journalEntry.findMany({
      where: {
        sourceType: { in: ['stock_transfer_out', 'stock_transfer_in'] },
        sourceId: transferId,
      },
      include: { lines: true },
    });
    expect(replayed).toHaveLength(2);
    expect(replayed.every((entry) => entry.periodYm === periodYm)).toBe(true);
    expect(
      replayed
        .flatMap((entry) => entry.lines)
        .filter((l) => l.accountCode === '156')
        .reduce((sum, line) => sum + line.debitVnd, 0),
    ).toBe(7000);
  });

  it('accepts receive without posting when source stock has no cost', async () => {
    await prisma.productStoreStock.update({
      where: { productId_storeId: { productId, storeId: storeCh1 } },
      data: { avgCostVnd: 0 },
    });
    const transferId = randomUUID();

    await pushTransfer({
      transferId,
      lineId: randomUUID(),
      qty: '1',
    });

    await expect(
      prisma.journalEntry.count({
        where: {
          sourceType: { in: ['stock_transfer_out', 'stock_transfer_in'] },
          sourceId: transferId,
        },
      }),
    ).resolves.toBe(0);
  });
});
