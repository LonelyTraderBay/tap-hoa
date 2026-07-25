import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Phase 3 supplier return e2e', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;
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
    storeId = (await prisma.store.findFirst({ where: { code: 'CH1' } }))!.id;
    productId = (
      await prisma.product.findUnique({ where: { sku: 'STING-330' } })
    )!.id;
  });

  afterAll(async () => {
    await prisma.store.update({
      where: { id: storeId },
      data: { vatEnabled: false },
    });
    await app.close();
  });

  it('reduces stock + AP and posts reverse purchase journal', async () => {
    await prisma.journalLine.deleteMany();
    await prisma.journalEntry.deleteMany();
    await prisma.supplierReturnLine.deleteMany();
    await prisma.supplierReturn.deleteMany({ where: { storeId } });
    await prisma.supplierPayable.deleteMany({ where: { storeId } });
    await prisma.purchaseReceiptLine.deleteMany({
      where: { receipt: { storeId } },
    });
    await prisma.purchaseReceipt.deleteMany({ where: { storeId } });
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
        deviceId: 'sup-ret-1',
        sales: [],
        purchaseReceipts: [
          {
            id: receiptId,
            storeId,
            supplierName: 'NCC Return',
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                id: randomUUID(),
                productId,
                qty: '10',
                unitCostVnd: 11_000,
              },
            ],
          },
        ],
      })
      .expect(201);

    const payable = await prisma.supplierPayable.findFirst({
      where: { purchaseReceiptId: receiptId },
    });
    expect(payable!.balanceVnd).toBe(110_000);
    const supplierId = payable!.supplierId;

    const ret = await request(app.getHttpServer())
      .post(`/suppliers/${supplierId}/returns`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        storeId,
        lines: [{ productId, qty: '2', unitCostVnd: 11_000 }],
      })
      .expect(201);

    expect(ret.body.amountVnd).toBe(22_000);

    const stock = await prisma.productStoreStock.findUnique({
      where: { productId_storeId: { productId, storeId } },
    });
    expect(Number(stock!.qty)).toBe(8);

    const payableAfter = await prisma.supplierPayable.findUnique({
      where: { id: payable!.id },
    });
    expect(payableAfter!.balanceVnd).toBe(88_000);

    const entry = await prisma.journalEntry.findUnique({
      where: {
        sourceType_sourceId: {
          sourceType: 'supplier_return',
          sourceId: ret.body.id,
        },
      },
      include: { lines: true },
    });
    expect(entry).toBeTruthy();
    expect(entry!.lines.find((l) => l.accountCode === '331')?.debitVnd).toBe(
      22_000,
    );
    expect(entry!.lines.find((l) => l.accountCode === '156')?.creditVnd).toBe(
      20_000,
    );
    expect(entry!.lines.find((l) => l.accountCode === '1331')?.creditVnd).toBe(
      2_000,
    );
  });
});
