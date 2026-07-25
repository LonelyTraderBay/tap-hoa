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

  async function createSyncedSale(deviceId: string) {
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
});
