import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcrypt';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

const MANAGER_PHONE = '0900000041';

describe('Wave 4 account ledger e2e', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let ownerToken: string;
  let managerToken: string;
  let store1: string;
  let store2: string;

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
    store1 = (await prisma.store.findFirst({ where: { code: 'CH1' } }))!.id;
    store2 = (await prisma.store.findFirst({ where: { code: 'CH2' } }))!.id;

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
        name: 'QL so cai',
        passwordHash,
        role: 'store_manager',
        canLedger: true,
        canEinvoice: false,
      },
    });
    await prisma.userStore.upsert({
      where: { userId_storeId: { userId: manager.id, storeId: store1 } },
      update: {},
      create: { userId: manager.id, storeId: store1 },
    });
    await prisma.userStore.deleteMany({
      where: { userId: manager.id, storeId: { not: store1 } },
    });

    const managerLogin = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: MANAGER_PHONE, password: '123456' })
      .expect(201);
    managerToken = managerLogin.body.accessToken;
  });

  afterAll(async () => {
    await app.close();
  });

  async function createJournal(input: {
    storeId: string;
    periodYm: string;
    postedAt: string;
    debit111?: number;
    credit111?: number;
  }) {
    const debit111 = input.debit111 ?? 0;
    const credit111 = input.credit111 ?? 0;
    const counterDebit = credit111;
    const counterCredit = debit111;
    await prisma.journalEntry.create({
      data: {
        id: randomUUID(),
        storeId: input.storeId,
        periodYm: input.periodYm,
        sourceType: 'account_ledger_e2e',
        sourceId: randomUUID(),
        postedAt: new Date(input.postedAt),
        memo: 'account ledger e2e',
        lines: {
          create: [
            {
              id: randomUUID(),
              accountCode: '111',
              debitVnd: debit111,
              creditVnd: credit111,
            },
            {
              id: randomUUID(),
              accountCode: debit111 > 0 ? '511' : '642',
              debitVnd: counterDebit,
              creditVnd: counterCredit,
            },
          ],
        },
      },
    });
  }

  it('returns opening, running, and closing balances with scoped access', async () => {
    await prisma.journalLine.deleteMany();
    await prisma.journalEntry.deleteMany();

    await createJournal({
      storeId: store1,
      periodYm: '2026-06',
      postedAt: '2026-06-10T01:00:00.000Z',
      debit111: 1000,
    });
    await createJournal({
      storeId: store2,
      periodYm: '2026-06',
      postedAt: '2026-06-11T01:00:00.000Z',
      debit111: 3000,
    });
    await createJournal({
      storeId: store1,
      periodYm: '2026-07',
      postedAt: '2026-07-05T01:00:00.000Z',
      credit111: 200,
    });
    await createJournal({
      storeId: store2,
      periodYm: '2026-07',
      postedAt: '2026-07-06T01:00:00.000Z',
      credit111: 700,
    });
    await createJournal({
      storeId: store1,
      periodYm: '2026-07',
      postedAt: '2026-07-10T01:00:00.000Z',
      debit111: 500,
    });

    const aggregate = await request(app.getHttpServer())
      .get('/ledger/account-ledger')
      .query({ accountCode: '111', periodYm: '2026-07' })
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);

    expect(aggregate.body.openingBalance).toBe(4000);
    expect(
      aggregate.body.lines.map(
        (l: { runningBalance: number }) => l.runningBalance,
      ),
    ).toEqual([3800, 3100, 3600]);
    expect(aggregate.body.closingBalance).toBe(3600);

    const storeScoped = await request(app.getHttpServer())
      .get('/ledger/account-ledger')
      .query({ accountCode: '111', periodYm: '2026-07', storeId: store1 })
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);

    expect(storeScoped.body.openingBalance).toBe(1000);
    expect(
      storeScoped.body.lines.map(
        (l: { runningBalance: number }) => l.runningBalance,
      ),
    ).toEqual([800, 1300]);
    expect(storeScoped.body.closingBalance).toBe(1300);

    const managerScoped = await request(app.getHttpServer())
      .get('/ledger/account-ledger')
      .query({ accountCode: '111', periodYm: '2026-07' })
      .set('Authorization', `Bearer ${managerToken}`)
      .expect(200);

    expect(managerScoped.body.openingBalance).toBe(1000);
    expect(managerScoped.body.lines).toHaveLength(2);
    expect(managerScoped.body.closingBalance).toBe(1300);

    await request(app.getHttpServer())
      .get('/ledger/account-ledger')
      .query({ accountCode: '111', periodYm: '2026-07', storeId: store2 })
      .set('Authorization', `Bearer ${managerToken}`)
      .expect(403);
  });
});
