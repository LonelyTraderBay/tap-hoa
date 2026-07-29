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

  // H1: loadShiftCashInputsWithClient bỏ sót hoàn tiền mặt trả hàng bán
  // (SaleReturn.cashRefundVnd) khi tính expectedCashVnd lúc đóng ca — khiến
  // hệ thống báo "lệch âm" giả dù tiền mặt đếm được khớp đúng thực tế.
  it('H1: trừ hoàn tiền mặt trả hàng (SaleReturn.cashRefundVnd) khỏi expectedCashVnd khi đóng ca', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id;

    const product = await prisma.product.findUniqueOrThrow({
      where: { sku: 'STING-330' },
    });
    // Đặt tồn đủ lớn, độc lập với các file e2e khác đã tiêu hao tồn của SKU
    // này trước đó trong cùng lần chạy --runInBand.
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId: product.id, storeId } },
      create: { productId: product.id, storeId, qty: 1000, minQty: 0 },
      update: { qty: 1000 },
    });

    const clientId = randomUUID();
    const opened = await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 500_000, clientId })
      .expect(201);
    const shiftId = opened.body.id as string;

    // Chứng từ phải có clientCreatedAt >= shift.openedAt.
    const nowIso = new Date().toISOString();

    // ---- bán hàng tiền mặt trong ca: 4 x 50.000 = 200.000 ----
    const saleId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'shifts-h1-test',
        sales: [
          {
            id: saleId,
            storeId,
            shiftId,
            soldById: login.user.id,
            paymentMethod: 'cash',
            cashAmount: 200_000,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 200_000,
            clientCreatedAt: nowIso,
            lines: [
              {
                id: randomUUID(),
                productId: product.id,
                qty: '4',
                unitPrice: 50_000,
                lineTotal: 200_000,
              },
            ],
          },
        ],
      })
      .expect(201)
      .expect((res) => {
        expect(res.body.rejected ?? []).toHaveLength(0);
        expect(res.body.acceptedIds).toContain(saleId);
      });

    // ---- trả 1 đơn vị trong CÙNG ca: hoàn 30.000 tiền mặt + 20.000 chuyển
    // khoản (tổng dòng hàng 50.000). Phần chuyển khoản KHÔNG được trừ vào
    // expectedCashVnd — chỉ cashRefundVnd mới chạm tiền mặt trong ngăn kéo.
    const returnId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'shifts-h1-test',
        sales: [],
        saleReturns: [
          {
            id: returnId,
            storeId,
            originalSaleId: saleId,
            shiftId,
            cashRefundVnd: 30_000,
            transferRefundVnd: 20_000,
            debtCreditVnd: 0,
            totalRefundVnd: 50_000,
            clientCreatedAt: nowIso,
            lines: [
              {
                id: randomUUID(),
                productId: product.id,
                qty: '1',
                unitPrice: 50_000,
                lineRefundVnd: 50_000,
              },
            ],
          },
        ],
      })
      .expect(201)
      .expect((res) => {
        expect(res.body.rejectedSaleReturns ?? []).toHaveLength(0);
        expect(res.body.acceptedSaleReturnIds).toContain(returnId);
      });

    // ---- đóng ca ----
    // expectedCashVnd = mở ca 500.000 + bán TM 200.000 − hoàn TM 30.000 = 670.000.
    // Trước khi vá H1, hệ thống bỏ sót khoản hoàn tiền mặt nên expected sẽ là
    // 700.000 — đếm đúng thực tế 670.000 sẽ bị báo lệch âm giả 30.000 dù tiền
    // mặt trong ngăn kéo hoàn toàn khớp (doanh thu tiền mặt − hoàn tiền mặt).
    const closed = await request(app.getHttpServer())
      .post(`/shifts/${shiftId}/close`)
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ closingCash: 670_000 })
      .expect(201);

    expect(closed.body.expectedCashVnd).toBe(670_000);
    expect(closed.body.varianceVnd).toBe(0);
    // Hoàn chuyển khoản của trả hàng không tính vào CK trong ca (sale gốc là
    // bán tiền mặt thuần, transferInShiftVnd phải giữ nguyên 0).
    expect(closed.body.transferInShiftVnd).toBe(0);
  });

  // H7: shiftCloses xử lý TRƯỚC pushSaleReturns() trong cùng push() — nếu 1
  // request /sync/push DUY NHẤT vừa có saleReturn hoàn tiền mặt vừa có
  // shiftClose của CHÍNH ca đó, khoản hoàn tiền mặt phải đã COMMIT vào DB
  // trước khi transaction đóng ca (loadShiftCashInputsWithClient, fix H1)
  // chạy aggregate tính expectedCashVnd — nếu không sẽ tái phát đúng lỗi H1
  // (báo lệch âm giả) qua nguyên nhân khác (thứ tự xử lý trong cùng request,
  // không phải thiếu query). Đối xứng với test H1 ở trên, chỉ khác: saleReturn
  // và shiftClose gộp CHUNG 1 request thay vì 2 request riêng (request đóng
  // ca ở H1 đi qua REST /shifts/:id/close, còn ở đây đi qua /sync/push).
  it('H7: hoàn tiền mặt trả hàng và đóng ca gộp CÙNG 1 request /sync/push vẫn trừ đúng khỏi expectedCashVnd', async () => {
    const login = await loginAsOwner(app);
    const stores = await request(app.getHttpServer())
      .get('/stores')
      .set('Authorization', `Bearer ${login.accessToken}`);
    const storeId = stores.body[0].id;

    const product = await prisma.product.findUniqueOrThrow({
      where: { sku: 'STING-330' },
    });
    // Đặt tồn đủ lớn, độc lập với các file e2e khác đã tiêu hao tồn của SKU
    // này trước đó trong cùng lần chạy --runInBand.
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId: product.id, storeId } },
      create: { productId: product.id, storeId, qty: 1000, minQty: 0 },
      update: { qty: 1000 },
    });

    const clientId = randomUUID();
    const opened = await request(app.getHttpServer())
      .post('/shifts/open')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ storeId, openingCash: 500_000, clientId })
      .expect(201);
    const shiftId = opened.body.id as string;

    // Chứng từ phải có clientCreatedAt >= shift.openedAt.
    const nowIso = new Date().toISOString();

    // ---- bán hàng tiền mặt trong ca: 4 x 50.000 = 200.000 (request riêng —
    // saleReturn cần originalSaleId trỏ tới 1 sale đã tồn tại trong DB) ----
    const saleId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'shifts-h7-test',
        sales: [
          {
            id: saleId,
            storeId,
            shiftId,
            soldById: login.user.id,
            paymentMethod: 'cash',
            cashAmount: 200_000,
            transferAmount: 0,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 200_000,
            clientCreatedAt: nowIso,
            lines: [
              {
                id: randomUUID(),
                productId: product.id,
                qty: '4',
                unitPrice: 50_000,
                lineTotal: 200_000,
              },
            ],
          },
        ],
      })
      .expect(201)
      .expect((res) => {
        expect(res.body.rejected ?? []).toHaveLength(0);
        expect(res.body.acceptedIds).toContain(saleId);
      });

    // ---- CÙNG 1 request /sync/push: vừa trả 1 đơn vị (hoàn 30.000 tiền mặt
    // + 20.000 chuyển khoản, tổng dòng hàng 50.000) VỪA đóng CHÍNH ca đó.
    // Trước khi vá H7, vòng lặp shiftCloses chạy TRƯỚC pushSaleReturns()
    // trong push() nên tại thời điểm transaction đóng ca aggregate
    // SaleReturn.cashRefundVnd theo shiftId, khoản hoàn 30.000 của CÙNG
    // request này chưa kịp commit → expectedCashVnd sai thành 700.000 (bỏ
    // sót khoản hoàn) thay vì đúng 670.000 — tái phát lỗi H1 dù công thức
    // tính đã đúng (H1 đã vá) chỉ vì thứ tự xử lý trong cùng request.
    const returnId = randomUUID();
    const push = await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({
        deviceId: 'shifts-h7-test',
        sales: [],
        saleReturns: [
          {
            id: returnId,
            storeId,
            originalSaleId: saleId,
            shiftId,
            cashRefundVnd: 30_000,
            transferRefundVnd: 20_000,
            debtCreditVnd: 0,
            totalRefundVnd: 50_000,
            clientCreatedAt: nowIso,
            lines: [
              {
                id: randomUUID(),
                productId: product.id,
                qty: '1',
                unitPrice: 50_000,
                lineRefundVnd: 50_000,
              },
            ],
          },
        ],
        shiftCloses: [
          {
            id: shiftId,
            closingCash: 670_000,
            closedAt: nowIso,
          },
        ],
      })
      .expect(201);

    expect(push.body.rejectedSaleReturns ?? []).toHaveLength(0);
    expect(push.body.acceptedSaleReturnIds).toContain(returnId);
    expect(push.body.acceptedShiftCloseIds).toContain(shiftId);
    // expectedCashVnd = mở ca 500.000 + bán TM 200.000 − hoàn TM 30.000 =
    // 670.000, khớp đúng closingCash đếm tay → varianceVnd = 0. Hoàn chuyển
    // khoản (20.000) không tính vào tiền mặt lẫn transferInShiftVnd (sale
    // gốc là bán tiền mặt thuần).
    expect(push.body.closedShifts).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          id: shiftId,
          expectedCashVnd: 670_000,
          varianceVnd: 0,
          transferInShiftVnd: 0,
          closingCash: 670_000,
        }),
      ]),
    );

    const shift = await prisma.shift.findUniqueOrThrow({
      where: { id: shiftId },
    });
    expect(shift.expectedCashVnd).toBe(670_000);
    expect(shift.varianceVnd).toBe(0);
    expect(shift.closingCash).toBe(670_000);
  });
});
