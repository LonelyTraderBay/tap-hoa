import { Injectable } from '@nestjs/common';
import { Prisma, Role } from '@prisma/client';
import { AuthUser } from '../auth/jwt.strategy';
import { PrismaService } from '../prisma/prisma.service';
import { PushProductUpsertDto } from '../sync/dto/push-sale.dto';

type RejectResult = { accepted: false; reason: string };
type AcceptResult = { accepted: true };
type ProcessResult = AcceptResult | RejectResult;

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

  private canAccessStore(user: AuthUser, storeId: string): boolean {
    return user.role === Role.owner || user.storeIds.includes(storeId);
  }

  private isManagerOrOwner(user: AuthUser): boolean {
    return user.role === Role.owner || user.role === Role.store_manager;
  }

  private parseNonNegativeQty(raw: string): Prisma.Decimal | null {
    try {
      const qty = new Prisma.Decimal(raw);
      if (!qty.isFinite() || qty.lessThan(0)) {
        return null;
      }
      return qty;
    } catch {
      return null;
    }
  }

  async upsertFromSync(
    user: AuthUser,
    dto: PushProductUpsertDto,
  ): Promise<ProcessResult> {
    if (!dto.id || !dto.storeId) {
      return { accepted: false, reason: 'invalid_product' };
    }

    if (!this.canAccessStore(user, dto.storeId)) {
      return { accepted: false, reason: 'store_forbidden' };
    }
    if (!this.isManagerOrOwner(user)) {
      return { accepted: false, reason: 'role_forbidden' };
    }

    const sku = dto.sku?.trim() ?? '';
    const name = dto.name?.trim() ?? '';
    const unit = dto.unit?.trim() ?? '';
    if (!sku || !name || !unit) {
      return { accepted: false, reason: 'invalid_product' };
    }
    if (
      !Number.isSafeInteger(dto.basePriceVnd) ||
      dto.basePriceVnd < 0
    ) {
      return { accepted: false, reason: 'invalid_product' };
    }
    const costVnd = dto.costVnd ?? 0;
    if (!Number.isSafeInteger(costVnd) || costVnd < 0) {
      return { accepted: false, reason: 'invalid_product' };
    }

    let seedQty: Prisma.Decimal | null = null;
    let seedMinQty: Prisma.Decimal | null = null;
    if (dto.seedStock != null) {
      seedQty = this.parseNonNegativeQty(dto.seedStock.qty);
      if (seedQty == null) {
        return { accepted: false, reason: 'invalid_product' };
      }
      if (dto.seedStock.minQty != null) {
        seedMinQty = this.parseNonNegativeQty(dto.seedStock.minQty);
        if (seedMinQty == null) {
          return { accepted: false, reason: 'invalid_product' };
        }
      }
    }

    const barcode =
      dto.barcode == null || dto.barcode.trim() === ''
        ? null
        : dto.barcode.trim();

    const skuConflict = await this.prisma.product.findFirst({
      where: { sku, id: { not: dto.id } },
    });
    if (skuConflict) {
      return { accepted: false, reason: 'sku_conflict' };
    }

    if (barcode) {
      const barcodeConflict = await this.prisma.product.findFirst({
        where: { barcode, id: { not: dto.id } },
      });
      if (barcodeConflict) {
        return { accepted: false, reason: 'barcode_conflict' };
      }
    }

    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.product.upsert({
          where: { id: dto.id },
          create: {
            id: dto.id,
            sku,
            barcode,
            name,
            unit,
            isWeighted: dto.isWeighted,
            basePriceVnd: dto.basePriceVnd,
            costVnd,
            active: dto.active,
          },
          update: {
            sku,
            barcode,
            name,
            unit,
            isWeighted: dto.isWeighted,
            basePriceVnd: dto.basePriceVnd,
            costVnd,
            active: dto.active,
          },
        });

        if (dto.seedStock != null && seedQty != null) {
          const existing = await tx.productStoreStock.findUnique({
            where: {
              productId_storeId: {
                productId: dto.id,
                storeId: dto.storeId,
              },
            },
          });
          if (!existing) {
            await tx.productStoreStock.create({
              data: {
                productId: dto.id,
                storeId: dto.storeId,
                qty: seedQty,
                minQty: seedMinQty ?? new Prisma.Decimal(0),
              },
            });
          } else if (seedMinQty != null) {
            await tx.productStoreStock.update({
              where: {
                productId_storeId: {
                  productId: dto.id,
                  storeId: dto.storeId,
                },
              },
              data: { minQty: seedMinQty },
            });
          }
        }
      });
      return { accepted: true };
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError) {
        if (error.code === 'P2002') {
          const target = error.meta?.target;
          const fields = Array.isArray(target)
            ? target.map(String)
            : typeof target === 'string'
              ? [target]
              : [];
          if (fields.some((f) => f.includes('sku'))) {
            return { accepted: false, reason: 'sku_conflict' };
          }
          if (fields.some((f) => f.includes('barcode'))) {
            return { accepted: false, reason: 'barcode_conflict' };
          }
        }
      }
      throw error;
    }
  }
}
