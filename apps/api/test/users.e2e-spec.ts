import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

const OWNER_PHONE = '0900000001';
const TEST_PHONE_PREFIX = '09501';
const CASHIER_PHONE = `${TEST_PHONE_PREFIX}00001`;
const MANAGER_PHONE = `${TEST_PHONE_PREFIX}00002`;
const SPARE_PHONE = `${TEST_PHONE_PREFIX}00003`;

describe('Users management e2e', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let store1Id: string;
  let store2Id: string;
  let ownerId: string;
  let ownerToken: string;

  async function login(phone: string, password: string) {
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone, password })
      .expect(201);
    return res.body.accessToken as string;
  }

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
    await prisma.user.update({
      where: { phone: OWNER_PHONE },
      data: { role: Role.owner, active: true },
    });
    ownerId = (await prisma.user.findUniqueOrThrow({
      where: { phone: OWNER_PHONE },
      select: { id: true },
    })).id;
  });

  beforeEach(async () => {
    await cleanupTestUsers();
    ownerToken = await login(OWNER_PHONE, '123456');
  });

  afterAll(async () => {
    await cleanupTestUsers();
    // Chủ được seed phải luôn dùng được sau khi chạy test.
    await prisma.user.update({
      where: { phone: OWNER_PHONE },
      data: { role: Role.owner, active: true },
    });
    await app.close();
  });

  it('owner creates a cashier and a store_manager who can then log in', async () => {
    const cashier = await request(app.getHttpServer())
      .post('/users')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        phone: CASHIER_PHONE,
        name: 'Thu ngan A',
        password: '123456',
        role: 'cashier',
        storeIds: [store1Id],
      })
      .expect(201);

    expect(cashier.body).toMatchObject({
      phone: CASHIER_PHONE,
      name: 'Thu ngan A',
      role: 'cashier',
      canLedger: false,
      canEinvoice: false,
      active: true,
      storeIds: [store1Id],
    });
    expect(cashier.body.passwordHash).toBeUndefined();

    const manager = await request(app.getHttpServer())
      .post('/users')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        phone: MANAGER_PHONE,
        name: 'Quan ly B',
        password: '123456',
        role: 'store_manager',
        storeIds: [store2Id],
        canLedger: true,
      })
      .expect(201);

    expect(manager.body).toMatchObject({
      role: 'store_manager',
      canLedger: true,
      canEinvoice: false,
      storeIds: [store2Id],
    });

    // Tạo tài khoản phải ghi audit log — không kèm password/passwordHash.
    const cashierAudit = await prisma.auditLog.findFirst({
      where: { action: 'user_create', entityId: cashier.body.id },
    });
    expect(cashierAudit).toMatchObject({
      actorUserId: ownerId,
      entityType: 'user',
    });
    expect(JSON.parse(cashierAudit?.detailJson ?? '{}')).toMatchObject({
      phone: CASHIER_PHONE,
      role: 'cashier',
      storeIds: [store1Id],
    });
    expect(cashierAudit?.detailJson ?? '').not.toMatch(/password/i);

    const managerAudit = await prisma.auditLog.findFirst({
      where: { action: 'user_create', entityId: manager.body.id },
    });
    expect(managerAudit).toMatchObject({
      actorUserId: ownerId,
      entityType: 'user',
    });
    expect(JSON.parse(managerAudit?.detailJson ?? '{}')).toMatchObject({
      phone: MANAGER_PHONE,
      role: 'store_manager',
      storeIds: [store2Id],
    });

    const cashierLogin = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: CASHIER_PHONE, password: '123456' })
      .expect(201);
    expect(cashierLogin.body.accessToken).toBeTruthy();
    expect(cashierLogin.body.user.role).toBe('cashier');

    const managerLogin = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: MANAGER_PHONE, password: '123456' })
      .expect(201);
    expect(managerLogin.body.user.canLedger).toBe(true);
  });

  it('GET /users is owner-wide, store-scoped for store_manager and denied for cashier', async () => {
    await request(app.getHttpServer())
      .post('/users')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        phone: CASHIER_PHONE,
        name: 'Thu ngan CH1',
        password: '123456',
        role: 'cashier',
        storeIds: [store1Id],
      })
      .expect(201);

    await request(app.getHttpServer())
      .post('/users')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        phone: MANAGER_PHONE,
        name: 'Quan ly CH2',
        password: '123456',
        role: 'store_manager',
        storeIds: [store2Id],
      })
      .expect(201);

    const ownerList = await request(app.getHttpServer())
      .get('/users')
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    const ownerPhones = ownerList.body.map((u: { phone: string }) => u.phone);
    expect(ownerPhones).toEqual(expect.arrayContaining([CASHIER_PHONE, MANAGER_PHONE]));
    expect(
      ownerList.body.every(
        (u: Record<string, unknown>) => u.passwordHash === undefined,
      ),
    ).toBe(true);

    const managerToken = await login(MANAGER_PHONE, '123456');
    const managerList = await request(app.getHttpServer())
      .get('/users')
      .set('Authorization', `Bearer ${managerToken}`)
      .expect(200);
    const managerPhones = managerList.body.map((u: { phone: string }) => u.phone);
    // Chủ có cả CH1 + CH2 nên vẫn thấy; thu ngân chỉ ở CH1 thì không.
    expect(managerPhones).toContain(MANAGER_PHONE);
    expect(managerPhones).toContain(OWNER_PHONE);
    expect(managerPhones).not.toContain(CASHIER_PHONE);

    const cashierToken = await login(CASHIER_PHONE, '123456');
    await request(app.getHttpServer())
      .get('/users')
      .set('Authorization', `Bearer ${cashierToken}`)
      .expect(403);
  });

  it('rejects duplicate phone, short password and cashier accounting flags', async () => {
    await request(app.getHttpServer())
      .post('/users')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        phone: CASHIER_PHONE,
        name: 'Thu ngan A',
        password: '123456',
        role: 'cashier',
        storeIds: [store1Id],
      })
      .expect(201);

    await request(app.getHttpServer())
      .post('/users')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        phone: CASHIER_PHONE,
        name: 'Trung so dien thoai',
        password: '123456',
        role: 'cashier',
        storeIds: [store1Id],
      })
      .expect(409);

    await request(app.getHttpServer())
      .post('/users')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        phone: SPARE_PHONE,
        name: 'Mat khau ngan',
        password: '12345',
        role: 'cashier',
        storeIds: [store1Id],
      })
      .expect(400);

    await request(app.getHttpServer())
      .post('/users')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        phone: SPARE_PHONE,
        name: 'Thu ngan co quyen so',
        password: '123456',
        role: 'cashier',
        storeIds: [store1Id],
        canLedger: true,
      })
      .expect(400);

    await request(app.getHttpServer())
      .post('/users')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        phone: SPARE_PHONE,
        name: 'Diem ban khong ton tai',
        password: '123456',
        role: 'cashier',
        storeIds: ['00000000-0000-4000-8000-000000000000'],
      })
      .expect(400);
  });

  it('PATCH /users/:id replaces the whole store set and rejects an empty body', async () => {
    const created = await request(app.getHttpServer())
      .post('/users')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        phone: MANAGER_PHONE,
        name: 'Quan ly B',
        password: '123456',
        role: 'store_manager',
        storeIds: [store1Id],
        canLedger: true,
      })
      .expect(201);

    const updated = await request(app.getHttpServer())
      .patch(`/users/${created.body.id}`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ name: 'Quan ly B2', storeIds: [store2Id], active: false })
      .expect(200);

    expect(updated.body.name).toBe('Quan ly B2');
    expect(updated.body.storeIds).toEqual([store2Id]);
    expect(updated.body.active).toBe(false);

    // Sửa name/storeIds/active mà không đổi role thì không được ghi audit — tránh nhiễu.
    const noRoleChangeAudit = await prisma.auditLog.findFirst({
      where: { action: 'user_role_change', entityId: created.body.id },
    });
    expect(noRoleChangeAudit).toBeNull();

    await request(app.getHttpServer())
      .patch(`/users/${created.body.id}`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({})
      .expect(400);

    // Hạ xuống thu ngân thì cờ kế toán bị tắt theo.
    const demoted = await request(app.getHttpServer())
      .patch(`/users/${created.body.id}`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ role: 'cashier', active: true })
      .expect(200);
    expect(demoted.body.role).toBe('cashier');
    expect(demoted.body.canLedger).toBe(false);

    // Đổi role thật sự (store_manager -> cashier) phải ghi đúng 1 dòng audit.
    const roleChangeAudits = await prisma.auditLog.findMany({
      where: { action: 'user_role_change', entityId: created.body.id },
    });
    expect(roleChangeAudits).toHaveLength(1);
    expect(roleChangeAudits[0]).toMatchObject({
      actorUserId: ownerId,
      entityType: 'user',
    });
    expect(JSON.parse(roleChangeAudits[0].detailJson ?? '{}')).toMatchObject({
      fromRole: 'store_manager',
      toRole: 'cashier',
    });

    await request(app.getHttpServer())
      .patch(`/users/${created.body.id}`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ canLedger: true })
      .expect(400);
  });

  it('lets a user change only their own password', async () => {
    const cashier = await request(app.getHttpServer())
      .post('/users')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        phone: CASHIER_PHONE,
        name: 'Thu ngan A',
        password: '123456',
        role: 'cashier',
        storeIds: [store1Id],
      })
      .expect(201);

    const other = await request(app.getHttpServer())
      .post('/users')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        phone: MANAGER_PHONE,
        name: 'Quan ly B',
        password: '123456',
        role: 'store_manager',
        storeIds: [store1Id],
      })
      .expect(201);

    const cashierToken = await login(CASHIER_PHONE, '123456');

    // Tự đổi mật khẩu của chính mình phải kèm currentPassword đúng.
    await request(app.getHttpServer())
      .patch(`/users/${cashier.body.id}/password`)
      .set('Authorization', `Bearer ${cashierToken}`)
      .send({ password: 'moi123456', currentPassword: '123456' })
      .expect(200);

    await login(CASHIER_PHONE, 'moi123456');

    // Tự đổi mật khẩu phải ghi audit user_password_reset với selfChange: true.
    const selfChangeAudit = await prisma.auditLog.findFirst({
      where: { action: 'user_password_reset', entityId: cashier.body.id },
    });
    expect(selfChangeAudit).toMatchObject({
      actorUserId: cashier.body.id,
      entityType: 'user',
    });
    expect(JSON.parse(selfChangeAudit?.detailJson ?? '{}')).toMatchObject({
      selfChange: true,
    });

    await request(app.getHttpServer())
      .patch(`/users/${other.body.id}/password`)
      .set('Authorization', `Bearer ${cashierToken}`)
      .send({ password: 'moi123456' })
      .expect(403);

    await request(app.getHttpServer())
      .patch(`/users/${cashier.body.id}/password`)
      .set('Authorization', `Bearer ${cashierToken}`)
      .send({ password: '12345', currentPassword: 'moi123456' })
      .expect(400);

    // Chủ đổi được mật khẩu của bất kỳ ai — không cần currentPassword (đường hồi phục).
    await request(app.getHttpServer())
      .patch(`/users/${other.body.id}/password`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ password: 'chudoi123' })
      .expect(200);
    await login(MANAGER_PHONE, 'chudoi123');

    // Owner reset mật khẩu người khác cũng phải ghi audit, với selfChange: false.
    const ownerResetAudit = await prisma.auditLog.findFirst({
      where: { action: 'user_password_reset', entityId: other.body.id },
    });
    expect(ownerResetAudit).toMatchObject({
      actorUserId: ownerId,
      entityType: 'user',
    });
    expect(JSON.parse(ownerResetAudit?.detailJson ?? '{}')).toMatchObject({
      selfChange: false,
    });
  });

  it('rejects self password change with wrong or missing currentPassword, and leaves the old password intact', async () => {
    const cashier = await request(app.getHttpServer())
      .post('/users')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        phone: CASHIER_PHONE,
        name: 'Thu ngan A',
        password: '123456',
        role: 'cashier',
        storeIds: [store1Id],
      })
      .expect(201);

    const cashierToken = await login(CASHIER_PHONE, '123456');

    // Sai currentPassword → 400, mật khẩu cũ vẫn dùng được.
    await request(app.getHttpServer())
      .patch(`/users/${cashier.body.id}/password`)
      .set('Authorization', `Bearer ${cashierToken}`)
      .send({ password: 'moi123456', currentPassword: 'saimatkhau' })
      .expect(400);
    await login(CASHIER_PHONE, '123456');

    // Thiếu currentPassword → 400, mật khẩu cũ vẫn dùng được.
    await request(app.getHttpServer())
      .patch(`/users/${cashier.body.id}/password`)
      .set('Authorization', `Bearer ${cashierToken}`)
      .send({ password: 'moi123456' })
      .expect(400);
    await login(CASHIER_PHONE, '123456');

    // Owner tự đổi mật khẩu của chính mình cũng phải kèm currentPassword đúng.
    await request(app.getHttpServer())
      .patch(`/users/${ownerId}/password`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ password: 'chusaimoi123' })
      .expect(400);
    await login(OWNER_PHONE, '123456');

    try {
      const changed = await request(app.getHttpServer())
        .patch(`/users/${ownerId}/password`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ password: 'chumoi123456', currentPassword: '123456' })
        .expect(200);
      expect(changed.body.id).toBe(ownerId);
      await login(OWNER_PHONE, 'chumoi123456');
    } finally {
      // Trả owner về mật khẩu seed trực tiếp qua Prisma để không phụ thuộc vào
      // endpoint đang test — các test/lần chạy khác cần đăng nhập lại bằng '123456'.
      const passwordHash = await bcrypt.hash('123456', 10);
      await prisma.user.update({
        where: { phone: OWNER_PHONE },
        data: { passwordHash },
      });
    }
    await login(OWNER_PHONE, '123456');
  });

  it('refuses to demote or deactivate the last active owner', async () => {
    const otherActiveOwners = await prisma.user.findMany({
      where: { role: Role.owner, active: true, phone: { not: OWNER_PHONE } },
      select: { id: true },
    });
    const otherIds = otherActiveOwners.map((user) => user.id);
    await prisma.user.updateMany({
      where: { id: { in: otherIds } },
      data: { active: false },
    });

    try {
      await request(app.getHttpServer())
        .patch(`/users/${ownerId}`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ role: 'store_manager' })
        .expect(400);

      await request(app.getHttpServer())
        .patch(`/users/${ownerId}`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ active: false })
        .expect(400);

      const stillOwner = await prisma.user.findUniqueOrThrow({
        where: { id: ownerId },
        select: { role: true, active: true },
      });
      expect(stillOwner.role).toBe(Role.owner);
      expect(stillOwner.active).toBe(true);
    } finally {
      await prisma.user.updateMany({
        where: { id: { in: otherIds } },
        data: { active: true },
      });
    }
  });

  it('denies user management to non-owners', async () => {
    const created = await request(app.getHttpServer())
      .post('/users')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        phone: MANAGER_PHONE,
        name: 'Quan ly B',
        password: '123456',
        role: 'store_manager',
        storeIds: [store1Id],
      })
      .expect(201);

    const managerToken = await login(MANAGER_PHONE, '123456');

    await request(app.getHttpServer())
      .post('/users')
      .set('Authorization', `Bearer ${managerToken}`)
      .send({
        phone: SPARE_PHONE,
        name: 'Thu ngan cua quan ly',
        password: '123456',
        role: 'cashier',
        storeIds: [store1Id],
      })
      .expect(403);

    await request(app.getHttpServer())
      .patch(`/users/${created.body.id}`)
      .set('Authorization', `Bearer ${managerToken}`)
      .send({ name: 'Tu doi ten' })
      .expect(403);
  });
});
