import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

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

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    prisma = moduleRef.get(PrismaService);
    await app.init();
  });

  beforeEach(async () => {
    await prisma.store.deleteMany({ where: { code: { startsWith: 'W9' } } });
  });

  afterEach(async () => {
    await prisma.store.deleteMany({ where: { code: { startsWith: 'W9' } } });
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

    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(stores.body.some((s: { code: string }) => s.code === code)).toBe(
      true,
    );

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
});
