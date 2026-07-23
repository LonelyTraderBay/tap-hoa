import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';

async function loginAsOwner(app: INestApplication) {
  const res = await request(app.getHttpServer())
    .post('/auth/login')
    .send({ phone: '0900000001', password: '123456' })
    .expect(201);
  return {
    accessToken: res.body.accessToken as string,
  };
}

describe('Sync pull', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    await app.init();
  });

  afterAll(() => app.close());

  it('GET /sync/pull returns seeded STING-330 for store', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id;

    const res = await request(app.getHttpServer())
      .get('/sync/pull')
      .query({
        since: new Date(0).toISOString(),
        storeId,
      })
      .set('Authorization', `Bearer ${login.accessToken}`)
      .expect(200);

    expect(res.body.products.some((p: { sku: string }) => p.sku === 'STING-330')).toBe(
      true,
    );
    expect(res.body.stocks[0].qty).toBeDefined();
    expect(res.body.serverTime).toBeDefined();
  });
});
