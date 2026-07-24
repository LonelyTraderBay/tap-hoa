import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

async function loginAsOwner(app: INestApplication) {
  const res = await request(app.getHttpServer())
    .post('/auth/login')
    .send({ phone: '0900000001', password: '123456' })
    .expect(201);
  return {
    accessToken: res.body.accessToken as string,
    user: res.body.user as { id: string },
  };
}

async function loginAsCashier(app: INestApplication) {
  const res = await request(app.getHttpServer())
    .post('/auth/login')
    .send({ phone: '0900000002', password: '123456' })
    .expect(201);
  return {
    accessToken: res.body.accessToken as string,
    user: res.body.user as { id: string },
  };
}

describe('Shifts', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    prisma = moduleRef.get(PrismaService);
    await app.init();

    const passwordHash = await bcrypt.hash('123456', 10);
    const store = await prisma.store.findFirst({ where: { code: 'CH1' } });
    if (!store) {
      throw new Error('Seed store CH1 not found');
    }
    await prisma.user.upsert({
      where: { phone: '0900000002' },
      update: {},
      create: {
        phone: '0900000002',
        name: 'Cashier 2',
        passwordHash,
        role: Role.cashier,
        stores: { create: [{ storeId: store.id }] },
      },
    });
  });

  beforeEach(async () => {
    await prisma.shift.updateMany({
      where: { closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
    });
  });

  afterAll(() => app.close());

  it('opens shift', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id;
    const clientId = randomUUID();
    const res = await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        storeId,
        openingCash: 500000,
        clientId,
      })
      .expect(201);
    expect(res.body.openingCash).toBe(500000);
    expect(res.body.id).toBe(clientId);

    await request(app.getHttpServer())
      .post(`/shifts/${clientId}/close`)
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ closingCash: 500000 })
      .expect(201);
  });

  it('rejects second open shift for same store and user', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id;
    const firstClientId = randomUUID();

    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        storeId,
        openingCash: 100000,
        clientId: firstClientId,
      })
      .expect(201);

    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        storeId,
        openingCash: 200000,
        clientId: randomUUID(),
      })
      .expect(409);

    await request(app.getHttpServer())
      .post(`/shifts/${firstClientId}/close`)
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ closingCash: 100000 })
      .expect(201);
  });

  it('closes shift', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id;
    const clientId = randomUUID();

    const opened = await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 300000, clientId })
      .expect(201);

    const closed = await request(app.getHttpServer())
      .post(`/shifts/${opened.body.id}/close`)
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ closingCash: 350000, note: 'End of day' })
      .expect(201);

    expect(closed.body.closingCash).toBe(350000);
    expect(closed.body.closedAt).toBeDefined();
    expect(closed.body.note).toBe('End of day');
    expect(closed.body.expectedCashVnd).toBe(300000);
    expect(closed.body.varianceVnd).toBe(50000);
    expect(closed.body.transferInShiftVnd).toBe(0);
  });

  it('returns same shift on idempotent open with same clientId', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id;
    const clientId = randomUUID();

    const first = await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 500000, clientId })
      .expect(201);

    const second = await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 999999, clientId })
      .expect(201);

    expect(second.body.id).toBe(clientId);
    expect(second.body.id).toBe(first.body.id);
    expect(second.body.openingCash).toBe(500000);

    await request(app.getHttpServer())
      .post(`/shifts/${clientId}/close`)
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ closingCash: 500000 })
      .expect(201);
  });

  it('rejects open with another user clientId', async () => {
    const owner = await loginAsOwner(app);
    const cashier = await loginAsCashier(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${owner.accessToken}`);
    const storeId = stores.body[0].id;
    const clientId = randomUUID();

    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${owner.accessToken}`)
      .send({ storeId, openingCash: 100000, clientId })
      .expect(201);

    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${cashier.accessToken}`)
      .send({ storeId, openingCash: 100000, clientId })
      .expect(403);

    await request(app.getHttpServer())
      .post(`/shifts/${clientId}/close`)
      .set('Authorization', `Bearer ${owner.accessToken}`)
      .send({ closingCash: 100000 })
      .expect(201);
  });

  it('rejects reopen with clientId of closed shift', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id;
    const clientId = randomUUID();

    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 200000, clientId })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/shifts/${clientId}/close`)
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ closingCash: 200000 })
      .expect(201);

    await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 300000, clientId })
      .expect(409);
  });
});
