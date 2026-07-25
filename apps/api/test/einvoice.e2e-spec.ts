import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Phase 2 e-invoice e2e', () => {
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
    await app.close();
  });

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
});
