import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ProductsService {
  constructor(private readonly prisma: PrismaService) {}

  async findUpdatedSince(since: Date) {
    return this.prisma.product.findMany({
      where: { updatedAt: { gt: since } },
      orderBy: { sku: 'asc' },
    });
  }

  async findStocksForStoreSince(storeId: string, since: Date) {
    return this.prisma.productStoreStock.findMany({
      where: { storeId, updatedAt: { gt: since } },
      orderBy: { productId: 'asc' },
    });
  }
}
