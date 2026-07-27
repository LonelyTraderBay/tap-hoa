import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

const TEST_PHONE_PREFIX = '09502';
const MANAGER_PHONE = `${TEST_PHONE_PREFIX}00001`;

async function loginAsOwner(app: INestApplication) {
  const res = await request(app.getHttpServer())
    .post('/auth/login')
    .send({ phone: '0900000001', password: '123456' })
    .expect(201);
  return res.body.accessToken as string;
}

describe('Stores', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let store1Id: string;
  let store2Id: string;

  async function cleanupTestUsers() {
    const users = await prisma.user.findMany({
      where: { phone: { startsWith: TEST_PHONE_PREFIX } },
      select: { id: true },
    });
    const ids = users.map((user) => user.id);
    if (ids.length === 0) return;
    await prisma.userStore.deleteMany({ where: { userId: { in: ids } } });
    await prisma.user.deleteMany({ where: { id: { in: ids } } });
  }

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    prisma = moduleRef.get(PrismaService);
    await app.init();

    store1Id = (await prisma.store.findFirst({ where: { code: 'CH1' } }))!.id;
    store2Id = (await prisma.store.findFirst({ where: { code: 'CH2' } }))!.id;
  });

  beforeEach(async () => {
    await prisma.store.deleteMany({ where: { code: { startsWith: 'W9' } } });
  });

  afterEach(async () => {
    await prisma.store.deleteMany({ where: { code: { startsWith: 'W9' } } });
    await cleanupTestUsers();
    // Trả CH1/CH2 về allowNegativeStock mặc định để không rò rỉ state sang test khác.
    await prisma.store.updateMany({
      where: { id: { in: [store1Id, store2Id] } },
      data: { allowNegativeStock: false },
    });
  });

  afterAll(() => app.close());

  it('POST /stores creates and PATCH /stores/:id edits an owner store', async () => {
    const token = await loginAsOwner(app);
    const code = `W9${Date.now().toString().slice(-6)}`;

    const created = await request(app.getHttpServer())
      .post('/stores')
      .set('Authorization', `Bearer ${token}`)
      .send({
        code,
        name: 'Wave 9 Store',
        debtOverdueDays: 21,
        largeDebtThresholdVnd: 50000,
      })
      .expect(201);

    expect(created.body.code).toBe(code);
    expect(created.body.name).toBe('Wave 9 Store');
    expect(created.body.debtOverdueDays).toBe(21);
    expect(created.body.largeDebtThresholdVnd).toBe(50000);
    // allowNegativeStock is server-side config (P1.2), off by default.
    expect(created.body.allowNegativeStock).toBe(false);

    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(stores.body.some((s: { code: string }) => s.code === code)).toBe(
      true,
    );
    const listed = stores.body.find(
      (s: { code: string }) => s.code === code,
    );
    expect(listed.allowNegativeStock).toBe(false);

    const updated = await request(app.getHttpServer())
      .patch(`/stores/${created.body.id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        code: `${code}A`,
        name: 'Wave 9 Store Edited',
        largeDebtThresholdVnd: null,
      })
      .expect(200);

    expect(updated.body.code).toBe(`${code}A`);
    expect(updated.body.name).toBe('Wave 9 Store Edited');
    expect(updated.body.largeDebtThresholdVnd).toBeNull();
  });

  it('PATCH /stores/:id/allow-negative-stock — owner can set on any store and GET /stores reflects it', async () => {
    const token = await loginAsOwner(app);

    const res = await request(app.getHttpServer())
      .patch(`/stores/${store1Id}/allow-negative-stock`)
      .set('Authorization', `Bearer ${token}`)
      .send({ allowNegativeStock: true })
      .expect(200);
    expect(res.body).toMatchObject({
      id: store1Id,
      allowNegativeStock: true,
    });

    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    const store1 = stores.body.find(
      (s: { id: string }) => s.id === store1Id,
    );
    expect(store1.allowNegativeStock).toBe(true);

    await request(app.getHttpServer())
      .patch(`/stores/${store1Id}/allow-negative-stock`)
      .set('Authorization', `Bearer ${token}`)
      .send({ allowNegativeStock: 'yes' })
      .expect(400);
  });

  it('PATCH /stores/:id/allow-negative-stock — store_manager can set only their own store', async () => {
    const ownerToken = await loginAsOwner(app);

    await request(app.getHttpServer())
      .post('/users')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        phone: MANAGER_PHONE,
        name: 'QL cai dat kho',
        password: '123456',
        role: 'store_manager',
        storeIds: [store2Id],
      })
      .expect(201);

    const managerLogin = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: MANAGER_PHONE, password: '123456' })
      .expect(201);
    const managerToken = managerLogin.body.accessToken as string;

    // Không thuộc cửa hàng này → từ chối.
    await request(app.getHttpServer())
      .patch(`/stores/${store1Id}/allow-negative-stock`)
      .set('Authorization', `Bearer ${managerToken}`)
      .send({ allowNegativeStock: true })
      .expect(403);
    const store1Unchanged = await prisma.store.findUniqueOrThrow({
      where: { id: store1Id },
      select: { allowNegativeStock: true },
    });
    expect(store1Unchanged.allowNegativeStock).toBe(false);

    // Đúng cửa hàng của mình → cho phép.
    const res = await request(app.getHttpServer())
      .patch(`/stores/${store2Id}/allow-negative-stock`)
      .set('Authorization', `Bearer ${managerToken}`)
      .send({ allowNegativeStock: true })
      .expect(200);
    expect(res.body).toMatchObject({
      id: store2Id,
      allowNegativeStock: true,
    });
  });
});
