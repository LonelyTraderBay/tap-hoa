import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import { createServer, IncomingMessage, Server, ServerResponse } from 'http';
import { AddressInfo } from 'net';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

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

  beforeAll(async () => {
    mock = createServer((req: IncomingMessage, res: ServerResponse) => {
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
              xmlPath: 'http://mock/adj.xml',
              pdfPath: 'http://mock/adj.pdf',
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
            xmlPath: 'http://mock/inv.xml',
            pdfPath: 'http://mock/inv.pdf',
          }),
        );
      });
    });
    await new Promise<void>((resolve) => mock.listen(0, '127.0.0.1', resolve));
    const port = (mock.address() as AddressInfo).port;
    process.env.EINVOICE_PROVIDER = 'http';
    process.env.EINVOICE_HTTP_URL = `http://127.0.0.1:${port}/issue`;

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
});
