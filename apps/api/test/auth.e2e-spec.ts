import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Auth', () => {
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

  afterEach(async () => {
    await prisma.user.updateMany({
      where: { phone: '0900000001' },
      data: { active: true },
    });
  });

  afterAll(() => app.close());

  it('login returns token', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: '0900000001', password: '123456' })
      .expect(201);
    expect(res.body.accessToken).toBeDefined();
    expect(res.body.user.role).toBe('owner');
  });

  it('GET /stores with Bearer returns CH1 and CH2 for owner', async () => {
    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: '0900000001', password: '123456' })
      .expect(201);

    const res = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.body.accessToken}`)
      .expect(200);

    const codes = res.body.map((s: { code: string }) => s.code).sort();
    expect(codes).toEqual(['CH1', 'CH2']);
  });

  it('rejects login for an inactive user', async () => {
    await prisma.user.update({
      where: { phone: '0900000001' },
      data: { active: false },
    });

    await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: '0900000001', password: '123456' })
      .expect(401);
  });

  it('rejects an existing token after the user is deactivated', async () => {
    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: '0900000001', password: '123456' })
      .expect(201);
    await prisma.user.update({
      where: { phone: '0900000001' },
      data: { active: false },
    });

    await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.body.accessToken}`)
      .expect(401);
  });
});
