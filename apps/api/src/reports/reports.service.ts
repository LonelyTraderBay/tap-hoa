import {
  BadRequestException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { AuthUser } from '../auth/jwt.strategy';
import { PrismaService } from '../prisma/prisma.service';

export type StoreDayReport = {
  storeId: string;
  revenueVnd: number;
  orderCount: number;
  cashVnd: number;
  transferVnd: number;
  debtVnd: number;
};

export type DayReportResponse = {
  byStore: StoreDayReport[];
  totalRevenueVnd: number;
};

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  private assertStoreAccess(user: AuthUser, storeId: string) {
    if (user.role === Role.owner) {
      return;
    }
    if (!user.storeIds.includes(storeId)) {
      throw new ForbiddenException('No access to this store');
    }
  }

  private parseDateRange(date: string): { start: Date; end: Date } {
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(date);
    if (!match) {
      throw new BadRequestException('date must be YYYY-MM-DD');
    }
    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);
    const start = new Date(Date.UTC(year, month - 1, day));
    const end = new Date(Date.UTC(year, month - 1, day + 1));
    if (
      start.getUTCFullYear() !== year ||
      start.getUTCMonth() !== month - 1 ||
      start.getUTCDate() !== day
    ) {
      throw new BadRequestException('date must be YYYY-MM-DD');
    }
    return { start, end };
  }

  private async resolveStoreIds(
    user: AuthUser,
    storeId?: string,
  ): Promise<string[]> {
    if (storeId) {
      this.assertStoreAccess(user, storeId);
      return [storeId];
    }
    if (user.role === Role.owner) {
      const stores = await this.prisma.store.findMany({
        where: { active: true },
        select: { id: true },
      });
      return stores.map((store) => store.id);
    }
    return user.storeIds;
  }

  async dayReport(
    user: AuthUser,
    date: string,
    storeId?: string,
  ): Promise<DayReportResponse> {
    const { start, end } = this.parseDateRange(date);
    const storeIds = await this.resolveStoreIds(user, storeId);

    if (storeIds.length === 0) {
      return { byStore: [], totalRevenueVnd: 0 };
    }

    const grouped = await this.prisma.sale.groupBy({
      by: ['storeId'],
      where: {
        storeId: { in: storeIds },
        clientCreatedAt: { gte: start, lt: end },
      },
      _sum: {
        totalVnd: true,
        cashAmount: true,
        transferAmount: true,
        debtAmount: true,
      },
      _count: { id: true },
    });

    const byStore: StoreDayReport[] = grouped.map((row) => ({
      storeId: row.storeId,
      revenueVnd: row._sum.totalVnd ?? 0,
      orderCount: row._count.id,
      cashVnd: row._sum.cashAmount ?? 0,
      transferVnd: row._sum.transferAmount ?? 0,
      debtVnd: row._sum.debtAmount ?? 0,
    }));

    byStore.sort((a, b) => a.storeId.localeCompare(b.storeId));

    const totalRevenueVnd = byStore.reduce(
      (sum, row) => sum + row.revenueVnd,
      0,
    );

    return { byStore, totalRevenueVnd };
  }
}
