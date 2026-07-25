import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { AuthUser } from '../auth/jwt.strategy';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class StoresService {
  constructor(private readonly prisma: PrismaService) {}

  private storeSelect = {
    id: true,
    code: true,
    name: true,
    debtOverdueDays: true,
    vatEnabled: true,
    defaultVatRateBps: true,
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

  private assertStoreManage(user: AuthUser, storeId: string) {
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('Only owner or store_manager');
    }
    if (user.role !== Role.owner && !user.storeIds.includes(storeId)) {
      throw new ForbiddenException('No access to this store');
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
