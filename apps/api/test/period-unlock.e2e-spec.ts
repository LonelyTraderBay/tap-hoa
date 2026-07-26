import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcrypt';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { periodYmFromDate } from '../src/ledger/journal-builders';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

const MANAGER_PHONE = '0900000042';
const CASHIER_PHONE = '0900000043';

describe('Period unlock e2e', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let ownerToken: string;
  let managerToken: string;
  let cashierToken: string;
  let ownerId: string;
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

    const ownerLogin = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: '0900000001', password: '123456' })
      .expect(201);
    ownerToken = ownerLogin.body.accessToken;
    ownerId = ownerLogin.body.user.id;
    storeId = (await prisma.store.findFirst({ where: { code: 'CH1' } }))!.id;
    productId = (
      await prisma.product.findUnique({ where: { sku: 'STING-330' } })
    )!.id;

    const passwordHash = await bcrypt.hash('123456', 10);
    const manager = await prisma.user.upsert({
      where: { phone: MANAGER_PHONE },
      update: {
        active: true,
        passwordHash,
        role: 'store_manager',
        canLedger: true,
        canEinvoice: false,
      },
      create: {
        phone: MANAGER_PHONE,
        name: 'QL unlock',
        passwordHash,
        role: 'store_manager',
        canLedger: true,
        canEinvoice: false,
      },
    });
    await prisma.userStore.upsert({
      where: { userId_storeId: { userId: manager.id, storeId } },
      update: {},
      create: { userId: manager.id, storeId },
    });
    const cashier = await prisma.user.upsert({
      where: { phone: CASHIER_PHONE },
      update: { active: true, passwordHash, role: 'cashier' },
      create: {
        phone: CASHIER_PHONE,
        name: 'Thu ngan unlock',
        passwordHash,
        role: 'cashier',
      },
    });
    await prisma.userStore.upsert({
      where: { userId_storeId: { userId: cashier.id, storeId } },
      update: {},
      create: { userId: cashier.id, storeId },
    });
    const managerLogin = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: MANAGER_PHONE, password: '123456' })
      .expect(201);
    managerToken = managerLogin.body.accessToken;
    const cashierLogin = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: CASHIER_PHONE, password: '123456' })
      .expect(201);
    cashierToken = cashierLogin.body.accessToken;
  });

  beforeEach(async () => {
    await prisma.journalLine.deleteMany();
    await prisma.journalEntry.deleteMany();
    await prisma.auditLog.deleteMany();
    await prisma.periodLock.deleteMany();
    await prisma.eInvoice.deleteMany({
      where: { sale: { storeId } },
    });
    await prisma.saleReturnLine.deleteMany({
      where: { saleReturn: { storeId } },
    });
    await prisma.saleReturn.deleteMany({ where: { storeId } });
    await prisma.saleLine.deleteMany({ where: { sale: { storeId } } });
    await prisma.sale.deleteMany({ where: { storeId } });
    await prisma.shift.updateMany({
      where: { storeId, closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
    });
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId } },
      create: {
        productId,
        storeId,
        qty: 100,
        minQty: 0,
        avgCostVnd: 9000,
      },
      update: { qty: 100, avgCostVnd: 9000 },
    });
  });

  afterAll(async () => {
    await prisma.periodLock.deleteMany();
    await app.close();
  });

  async function openShift() {
    return prisma.shift.create({
      data: {
        id: randomUUID(),
        storeId,
        userId: ownerId,
        openedAt: new Date(),
        openingCash: 0,
      },
    });
  }

  function pushSale(input: { saleId: string; shiftId: string; at: Date }) {
    return request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        deviceId: 'period-unlock',
        sales: [
          {
            id: input.saleId,
            storeId,
            shiftId: input.shiftId,
            soldById: ownerId,
            paymentMethod: 'cash',
            cashAmount: 10000,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 10000,
            customerId: null,
            clientCreatedAt: input.at.toISOString(),
            lines: [
              {
                productId,
                qty: '1',
                unitPrice: 10000,
                lineTotal: 10000,
              },
            ],
          },
        ],
      })
      .expect(201);
  }

  it('unlocks a period with audit and allows new journals again', async () => {
    const shift = await openShift();
    const at = new Date();
    const periodYm = periodYmFromDate(at);
    await request(app.getHttpServer())
      .post('/ledger/period-locks')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ periodYm })
      .expect(201);

    const blockedSaleId = randomUUID();
    await pushSale({ saleId: blockedSaleId, shiftId: shift.id, at });
    await expect(
      prisma.journalEntry.findUnique({
        where: {
          sourceType_sourceId: { sourceType: 'sale', sourceId: blockedSaleId },
        },
      }),
    ).resolves.toBeNull();

    await request(app.getHttpServer())
      .post(`/ledger/period-locks/${periodYm}/unlock`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ reason: '  x  ' })
      .expect(400);

    await request(app.getHttpServer())
      .post(`/ledger/period-locks/${periodYm}/unlock`)
      .set('Authorization', `Bearer ${managerToken}`)
      .send({ reason: 'manager attempt' })
      .expect(403);
    await request(app.getHttpServer())
      .post(`/ledger/period-locks/${periodYm}/unlock`)
      .set('Authorization', `Bearer ${cashierToken}`)
      .send({ reason: 'cashier attempt' })
      .expect(403);

    await request(app.getHttpServer())
      .post(`/ledger/period-locks/${periodYm}/unlock`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ reason: '  Owner reviewed closeout  ' })
      .expect(200)
      .expect(({ body }) => {
        expect(body).toEqual({ unlocked: true, periodYm, replayed: 1 });
      });
    await expect(
      prisma.periodLock.findUnique({ where: { periodYm } }),
    ).resolves.toBeNull();

    const replayedBlockedSale = await prisma.journalEntry.findUnique({
      where: {
        sourceType_sourceId: { sourceType: 'sale', sourceId: blockedSaleId },
      },
    });
    expect(replayedBlockedSale?.periodYm).toBe(periodYm);

    const postedSaleId = randomUUID();
    await pushSale({ saleId: postedSaleId, shiftId: shift.id, at });
    const posted = await prisma.journalEntry.findUnique({
      where: {
        sourceType_sourceId: { sourceType: 'sale', sourceId: postedSaleId },
      },
    });
    expect(posted?.periodYm).toBe(periodYm);

    const audit = await request(app.getHttpServer())
      .get('/ledger/audit')
      .query({ limit: 10 })
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    const unlock = audit.body.find(
      (row: { action: string; entityId: string }) =>
        row.action === 'period_unlock' && row.entityId === periodYm,
    );
    expect(unlock).toMatchObject({
      actorUserId: ownerId,
      entityType: 'period_lock',
      detailJson: JSON.stringify({ reason: 'Owner reviewed closeout' }),
    });
    expect(unlock.at).toBeTruthy();

    await request(app.getHttpServer())
      .get('/ledger/audit')
      .set('Authorization', `Bearer ${managerToken}`)
      .expect(200);
    await request(app.getHttpServer())
      .get('/ledger/audit')
      .set('Authorization', `Bearer ${cashierToken}`)
      .expect(403);
  });
});
