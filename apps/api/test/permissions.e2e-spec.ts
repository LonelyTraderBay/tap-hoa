import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcrypt';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Wave E ledger/e-invoice permissions e2e', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let storeId: string;
  let passwordHash: string;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    prisma = moduleRef.get(PrismaService);
    await app.init();

    storeId = (await prisma.store.findFirst({ where: { code: 'CH1' } }))!.id;
    passwordHash = await bcrypt.hash('123456', 10);
  });

  afterAll(async () => {
    await app.close();
  });

  async function login(phone: string) {
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone, password: '123456' })
      .expect(201);
    return res.body.accessToken as string;
  }

  async function upsertStoreUser(input: {
    phone: string;
    name: string;
    role: 'owner' | 'store_manager' | 'cashier';
    canLedger: boolean;
    canEinvoice: boolean;
  }) {
    const user = await prisma.user.upsert({
      where: { phone: input.phone },
      update: {
        name: input.name,
        role: input.role,
        passwordHash,
        active: true,
        canLedger: input.canLedger,
        canEinvoice: input.canEinvoice,
      },
      create: {
        phone: input.phone,
        name: input.name,
        role: input.role,
        passwordHash,
        active: true,
        canLedger: input.canLedger,
        canEinvoice: input.canEinvoice,
      },
    });
    await prisma.userStore.upsert({
      where: { userId_storeId: { userId: user.id, storeId } },
      update: {},
      create: { userId: user.id, storeId },
    });
    return user;
  }

  async function expectPermissionMatrix(
    token: string,
    expected: { ledger: number; einvoice: number },
  ) {
    await request(app.getHttpServer())
      .get('/ledger/period-locks')
      .set('Authorization', `Bearer ${token}`)
      .expect(expected.ledger);

    await request(app.getHttpServer())
      .post('/einvoices/issue')
      .set('Authorization', `Bearer ${token}`)
      .send({})
      .expect(expected.einvoice);
  }

  it('splits ledger and e-invoice access by effective user flags', async () => {
    await prisma.user.update({
      where: { phone: '0900000001' },
      data: { canLedger: false, canEinvoice: false, active: true },
    });
    const ownerToken = await login('0900000001');
    await expectPermissionMatrix(ownerToken, { ledger: 200, einvoice: 400 });

    await upsertStoreUser({
      phone: '0900000091',
      name: 'QL ledger only',
      role: 'store_manager',
      canLedger: true,
      canEinvoice: false,
    });
    const ledgerOnlyToken = await login('0900000091');
    await expectPermissionMatrix(ledgerOnlyToken, { ledger: 200, einvoice: 403 });

    await upsertStoreUser({
      phone: '0900000092',
      name: 'QL einvoice only',
      role: 'store_manager',
      canLedger: false,
      canEinvoice: true,
    });
    const einvoiceOnlyToken = await login('0900000092');
    await expectPermissionMatrix(einvoiceOnlyToken, { ledger: 403, einvoice: 400 });

    await upsertStoreUser({
      phone: '0900000093',
      name: 'QL no flags',
      role: 'store_manager',
      canLedger: false,
      canEinvoice: false,
    });
    const noFlagsToken = await login('0900000093');
    await expectPermissionMatrix(noFlagsToken, { ledger: 403, einvoice: 403 });

    await upsertStoreUser({
      phone: '0900000094',
      name: 'Thu ngan raw flags ignored',
      role: 'cashier',
      canLedger: true,
      canEinvoice: true,
    });
    const cashierToken = await login('0900000094');
    await expectPermissionMatrix(cashierToken, { ledger: 403, einvoice: 403 });
  });
});
