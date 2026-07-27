import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcrypt';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

/** Raw-byte response parser for supertest/superagent (Node client has no
 * built-in parser for application/pdf, and we don't want to rely on its
 * generic application/xml handling) — same pattern as vat-summary.e2e-spec.ts
 * for `/reports/period/export.pdf`. */
function bufferParse(res: any, cb: (err: Error | null, body?: Buffer) => void) {
  const chunks: Buffer[] = [];
  res.on('data', (c: Buffer) => chunks.push(Buffer.from(c)));
  res.on('end', () => cb(null, Buffer.concat(chunks)));
}

describe('Phase 2 e-invoice e2e', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;
  let userId: string;
  let storeId: string;
  let store2Id: string;
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
    store2Id = (await prisma.store.findFirst({ where: { code: 'CH2' } }))!.id;
    productId = (await prisma.product.findUnique({ where: { sku: 'STING-330' } }))!
      .id;
  });

  afterAll(async () => {
    await app.close();
  });

  /** P2.4 — store_manager scoped to CH2 only, with canEinvoice — used to
   * prove the download endpoint's `assertStoreAccess` check (not just the
   * controller guard) blocks cross-store access. */
  async function loginOtherStoreEinvoiceManager(): Promise<string> {
    const phone = `0950${randomUUID().replace(/\D/g, '').slice(0, 6)}`;
    const passwordHash = await bcrypt.hash('123456', 10);
    const user = await prisma.user.create({
      data: {
        id: randomUUID(),
        phone,
        name: 'QL HĐĐT CH2',
        role: 'store_manager',
        passwordHash,
        active: true,
        canLedger: false,
        canEinvoice: true,
        stores: { create: [{ storeId: store2Id }] },
      },
    });
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: user.phone, password: '123456' })
      .expect(201);
    return res.body.accessToken as string;
  }

  async function createSyncedSale(
    deviceId: string,
    opts: { customerId?: string | null; totalVnd?: number } = {},
  ) {
    const totalVnd = opts.totalVnd ?? 15000;
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
        deviceId,
        sales: [
          {
            id: saleId,
            storeId,
            shiftId: shift.id,
            paymentMethod: 'cash',
            cashAmount: totalVnd,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd,
            customerId: opts.customerId ?? null,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                id: randomUUID(),
                productId,
                qty: '1',
                unitPrice: totalVnd,
                lineTotal: totalVnd,
              },
            ],
          },
        ],
      })
      .expect(201);
    return saleId;
  }

  it('rejects missing sale; issues stub for synced sale', async () => {
    await request(app.getHttpServer())
      .post('/einvoices/issue')
      .set('Authorization', `Bearer ${token}`)
      .send({ saleId: randomUUID() })
      .expect(404);

    await prisma.eInvoice.deleteMany();
    const saleId = await createSyncedSale('e2e-einvoice');

    const issued = await request(app.getHttpServer())
      .post('/einvoices/issue')
      .set('Authorization', `Bearer ${token}`)
      .send({
        saleId,
        buyerTaxCode: '0123456789',
        templateCode: '1',
        serial: 'C25TAA',
      })
      .expect(201);

    expect(issued.body.status).toBe('issued');
    expect(issued.body.provider).toBe('stub');
    expect(issued.body.invoiceNumber).toMatch(/^STUB-/);
  });

  it('cancels issued stub invoice idempotently and blocks re-issue', async () => {
    await prisma.eInvoice.deleteMany();
    const saleId = await createSyncedSale('e2e-einvoice-cancel');

    const issued = await request(app.getHttpServer())
      .post('/einvoices/issue')
      .set('Authorization', `Bearer ${token}`)
      .send({ saleId })
      .expect(201);

    const cancelled = await request(app.getHttpServer())
      .post(`/einvoices/${issued.body.id}/cancel`)
      .set('Authorization', `Bearer ${token}`)
      .send({ reason: 'Khach huy don' })
      .expect(201);

    expect(cancelled.body.status).toBe('cancelled');

    const repeated = await request(app.getHttpServer())
      .post(`/einvoices/${issued.body.id}/cancel`)
      .set('Authorization', `Bearer ${token}`)
      .send({ reason: 'Khach huy don' })
      .expect(201);
    expect(repeated.body.status).toBe('cancelled');

    await request(app.getHttpServer())
      .post('/einvoices/issue')
      .set('Authorization', `Bearer ${token}`)
      .send({ saleId })
      .expect(400);
  });

  it('rejects cancel from non-cancellable status', async () => {
    await prisma.eInvoice.deleteMany();
    const saleId = await createSyncedSale('e2e-einvoice-cancel-invalid');
    const invoice = await prisma.eInvoice.create({
      data: {
        id: randomUUID(),
        saleId,
        status: 'failed',
        provider: 'stub',
      },
    });

    await request(app.getHttpServer())
      .post(`/einvoices/${invoice.id}/cancel`)
      .set('Authorization', `Bearer ${token}`)
      .send({ reason: 'Khach huy don' })
      .expect(400);
  });

  it('issues a customer batch and creates an adjustment invoice', async () => {
    await prisma.eInvoice.deleteMany();
    const customer = await prisma.customer.create({
      data: {
        id: randomUUID(),
        storeId,
        name: 'Khach gop HD',
      },
    });
    const saleA = await createSyncedSale('e2e-einvoice-batch-a', {
      customerId: customer.id,
      totalVnd: 12000,
    });
    const saleB = await createSyncedSale('e2e-einvoice-batch-b', {
      customerId: customer.id,
      totalVnd: 18000,
    });

    const issued = await request(app.getHttpServer())
      .post('/einvoices/issue-batch')
      .set('Authorization', `Bearer ${token}`)
      .send({
        customerId: customer.id,
        saleIds: [saleA, saleB],
        buyerTaxCode: '0123456789',
      })
      .expect(201);

    expect(issued.body.status).toBe('issued');
    expect(issued.body.invoiceNumber).toMatch(/^STUB-BATCH-/);
    expect(issued.body.saleIds).toEqual(expect.arrayContaining([saleA, saleB]));
    const links = await prisma.eInvoiceSale.findMany({
      where: { invoiceId: issued.body.id },
    });
    expect(links).toHaveLength(2);

    const bySecondSale = await request(app.getHttpServer())
      .get(`/einvoices/by-sale/${saleB}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(bySecondSale.body.id).toBe(issued.body.id);

    const repeated = await request(app.getHttpServer())
      .post('/einvoices/issue')
      .set('Authorization', `Bearer ${token}`)
      .send({ saleId: saleB })
      .expect(201);
    expect(repeated.body.id).toBe(issued.body.id);

    const repeatedBatch = await request(app.getHttpServer())
      .post('/einvoices/issue-batch')
      .set('Authorization', `Bearer ${token}`)
      .send({ customerId: customer.id, saleIds: [saleA, saleB] })
      .expect(201);
    expect(repeatedBatch.body.id).toBe(issued.body.id);
    expect(repeatedBatch.body.saleIds).toEqual(
      expect.arrayContaining([saleA, saleB]),
    );

    const adjusted = await request(app.getHttpServer())
      .post(`/einvoices/${issued.body.id}/adjust`)
      .set('Authorization', `Bearer ${token}`)
      .send({ reason: 'Dieu chinh thong tin khach hang' })
      .expect(201);

    expect(adjusted.body.status).toBe('issued');
    expect(adjusted.body.invoiceNumber).toMatch(/^STUB-ADJ-/);
    expect(adjusted.body.adjustmentForId).toBe(issued.body.id);
    expect(adjusted.body.adjustmentReason).toBe(
      'Dieu chinh thong tin khach hang',
    );

    const original = await prisma.eInvoice.findUnique({
      where: { id: issued.body.id },
    });
    expect(original?.status).toBe('adjusted');

    const latestBySale = await request(app.getHttpServer())
      .get(`/einvoices/by-sale/${saleA}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(latestBySale.body.id).toBe(adjusted.body.id);
  });

  it('prevents concurrent issue and batch from claiming the same sale twice', async () => {
    await prisma.eInvoice.deleteMany();
    const customer = await prisma.customer.create({
      data: {
        id: randomUUID(),
        storeId,
        name: 'Khach race HD',
      },
    });
    const saleId = await createSyncedSale('e2e-einvoice-race', {
      customerId: customer.id,
      totalVnd: 14000,
    });

    const responses = await Promise.all([
      request(app.getHttpServer())
        .post('/einvoices/issue')
        .set('Authorization', `Bearer ${token}`)
        .send({ saleId }),
      request(app.getHttpServer())
        .post('/einvoices/issue-batch')
        .set('Authorization', `Bearer ${token}`)
        .send({ customerId: customer.id, saleIds: [saleId] }),
    ]);

    expect(responses.some((response) => response.status === 201)).toBe(true);
    expect(responses.every((response) => [201, 400].includes(response.status))).toBe(
      true,
    );
    await expect(
      prisma.eInvoiceSale.count({
        where: { saleId, isAdjustment: false, claimActive: true },
      }),
    ).resolves.toBe(1);
    const invoices = await prisma.eInvoice.findMany({
      where: {
        adjustmentForId: null,
        saleLinks: {
          some: { saleId, isAdjustment: false, claimActive: true },
        },
      },
    });
    expect(invoices).toHaveLength(1);
  });

  // P2.4 — stub adapter now produces real PDF/XML bytes (not the old fake
  // `stub://...` strings), downloadable via new endpoints, plus an audit
  // trail for issue/cancel/adjust that must actually surface through
  // GET /ledger/audit (LedgerService.defaultAuditActions allowlist gotcha).
  describe('P2.4 — stub PDF/XML download + lifecycle audit', () => {
    it('issue produces real downloadable PDF/XML bytes; blocks cross-store download; audit visible via GET /ledger/audit', async () => {
      await prisma.eInvoice.deleteMany();
      const saleId = await createSyncedSale('e2e-einvoice-download');

      const issued = await request(app.getHttpServer())
        .post('/einvoices/issue')
        .set('Authorization', `Bearer ${token}`)
        .send({ saleId, buyerTaxCode: '0123456789' })
        .expect(201);

      // No more fake `stub://` strings on the invoice row.
      expect(issued.body.xmlPath).toBeFalsy();
      expect(issued.body.pdfPath).toBeFalsy();

      const pdfRes = await request(app.getHttpServer())
        .get(`/einvoices/${issued.body.id}/pdf`)
        .set('Authorization', `Bearer ${token}`)
        .buffer(true)
        .parse(bufferParse)
        .expect(200);
      expect(pdfRes.headers['content-type']).toContain('application/pdf');
      const pdfBuf = pdfRes.body as Buffer;
      expect(pdfBuf.subarray(0, 4).toString('latin1')).toBe('%PDF');

      const xmlRes = await request(app.getHttpServer())
        .get(`/einvoices/${issued.body.id}/xml`)
        .set('Authorization', `Bearer ${token}`)
        .buffer(true)
        .parse(bufferParse)
        .expect(200);
      expect(xmlRes.headers['content-type']).toContain('application/xml');
      const xmlText = (xmlRes.body as Buffer).toString('utf8');
      expect(xmlText).toContain('<Invoice>');
      expect(xmlText).toContain(`<Number>${issued.body.invoiceNumber}</Number>`);
      expect(xmlText).toContain('<TotalVnd>15000</TotalVnd>');

      // Cross-store manager (CH2) must be blocked from downloading a CH1 invoice.
      const otherStoreToken = await loginOtherStoreEinvoiceManager();
      await request(app.getHttpServer())
        .get(`/einvoices/${issued.body.id}/pdf`)
        .set('Authorization', `Bearer ${otherStoreToken}`)
        .expect(403);

      // Audit row exists with the expected shape...
      const auditRow = await prisma.auditLog.findFirst({
        where: { action: 'einvoice_issue', entityId: issued.body.id },
      });
      expect(auditRow).toMatchObject({
        actorUserId: userId,
        entityType: 'einvoice',
      });
      const detail = JSON.parse(auditRow!.detailJson!);
      expect(detail).toMatchObject({
        storeId,
        invoiceNumber: issued.body.invoiceNumber,
        provider: 'stub',
        saleIds: [saleId],
      });
      expect(auditRow!.detailJson).not.toMatch(/buyerTaxCode/i);
      expect(auditRow!.detailJson).not.toContain('0123456789');

      // ...and — the P1.7 gotcha — actually surfaces via GET /ledger/audit
      // (defaultAuditActions allowlist), not just written silently to the DB.
      const auditApi = await request(app.getHttpServer())
        .get('/ledger/audit')
        .query({ entityType: 'einvoice', entityId: issued.body.id })
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      expect(
        auditApi.body.some(
          (row: { action: string; entityId: string }) =>
            row.action === 'einvoice_issue' && row.entityId === issued.body.id,
        ),
      ).toBe(true);
    });

    it('cancel and adjust write einvoice_cancel/einvoice_adjust audit rows visible via GET /ledger/audit; adjustment has its own downloadable content', async () => {
      await prisma.eInvoice.deleteMany();
      const saleId = await createSyncedSale('e2e-einvoice-audit-cancel');
      const issued = await request(app.getHttpServer())
        .post('/einvoices/issue')
        .set('Authorization', `Bearer ${token}`)
        .send({ saleId })
        .expect(201);

      const cancelled = await request(app.getHttpServer())
        .post(`/einvoices/${issued.body.id}/cancel`)
        .set('Authorization', `Bearer ${token}`)
        .send({ reason: 'Khach huy don P2.4' })
        .expect(201);
      expect(cancelled.body.status).toBe('cancelled');

      const cancelAudit = await prisma.auditLog.findFirst({
        where: { action: 'einvoice_cancel', entityId: issued.body.id },
      });
      expect(cancelAudit).toMatchObject({
        actorUserId: userId,
        entityType: 'einvoice',
      });
      expect(JSON.parse(cancelAudit!.detailJson!)).toMatchObject({
        storeId,
        reason: 'Khach huy don P2.4',
        saleIds: [saleId],
      });

      const cancelAuditApi = await request(app.getHttpServer())
        .get('/ledger/audit')
        .query({ entityType: 'einvoice', entityId: issued.body.id })
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      expect(
        cancelAuditApi.body.some(
          (row: { action: string }) => row.action === 'einvoice_cancel',
        ),
      ).toBe(true);

      // Fresh sale/invoice for the adjust path (cancelled invoices can't be adjusted).
      const saleId2 = await createSyncedSale('e2e-einvoice-audit-adjust');
      const issued2 = await request(app.getHttpServer())
        .post('/einvoices/issue')
        .set('Authorization', `Bearer ${token}`)
        .send({ saleId: saleId2 })
        .expect(201);
      const adjusted = await request(app.getHttpServer())
        .post(`/einvoices/${issued2.body.id}/adjust`)
        .set('Authorization', `Bearer ${token}`)
        .send({ reason: 'Dieu chinh P2.4' })
        .expect(201);
      expect(adjusted.body.invoiceNumber).toMatch(/^STUB-ADJ-/);

      const adjustAudit = await prisma.auditLog.findFirst({
        where: { action: 'einvoice_adjust', entityId: adjusted.body.id },
      });
      expect(adjustAudit).toMatchObject({
        actorUserId: userId,
        entityType: 'einvoice',
      });
      expect(JSON.parse(adjustAudit!.detailJson!)).toMatchObject({
        storeId,
        reason: 'Dieu chinh P2.4',
        originalInvoiceId: issued2.body.id,
        originalInvoiceNumber: issued2.body.invoiceNumber,
      });

      const adjustAuditApi = await request(app.getHttpServer())
        .get('/ledger/audit')
        .query({ entityType: 'einvoice', entityId: adjusted.body.id })
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      expect(
        adjustAuditApi.body.some(
          (row: { action: string }) => row.action === 'einvoice_adjust',
        ),
      ).toBe(true);

      // The adjustment invoice has its own real, downloadable content.
      const adjXml = await request(app.getHttpServer())
        .get(`/einvoices/${adjusted.body.id}/xml`)
        .set('Authorization', `Bearer ${token}`)
        .buffer(true)
        .parse(bufferParse)
        .expect(200);
      const adjXmlText = (adjXml.body as Buffer).toString('utf8');
      expect(adjXmlText).toContain(`<Number>${adjusted.body.invoiceNumber}</Number>`);
    });

    it('returns 404 when an invoice has neither stored content nor a provider URL', async () => {
      await prisma.eInvoice.deleteMany();
      const saleId = await createSyncedSale('e2e-einvoice-no-content');
      const bare = await prisma.eInvoice.create({
        data: {
          id: randomUUID(),
          saleId,
          status: 'failed',
          provider: 'stub',
        },
      });

      await request(app.getHttpServer())
        .get(`/einvoices/${bare.id}/pdf`)
        .set('Authorization', `Bearer ${token}`)
        .expect(404);
      await request(app.getHttpServer())
        .get(`/einvoices/${bare.id}/xml`)
        .set('Authorization', `Bearer ${token}`)
        .expect(404);
    });
  });
});
