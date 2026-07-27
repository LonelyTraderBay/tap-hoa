import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { randomUUID } from 'crypto';
import { AuthUser } from '../auth/jwt.strategy';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateUserData,
  SetPasswordData,
  UpdateUserData,
  assertCashierPermissionFlags,
} from './user-validation';

const BCRYPT_ROUNDS = 10;

type UserRow = {
  id: string;
  phone: string;
  name: string;
  role: Role;
  canLedger: boolean;
  canEinvoice: boolean;
  active: boolean;
  stores: { storeId: string }[];
};

export type PublicUser = {
  id: string;
  phone: string;
  name: string;
  role: Role;
  canLedger: boolean;
  canEinvoice: boolean;
  active: boolean;
  storeIds: string[];
};

/** Shape duy nhất trả ra ngoài — không bao giờ kèm passwordHash. */
export function toPublicUser(user: UserRow): PublicUser {
  return {
    id: user.id,
    phone: user.phone,
    name: user.name,
    role: user.role,
    canLedger: user.canLedger,
    canEinvoice: user.canEinvoice,
    active: user.active,
    storeIds: user.stores.map((store) => store.storeId),
  };
}

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  private userSelect = {
    id: true,
    phone: true,
    name: true,
    role: true,
    canLedger: true,
    canEinvoice: true,
    active: true,
    stores: { select: { storeId: true } },
  } as const;

  private userOrderBy = [
    { name: 'asc' },
    { phone: 'asc' },
  ] as Prisma.UserOrderByWithRelationInput[];

  async findForUser(user: AuthUser): Promise<PublicUser[]> {
    if (user.role === Role.owner) {
      const users = await this.prisma.user.findMany({
        select: this.userSelect,
        orderBy: this.userOrderBy,
      });
      return users.map(toPublicUser);
    }
    if (user.role === Role.store_manager) {
      const users = await this.prisma.user.findMany({
        where: { stores: { some: { storeId: { in: user.storeIds } } } },
        select: this.userSelect,
        orderBy: this.userOrderBy,
      });
      return users.map(toPublicUser);
    }
    throw new ForbiddenException('Only owner or store_manager');
  }

  async create(actor: AuthUser, data: CreateUserData): Promise<PublicUser> {
    this.assertOwner(actor);
    await this.assertStoresExist(data.storeIds);
    const passwordHash = await bcrypt.hash(data.password, BCRYPT_ROUNDS);
    try {
      const created = await this.prisma.$transaction(async (tx) => {
        const user = await tx.user.create({
          data: {
            phone: data.phone,
            name: data.name,
            passwordHash,
            role: data.role,
            canLedger: data.canLedger,
            canEinvoice: data.canEinvoice,
            stores: {
              create: data.storeIds.map((storeId) => ({ storeId })),
            },
          },
          select: this.userSelect,
        });
        // Không log password/passwordHash — chỉ những gì cần cho việc kiểm toán ai
        // tạo tài khoản nào với vai trò/điểm bán gì.
        await tx.auditLog.create({
          data: {
            id: randomUUID(),
            actorUserId: actor.userId,
            action: 'user_create',
            entityType: 'user',
            entityId: user.id,
            detailJson: JSON.stringify({
              phone: user.phone,
              role: user.role,
              storeIds: user.stores.map((s) => s.storeId),
            }),
          },
        });
        return user;
      });
      return toPublicUser(created);
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException('Phone already exists');
      }
      throw error;
    }
  }

  async update(
    actor: AuthUser,
    userId: string,
    data: UpdateUserData,
  ): Promise<PublicUser> {
    this.assertOwner(actor);
    const target = await this.prisma.user.findUnique({
      where: { id: userId },
      select: this.userSelect,
    });
    if (!target) {
      throw new NotFoundException('User not found');
    }

    if (data.active === false && target.id === actor.userId) {
      throw new BadRequestException('Cannot deactivate your own account');
    }

    const nextRole = data.role ?? target.role;
    const losesLastOwner =
      target.role === Role.owner &&
      target.active &&
      (nextRole !== Role.owner || data.active === false);
    if (losesLastOwner) {
      const activeOwners = await this.prisma.user.count({
        where: { role: Role.owner, active: true },
      });
      if (activeOwners <= 1) {
        throw new BadRequestException('At least one active owner is required');
      }
    }

    // Hạ vai trò xuống thu ngân thì cờ kế toán tự tắt; cố tình bật thì báo lỗi.
    const nextCanLedger =
      nextRole === Role.cashier ? false : (data.canLedger ?? target.canLedger);
    const nextCanEinvoice =
      nextRole === Role.cashier
        ? false
        : (data.canEinvoice ?? target.canEinvoice);
    assertCashierPermissionFlags(
      nextRole,
      data.canLedger ?? false,
      data.canEinvoice ?? false,
    );

    if (data.storeIds) {
      await this.assertStoresExist(data.storeIds);
    }

    const roleChanged = data.role !== undefined && data.role !== target.role;
    const storeIds = data.storeIds;
    const updated = await this.prisma.$transaction(async (tx) => {
      if (storeIds) {
        await tx.userStore.deleteMany({ where: { userId } });
        await tx.userStore.createMany({
          data: storeIds.map((storeId) => ({ userId, storeId })),
        });
      }
      const user = await tx.user.update({
        where: { id: userId },
        data: {
          ...(data.name !== undefined ? { name: data.name } : {}),
          ...(data.role !== undefined ? { role: data.role } : {}),
          ...(data.active !== undefined ? { active: data.active } : {}),
          canLedger: nextCanLedger,
          canEinvoice: nextCanEinvoice,
        },
        select: this.userSelect,
      });
      // Chỉ log khi vai trò thực sự đổi — sửa tên/cờ quyền/điểm bán/active không
      // phải là mục tiêu của task này, tránh nhiễu nhật ký kiểm toán.
      if (roleChanged) {
        await tx.auditLog.create({
          data: {
            id: randomUUID(),
            actorUserId: actor.userId,
            action: 'user_role_change',
            entityType: 'user',
            entityId: userId,
            detailJson: JSON.stringify({
              fromRole: target.role,
              toRole: data.role,
            }),
          },
        });
      }
      return user;
    });
    return toPublicUser(updated);
  }

  async setPassword(
    actor: AuthUser,
    userId: string,
    data: SetPasswordData,
  ): Promise<PublicUser> {
    if (actor.role !== Role.owner && actor.userId !== userId) {
      throw new ForbiddenException('Only owner can change other passwords');
    }

    if (actor.userId === userId) {
      // Tự đổi mật khẩu của chính mình (kể cả owner) phải chứng minh biết mật khẩu
      // hiện tại — nếu không, một phiên đăng nhập bị bỏ quên/chiếm dụng có thể khóa
      // vĩnh viễn tài khoản thật bằng cách đặt mật khẩu mới mà chủ tài khoản không biết.
      // `userSelect` không kèm passwordHash (không bao giờ lộ ra response công khai)
      // nên phải truy vấn riêng ở đây.
      const current = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { passwordHash: true },
      });
      if (!current) {
        throw new NotFoundException('User not found');
      }
      const matches =
        data.currentPassword !== undefined &&
        (await bcrypt.compare(data.currentPassword, current.passwordHash));
      if (!matches) {
        throw new BadRequestException('current_password_incorrect');
      }
    }

    const passwordHash = await bcrypt.hash(data.password, BCRYPT_ROUNDS);
    try {
      const updated = await this.prisma.$transaction(async (tx) => {
        const user = await tx.user.update({
          where: { id: userId },
          data: { passwordHash },
          select: this.userSelect,
        });
        await tx.auditLog.create({
          data: {
            id: randomUUID(),
            actorUserId: actor.userId,
            action: 'user_password_reset',
            entityType: 'user',
            entityId: userId,
            detailJson: JSON.stringify({
              selfChange: actor.userId === userId,
            }),
          },
        });
        return user;
      });
      return toPublicUser(updated);
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2025'
      ) {
        throw new NotFoundException('User not found');
      }
      throw error;
    }
  }

  private assertOwner(user: AuthUser) {
    if (user.role !== Role.owner) {
      throw new ForbiddenException('Only owner');
    }
  }

  private async assertStoresExist(storeIds: string[]) {
    const found = await this.prisma.store.count({
      where: { id: { in: storeIds } },
    });
    if (found !== storeIds.length) {
      throw new BadRequestException('storeIds contains an unknown store');
    }
  }
}
