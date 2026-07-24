import { Injectable } from '@nestjs/common';
import { Prisma, Role } from '@prisma/client';
import { randomUUID } from 'crypto';
import { AuthUser } from '../auth/jwt.strategy';
import { PrismaService } from '../prisma/prisma.service';
import {
  PushProductGroupUpsertDto,
  PushProductUpsertDto,
} from '../sync/dto/push-sale.dto';

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

  async findGroupsUpdatedSince(since: Date) {
    return this.prisma.productGroup.findMany({
      where: { updatedAt: { gt: since } },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    });
  }

  async findComboComponentsUpdated(since: Date) {
    const products = await this.prisma.product.findMany({
      where: { kind: 'combo', updatedAt: { gt: since } },
      select: { id: true },
    });
    if (products.length === 0) {
      return this.prisma.productComboComponent.findMany({
        take: 0,
      });
    }
    return this.prisma.productComboComponent.findMany({
      where: { comboProductId: { in: products.map((p) => p.id) } },
    });
  }

  async findAllComboComponents() {
    return this.prisma.productComboComponent.findMany();
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

  async upsertGroupFromSync(
    user: AuthUser,
    dto: PushProductGroupUpsertDto,
  ): Promise<ProcessResult> {
    if (!this.isManagerOrOwner(user)) {
      return { accepted: false, reason: 'role_forbidden' };
    }
    const name = dto.name?.trim() ?? '';
    if (!dto.id || !name) {
      return { accepted: false, reason: 'invalid_product_group' };
    }
    await this.prisma.productGroup.upsert({
      where: { id: dto.id },
      create: {
        id: dto.id,
        name,
        sortOrder: dto.sortOrder ?? 0,
        active: dto.active ?? true,
      },
      update: {
        name,
        sortOrder: dto.sortOrder ?? 0,
        active: dto.active ?? true,
      },
    });
    return { accepted: true };
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
    if (!Number.isSafeInteger(dto.basePriceVnd) || dto.basePriceVnd < 0) {
      return { accepted: false, reason: 'invalid_product' };
    }
    const costVnd = dto.costVnd ?? 0;
    if (!Number.isSafeInteger(costVnd) || costVnd < 0) {
      return { accepted: false, reason: 'invalid_product' };
    }

    const kind = dto.kind === 'combo' ? 'combo' : 'normal';
    let packSize: Prisma.Decimal | null = null;
    if (dto.packSize != null && dto.packSize !== '') {
      packSize = this.parseNonNegativeQty(dto.packSize);
      if (packSize == null || packSize.lessThanOrEqualTo(0)) {
        return { accepted: false, reason: 'invalid_product' };
      }
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
    const sellUnit =
      dto.sellUnit == null || dto.sellUnit.trim() === ''
        ? null
        : dto.sellUnit.trim();
    const groupId =
      dto.groupId == null || dto.groupId.trim() === ''
        ? null
        : dto.groupId.trim();

    if (groupId) {
      const group = await this.prisma.productGroup.findUnique({
        where: { id: groupId },
      });
      if (!group) {
        return { accepted: false, reason: 'invalid_group' };
      }
    }

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

    const components = dto.components ?? [];
    if (kind === 'combo') {
      if (components.length === 0) {
        return { accepted: false, reason: 'invalid_combo' };
      }
      for (const c of components) {
        const qty = this.parseNonNegativeQty(c.qtyBase);
        if (!c.componentProductId || qty == null || qty.lessThanOrEqualTo(0)) {
          return { accepted: false, reason: 'invalid_combo' };
        }
        if (c.componentProductId === dto.id) {
          return { accepted: false, reason: 'invalid_combo' };
        }
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
            sellUnit,
            packSize,
            kind,
            groupId,
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
            sellUnit,
            packSize,
            kind,
            groupId,
            isWeighted: dto.isWeighted,
            basePriceVnd: dto.basePriceVnd,
            costVnd,
            active: dto.active,
          },
        });

        if (kind === 'combo') {
          await tx.productComboComponent.deleteMany({
            where: { comboProductId: dto.id },
          });
          for (const c of components) {
            await tx.productComboComponent.create({
              data: {
                id: c.id ?? randomUUID(),
                comboProductId: dto.id,
                componentProductId: c.componentProductId,
                qtyBase: new Prisma.Decimal(c.qtyBase),
              },
            });
          }
        } else {
          await tx.productComboComponent.deleteMany({
            where: { comboProductId: dto.id },
          });
        }

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
