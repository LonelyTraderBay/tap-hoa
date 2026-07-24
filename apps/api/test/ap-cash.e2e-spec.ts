import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Phase 2 AP + cash e2e', () => {
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
    await app.close();
  });

  it('purchase increases AP; payment decreases AP and posts journal', async () => {
    await prisma.periodLock.deleteMany();
    await prisma.journalLine.deleteMany({
      where: { entry: { sourceType: { in: ['purchase_receipt', 'supplier_payment'] } } },
    });
    await prisma.journalEntry.deleteMany({
      where: { sourceType: { in: ['purchase_receipt', 'supplier_payment'] } },
    });
    await prisma.supplierPayment.deleteMany();
    await prisma.supplierPayable.deleteMany();
    await prisma.purchaseReceiptLine.deleteMany();
    await prisma.purchaseReceipt.deleteMany({ where: { storeId } });
    await prisma.supplier.deleteMany({ where: { name: 'NCC AP Test' } });

    const receiptId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'e2e-ap',
        sales: [],
        purchaseReceipts: [
          {
            id: receiptId,
            storeId,
            supplierName: 'NCC AP Test',
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                id: randomUUID(),
                productId,
                qty: '10',
                unitCostVnd: 8000,
              },
            ],
          },
        ],
      })
      .expect(201);

    const payable = await prisma.supplierPayable.findFirst({
      where: { purchaseReceiptId: receiptId },
    });
    expect(payable).toBeTruthy();
    expect(payable!.amountVnd).toBe(80000);
    expect(payable!.balanceVnd).toBe(80000);

    const journal = await prisma.journalEntry.findUnique({
      where: {
        sourceType_sourceId: {
          sourceType: 'purchase_receipt',
          sourceId: receiptId,
        },
      },
      include: { lines: true },
    });
    expect(journal).toBeTruthy();
    const cr331 = journal!.lines.find((l) => l.accountCode === '331');
    expect(cr331?.creditVnd).toBe(80000);

    const payRes = await request(app.getHttpServer())
      .post(`/suppliers/${payable!.supplierId}/payments`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        storeId,
        amountVnd: 30000,
        channel: 'cash',
      })
      .expect(201);

    const after = await prisma.supplierPayable.findUnique({
      where: { id: payable!.id },
    });
    expect(after!.balanceVnd).toBe(50000);

    const payJournal = await prisma.journalEntry.findUnique({
      where: {
        sourceType_sourceId: {
          sourceType: 'supplier_payment',
          sourceId: payRes.body.id,
        },
      },
      include: { lines: true },
    });
    expect(payJournal).toBeTruthy();
    expect(
      payJournal!.lines.find((l) => l.accountCode === '331')?.debitVnd,
    ).toBe(30000);
    expect(
      payJournal!.lines.find((l) => l.accountCode === '111')?.creditVnd,
    ).toBe(30000);
  });

  it('owner can create bank account', async () => {
    const res = await request(app.getHttpServer())
      .post('/suppliers/bank-accounts')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Vietcombank chính', bankName: 'VCB', accountNo: '001' })
      .expect(201);
    expect(res.body.name).toContain('Vietcombank');
    await prisma.bankAccount.delete({ where: { id: res.body.id } });
  });
});
