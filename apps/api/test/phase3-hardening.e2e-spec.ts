import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import { createServer, IncomingMessage, Server, ServerResponse } from 'http';
import { AddressInfo } from 'net';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Phase 3 hardening e2e', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;
  let userId: string;
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
    token = login.body.accessToken;
    userId = login.body.user.id;
    store1 = (await prisma.store.findFirst({ where: { code: 'CH1' } }))!.id;
    store2 = (await prisma.store.findFirst({ where: { code: 'CH2' } }))!.id;
    productId = (
      await prisma.product.findUnique({ where: { sku: 'STING-330' } })
    )!.id;
    const now = new Date();
    const ict = new Date(now.getTime() + 7 * 3600_000);
    periodYm = `${ict.getUTCFullYear()}-${String(ict.getUTCMonth() + 1).padStart(2, '0')}`;
  });

  afterAll(async () => {
    await prisma.eInvoice.deleteMany();
    await prisma.store.updateMany({
      data: { vatEnabled: false, defaultVatRateBps: 1000 },
    });
    await prisma.product.update({
      where: { id: productId },
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
        userId,
        openedAt: new Date(),
        openingCash: 0,
      },
    });
  }

  it('period VAT/TB scoped by storeId', async () => {
    await prisma.journalLine.deleteMany();
    await prisma.journalEntry.deleteMany();
    await prisma.periodLock.deleteMany({ where: { periodYm } });
    await prisma.store.updateMany({
      data: { vatEnabled: true, defaultVatRateBps: 1000 },
    });
    for (const storeId of [store1, store2]) {
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
      const shift = await openShift(storeId);
      await request(app.getHttpServer())
        .post('/sync/push')
        .set('Authorization', `Bearer ${token}`)
        .send({
          deviceId: `hard-scope-${storeId.slice(0, 8)}`,
          sales: [
            {
              id: randomUUID(),
              storeId,
              shiftId: shift.id,
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
        })
        .expect(201);
    }

    const s1 = await request(app.getHttpServer())
      .get('/reports/period/vat')
      .query({ periodYm, storeId: store1 })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(s1.body.scope).toBe('store');
    expect(s1.body.outputVatVnd).toBe(10_000);

    const agg = await request(app.getHttpServer())
      .get('/reports/period/vat')
      .query({ periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(agg.body.scope).toBe('aggregate');
    expect(agg.body.outputVatVnd).toBe(20_000);
  });

  it('VAT summary nets sale return (Cr3331 - Dr3331)', async () => {
    await prisma.journalLine.deleteMany();
    await prisma.journalEntry.deleteMany();
    await prisma.periodLock.deleteMany({ where: { periodYm } });
    await prisma.saleReturnLine.deleteMany();
    await prisma.saleReturn.deleteMany({ where: { storeId: store1 } });
    await prisma.saleLine.deleteMany({ where: { sale: { storeId: store1 } } });
    await prisma.sale.deleteMany({ where: { storeId: store1 } });
    await prisma.store.update({
      where: { id: store1 },
      data: { vatEnabled: true, defaultVatRateBps: 1000 },
    });
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId: store1 } },
      create: {
        productId,
        storeId: store1,
        qty: 20,
        minQty: 0,
        avgCostVnd: 80_000,
      },
      update: { qty: 20, avgCostVnd: 80_000 },
    });
    const shift = await openShift(store1);
    const saleId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'hard-vat-net',
        sales: [
          {
            id: saleId,
            storeId: store1,
            shiftId: shift.id,
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
        saleReturns: [
          {
            id: randomUUID(),
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

    const vat = await request(app.getHttpServer())
      .get('/reports/period/vat')
      .query({ periodYm, storeId: store1 })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(vat.body.outputVatVnd).toBe(0);
    expect(vat.body.revenueBaseVnd).toBe(0);
  });

  it('mixed product vatRateBps on sale journal', async () => {
    await prisma.journalLine.deleteMany();
    await prisma.journalEntry.deleteMany();
    await prisma.periodLock.deleteMany({ where: { periodYm } });
    const p5 = await prisma.product.upsert({
      where: { sku: 'VAT5-ITEM' },
      create: {
        id: randomUUID(),
        sku: 'VAT5-ITEM',
        name: 'VAT 5%',
        unit: 'lon',
        basePriceVnd: 105_000,
        costVnd: 70_000,
        vatRateBps: 500,
      },
      update: { vatRateBps: 500, basePriceVnd: 105_000 },
    });
    await prisma.product.update({
      where: { id: productId },
      data: { vatRateBps: 1000 },
    });
    await prisma.store.update({
      where: { id: store1 },
      data: { vatEnabled: true, defaultVatRateBps: 1000 },
    });
    for (const pid of [productId, p5.id]) {
      await prisma.productStoreStock.upsert({
        where: { productId_storeId: { productId: pid, storeId: store1 } },
        create: {
          productId: pid,
          storeId: store1,
          qty: 10,
          minQty: 0,
          avgCostVnd: 50_000,
        },
        update: { qty: 10, avgCostVnd: 50_000 },
      });
    }
    const shift = await openShift(store1);
    const saleId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'hard-mixed-vat',
        sales: [
          {
            id: saleId,
            storeId: store1,
            shiftId: shift.id,
            paymentMethod: 'cash',
            cashAmount: 215_000,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 215_000,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                productId,
                qty: '1',
                unitPrice: 110_000,
                lineTotal: 110_000,
              },
              {
                productId: p5.id,
                qty: '1',
                unitPrice: 105_000,
                lineTotal: 105_000,
              },
            ],
          },
        ],
      })
      .expect(201);

    const entry = await prisma.journalEntry.findUnique({
      where: {
        sourceType_sourceId: { sourceType: 'sale', sourceId: saleId },
      },
      include: { lines: true },
    });
    expect(entry!.lines.find((l) => l.accountCode === '3331')?.creditVnd).toBe(
      15_000,
    );
    expect(entry!.lines.find((l) => l.accountCode === '511')?.creditVnd).toBe(
      200_000,
    );
    const snaps = await prisma.saleLine.findMany({ where: { saleId } });
    expect(snaps.every((l) => l.vatRateBps != null && l.netVnd != null)).toBe(
      true,
    );
  });

  it('supplier return requires receipt and blocks over-AP', async () => {
    await prisma.supplierReturnLine.deleteMany();
    await prisma.supplierReturn.deleteMany({ where: { storeId: store1 } });
    await prisma.supplierPayable.deleteMany({ where: { storeId: store1 } });
    await prisma.purchaseReceiptLine.deleteMany({
      where: { receipt: { storeId: store1 } },
    });
    await prisma.purchaseReceipt.deleteMany({ where: { storeId: store1 } });
    await prisma.store.update({
      where: { id: store1 },
      data: { vatEnabled: true, defaultVatRateBps: 1000 },
    });
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId: store1 } },
      create: {
        productId,
        storeId: store1,
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
        deviceId: 'hard-sup-ret',
        sales: [],
        purchaseReceipts: [
          {
            id: receiptId,
            storeId: store1,
            supplierName: 'NCC Hard',
            clientCreatedAt: new Date().toISOString(),
            lines: [
              { id: randomUUID(), productId, qty: '2', unitCostVnd: 11_000 },
            ],
          },
        ],
      })
      .expect(201);
    const payable = await prisma.supplierPayable.findFirst({
      where: { purchaseReceiptId: receiptId },
    });
    const supplierId = payable!.supplierId;

    await request(app.getHttpServer())
      .post(`/suppliers/${supplierId}/returns`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        storeId: store1,
        lines: [{ productId, qty: '1', unitCostVnd: 11_000 }],
      })
      .expect(400);

    await request(app.getHttpServer())
      .post(`/suppliers/${supplierId}/returns`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        storeId: store1,
        purchaseReceiptId: receiptId,
        lines: [{ productId, qty: '3', unitCostVnd: 11_000 }],
      })
      .expect(400);

    const clientId = randomUUID();
    const ok = await request(app.getHttpServer())
      .post(`/suppliers/${supplierId}/returns`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        storeId: store1,
        purchaseReceiptId: receiptId,
        clientId,
        lines: [{ productId, qty: '1', unitCostVnd: 11_000 }],
      })
      .expect(201);
    const again = await request(app.getHttpServer())
      .post(`/suppliers/${supplierId}/returns`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        storeId: store1,
        purchaseReceiptId: receiptId,
        clientId,
        lines: [{ productId, qty: '1', unitCostVnd: 11_000 }],
      })
      .expect(201);
    expect(again.body.id).toBe(ok.body.id);
    expect(again.body.idempotent).toBe(true);
  });

  it('bank recon import idempotent + GET read-only + lock rejects variance', async () => {
    await prisma.bankReconLock.deleteMany({
      where: { storeId: store1, periodYm },
    });
    await prisma.bankStatementLine.deleteMany({
      where: { storeId: store1, periodYm },
    });
    const day = `${periodYm}-10`;
    const csv = `date,amountVnd,memo\n${day},12345,"CK ""test"""`;
    const a = await request(app.getHttpServer())
      .post('/reports/bank-recon/import')
      .set('Authorization', `Bearer ${token}`)
      .send({ storeId: store1, periodYm, csv })
      .expect(201);
    expect(a.body.imported).toBe(1);
    const b = await request(app.getHttpServer())
      .post('/reports/bank-recon/import')
      .set('Authorization', `Bearer ${token}`)
      .send({ storeId: store1, periodYm, csv })
      .expect(201);
    expect(b.body.imported).toBe(0);
    expect(b.body.skippedDuplicates).toBe(1);

    const before = await prisma.bankStatementLine.findMany({
      where: { storeId: store1, periodYm },
    });
    await request(app.getHttpServer())
      .get('/reports/bank-recon')
      .query({ storeId: store1, periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    const after = await prisma.bankStatementLine.findMany({
      where: { storeId: store1, periodYm },
    });
    expect(after.every((l) => l.matchedRef == null)).toBe(true);
    expect(after.length).toBe(before.length);

    await request(app.getHttpServer())
      .post('/reports/bank-recon/lock')
      .set('Authorization', `Bearer ${token}`)
      .send({ storeId: store1, periodYm })
      .expect(400);
  });

  it('HTTP einvoice sends Idempotency-Key and rejects unknown status', async () => {
    let sawIdem: string | undefined;
    let mode: 'ok' | 'bad_status' = 'ok';
    const mock: Server = createServer(
      (req: IncomingMessage, res: ServerResponse) => {
        sawIdem = req.headers['idempotency-key'] as string | undefined;
        const chunks: Buffer[] = [];
        req.on('data', (c) => chunks.push(Buffer.from(c)));
        req.on('end', () => {
          res.writeHead(200, { 'content-type': 'application/json' });
          if (mode === 'bad_status') {
            res.end(
              JSON.stringify({
                providerRef: 'x',
                invoiceNumber: 'Y',
                status: 'weird',
              }),
            );
            return;
          }
          res.end(
            JSON.stringify({
              providerRef: 'mock-hard',
              invoiceNumber: 'HARD-1',
              status: 'issued',
              xmlPath: 'http://127.0.0.1/x.xml',
              pdfPath: 'http://127.0.0.1/x.pdf',
            }),
          );
        });
      },
    );
    await new Promise<void>((r) => mock.listen(0, '127.0.0.1', r));
    const port = (mock.address() as AddressInfo).port;
    const prevProvider = process.env.EINVOICE_PROVIDER;
    const prevUrl = process.env.EINVOICE_HTTP_URL;
    process.env.EINVOICE_PROVIDER = 'http';
    process.env.EINVOICE_HTTP_URL = `http://127.0.0.1:${port}/issue`;
    process.env.EINVOICE_HTTP_ALLOW_INSECURE = '1';

    // Reboot module so adapter picks env — use existing app adapter via env at issue time
    // Http adapter reads env per request; OK without reboot.
    await prisma.eInvoice.deleteMany();
    const shift = await openShift(store1);
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId: store1 } },
      create: {
        productId,
        storeId: store1,
        qty: 5,
        minQty: 0,
        avgCostVnd: 9000,
      },
      update: { qty: 5 },
    });
    const saleId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'hard-einvoice',
        sales: [
          {
            id: saleId,
            storeId: store1,
            shiftId: shift.id,
            paymentMethod: 'cash',
            cashAmount: 10_000,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 10_000,
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

    // App was created with stub adapter — recreate nest app with http provider
    await app.close();
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    prisma = moduleRef.get(PrismaService);
    await app.init();

    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: '0900000001', password: '123456' })
      .expect(201);
    token = login.body.accessToken;

    await request(app.getHttpServer())
      .post('/einvoices/issue')
      .set('Authorization', `Bearer ${token}`)
      .send({ saleId })
      .expect(201);
    expect(sawIdem).toBe(saleId);

    mode = 'bad_status';
    const sale2 = randomUUID();
    const shift2 = await openShift(store1);
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'hard-einvoice-2',
        sales: [
          {
            id: sale2,
            storeId: store1,
            shiftId: shift2.id,
            paymentMethod: 'cash',
            cashAmount: 10_000,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 10_000,
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
    await request(app.getHttpServer())
      .post('/einvoices/issue')
      .set('Authorization', `Bearer ${token}`)
      .send({ saleId: sale2 })
      .expect(400);

    await new Promise<void>((resolve, reject) =>
      mock.close((err) => (err ? reject(err) : resolve())),
    );
    if (prevProvider) process.env.EINVOICE_PROVIDER = prevProvider;
    else delete process.env.EINVOICE_PROVIDER;
    if (prevUrl) process.env.EINVOICE_HTTP_URL = prevUrl;
    else delete process.env.EINVOICE_HTTP_URL;
  });
});
