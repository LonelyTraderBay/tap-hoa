import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, Role } from '@prisma/client';
import { AuthUser } from '../auth/jwt.strategy';
import { PrismaService } from '../prisma/prisma.service';

type StoreMutationData = {
  code?: string;
  name?: string;
  debtOverdueDays?: number;
  largeDebtThresholdVnd?: number | null;
};

@Injectable()
export class StoresService {
  constructor(private readonly prisma: PrismaService) {}

  private storeSelect = {
    id: true,
    code: true,
    name: true,
    active: true,
    debtOverdueDays: true,
    largeDebtThresholdVnd: true,
    vatEnabled: true,
    defaultVatRateBps: true,
    allowNegativeStock: true,
    updatedAt: true,
  } as const;

  async findForUser(role: Role, storeIds: string[]) {
    if (role === Role.owner) {
      return this.prisma.store.findMany({
        where: { active: true },
        select: this.storeSelect,
        orderBy: { code: 'asc' },
      });
    }
    return this.prisma.store.findMany({
      where: { active: true, id: { in: storeIds } },
      select: this.storeSelect,
      orderBy: { code: 'asc' },
    });
  }

  private assertOwner(user: AuthUser) {
    if (user.role !== Role.owner) {
      throw new ForbiddenException('Only owner');
    }
  }

  private assertStoreManage(user: AuthUser, storeId: string) {
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('Only owner or store_manager');
    }
    if (user.role !== Role.owner && !user.storeIds.includes(storeId)) {
      throw new ForbiddenException('No access to this store');
    }
  }

  async create(user: AuthUser, data: StoreMutationData) {
    this.assertOwner(user);
    if (!data.code || !data.name) {
      throw new BadRequestException('code and name are required');
    }
    try {
      return await this.prisma.store.create({
        data: {
          code: data.code,
          name: data.name,
          ...(data.debtOverdueDays !== undefined
            ? { debtOverdueDays: data.debtOverdueDays }
            : {}),
          ...(data.largeDebtThresholdVnd !== undefined
            ? { largeDebtThresholdVnd: data.largeDebtThresholdVnd }
            : {}),
        },
        select: this.storeSelect,
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new BadRequestException('Store code already exists');
      }
      throw error;
    }
  }

  async update(user: AuthUser, storeId: string, data: StoreMutationData) {
    this.assertOwner(user);
    try {
      return await this.prisma.store.update({
        where: { id: storeId },
        data,
        select: this.storeSelect,
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new BadRequestException('Store code already exists');
      }
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2025'
      ) {
        throw new NotFoundException('Store not found');
      }
      throw error;
    }
  }

  async setDebtOverdueDays(user: AuthUser, storeId: string, days: number) {
    this.assertStoreManage(user, storeId);
    try {
      return await this.prisma.store.update({
        where: { id: storeId },
        data: { debtOverdueDays: days },
        select: { id: true, debtOverdueDays: true },
      });
    } catch {
      throw new NotFoundException('Store not found');
    }
  }

  async setAllowNegativeStock(
    user: AuthUser,
    storeId: string,
    allowNegativeStock: boolean,
  ) {
    this.assertStoreManage(user, storeId);
    try {
      return await this.prisma.store.update({
        where: { id: storeId },
        data: { allowNegativeStock },
        select: { id: true, allowNegativeStock: true },
      });
    } catch {
      throw new NotFoundException('Store not found');
    }
  }

  async setVatSettings(
    user: AuthUser,
    storeId: string,
    data: { vatEnabled?: boolean; defaultVatRateBps?: number },
  ) {
    this.assertStoreManage(user, storeId);
    try {
      return await this.prisma.store.update({
        where: { id: storeId },
        data: {
          ...(data.vatEnabled !== undefined
            ? { vatEnabled: data.vatEnabled }
            : {}),
          ...(data.defaultVatRateBps !== undefined
            ? { defaultVatRateBps: data.defaultVatRateBps }
            : {}),
        },
        select: {
          id: true,
          vatEnabled: true,
          defaultVatRateBps: true,
        },
      });
    } catch {
      throw new NotFoundException('Store not found');
    }
  }
}
