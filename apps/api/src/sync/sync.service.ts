import { ForbiddenException, Injectable } from '@nestjs/common';
import { PaymentMethod, Prisma, Role } from '@prisma/client';
import { randomUUID } from 'crypto';
import { AuthUser } from '../auth/jwt.strategy';
import { CustomersService } from '../customers/customers.service';
import { PrismaService } from '../prisma/prisma.service';
import { ProductsService } from '../products/products.service';
import { PushSaleDto } from './dto/push-sale.dto';

const PAYMENT_METHODS = new Set<string>(Object.values(PaymentMethod));

@Injectable()
export class SyncService {
  constructor(
    private readonly productsService: ProductsService,
    private readonly customersService: CustomersService,
    private readonly prisma: PrismaService,
  ) {}

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

  async pushSales(user: AuthUser, deviceId: string, sales: PushSaleDto[]) {
    const acceptedIds: string[] = [];
    const rejected: { id: string; reason: string }[] = [];

    for (const sale of sales) {
      const result = await this.processSale(user, deviceId, sale);
      if (result.accepted) {
        acceptedIds.push(sale.id);
      } else {
        rejected.push({ id: sale.id, reason: result.reason });
      }
    }

    return { acceptedIds, rejected };
  }

  private async processSale(
    user: AuthUser,
    deviceId: string,
    sale: PushSaleDto,
  ): Promise<{ accepted: true } | { accepted: false; reason: string }> {
    try {
      this.assertStoreAccess(user, sale.storeId);
    } catch {
      return { accepted: false, reason: 'store_forbidden' };
    }

    const validationError = this.validateSalePayload(sale);
    if (validationError) {
      return { accepted: false, reason: validationError };
    }

    const existing = await this.prisma.sale.findUnique({
      where: { id: sale.id },
    });
    if (existing) {
      return { accepted: true };
    }

    const shift = await this.prisma.shift.findUnique({
      where: { id: sale.shiftId },
    });
    if (!shift || shift.storeId !== sale.storeId) {
      return { accepted: false, reason: 'shift_not_found' };
    }

    if (sale.debtAmount > 0) {
      await this.ensureDebtCustomer(sale);
      const customer = await this.prisma.customer.findUnique({
        where: { id: sale.customerId! },
      });
      if (!customer) {
        return { accepted: false, reason: 'customer_not_found' };
      }
    }

    try {
      await this.prisma.$transaction(async (tx) => {
        for (const line of sale.lines) {
          const stock = await tx.productStoreStock.findUnique({
            where: {
              productId_storeId: {
                productId: line.productId,
                storeId: sale.storeId,
              },
            },
          });
          if (!stock) {
            throw new Error('insufficient_stock');
          }

          const currentQty = new Prisma.Decimal(stock.qty.toString());
          const soldQty = new Prisma.Decimal(line.qty);
          const newQty = currentQty.minus(soldQty);
          if (newQty.lessThan(0)) {
            throw new Error('insufficient_stock');
          }

          await tx.productStoreStock.update({
            where: {
              productId_storeId: {
                productId: line.productId,
                storeId: sale.storeId,
              },
            },
            data: { qty: newQty },
          });
        }

        await tx.sale.create({
          data: {
            id: sale.id,
            storeId: sale.storeId,
            shiftId: sale.shiftId,
            soldById: sale.soldById,
            paymentMethod: sale.paymentMethod as PaymentMethod,
            cashAmount: sale.cashAmount,
            transferAmount: sale.transferAmount,
            debtAmount: sale.debtAmount,
            discountVnd: sale.discountVnd,
            totalVnd: sale.totalVnd,
            customerId: sale.customerId ?? null,
            clientCreatedAt: new Date(sale.clientCreatedAt),
            lines: {
              create: sale.lines.map((line) => ({
                id: randomUUID(),
                productId: line.productId,
                qty: new Prisma.Decimal(line.qty),
                unitPrice: line.unitPrice,
                lineTotal: line.lineTotal,
              })),
            },
          },
        });

        if (sale.debtAmount > 0 && sale.customerId) {
          await tx.customer.update({
            where: { id: sale.customerId },
            data: { balanceVnd: { increment: sale.debtAmount } },
          });
        }

        await tx.syncCursor.upsert({
          where: { deviceId },
          create: {
            deviceId,
            userId: user.userId,
            lastPullAt: new Date(0),
          },
          update: {},
        });
      });
      return { accepted: true };
    } catch (error) {
      if (error instanceof Error && error.message === 'insufficient_stock') {
        return { accepted: false, reason: 'insufficient_stock' };
      }
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        const raced = await this.prisma.sale.findUnique({
          where: { id: sale.id },
        });
        if (raced) {
          return { accepted: true };
        }
      }
      throw error;
    }
  }

  private async ensureDebtCustomer(sale: PushSaleDto): Promise<void> {
    const customerId = sale.customerId?.trim();
    if (!customerId || !sale.customer || sale.customer.id !== customerId) {
      return;
    }
    const name = sale.customer.name?.trim();
    if (!name) {
      return;
    }
    await this.customersService.create({
      id: customerId,
      name,
      phone: sale.customer.phone ?? null,
    });
  }

  private validateSalePayload(sale: PushSaleDto): string | null {
    if (!sale.id || !sale.storeId || !sale.shiftId || !sale.soldById) {
      return 'invalid_payload';
    }
    if (!PAYMENT_METHODS.has(sale.paymentMethod)) {
      return 'invalid_payload';
    }
    if (!Array.isArray(sale.lines) || sale.lines.length === 0) {
      return 'invalid_payload';
    }
    if (Number.isNaN(Date.parse(sale.clientCreatedAt))) {
      return 'invalid_payload';
    }

    const paymentTotal =
      sale.cashAmount + sale.transferAmount + sale.debtAmount;
    if (paymentTotal !== sale.totalVnd) {
      return 'payment_mismatch';
    }

    if (sale.debtAmount > 0) {
      if (!sale.customerId || sale.customerId.trim() === '') {
        return 'customer_required';
      }
    }

    for (const line of sale.lines) {
      if (!line.productId || !line.qty) {
        return 'invalid_payload';
      }
      try {
        new Prisma.Decimal(line.qty);
      } catch {
        return 'invalid_payload';
      }
    }

    return null;
  }
}
