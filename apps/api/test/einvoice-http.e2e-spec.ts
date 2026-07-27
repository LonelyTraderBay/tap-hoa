import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import { createServer, IncomingMessage, Server, ServerResponse } from 'http';
import { AddressInfo } from 'net';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

/** Raw-byte response parser for supertest/superagent — same pattern used by
 * vat-summary.e2e-spec.ts for binary export downloads. */
function bufferParse(res: any, cb: (err: Error | null, body?: Buffer) => void) {
  const chunks: Buffer[] = [];
  res.on('data', (c: Buffer) => chunks.push(Buffer.from(c)));
  res.on('end', () => cb(null, Buffer.concat(chunks)));
}

describe('Phase 3 e-invoice HTTP adapter e2e', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;
  let userId: string;
  let storeId: string;
  let productId: string;
  let mock: Server;
  let lastIssueBody: unknown;
  let lastCancelBody: unknown;
  let lastAdjustBody: unknown;
  let lastCancelIdempotency: string | string[] | undefined;
  let lastAdjustIdempotency: string | string[] | undefined;
  /** P2.4 — Authorization header the mock vendor observed on a document GET
   * (xmlPath/pdfPath fetch), used to prove the proxy download forwards
   * EINVOICE_HTTP_API_KEY the same way `issue`/`cancel`/`adjust` already do. */
  let lastDocAuthHeader: string | string[] | undefined;
  let mockOrigin = '';

  beforeAll(async () => {
    mock = createServer((req: IncomingMessage, res: ServerResponse) => {
      if (req.method === 'GET') {
        if (req.url === '/inv.pdf' || req.url === '/adj.pdf') {
          lastDocAuthHeader = req.headers['authorization'];
          res.writeHead(200, { 'content-type': 'application/pdf' });
          res.end(Buffer.from('%PDF-1.4\n% mock vendor pdf bytes\n'));
          return;
        }
        if (req.url === '/inv.xml' || req.url === '/adj.xml') {
          lastDocAuthHeader = req.headers['authorization'];
          res.writeHead(200, { 'content-type': 'application/xml' });
          res.end('<Invoice><Number>MOCK-VENDOR</Number></Invoice>');
          return;
        }
        res.writeHead(404);
        res.end();
        return;
      }
      const chunks: Buffer[] = [];
      req.on('data', (c) => chunks.push(Buffer.from(c)));
      req.on('end', () => {
        const body = JSON.parse(Buffer.concat(chunks).toString('utf8') || '{}');
        if (req.url?.endsWith('/adjust')) {
          lastAdjustBody = body;
          lastAdjustIdempotency = req.headers['idempotency-key'];
          res.writeHead(200, { 'content-type': 'application/json' });
          res.end(
            JSON.stringify({
              providerRef: 'mock-adjust-1',
              invoiceNumber: 'HTTP-ADJ-1',
              status: 'issued',
              xmlPath: `${mockOrigin}/adj.xml`,
              pdfPath: `${mockOrigin}/adj.pdf`,
            }),
          );
          return;
        }
        if (req.url?.endsWith('/cancel')) {
          lastCancelBody = body;
          lastCancelIdempotency = req.headers['idempotency-key'];
          res.writeHead(200, { 'content-type': 'application/json' });
          res.end(JSON.stringify({ status: 'cancelled' }));
          return;
        }
        lastIssueBody = body;
        res.writeHead(200, { 'content-type': 'application/json' });
        res.end(
          JSON.stringify({
            providerRef: 'mock-ref-1',
            invoiceNumber: 'HTTP-INV-1',
            status: 'issued',
            xmlPath: `${mockOrigin}/inv.xml`,
            pdfPath: `${mockOrigin}/inv.pdf`,
          }),
        );
      });
    });
    await new Promise<void>((resolve) => mock.listen(0, '127.0.0.1', resolve));
    const port = (mock.address() as AddressInfo).port;
    mockOrigin = `http://127.0.0.1:${port}`;
    process.env.EINVOICE_PROVIDER = 'http';
    process.env.EINVOICE_HTTP_URL = `${mockOrigin}/issue`;

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
  });

  afterAll(async () => {
    delete process.env.EINVOICE_PROVIDER;
    delete process.env.EINVOICE_HTTP_URL;
    delete process.env.EINVOICE_HTTP_CANCEL_URL;
    delete process.env.EINVOICE_HTTP_ADJUST_URL;
    delete process.env.EINVOICE_HTTP_API_KEY;
    await app.close();
    await new Promise<void>((resolve, reject) =>
      mock.close((err) => (err ? reject(err) : resolve())),
    );
  });

  it('issues via HTTP mock provider and stores provider=http', async () => {
    await prisma.eInvoice.deleteMany();
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
        deviceId: 'e2e-einvoice-http',
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
            clientCreatedAt: new Date().toISOString(),
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

    expect(issued.body.provider).toBe('http');
    expect(issued.body.invoiceNumber).toBe('HTTP-INV-1');
    expect(issued.body.providerRef).toBe('mock-ref-1');
    expect(lastIssueBody).toMatchObject({
      saleId,
      totalVnd: 15000,
      buyerTaxCode: '0123456789',
    });

    const cancelled = await request(app.getHttpServer())
      .post(`/einvoices/${issued.body.id}/cancel`)
      .set('Authorization', `Bearer ${token}`)
      .send({ reason: 'Sai thong tin khach hang' })
      .expect(201);

    expect(cancelled.body.status).toBe('cancelled');
    expect(lastCancelIdempotency).toBe(`cancel:${issued.body.id}`);
    expect(lastCancelBody).toMatchObject({
      invoiceId: issued.body.id,
      providerRef: 'mock-ref-1',
      reason: 'Sai thong tin khach hang',
    });
  });

  it('creates an adjustment through the HTTP mock provider', async () => {
    await prisma.eInvoice.deleteMany();
    await prisma.shift.updateMany({
      where: { storeId, closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
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
    await prisma.sale.create({
      data: {
        id: saleId,
        storeId,
        shiftId: shift.id,
        soldById: userId,
        paymentMethod: 'cash',
        cashAmount: 22000,
        transferAmount: 0,
        debtAmount: 0,
        discountVnd: 0,
        totalVnd: 22000,
        clientCreatedAt: new Date(),
        lines: {
          create: [
            {
              id: randomUUID(),
              productId,
              qty: '1',
              unitPrice: 22000,
              lineTotal: 22000,
            },
          ],
        },
      },
    });

    const issued = await request(app.getHttpServer())
      .post('/einvoices/issue')
      .set('Authorization', `Bearer ${token}`)
      .send({ saleId })
      .expect(201);

    const adjusted = await request(app.getHttpServer())
      .post(`/einvoices/${issued.body.id}/adjust`)
      .set('Authorization', `Bearer ${token}`)
      .send({ reason: 'Dieu chinh ten khach hang' })
      .expect(201);

    expect(adjusted.body.provider).toBe('http');
    expect(adjusted.body.invoiceNumber).toBe('HTTP-ADJ-1');
    expect(adjusted.body.adjustmentForId).toBe(issued.body.id);
    expect(lastAdjustIdempotency).toBe(`adjust:${issued.body.id}`);
    expect(lastAdjustBody).toMatchObject({
      invoiceId: issued.body.id,
      providerRef: 'mock-ref-1',
      originalInvoiceNumber: 'HTTP-INV-1',
      saleIds: [saleId],
      totalVnd: 22000,
      reason: 'Dieu chinh ten khach hang',
    });
  });

  // P2.4 — the vendor's real xmlPath/pdfPath (returned by the mock issue
  // response, now pointing back at this same mock server instead of the
  // unresolvable 'http://mock/...' placeholder) must be proxy-fetched and
  // streamed by our download endpoints, forwarding EINVOICE_HTTP_API_KEY
  // when configured — plus the issue/cancel lifecycle audit trail.
  it('proxies and streams vendor PDF/XML via download endpoints; forwards API key; audit visible via GET /ledger/audit', async () => {
    await prisma.eInvoice.deleteMany();
    await prisma.shift.updateMany({
      where: { storeId, closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
    });
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId } },
      create: { productId, storeId, qty: 20, minQty: 0, avgCostVnd: 9000 },
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
        deviceId: 'e2e-einvoice-http-download',
        sales: [
          {
            id: saleId,
            storeId,
            shiftId: shift.id,
            paymentMethod: 'cash',
            cashAmount: 17000,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 17000,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                id: randomUUID(),
                productId,
                qty: '1',
                unitPrice: 17000,
                lineTotal: 17000,
              },
            ],
          },
        ],
      })
      .expect(201);

    const issued = await request(app.getHttpServer())
      .post('/einvoices/issue')
      .set('Authorization', `Bearer ${token}`)
      .send({ saleId })
      .expect(201);
    expect(issued.body.provider).toBe('http');
    expect(issued.body.pdfPath).toBe(`${mockOrigin}/inv.pdf`);
    expect(issued.body.xmlPath).toBe(`${mockOrigin}/inv.xml`);

    const pdfRes = await request(app.getHttpServer())
      .get(`/einvoices/${issued.body.id}/pdf`)
      .set('Authorization', `Bearer ${token}`)
      .buffer(true)
      .parse(bufferParse)
      .expect(200);
    expect(pdfRes.headers['content-type']).toContain('application/pdf');
    expect((pdfRes.body as Buffer).toString('latin1')).toContain('%PDF');

    const xmlRes = await request(app.getHttpServer())
      .get(`/einvoices/${issued.body.id}/xml`)
      .set('Authorization', `Bearer ${token}`)
      .buffer(true)
      .parse(bufferParse)
      .expect(200);
    expect(xmlRes.headers['content-type']).toContain('application/xml');
    expect((xmlRes.body as Buffer).toString('utf8')).toContain(
      '<Invoice><Number>MOCK-VENDOR</Number></Invoice>',
    );
    // No API key configured yet — vendor should not have seen an auth header.
    expect(lastDocAuthHeader).toBeUndefined();

    // Forwards EINVOICE_HTTP_API_KEY the same way issue/cancel/adjust do.
    process.env.EINVOICE_HTTP_API_KEY = 'p24-proxy-test-key';
    try {
      await request(app.getHttpServer())
        .get(`/einvoices/${issued.body.id}/pdf`)
        .set('Authorization', `Bearer ${token}`)
        .buffer(true)
        .parse(bufferParse)
        .expect(200);
      expect(lastDocAuthHeader).toBe('Bearer p24-proxy-test-key');
    } finally {
      delete process.env.EINVOICE_HTTP_API_KEY;
    }

    const issueAudit = await prisma.auditLog.findFirst({
      where: { action: 'einvoice_issue', entityId: issued.body.id },
    });
    expect(issueAudit).toMatchObject({
      actorUserId: userId,
      entityType: 'einvoice',
    });
    expect(JSON.parse(issueAudit!.detailJson!)).toMatchObject({
      storeId,
      provider: 'http',
      invoiceNumber: 'HTTP-INV-1',
      saleIds: [saleId],
    });

    const issueAuditApi = await request(app.getHttpServer())
      .get('/ledger/audit')
      .query({ entityType: 'einvoice', entityId: issued.body.id })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(
      issueAuditApi.body.some(
        (row: { action: string; entityId: string }) =>
          row.action === 'einvoice_issue' && row.entityId === issued.body.id,
      ),
    ).toBe(true);

    const cancelled = await request(app.getHttpServer())
      .post(`/einvoices/${issued.body.id}/cancel`)
      .set('Authorization', `Bearer ${token}`)
      .send({ reason: 'Huy qua http mock' })
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
      reason: 'Huy qua http mock',
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
  });
});
