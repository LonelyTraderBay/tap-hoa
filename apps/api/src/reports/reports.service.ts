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

export type TopSkuItem = {
  productId: string;
  sku: string;
  name: string;
  qty: number;
  revenueVnd: number;
  estimatedGrossVnd: number | null;
};

export type TopSkusResponse = {
  date: string;
  items: TopSkuItem[];
};

const ICT_OFFSET_HOURS = 7;

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
    const probe = new Date(Date.UTC(year, month - 1, day, 12, 0, 0, 0));
    if (
      probe.getUTCFullYear() !== year ||
      probe.getUTCMonth() !== month - 1 ||
      probe.getUTCDate() !== day
    ) {
      throw new BadRequestException('date must be YYYY-MM-DD');
    }
    const start = new Date(
      Date.UTC(year, month - 1, day, -ICT_OFFSET_HOURS, 0, 0, 0),
    );
    const end = new Date(
      Date.UTC(year, month - 1, day + 1, -ICT_OFFSET_HOURS, 0, 0, 0),
    );
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

  async topSkus(
    user: AuthUser,
    date: string,
    storeId?: string,
    limit?: number,
  ): Promise<TopSkusResponse> {
    const { start, end } = this.parseDateRange(date);
    const storeIds = await this.resolveStoreIds(user, storeId);
    const effectiveLimit = Math.min(Math.max(limit ?? 10, 1), 50);

    if (storeIds.length === 0) {
      return { date, items: [] };
    }

    const lines = await this.prisma.saleLine.findMany({
      where: {
        sale: {
          storeId: { in: storeIds },
          clientCreatedAt: { gte: start, lt: end },
        },
      },
      select: {
        productId: true,
        qty: true,
        lineTotal: true,
      },
    });

    type Agg = {
      productId: string;
      qty: number;
      revenueVnd: number;
    };

    const byProduct = new Map<string, Agg>();

    for (const line of lines) {
      const qtyNum = Number(line.qty);
      let agg = byProduct.get(line.productId);
      if (!agg) {
        agg = {
          productId: line.productId,
          qty: 0,
          revenueVnd: 0,
        };
        byProduct.set(line.productId, agg);
      }
      agg.qty += qtyNum;
      agg.revenueVnd += line.lineTotal;
    }

    if (byProduct.size === 0) {
      return { date, items: [] };
    }

    const productIds = [...byProduct.keys()];
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds } },
      select: { id: true, sku: true, name: true, costVnd: true },
    });
    const productById = new Map(products.map((product) => [product.id, product]));

    const items: TopSkuItem[] = [...byProduct.values()]
      .map((agg) => {
        const product = productById.get(agg.productId);
        return {
          productId: agg.productId,
          sku: product?.sku ?? '',
          name: product?.name ?? '',
          qty: agg.qty,
          revenueVnd: agg.revenueVnd,
          estimatedGrossVnd: product
            ? agg.revenueVnd - agg.qty * product.costVnd
            : null,
        };
      })
      .sort((a, b) => {
        if (b.qty !== a.qty) {
          return b.qty - a.qty;
        }
        return b.revenueVnd - a.revenueVnd;
      })
      .slice(0, effectiveLimit);

    return { date, items };
  }
}
