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

async function loginAsCashier(app: INestApplication, phone: string) {
  const res = await request(app.getHttpServer())
    .post('/auth/login')
    .send({ phone, password: '123456' })
    .expect(201);
  return {
    accessToken: res.body.accessToken as string,
    user: res.body.user as { id: string },
  };
}

function makeProductPayload(
  id: string,
  storeId: string,
  overrides: Record<string, unknown> = {},
) {
  const sku = `NEW-${id.slice(0, 8)}`;
  return {
    id,
    sku,
    barcode: null,
    name: 'SP moi',
    unit: 'chai',
    isWeighted: false,
    basePriceVnd: 12000,
    costVnd: 9000,
    active: true,
    storeId,
    seedStock: { qty: '5', minQty: '1' },
    ...overrides,
  };
}

describe('Product upserts sync', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let storeCh1: string;
  let storeCh2: string;
  let cashierPhone: string;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    prisma = moduleRef.get(PrismaService);
    await app.init();

    const ch1 = await prisma.store.findFirstOrThrow({ where: { code: 'CH1' } });
    const ch2 = await prisma.store.findFirstOrThrow({ where: { code: 'CH2' } });
    storeCh1 = ch1.id;
    storeCh2 = ch2.id;

    cashierPhone = '0900000099';
    const passwordHash = await bcrypt.hash('123456', 10);
    await prisma.user.upsert({
      where: { phone: cashierPhone },
      update: {},
      create: {
        phone: cashierPhone,
        name: 'Product upsert cashier',
        passwordHash,
        role: Role.cashier,
        stores: { create: [{ storeId: storeCh1 }] },
      },
    });
  });

  beforeEach(async () => {
    const testProducts = await prisma.product.findMany({
      where: { sku: { startsWith: 'NEW-' } },
      select: { id: true },
    });
    const ids = testProducts.map((p) => p.id);
    if (ids.length > 0) {
      await prisma.productStoreStock.deleteMany({
        where: { productId: { in: ids } },
      });
      await prisma.product.deleteMany({ where: { id: { in: ids } } });
    }
  });

  afterAll(() => app.close());

  it('creates product + seeds stock for one store only', async () => {
    const login = await loginAsOwner(app);
    const id = randomUUID();
    const sku = `NEW-${id.slice(0, 8)}`;
    const payload = {
      id,
      sku,
      barcode: null,
      name: 'SP moi',
      unit: 'chai',
      isWeighted: false,
      basePriceVnd: 12000,
      costVnd: 9000,
      active: true,
      storeId: storeCh1,
      seedStock: { qty: '5', minQty: '1' },
    };
    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ deviceId: 'prod-1', sales: [], productUpserts: [payload] })
      .expect(201);
    expect(res.body.acceptedProductUpsertIds).toContain(id);
    const product = await prisma.product.findUniqueOrThrow({ where: { id } });
    expect(product.sku).toBe(sku);
    const stock1 = await prisma.productStoreStock.findUnique({
      where: { productId_storeId: { productId: id, storeId: storeCh1 } },
    });
    expect(stock1?.qty.toString()).toBe('5');
    const stock2 = await prisma.productStoreStock.findUnique({
      where: { productId_storeId: { productId: id, storeId: storeCh2 } },
    });
    expect(stock2).toBeNull();
  });

  it('update without seedStock does not overwrite qty', async () => {
    const login = await loginAsOwner(app);
    const id = randomUUID();
    const createPayload = makeProductPayload(id, storeCh1);
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ deviceId: 'prod-2', sales: [], productUpserts: [createPayload] })
      .expect(201);

    const updatePayload = {
      ...createPayload,
      name: 'SP da sua',
      seedStock: undefined,
    };
    delete updatePayload.seedStock;

    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ deviceId: 'prod-2', sales: [], productUpserts: [updatePayload] })
      .expect(201);
    expect(res.body.acceptedProductUpsertIds).toContain(id);

    const product = await prisma.product.findUniqueOrThrow({ where: { id } });
    expect(product.name).toBe('SP da sua');
    const stock = await prisma.productStoreStock.findUniqueOrThrow({
      where: { productId_storeId: { productId: id, storeId: storeCh1 } },
    });
    expect(stock.qty.toString()).toBe('5');
  });

  it('update with seedStock when stock exists ignores qty', async () => {
    const login = await loginAsOwner(app);
    const id = randomUUID();
    const createPayload = makeProductPayload(id, storeCh1);
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ deviceId: 'prod-3', sales: [], productUpserts: [createPayload] })
      .expect(201);

    const updatePayload = {
      ...createPayload,
      seedStock: { qty: '99', minQty: '3' },
    };
    const res = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ deviceId: 'prod-3', sales: [], productUpserts: [updatePayload] })
      .expect(201);
    expect(res.body.acceptedProductUpsertIds).toContain(id);

    const stock = await prisma.productStoreStock.findUniqueOrThrow({
      where: { productId_storeId: { productId: id, storeId: storeCh1 } },
    });
    expect(stock.qty.toString()).toBe('5');
    expect(stock.minQty.toString()).toBe('3');
  });

  it('rejects sku_conflict and role_forbidden', async () => {
    const login = await loginAsOwner(app);
    const skuConflictId = randomUUID();
    const skuConflictRes = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'prod-4',
        sales: [],
        productUpserts: [
          makeProductPayload(skuConflictId, storeCh1, { sku: 'STING-330' }),
        ],
      })
      .expect(201);
    expect(skuConflictRes.body.rejectedProductUpserts).toEqual([
      { id: skuConflictId, reason: 'sku_conflict' },
    ]);

    const cashier = await loginAsCashier(app, cashierPhone);
    const forbiddenId = randomUUID();
    const roleForbiddenRes = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${cashier.accessToken}`)
      .send({
        deviceId: 'prod-4',
        sales: [],
        productUpserts: [makeProductPayload(forbiddenId, storeCh1)],
      })
      .expect(201);
    expect(roleForbiddenRes.body.rejectedProductUpserts).toEqual([
      { id: forbiddenId, reason: 'role_forbidden' },
    ]);
  });

  it('idempotent retry accepts same id', async () => {
    const login = await loginAsOwner(app);
    const id = randomUUID();
    const payload = makeProductPayload(id, storeCh1);

    const first = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ deviceId: 'prod-5', sales: [], productUpserts: [payload] })
      .expect(201);
    expect(first.body.acceptedProductUpsertIds).toContain(id);

    const second = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ deviceId: 'prod-5', sales: [], productUpserts: [payload] })
      .expect(201);
    expect(second.body.acceptedProductUpsertIds).toContain(id);

    const products = await prisma.product.findMany({ where: { id } });
    expect(products).toHaveLength(1);
    const stocks = await prisma.productStoreStock.findMany({
      where: { productId: id, storeId: storeCh1 },
    });
    expect(stocks).toHaveLength(1);
  });
});
