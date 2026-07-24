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

  async findForUser(role: Role, storeIds: string[]) {
    if (role === Role.owner) {
      return this.prisma.store.findMany({
        where: { active: true },
        select: {
          id: true,
          code: true,
          name: true,
          debtOverdueDays: true,
        },
        orderBy: { code: 'asc' },
      });
    }
    return this.prisma.store.findMany({
      where: { active: true, id: { in: storeIds } },
      select: {
        id: true,
        code: true,
        name: true,
        debtOverdueDays: true,
      },
      orderBy: { code: 'asc' },
    });
  }

  async setDebtOverdueDays(user: AuthUser, storeId: string, days: number) {
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('Only owner or store_manager');
    }
    if (user.role !== Role.owner && !user.storeIds.includes(storeId)) {
      throw new ForbiddenException('No access to this store');
    }
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
}
