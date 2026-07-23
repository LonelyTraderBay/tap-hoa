import { ForbiddenException, Injectable } from '@nestjs/common';
import { Role } from '@prisma/client';
import { AuthUser } from '../auth/jwt.strategy';
import { ProductsService } from '../products/products.service';

@Injectable()
export class SyncService {
  constructor(private readonly productsService: ProductsService) {}

  private assertStoreAccess(user: AuthUser, storeId: string) {
    if (user.role === Role.owner) {
      return;
    }
    if (!user.storeIds.includes(storeId)) {
      throw new ForbiddenException('No access to this store');
    }
  }

  async pull(user: AuthUser, storeId: string, since: Date) {
    this.assertStoreAccess(user, storeId);

    const [products, stocks] = await Promise.all([
      this.productsService.findUpdatedSince(since),
      this.productsService.findStocksForStoreSince(storeId, since),
    ]);

    return {
      products: products.map((product) => ({
        id: product.id,
        sku: product.sku,
        barcode: product.barcode,
        name: product.name,
        unit: product.unit,
        isWeighted: product.isWeighted,
        basePriceVnd: product.basePriceVnd,
        costVnd: product.costVnd,
        active: product.active,
        updatedAt: product.updatedAt.toISOString(),
      })),
      stocks: stocks.map((stock) => ({
        productId: stock.productId,
        storeId: stock.storeId,
        qty: stock.qty.toString(),
        minQty: stock.minQty.toString(),
        updatedAt: stock.updatedAt.toISOString(),
      })),
      serverTime: new Date().toISOString(),
    };
  }
}
