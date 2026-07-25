import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Phase 3 VAT journals e2e', () => {
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
    await prisma.store.update({
      where: { id: storeId },
      data: { vatEnabled: false, defaultVatRateBps: 1000 },
    });
    await app.close();
  });

  async function resetStoreDocs() {
    await prisma.journalLine.deleteMany();
    await prisma.journalEntry.deleteMany();
    await prisma.auditLog.deleteMany();
    await prisma.periodLock.deleteMany();
    await prisma.eInvoice.deleteMany({ where: { sale: { storeId } } });
    await prisma.saleReturnLine.deleteMany({
      where: { saleReturn: { storeId } },
    });
    await prisma.saleReturn.deleteMany({ where: { storeId } });
    await prisma.saleLine.deleteMany({ where: { sale: { storeId } } });
    await prisma.sale.deleteMany({ where: { storeId } });
    await prisma.supplierPayable.deleteMany({ where: { storeId } });
    await prisma.purchaseReceiptLine.deleteMany({
      where: { receipt: { storeId } },
    });
    await prisma.purchaseReceipt.deleteMany({ where: { storeId } });
    await prisma.shift.updateMany({
      where: { storeId, closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
    });
  }

  it('VAT on: sale 110k@10% → Cr 511 100k + Cr 3331 10k', async () => {
    await resetStoreDocs();
    await prisma.store.update({
      where: { id: storeId },
      data: { vatEnabled: true, defaultVatRateBps: 1000 },
    });
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId } },
      create: {
        productId,
        storeId,
        qty: 50,
        minQty: 0,
        avgCostVnd: 80_000,
      },
      update: { qty: 50, avgCostVnd: 80_000 },
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
        deviceId: 'vat-1',
        sales: [
          {
            id: saleId,
            storeId,
            shiftId: shift.id,
            soldById: userId,
            paymentMethod: 'cash',
            cashAmount: 110_000,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 110_000,
            customerId: null,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                productId,
                qty: '1',
                unitPrice: 110_000,
                lineTotal: 110_000,
              },
            ],
          },
        ],
      })
      .expect(201);

    const entry = await prisma.journalEntry.findUnique({
      where: { sourceType_sourceId: { sourceType: 'sale', sourceId: saleId } },
      include: { lines: true },
    });
    expect(entry).toBeTruthy();
    expect(entry!.lines.find((l) => l.accountCode === '511')?.creditVnd).toBe(
      100_000,
    );
    expect(entry!.lines.find((l) => l.accountCode === '3331')?.creditVnd).toBe(
      10_000,
    );

    // idempotent
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'vat-1',
        sales: [
          {
            id: saleId,
            storeId,
            shiftId: shift.id,
            soldById: userId,
            paymentMethod: 'cash',
            cashAmount: 110_000,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 110_000,
            customerId: null,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                productId,
                qty: '1',
                unitPrice: 110_000,
                lineTotal: 110_000,
              },
            ],
          },
        ],
      })
      .expect(201);
    expect(
      await prisma.journalEntry.count({
        where: { sourceType: 'sale', sourceId: saleId },
      }),
    ).toBe(1);
  });

  it('VAT on: purchase splits inventory net + input VAT; WAC uses net', async () => {
    await resetStoreDocs();
    await prisma.store.update({
      where: { id: storeId },
      data: { vatEnabled: true, defaultVatRateBps: 1000 },
    });
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId } },
      create: {
        productId,
        storeId,
        qty: 0,
        minQty: 0,
        avgCostVnd: 0,
      },
      update: { qty: 0, avgCostVnd: 0 },
    });

    const receiptId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'vat-1',
        sales: [],
        purchaseReceipts: [
          {
            id: receiptId,
            storeId,
            supplierName: 'NCC VAT',
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                id: randomUUID(),
                productId,
                qty: '1',
                unitCostVnd: 110_000,
              },
            ],
          },
        ],
      })
      .expect(201);

    const entry = await prisma.journalEntry.findUnique({
      where: {
        sourceType_sourceId: {
          sourceType: 'purchase_receipt',
          sourceId: receiptId,
        },
      },
      include: { lines: true },
    });
    expect(entry).toBeTruthy();
    expect(entry!.lines.find((l) => l.accountCode === '156')?.debitVnd).toBe(
      100_000,
    );
    expect(entry!.lines.find((l) => l.accountCode === '1331')?.debitVnd).toBe(
      10_000,
    );
    expect(entry!.lines.find((l) => l.accountCode === '331')?.creditVnd).toBe(
      110_000,
    );

    const stock = await prisma.productStoreStock.findUnique({
      where: { productId_storeId: { productId, storeId } },
    });
    expect(stock?.avgCostVnd).toBe(100_000);
  });

  it('VAT off: sale keeps legacy Cr 511 = gross', async () => {
    await resetStoreDocs();
    await prisma.store.update({
      where: { id: storeId },
      data: { vatEnabled: false, defaultVatRateBps: 1000 },
    });
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId } },
      create: {
        productId,
        storeId,
        qty: 50,
        minQty: 0,
        avgCostVnd: 9_000,
      },
      update: { qty: 50, avgCostVnd: 9_000 },
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
        deviceId: 'vat-1',
        sales: [
          {
            id: saleId,
            storeId,
            shiftId: shift.id,
            soldById: userId,
            paymentMethod: 'cash',
            cashAmount: 10_000,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 10_000,
            customerId: null,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                productId,
                qty: '1',
                unitPrice: 10_000,
                lineTotal: 10_000,
              },
            ],
          },
        ],
      })
      .expect(201);

    const entry = await prisma.journalEntry.findUnique({
      where: { sourceType_sourceId: { sourceType: 'sale', sourceId: saleId } },
      include: { lines: true },
    });
    expect(entry!.lines.find((l) => l.accountCode === '511')?.creditVnd).toBe(
      10_000,
    );
    expect(entry!.lines.find((l) => l.accountCode === '3331')).toBeUndefined();
  });
});
