import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Phase 3 VAT summary e2e', () => {
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
    await prisma.store.update({
      where: { id: storeId },
      data: { vatEnabled: false, defaultVatRateBps: 1000 },
    });
    await app.close();
  });

  it('PATCH store vat + /reports/period/vat matches trial-balance lines', async () => {
    await prisma.journalLine.deleteMany();
    await prisma.journalEntry.deleteMany();
    await prisma.periodLock.deleteMany({ where: { periodYm } });
    await prisma.eInvoice.deleteMany({ where: { sale: { storeId } } });
    await prisma.supplierPayable.deleteMany({ where: { storeId } });
    await prisma.purchaseReceiptLine.deleteMany({
      where: { receipt: { storeId } },
    });
    await prisma.purchaseReceipt.deleteMany({ where: { storeId } });
    await prisma.saleLine.deleteMany({ where: { sale: { storeId } } });
    await prisma.saleReturnLine.deleteMany({
      where: { saleReturn: { storeId } },
    });
    await prisma.saleReturn.deleteMany({ where: { storeId } });
    await prisma.sale.deleteMany({ where: { storeId } });
    await prisma.shift.updateMany({
      where: { storeId, closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
    });

    const vatPatch = await request(app.getHttpServer())
      .patch(`/stores/${storeId}/vat`)
      .set('Authorization', `Bearer ${token}`)
      .send({ vatEnabled: true, defaultVatRateBps: 1000 })
      .expect(200);
    expect(vatPatch.body.vatEnabled).toBe(true);

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

    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'vat-sum-1',
        sales: [
          {
            id: randomUUID(),
            storeId,
            shiftId: shift.id,
            soldById: userId,
            paymentMethod: 'cash',
            cashAmount: 110_000,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 110_000,
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
        purchaseReceipts: [
          {
            id: randomUUID(),
            storeId,
            supplierName: 'NCC VAT sum',
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                id: randomUUID(),
                productId,
                qty: '1',
                unitCostVnd: 55_000,
              },
            ],
          },
        ],
      })
      .expect(201);

    const tb = await request(app.getHttpServer())
      .get('/ledger/trial-balance')
      .query({ periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    const cr3331 =
      tb.body.rows.find((r: { accountCode: string }) => r.accountCode === '3331')
        ?.creditVnd ?? 0;
    const dr1331 =
      tb.body.rows.find((r: { accountCode: string }) => r.accountCode === '1331')
        ?.debitVnd ?? 0;
    const cr511 =
      tb.body.rows.find((r: { accountCode: string }) => r.accountCode === '511')
        ?.creditVnd ?? 0;

    const vat = await request(app.getHttpServer())
      .get('/reports/period/vat')
      .query({ periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(vat.body.outputVatVnd).toBe(cr3331);
    expect(vat.body.inputVatVnd).toBe(dr1331);
    expect(vat.body.netVatVnd).toBe(cr3331 - dr1331);
    expect(vat.body.revenueBaseVnd).toBe(cr511);
    expect(vat.body.outputVatVnd).toBe(10_000);
    expect(vat.body.inputVatVnd).toBe(5_000);
    expect(vat.body.revenueBaseVnd).toBe(100_000);

    const xlsx = await request(app.getHttpServer())
      .get('/reports/period/export.xlsx')
      .query({ periodYm })
      .set('Authorization', `Bearer ${token}`)
      .buffer(true)
      .parse((res, cb) => {
        const chunks: Buffer[] = [];
        res.on('data', (c) => chunks.push(Buffer.from(c)));
        res.on('end', () => cb(null, Buffer.concat(chunks)));
      })
      .expect(200);
    const body = xlsx.body as Buffer;
    expect(body.subarray(0, 2).toString('utf8')).toBe('PK');

    const pdf = await request(app.getHttpServer())
      .get('/reports/period/export.pdf')
      .query({ periodYm })
      .set('Authorization', `Bearer ${token}`)
      .buffer(true)
      .parse((res, cb) => {
        const chunks: Buffer[] = [];
        res.on('data', (c) => chunks.push(Buffer.from(c)));
        res.on('end', () => cb(null, Buffer.concat(chunks)));
      })
      .expect(200);
    expect((pdf.body as Buffer).subarray(0, 4).toString('utf8')).toBe('%PDF');

    const decl = await request(app.getHttpServer())
      .get('/reports/period/vat-declaration.csv')
      .query({ periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(decl.body.csv).toContain('netVatVnd');
    expect(decl.body.csv).toContain('khong nop CQT');
  });
});
