import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcrypt';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

const MANAGER_PHONE = '0900000031';

describe('Phase 3 hardening A1 accounting e2e', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let ownerToken: string;
  let managerToken: string;
  let ownerId: string;
  let store1: string;
  let store2: string;
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
    ownerToken = login.body.accessToken;
    ownerId = login.body.user.id;
    store1 = (await prisma.store.findFirst({ where: { code: 'CH1' } }))!.id;
    store2 = (await prisma.store.findFirst({ where: { code: 'CH2' } }))!.id;
    productId = (
      await prisma.product.findUnique({ where: { sku: 'STING-330' } })
    )!.id;

    // Manager scoped to CH2 only
    const passwordHash = await bcrypt.hash('123456', 10);
    const manager = await prisma.user.upsert({
      where: { phone: MANAGER_PHONE },
      update: { active: true, role: 'store_manager' },
      create: {
        phone: MANAGER_PHONE,
        name: 'QL CH2',
        passwordHash,
        role: 'store_manager',
      },
    });
    await prisma.userStore.upsert({
      where: { userId_storeId: { userId: manager.id, storeId: store2 } },
      update: {},
      create: { userId: manager.id, storeId: store2 },
    });
    await prisma.userStore.deleteMany({
      where: { userId: manager.id, storeId: { not: store2 } },
    });
    const mLogin = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: MANAGER_PHONE, password: '123456' })
      .expect(201);
    managerToken = mLogin.body.accessToken;

    const ict = new Date(Date.now() + 7 * 3600_000);
    periodYm = `${ict.getUTCFullYear()}-${String(ict.getUTCMonth() + 1).padStart(2, '0')}`;
  });

  afterAll(async () => {
    await prisma.store.updateMany({
      data: { vatEnabled: false, defaultVatRateBps: 1000 },
    });
    await prisma.product.updateMany({
      where: { sku: { in: ['STING-330', 'VAT8-HARD'] } },
      data: { vatRateBps: null },
    });
    await app.close();
  });

  async function openShift(storeId: string) {
    await prisma.shift.updateMany({
      where: { storeId, closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
    });
    return prisma.shift.create({
      data: {
        id: randomUUID(),
        storeId,
        userId: ownerId,
        openedAt: new Date(),
        openingCash: 0,
      },
    });
  }

  async function resetJournalsAndDocs() {
    await prisma.journalLine.deleteMany();
    await prisma.journalEntry.deleteMany();
    await prisma.periodLock.deleteMany();
    await prisma.eInvoice.deleteMany();
    await prisma.saleReturnLine.deleteMany();
    await prisma.saleReturn.deleteMany();
    await prisma.debtLedgerEntry.deleteMany();
    await prisma.saleLine.deleteMany();
    await prisma.sale.deleteMany();
  }

  async function stockUp(storeId: string, pid: string, avgCostVnd: number) {
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId: pid, storeId } },
      create: { productId: pid, storeId, qty: 50, minQty: 0, avgCostVnd },
      update: { qty: 50, avgCostVnd },
    });
  }

  function pushSale(input: {
    token: string;
    deviceId: string;
    storeId: string;
    shiftId: string;
    lines: { productId: string; qty: string; unitPrice: number; lineTotal: number }[];
    discountVnd?: number;
  }) {
    const linesTotal = input.lines.reduce((s, l) => s + l.lineTotal, 0);
    const discount = input.discountVnd ?? 0;
    const saleId = randomUUID();
    return request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${input.token}`)
      .send({
        deviceId: input.deviceId,
        sales: [
          {
            id: saleId,
            storeId: input.storeId,
            shiftId: input.shiftId,
            paymentMethod: 'cash',
            cashAmount: linesTotal - discount,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: discount,
            totalVnd: linesTotal - discount,
            clientCreatedAt: new Date().toISOString(),
            lines: input.lines,
          },
        ],
      })
      .expect(201)
      .then(() => saleId);
  }

  it('multi-store isolation: storeId scoping, manager limited to own stores', async () => {
    await resetJournalsAndDocs();
    await prisma.store.updateMany({
      data: { vatEnabled: true, defaultVatRateBps: 1000 },
    });
    await prisma.product.update({
      where: { id: productId },
      data: { vatRateBps: null },
    });
    await stockUp(store1, productId, 80_000);
    await stockUp(store2, productId, 80_000);

    const shift1 = await openShift(store1);
    const shift2 = await openShift(store2);
    await pushSale({
      token: ownerToken,
      deviceId: 'a1-iso-1',
      storeId: store1,
      shiftId: shift1.id,
      lines: [
        { productId, qty: '1', unitPrice: 110_000, lineTotal: 110_000 },
      ],
    });
    await pushSale({
      token: ownerToken,
      deviceId: 'a1-iso-2',
      storeId: store2,
      shiftId: shift2.id,
      lines: [
        { productId, qty: '2', unitPrice: 110_000, lineTotal: 220_000 },
      ],
    });

    const vat1 = await request(app.getHttpServer())
      .get('/reports/period/vat')
      .query({ periodYm, storeId: store1 })
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    expect(vat1.body.scope).toBe('store');
    expect(vat1.body.outputVatVnd).toBe(10_000);
    expect(vat1.body.revenueBaseVnd).toBe(100_000);

    const vat2 = await request(app.getHttpServer())
      .get('/reports/period/vat')
      .query({ periodYm, storeId: store2 })
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    expect(vat2.body.outputVatVnd).toBe(20_000);

    const agg = await request(app.getHttpServer())
      .get('/reports/period/vat')
      .query({ periodYm })
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    expect(agg.body.scope).toBe('aggregate');
    expect(agg.body.outputVatVnd).toBe(30_000);

    const tb = await request(app.getHttpServer())
      .get('/reports/period/trial-balance')
      .query({ periodYm, storeId: store1 })
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    expect(tb.body.scope).toBe('store');
    expect(tb.body.storeId).toBe(store1);
    expect(tb.body.storeIds).toEqual([store1]);

    const tbAgg = await request(app.getHttpServer())
      .get('/reports/period/trial-balance')
      .query({ periodYm })
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    expect(tbAgg.body.scope).toBe('aggregate');
    expect(tbAgg.body.storeIds).toEqual(
      expect.arrayContaining([store1, store2]),
    );

    // Manager (CH2 only): aggregate = their stores only
    const mVat = await request(app.getHttpServer())
      .get('/reports/period/vat')
      .query({ periodYm })
      .set('Authorization', `Bearer ${managerToken}`)
      .expect(200);
    expect(mVat.body.outputVatVnd).toBe(20_000);

    const mTb = await request(app.getHttpServer())
      .get('/reports/period/trial-balance')
      .query({ periodYm })
      .set('Authorization', `Bearer ${managerToken}`)
      .expect(200);
    expect(mTb.body.storeIds).toEqual([store2]);

    // Manager may not read another store's period reports
    await request(app.getHttpServer())
      .get('/reports/period/vat')
      .query({ periodYm, storeId: store1 })
      .set('Authorization', `Bearer ${managerToken}`)
      .expect(403);
    await request(app.getHttpServer())
      .get('/reports/period/export.csv')
      .query({ periodYm, storeId: store1 })
      .set('Authorization', `Bearer ${managerToken}`)
      .expect(403);
  });

  it('sale return reverses VAT (net summary) and snapshots return lines', async () => {
    await resetJournalsAndDocs();
    await prisma.store.update({
      where: { id: store1 },
      data: { vatEnabled: true, defaultVatRateBps: 1000 },
    });
    await stockUp(store1, productId, 80_000);
    const shift = await openShift(store1);
    const saleId = await pushSale({
      token: ownerToken,
      deviceId: 'a1-ret-1',
      storeId: store1,
      shiftId: shift.id,
      lines: [
        { productId, qty: '1', unitPrice: 110_000, lineTotal: 110_000 },
      ],
    });

    const returnId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        deviceId: 'a1-ret-1',
        sales: [],
        saleReturns: [
          {
            id: returnId,
            storeId: store1,
            originalSaleId: saleId,
            shiftId: shift.id,
            cashRefundVnd: 110_000,
            transferRefundVnd: 0,
            debtCreditVnd: 0,
            totalRefundVnd: 110_000,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                id: randomUUID(),
                productId,
                qty: '1',
                unitPrice: 110_000,
                lineRefundVnd: 110_000,
              },
            ],
          },
        ],
      })
      .expect(201);

    // Return line carries tax snapshot
    const retLines = await prisma.saleReturnLine.findMany({
      where: { returnId },
    });
    expect(retLines).toHaveLength(1);
    expect(retLines[0].vatRateBps).toBe(1000);
    expect(retLines[0].netVnd).toBe(100_000);
    expect(retLines[0].vatVnd).toBe(10_000);

    // Journal reverses 511 net + 3331 VAT
    const entry = await prisma.journalEntry.findUnique({
      where: {
        sourceType_sourceId: {
          sourceType: 'sale_return',
          sourceId: returnId,
        },
      },
      include: { lines: true },
    });
    expect(entry).toBeTruthy();
    expect(entry!.lines.find((l) => l.accountCode === '511')?.debitVnd).toBe(
      100_000,
    );
    expect(entry!.lines.find((l) => l.accountCode === '3331')?.debitVnd).toBe(
      10_000,
    );

    // Period VAT summary is net movement → zero after full return
    const vat = await request(app.getHttpServer())
      .get('/reports/period/vat')
      .query({ periodYm, storeId: store1 })
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    expect(vat.body.outputVatVnd).toBe(0);
    expect(vat.body.revenueBaseVnd).toBe(0);
  });

  it('mixed product VAT rates with discount allocation snapshot at sale time', async () => {
    await resetJournalsAndDocs();
    await prisma.store.update({
      where: { id: store1 },
      data: { vatEnabled: true, defaultVatRateBps: 1000 },
    });
    await prisma.product.update({
      where: { id: productId },
      data: { vatRateBps: null }, // falls back to store 10%
    });
    const p8 = await prisma.product.upsert({
      where: { sku: 'VAT8-HARD' },
      create: {
        id: randomUUID(),
        sku: 'VAT8-HARD',
        name: 'Hang VAT 8%',
        unit: 'hop',
        basePriceVnd: 108_000,
        costVnd: 70_000,
        vatRateBps: 800,
      },
      update: { vatRateBps: 800, basePriceVnd: 108_000 },
    });
    await stockUp(store1, productId, 80_000);
    await stockUp(store1, p8.id, 70_000);
    const shift = await openShift(store1);

    // 110k@10% + 108k@8% with 18k discount → paid 200k.
    // Allocation: 100917 + 99083; splits 91743/9174 + 91744/7339.
    const saleId = await pushSale({
      token: ownerToken,
      deviceId: 'a1-mixed-1',
      storeId: store1,
      shiftId: shift.id,
      discountVnd: 18_000,
      lines: [
        { productId, qty: '1', unitPrice: 110_000, lineTotal: 110_000 },
        {
          productId: p8.id,
          qty: '1',
          unitPrice: 108_000,
          lineTotal: 108_000,
        },
      ],
    });

    const entry = await prisma.journalEntry.findUnique({
      where: { sourceType_sourceId: { sourceType: 'sale', sourceId: saleId } },
      include: { lines: true },
    });
    expect(entry).toBeTruthy();
    expect(entry!.lines.find((l) => l.accountCode === '511')?.creditVnd).toBe(
      183_487,
    );
    expect(entry!.lines.find((l) => l.accountCode === '3331')?.creditVnd).toBe(
      16_513,
    );

    // Snapshots persisted on sale lines at create time
    const saleLines = await prisma.saleLine.findMany({
      where: { saleId },
      orderBy: { lineTotal: 'desc' },
    });
    expect(saleLines).toHaveLength(2);
    const netSum = saleLines.reduce((s, l) => s + (l.netVnd ?? 0), 0);
    const vatSum = saleLines.reduce((s, l) => s + (l.vatVnd ?? 0), 0);
    expect(netSum).toBe(183_487);
    expect(vatSum).toBe(16_513);
    const rates = saleLines.map((l) => l.vatRateBps).sort();
    expect(rates).toEqual([800, 1000].sort());
  });
});
