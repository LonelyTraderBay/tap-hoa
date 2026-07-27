import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcrypt';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * P0.4 — tách quyền kế toán trên báo cáo kỳ (spec §5.7).
 *
 * Nhóm KẾ TOÁN (`/reports/period/*`, `/reports/cash-fund`,
 * `/reports/bank-recon*`, `/reports/ap-recon*`) bắt buộc `canLedger`.
 * Nhóm VẬN HÀNH (`/reports/day`, `/reports/top-skus`,
 * `/reports/stock-on-hand`, `/reports/debt-aging`, `/reports/ar.csv`)
 * KHÔNG được đổi hành vi — thu ngân/quản lý quầy dùng hằng ngày.
 */
describe('P0.4 reports accounting permission split e2e', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let storeId: string;
  let supplierId: string;
  let passwordHash: string;
  let periodYm: string;
  let today: string;

  let ownerToken: string;
  let ledgerManagerToken: string;
  let plainManagerToken: string;
  let cashierToken: string;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    prisma = moduleRef.get(PrismaService);
    await app.init();
    await seedChartOfAccounts(prisma);

    storeId = (await prisma.store.findFirst({ where: { code: 'CH1' } }))!.id;
    passwordHash = await bcrypt.hash('123456', 10);

    const ict = new Date(Date.now() + 7 * 3600_000);
    periodYm = `${ict.getUTCFullYear()}-${String(
      ict.getUTCMonth() + 1,
    ).padStart(2, '0')}`;
    today = `${periodYm}-${String(ict.getUTCDate()).padStart(2, '0')}`;

    const supplier = await prisma.supplier.create({
      data: { id: randomUUID(), name: `P0.4 perm ${randomUUID().slice(0, 8)}` },
    });
    supplierId = supplier.id;

    // Owner từ seed: role owner => canLedger luôn true dù cờ raw thế nào.
    await prisma.user.update({
      where: { phone: '0900000001' },
      data: { active: true, canLedger: false, canEinvoice: false },
    });
    ownerToken = await login('0900000001');

    await upsertStoreUser({
      phone: '0900000071',
      name: 'QL co ke toan',
      role: 'store_manager',
      canLedger: true,
    });
    ledgerManagerToken = await login('0900000071');

    await upsertStoreUser({
      phone: '0900000072',
      name: 'QL khong ke toan',
      role: 'store_manager',
      canLedger: false,
    });
    plainManagerToken = await login('0900000072');

    // Thu ngân: cờ raw bật vẫn phải bị chặn (effectivePermissions ép false).
    await upsertStoreUser({
      phone: '0900000073',
      name: 'Thu ngan',
      role: 'cashier',
      canLedger: true,
    });
    cashierToken = await login('0900000073');
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
  }) {
    const user = await prisma.user.upsert({
      where: { phone: input.phone },
      update: {
        name: input.name,
        role: input.role,
        passwordHash,
        active: true,
        canLedger: input.canLedger,
        canEinvoice: false,
      },
      create: {
        phone: input.phone,
        name: input.name,
        role: input.role,
        passwordHash,
        active: true,
        canLedger: input.canLedger,
        canEinvoice: false,
      },
    });
    await prisma.userStore.upsert({
      where: { userId_storeId: { userId: user.id, storeId } },
      update: {},
      create: { userId: user.id, storeId },
    });
    await prisma.userStore.deleteMany({
      where: { userId: user.id, storeId: { not: storeId } },
    });
    return user;
  }

  function getStatus(path: string, query: Record<string, string>, token: string) {
    return request(app.getHttpServer())
      .get(path)
      .query(query)
      .set('Authorization', `Bearer ${token}`)
      .then((res) => res.status);
  }

  function postStatus(
    path: string,
    body: Record<string, unknown>,
    token: string,
  ) {
    return request(app.getHttpServer())
      .post(path)
      .set('Authorization', `Bearer ${token}`)
      .send(body)
      .then((res) => res.status);
  }

  /** GET kế toán có đủ tham số hợp lệ: cho phép => 200, cấm => 403. */
  function accountingGetCases(): Array<[string, Record<string, string>]> {
    return [
      ['/reports/period/trial-balance', { periodYm }],
      ['/reports/period/pnl', { periodYm }],
      ['/reports/period/vat', { periodYm }],
      ['/reports/period/export.csv', { periodYm }],
      ['/reports/period/export.xlsx', { periodYm }],
      ['/reports/period/export.pdf', { periodYm }],
      ['/reports/period/vat-declaration.csv', { periodYm }],
      [
        '/reports/cash-fund',
        { storeId, from: `${periodYm}-01`, to: `${periodYm}-28` },
      ],
      ['/reports/bank-recon', { storeId, periodYm }],
      ['/reports/ap-recon', { storeId, supplierId, periodYm }],
    ];
  }

  /**
   * POST kế toán gửi body rỗng: guard chạy TRƯỚC handler nên user bị cấm
   * phải nhận 403, còn user hợp lệ mới rơi xuống validate => 400.
   */
  const accountingPostPaths = [
    '/reports/bank-recon/import',
    '/reports/bank-recon/match',
    '/reports/bank-recon/unmatch',
    '/reports/bank-recon/auto-match',
    '/reports/bank-recon/lock',
    '/reports/ap-recon/import',
    '/reports/ap-recon/match',
    '/reports/ap-recon/unmatch',
    '/reports/ap-recon/auto-match',
    '/reports/ap-recon/lock',
  ];

  describe('nhóm kế toán — bắt buộc canLedger', () => {
    it('owner đọc được mọi báo cáo kế toán', async () => {
      for (const [path, query] of accountingGetCases()) {
        await expect(getStatus(path, query, ownerToken)).resolves.toBe(200);
      }
      for (const path of accountingPostPaths) {
        await expect(postStatus(path, {}, ownerToken)).resolves.toBe(400);
      }
    });

    it('store_manager có canLedger đọc được mọi báo cáo kế toán', async () => {
      for (const [path, query] of accountingGetCases()) {
        await expect(
          getStatus(path, query, ledgerManagerToken),
        ).resolves.toBe(200);
      }
      for (const path of accountingPostPaths) {
        await expect(
          postStatus(path, {}, ledgerManagerToken),
        ).resolves.toBe(400);
      }
    });

    it('store_manager KHÔNG có canLedger bị 403 trên mọi báo cáo kế toán', async () => {
      for (const [path, query] of accountingGetCases()) {
        await expect(getStatus(path, query, plainManagerToken)).resolves.toBe(
          403,
        );
      }
      for (const path of accountingPostPaths) {
        await expect(postStatus(path, {}, plainManagerToken)).resolves.toBe(
          403,
        );
      }
    });

    it('cashier bị 403 trên mọi báo cáo kế toán dù cờ raw canLedger bật', async () => {
      for (const [path, query] of accountingGetCases()) {
        await expect(getStatus(path, query, cashierToken)).resolves.toBe(403);
      }
      for (const path of accountingPostPaths) {
        await expect(postStatus(path, {}, cashierToken)).resolves.toBe(403);
      }
    });
  });

  describe('nhóm vận hành — KHÔNG đổi hành vi', () => {
    const operationalCases = (
      ctx: { storeId: string; today: string },
    ): Array<[string, Record<string, string>]> => [
      ['/reports/day', { date: ctx.today }],
      ['/reports/top-skus', { date: ctx.today }],
      ['/reports/stock-on-hand', { storeId: ctx.storeId }],
      ['/reports/debt-aging', { storeId: ctx.storeId }],
      ['/reports/ar.csv', { storeId: ctx.storeId }],
    ];

    it('cả 4 vai đều đọc được báo cáo vận hành của cửa hàng mình', async () => {
      const tokens = [
        ownerToken,
        ledgerManagerToken,
        plainManagerToken,
        cashierToken,
      ];
      for (const token of tokens) {
        for (const [path, query] of operationalCases({ storeId, today })) {
          await expect(getStatus(path, query, token)).resolves.toBe(200);
        }
      }
    });

    it('debt-aging/ar.csv gộp toàn hệ thống giữ nguyên luật cũ (chỉ owner/QL)', async () => {
      await expect(getStatus('/reports/debt-aging', {}, ownerToken)).resolves.toBe(
        200,
      );
      await expect(
        getStatus('/reports/debt-aging', {}, ledgerManagerToken),
      ).resolves.toBe(200);
      await expect(
        getStatus('/reports/debt-aging', {}, plainManagerToken),
      ).resolves.toBe(200);
      await expect(
        getStatus('/reports/debt-aging', {}, cashierToken),
      ).resolves.toBe(403);

      await expect(
        getStatus('/reports/ar.csv', {}, plainManagerToken),
      ).resolves.toBe(200);
      await expect(getStatus('/reports/ar.csv', {}, cashierToken)).resolves.toBe(
        403,
      );
    });
  });
});
