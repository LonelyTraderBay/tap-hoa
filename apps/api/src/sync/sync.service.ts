import { ForbiddenException, Injectable } from '@nestjs/common';
import { PaymentMethod, Prisma, Role } from '@prisma/client';
import { randomUUID } from 'crypto';
import { AuthUser } from '../auth/jwt.strategy';
import { CustomersService } from '../customers/customers.service';
import { PrismaService } from '../prisma/prisma.service';
import { ProductsService } from '../products/products.service';
import { ShiftsService } from '../shifts/shifts.service';
import {
  PushSaleDto,
  PushShiftCloseDto,
  PushShiftOpenDto,
  PushSyncDto,
} from './dto/push-sale.dto';

const PAYMENT_METHODS = new Set<string>(Object.values(PaymentMethod));

@Injectable()
export class SyncService {
  constructor(
    private readonly productsService: ProductsService,
    private readonly customersService: CustomersService,
    private readonly prisma: PrismaService,
    private readonly shiftsService: ShiftsService,
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
    const serverTime = new Date();

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
      serverTime: serverTime.toISOString(),
    };
  }

  async push(user: AuthUser, body: PushSyncDto) {
    const acceptedShiftIds: string[] = [];
    const rejectedShifts: { id: string; reason: string }[] = [];
    for (const shift of body.shiftOpens ?? []) {
      const reason = await this.processShiftOpen(user, shift);
      if (reason) {
        rejectedShifts.push({ id: shift.id, reason });
      } else {
        acceptedShiftIds.push(shift.id);
      }
    }

    const salesResult = await this.pushSales(user, body.deviceId, body.sales);

    const acceptedShiftCloseIds: string[] = [];
    for (const shift of body.shiftCloses ?? []) {
      const reason = await this.processShiftClose(user, shift);
      if (reason) {
        rejectedShifts.push({ id: shift.id, reason });
      } else {
        acceptedShiftCloseIds.push(shift.id);
      }
    }

    return {
      acceptedShiftIds,
      acceptedShiftCloseIds,
      rejectedShifts,
      ...salesResult,
    };
  }

  private async processShiftOpen(user: AuthUser, shift: PushShiftOpenDto) {
    if (
      !shift.id ||
      !shift.storeId ||
      !Number.isSafeInteger(shift.openingCash) ||
      shift.openingCash < 0 ||
      Number.isNaN(Date.parse(shift.openedAt))
    ) {
      return 'invalid_shift';
    }
    try {
      await this.shiftsService.upsertFromSync(user, {
        clientId: shift.id,
        storeId: shift.storeId,
        openingCash: shift.openingCash,
        openedAt: shift.openedAt,
      });
      return null;
    } catch {
      return 'shift_conflict';
    }
  }

  private async processShiftClose(user: AuthUser, shift: PushShiftCloseDto) {
    if (
      !shift.id ||
      !Number.isSafeInteger(shift.closingCash) ||
      shift.closingCash < 0 ||
      Number.isNaN(Date.parse(shift.closedAt))
    ) {
      return 'invalid_shift';
    }
    try {
      await this.shiftsService.closeFromSync(user, shift.id, {
        closingCash: shift.closingCash,
        note: shift.note ?? undefined,
        closedAt: shift.closedAt,
      });
      return null;
    } catch {
      return 'shift_conflict';
    }
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
    if (shift.userId !== user.userId) {
      return { accepted: false, reason: 'shift_forbidden' };
    }
    const clientCreatedAt = new Date(sale.clientCreatedAt);
    if (
      clientCreatedAt < shift.openedAt ||
      (shift.closedAt != null && clientCreatedAt > shift.closedAt)
    ) {
      return { accepted: false, reason: 'shift_not_open_at_sale' };
    }

    if (sale.debtAmount > 0) {
      try {
        await this.ensureDebtCustomer(user, sale);
      } catch {
        return { accepted: false, reason: 'customer_not_found' };
      }
      const customer = await this.prisma.customer.findUnique({
        where: { id: sale.customerId! },
      });
      if (!customer || customer.storeId !== sale.storeId) {
        return { accepted: false, reason: 'customer_not_found' };
      }
    }

    try {
      await this.prisma.$transaction(async (tx) => {
        for (const line of sale.lines) {
          const updated = await tx.$queryRaw<{ productId: string }[]>`
            UPDATE "ProductStoreStock"
            SET "qty" = "qty" - CAST(${line.qty} AS DECIMAL),
                "updatedAt" = CURRENT_TIMESTAMP
            WHERE "productId" = ${line.productId}
              AND "storeId" = ${sale.storeId}
            RETURNING "productId"
          `;
          if (updated.length === 0) {
            throw new Error('stock_not_found');
          }
        }

        await tx.sale.create({
          data: {
            id: sale.id,
            storeId: sale.storeId,
            shiftId: sale.shiftId,
            soldById: user.userId,
            paymentMethod: sale.paymentMethod as PaymentMethod,
            cashAmount: sale.cashAmount,
            transferAmount: sale.transferAmount,
            debtAmount: sale.debtAmount,
            discountVnd: sale.discountVnd,
            totalVnd: sale.totalVnd,
            customerId: sale.customerId ?? null,
            clientCreatedAt,
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
      if (error instanceof Error && error.message === 'stock_not_found') {
        return { accepted: false, reason: 'stock_not_found' };
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

  private async ensureDebtCustomer(
    user: AuthUser,
    sale: PushSaleDto,
  ): Promise<void> {
    const customerId = sale.customerId?.trim();
    if (!customerId || !sale.customer || sale.customer.id !== customerId) {
      return;
    }
    const name = sale.customer.name?.trim();
    if (!name) {
      return;
    }
    await this.customersService.create(user, {
      id: customerId,
      storeId: sale.storeId,
      name,
      phone: sale.customer.phone ?? null,
    });
  }

  private validateSalePayload(sale: PushSaleDto): string | null {
    if (!sale.id || !sale.storeId || !sale.shiftId) {
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

    const moneyValues = [
      sale.cashAmount,
      sale.transferAmount,
      sale.debtAmount,
      sale.discountVnd,
      sale.totalVnd,
    ];
    if (
      moneyValues.some(
        (value) => !Number.isSafeInteger(value) || value < 0,
      )
    ) {
      return 'invalid_money';
    }

    if (sale.debtAmount > 0) {
      if (!sale.customerId || sale.customerId.trim() === '') {
        return 'customer_required';
      }
    }

    let linesTotal = new Prisma.Decimal(0);
    for (const line of sale.lines) {
      if (!line.productId || !line.qty) {
        return 'invalid_payload';
      }
      if (
        !Number.isSafeInteger(line.unitPrice) ||
        line.unitPrice < 0 ||
        !Number.isSafeInteger(line.lineTotal) ||
        line.lineTotal < 0
      ) {
        return 'invalid_money';
      }
      try {
        const qty = new Prisma.Decimal(line.qty);
        if (!qty.isFinite() || qty.lessThanOrEqualTo(0)) {
          return 'invalid_quantity';
        }
        const expectedLineTotal = qty.times(line.unitPrice);
        if (!expectedLineTotal.equals(line.lineTotal)) {
          return 'line_total_mismatch';
        }
        linesTotal = linesTotal.plus(line.lineTotal);
      } catch {
        return 'invalid_payload';
      }
    }

    const expectedSaleTotal = linesTotal.minus(sale.discountVnd);
    if (
      expectedSaleTotal.lessThan(0) ||
      !expectedSaleTotal.equals(sale.totalVnd)
    ) {
      return 'sale_total_mismatch';
    }
    const paymentTotal =
      sale.cashAmount + sale.transferAmount + sale.debtAmount;
    if (paymentTotal !== sale.totalVnd) {
      return 'payment_mismatch';
    }

    return null;
  }
}
