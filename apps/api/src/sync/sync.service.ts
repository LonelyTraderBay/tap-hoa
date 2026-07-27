import { ForbiddenException, Injectable } from '@nestjs/common';
import { PaymentMethod, Prisma, Role } from '@prisma/client';
import { randomUUID } from 'crypto';
import { AuthUser } from '../auth/jwt.strategy';
import { CustomersService } from '../customers/customers.service';
import { DevicesService } from '../devices/devices.service';
import { computeSaleLineVatSnapshots } from '../ledger/journal-builders';
import { LedgerService } from '../ledger/ledger.service';
import { PrismaService } from '../prisma/prisma.service';
import { ProductsService } from '../products/products.service';
import { ShiftsService } from '../shifts/shifts.service';
import {
  PushCashVoucherDto,
  PushCustomerUpsertDto,
  PushDebtPaymentDto,
  PushProductGroupUpsertDto,
  PushProductUpsertDto,
  PushSaleDto,
  PushSaleReturnDto,
  PushShiftCloseDto,
  PushShiftOpenDto,
  PushSyncDto,
} from './dto/push-sale.dto';
import { crossesLargeDebtThreshold } from './large-debt-threshold';
import { StockOpsService } from './stock-ops.service';
import { SaleReturnsService } from './sale-returns.service';

const PAYMENT_METHODS = new Set<string>(Object.values(PaymentMethod));

export type ClosedShiftSnapshot = {
  id: string;
  expectedCashVnd: number;
  varianceVnd: number;
  transferInShiftVnd: number;
  closingCash: number;
  closedAt: string;
  note: string | null;
};

type LargeDebtAlert = {
  storeId: string;
  customerId: string;
  customerName: string;
  balanceVnd: number;
  thresholdVnd: number;
};

@Injectable()
export class SyncService {
  constructor(
    private readonly productsService: ProductsService,
    private readonly customersService: CustomersService,
    private readonly prisma: PrismaService,
    private readonly shiftsService: ShiftsService,
    private readonly stockOps: StockOpsService,
    private readonly saleReturns: SaleReturnsService,
    private readonly devicesService: DevicesService,
    private readonly ledger: LedgerService,
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

    const [
      products,
      stocks,
      customers,
      debtLedger,
      cashCategories,
      cashVouchers,
      inventory,
      productGroups,
      comboComponents,
      store,
      saleReturns,
    ] = await Promise.all([
      this.productsService.findUpdatedSince(since),
      this.productsService.findStocksForStoreSince(storeId, since),
      this.prisma.customer.findMany({
        where: { storeId, updatedAt: { gt: since } },
      }),
      this.prisma.debtLedgerEntry.findMany({
        where: { storeId, updatedAt: { gt: since } },
        orderBy: { clientCreatedAt: 'asc' },
      }),
      this.prisma.cashCategory.findMany({
        orderBy: { sortOrder: 'asc' },
      }),
      this.prisma.cashVoucher.findMany({
        where: { storeId, updatedAt: { gt: since } },
        orderBy: { clientCreatedAt: 'asc' },
      }),
      this.stockOps.pullInventory(storeId, since),
      this.productsService.findGroupsUpdatedSince(since),
      this.productsService.findComboComponentsUpdated(since),
      this.prisma.store.findUnique({ where: { id: storeId } }),
      this.prisma.saleReturn.findMany({
        where: { storeId, updatedAt: { gt: since } },
        include: { lines: true },
        orderBy: { clientCreatedAt: 'asc' },
      }),
    ]);

    return {
      products: products.map((product) => ({
        id: product.id,
        sku: product.sku,
        barcode: product.barcode,
        name: product.name,
        unit: product.unit,
        sellUnit: product.sellUnit,
        packSize: product.packSize?.toString() ?? null,
        kind: product.kind,
        groupId: product.groupId,
        isWeighted: product.isWeighted,
        basePriceVnd: product.basePriceVnd,
        costVnd: product.costVnd,
        active: product.active,
        updatedAt: product.updatedAt.toISOString(),
      })),
      productGroups: productGroups.map((g) => ({
        id: g.id,
        name: g.name,
        sortOrder: g.sortOrder,
        active: g.active,
        updatedAt: g.updatedAt.toISOString(),
      })),
      comboComponents: comboComponents.map((c) => ({
        id: c.id,
        comboProductId: c.comboProductId,
        componentProductId: c.componentProductId,
        qtyBase: c.qtyBase.toString(),
      })),
      stocks: stocks.map((stock) => ({
        productId: stock.productId,
        storeId: stock.storeId,
        qty: stock.qty.toString(),
        minQty: stock.minQty.toString(),
        avgCostVnd: stock.avgCostVnd,
        updatedAt: stock.updatedAt.toISOString(),
      })),
      store: store
        ? {
            id: store.id,
            code: store.code,
            name: store.name,
            active: store.active,
            debtOverdueDays: store.debtOverdueDays,
            largeDebtThresholdVnd: store.largeDebtThresholdVnd,
            allowNegativeStock: store.allowNegativeStock,
            updatedAt: store.updatedAt.toISOString(),
          }
        : null,
      saleReturns: saleReturns.map((r) => ({
        id: r.id,
        storeId: r.storeId,
        originalSaleId: r.originalSaleId,
        shiftId: r.shiftId,
        recordedById: r.recordedById,
        cashRefundVnd: r.cashRefundVnd,
        transferRefundVnd: r.transferRefundVnd,
        debtCreditVnd: r.debtCreditVnd,
        totalRefundVnd: r.totalRefundVnd,
        note: r.note,
        clientCreatedAt: r.clientCreatedAt.toISOString(),
        updatedAt: r.updatedAt.toISOString(),
        lines: r.lines.map((l) => ({
          id: l.id,
          productId: l.productId,
          qty: l.qty.toString(),
          unitPrice: l.unitPrice,
          lineRefundVnd: l.lineRefundVnd,
        })),
      })),
      customers: customers.map((c) => ({
        id: c.id,
        storeId: c.storeId,
        name: c.name,
        phone: c.phone,
        balanceVnd: c.balanceVnd,
        creditLimitVnd: c.creditLimitVnd,
        updatedAt: c.updatedAt.toISOString(),
      })),
      debtLedger: debtLedger.map((e) => ({
        id: e.id,
        storeId: e.storeId,
        customerId: e.customerId,
        type: e.type,
        amountVnd: e.amountVnd,
        balanceAfterVnd: e.balanceAfterVnd,
        saleId: e.saleId,
        shiftId: e.shiftId,
        recordedById: e.recordedById,
        paymentMethod: e.paymentMethod,
        note: e.note,
        clientCreatedAt: e.clientCreatedAt.toISOString(),
        updatedAt: e.updatedAt.toISOString(),
      })),
      cashCategories: cashCategories.map((c) => ({
        id: c.id,
        code: c.code,
        name: c.name,
        direction: c.direction,
        sortOrder: c.sortOrder,
      })),
      cashVouchers: cashVouchers.map((v) => ({
        id: v.id,
        storeId: v.storeId,
        shiftId: v.shiftId,
        categoryId: v.categoryId,
        direction: v.direction,
        channel: v.channel,
        amountVnd: v.amountVnd,
        note: v.note,
        recordedById: v.recordedById,
        clientCreatedAt: v.clientCreatedAt.toISOString(),
        updatedAt: v.updatedAt.toISOString(),
      })),
      ...inventory,
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

    const inventoryResult = await this.pushInventory(user, body);

    const salesResult = await this.pushSales(user, body.deviceId, body.sales);

    const voucherResult = await this.pushCashVouchers(
      user,
      body.cashVouchers ?? [],
    );

    const debtResult = await this.pushDebtPayments(
      user,
      body.debtPayments ?? [],
    );

    const acceptedShiftCloseIds: string[] = [];
    const closedShifts: ClosedShiftSnapshot[] = [];
    for (const shift of body.shiftCloses ?? []) {
      const result = await this.processShiftClose(user, shift);
      if ('reason' in result) {
        rejectedShifts.push({ id: shift.id, reason: result.reason });
      } else {
        acceptedShiftCloseIds.push(shift.id);
        closedShifts.push(result.snapshot);
      }
    }
    const customerResult = await this.pushCustomerUpserts(
      user,
      body.customerUpserts ?? [],
    );

    const productResult = await this.pushProductUpserts(
      user,
      body.productUpserts ?? [],
    );

    const groupResult = await this.pushProductGroupUpserts(
      user,
      body.productGroupUpserts ?? [],
    );

    const returnResult = await this.pushSaleReturns(
      user,
      body.saleReturns ?? [],
    );

    await this.prisma.syncCursor.upsert({
      where: { deviceId: body.deviceId },
      create: {
        deviceId: body.deviceId,
        userId: user.userId,
        lastPullAt: new Date(0),
        lastPushAt: new Date(),
      },
      update: {
        userId: user.userId,
        lastPushAt: new Date(),
      },
    });

    const response = {
      acceptedShiftIds,
      acceptedShiftCloseIds,
      closedShifts,
      rejectedShifts,
      ...salesResult,
      ...inventoryResult,
      ...voucherResult,
      ...debtResult,
      ...customerResult,
      ...productResult,
      ...groupResult,
      ...returnResult,
    };

    const rejectCount = this.countRejected(response);
    if (rejectCount > 0) {
      void this.devicesService.notifyUser(user.userId, {
        title: 'Đồng bộ bị từ chối',
        body: `${rejectCount} mục outbox bị server từ chối`,
        data: { type: 'sync_reject', count: String(rejectCount) },
      });
    }

    return response;
  }

  private countRejected(result: Record<string, unknown>): number {
    let n = 0;
    for (const [key, value] of Object.entries(result)) {
      if (!key.startsWith('rejected') || !Array.isArray(value)) continue;
      n += value.length;
    }
    return n;
  }

  private async pushInventory(user: AuthUser, body: PushSyncDto) {
    const acceptedStockTransferCreateIds: string[] = [];
    const rejectedStockTransferCreates: { id: string; reason: string }[] = [];
    for (const dto of body.stockTransferCreates ?? []) {
      const result = await this.stockOps.processTransferCreate(user, dto);
      if (result.accepted) {
        acceptedStockTransferCreateIds.push(dto.id);
      } else {
        rejectedStockTransferCreates.push({ id: dto.id, reason: result.reason });
      }
    }

    const acceptedStockTransferApproveIds: string[] = [];
    const rejectedStockTransferApproves: { id: string; reason: string }[] = [];
    for (const dto of body.stockTransferApproves ?? []) {
      const result = await this.stockOps.processTransferApprove(user, dto);
      if (result.accepted) {
        acceptedStockTransferApproveIds.push(dto.id);
      } else {
        rejectedStockTransferApproves.push({ id: dto.id, reason: result.reason });
      }
    }

    const acceptedStockTransferRejectIds: string[] = [];
    const rejectedStockTransferRejects: { id: string; reason: string }[] = [];
    for (const dto of body.stockTransferRejects ?? []) {
      const result = await this.stockOps.processTransferReject(user, dto);
      if (result.accepted) {
        acceptedStockTransferRejectIds.push(dto.id);
      } else {
        rejectedStockTransferRejects.push({ id: dto.id, reason: result.reason });
      }
    }

    const acceptedStockTransferReceiveIds: string[] = [];
    const rejectedStockTransferReceives: { id: string; reason: string }[] = [];
    for (const dto of body.stockTransferReceives ?? []) {
      const result = await this.stockOps.processTransferReceive(user, dto);
      if (result.accepted) {
        acceptedStockTransferReceiveIds.push(dto.id);
      } else {
        rejectedStockTransferReceives.push({ id: dto.id, reason: result.reason });
      }
    }

    const acceptedStocktakeIds: string[] = [];
    const rejectedStocktakes: { id: string; reason: string }[] = [];
    for (const dto of body.stocktakes ?? []) {
      const result = await this.stockOps.processStocktake(user, dto);
      if (result.accepted) {
        acceptedStocktakeIds.push(dto.id);
      } else {
        rejectedStocktakes.push({ id: dto.id, reason: result.reason });
      }
    }

    const acceptedPurchaseOrderCreateIds: string[] = [];
    const rejectedPurchaseOrderCreates: { id: string; reason: string }[] = [];
    for (const dto of body.purchaseOrderCreates ?? []) {
      const result = await this.stockOps.processPurchaseOrderCreate(user, dto);
      if (result.accepted) {
        acceptedPurchaseOrderCreateIds.push(dto.id);
      } else {
        rejectedPurchaseOrderCreates.push({ id: dto.id, reason: result.reason });
      }
    }

    const acceptedPurchaseOrderOrderIds: string[] = [];
    const rejectedPurchaseOrderOrders: { id: string; reason: string }[] = [];
    for (const dto of body.purchaseOrderOrders ?? []) {
      const result = await this.stockOps.processPurchaseOrderOrder(user, dto);
      if (result.accepted) {
        acceptedPurchaseOrderOrderIds.push(dto.id);
      } else {
        rejectedPurchaseOrderOrders.push({ id: dto.id, reason: result.reason });
      }
    }

    const acceptedPurchaseOrderCloseIds: string[] = [];
    const rejectedPurchaseOrderCloses: { id: string; reason: string }[] = [];
    for (const dto of body.purchaseOrderCloses ?? []) {
      const result = await this.stockOps.processPurchaseOrderClose(user, dto);
      if (result.accepted) {
        acceptedPurchaseOrderCloseIds.push(dto.id);
      } else {
        rejectedPurchaseOrderCloses.push({ id: dto.id, reason: result.reason });
      }
    }

    const acceptedPurchaseReceiptIds: string[] = [];
    const rejectedPurchaseReceipts: { id: string; reason: string }[] = [];
    for (const dto of body.purchaseReceipts ?? []) {
      const result = await this.stockOps.processPurchaseReceipt(user, dto);
      if (result.accepted) {
        acceptedPurchaseReceiptIds.push(dto.id);
      } else {
        rejectedPurchaseReceipts.push({ id: dto.id, reason: result.reason });
      }
    }

    const acceptedWastageIds: string[] = [];
    const rejectedWastages: { id: string; reason: string }[] = [];
    for (const dto of body.wastages ?? []) {
      const result = await this.stockOps.processWastage(user, dto);
      if (result.accepted) {
        acceptedWastageIds.push(dto.id);
      } else {
        rejectedWastages.push({ id: dto.id, reason: result.reason });
      }
    }

    return {
      acceptedStockTransferCreateIds,
      rejectedStockTransferCreates,
      acceptedStockTransferApproveIds,
      rejectedStockTransferApproves,
      acceptedStockTransferRejectIds,
      rejectedStockTransferRejects,
      acceptedStockTransferReceiveIds,
      rejectedStockTransferReceives,
      acceptedStocktakeIds,
      rejectedStocktakes,
      acceptedPurchaseOrderCreateIds,
      rejectedPurchaseOrderCreates,
      acceptedPurchaseOrderOrderIds,
      rejectedPurchaseOrderOrders,
      acceptedPurchaseOrderCloseIds,
      rejectedPurchaseOrderCloses,
      acceptedPurchaseReceiptIds,
      rejectedPurchaseReceipts,
      acceptedWastageIds,
      rejectedWastages,
    };
  }

  private async pushCashVouchers(
    user: AuthUser,
    vouchers: PushCashVoucherDto[],
  ) {
    const acceptedCashVoucherIds: string[] = [];
    const rejectedCashVouchers: { id: string; reason: string }[] = [];
    for (const voucher of vouchers) {
      const result = await this.processCashVoucher(user, voucher);
      if (result.accepted) {
        acceptedCashVoucherIds.push(voucher.id);
      } else {
        rejectedCashVouchers.push({
          id: voucher.id,
          reason: result.reason ?? 'invalid_voucher',
        });
      }
    }
    return { acceptedCashVoucherIds, rejectedCashVouchers };
  }

  private async processCashVoucher(
    user: AuthUser,
    voucher: PushCashVoucherDto,
  ): Promise<{ accepted: boolean; reason?: string }> {
    if (
      !voucher.id ||
      !voucher.storeId ||
      !voucher.shiftId ||
      !voucher.categoryId ||
      (voucher.direction !== 'in' && voucher.direction !== 'out') ||
      (voucher.channel !== 'cash' && voucher.channel !== 'transfer') ||
      Number.isNaN(Date.parse(voucher.clientCreatedAt))
    ) {
      return { accepted: false, reason: 'invalid_voucher' };
    }
    if (
      !Number.isSafeInteger(voucher.amountVnd) ||
      voucher.amountVnd <= 0
    ) {
      return { accepted: false, reason: 'invalid_amount' };
    }

    try {
      this.assertStoreAccess(user, voucher.storeId);
    } catch {
      return { accepted: false, reason: 'store_forbidden' };
    }

    const existing = await this.prisma.cashVoucher.findUnique({
      where: { id: voucher.id },
    });
    if (existing) {
      return { accepted: true };
    }

    const category = await this.prisma.cashCategory.findUnique({
      where: { id: voucher.categoryId },
    });
    if (!category) {
      return { accepted: false, reason: 'invalid_voucher' };
    }
    if (category.direction !== voucher.direction) {
      return { accepted: false, reason: 'category_direction_mismatch' };
    }

    try {
      await this.prisma.$transaction(async (tx) => {
        const shift = await tx.shift.findUnique({
          where: { id: voucher.shiftId },
        });
        if (!shift || shift.closedAt != null) {
          throw new Error('shift_not_open');
        }
        if (shift.storeId !== voucher.storeId) {
          throw new Error('store_forbidden');
        }

        await tx.cashVoucher.create({
          data: {
            id: voucher.id,
            storeId: voucher.storeId,
            shiftId: voucher.shiftId,
            categoryId: voucher.categoryId,
            direction: voucher.direction,
            channel: voucher.channel,
            amountVnd: voucher.amountVnd,
            note: voucher.note?.trim() || null,
            recordedById: user.userId,
            clientCreatedAt: new Date(voucher.clientCreatedAt),
          },
        });
      });
      await this.ledger.safePost(
        () => this.ledger.postFromCashVoucher(voucher.id, user.userId),
        {
          sourceType: 'cash_voucher',
          sourceId: voucher.id,
          actorUserId: user.userId,
        },
      );
      return { accepted: true };
    } catch (error) {
      if (error instanceof Error && error.message === 'shift_not_open') {
        return { accepted: false, reason: 'shift_not_open' };
      }
      if (error instanceof Error && error.message === 'store_forbidden') {
        return { accepted: false, reason: 'store_forbidden' };
      }
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        return { accepted: true };
      }
      throw error;
    }
  }

  private async pushDebtPayments(
    user: AuthUser,
    payments: PushDebtPaymentDto[],
  ) {
    const acceptedDebtPaymentIds: string[] = [];
    const rejectedDebtPayments: { id: string; reason: string }[] = [];
    for (const payment of payments) {
      const result = await this.processDebtPayment(user, payment);
      if (result.accepted) {
        acceptedDebtPaymentIds.push(payment.id);
      } else {
        rejectedDebtPayments.push({
          id: payment.id,
          reason: result.reason ?? 'invalid_payment',
        });
      }
    }
    return { acceptedDebtPaymentIds, rejectedDebtPayments };
  }

  private async processDebtPayment(
    user: AuthUser,
    payment: PushDebtPaymentDto,
  ): Promise<{ accepted: boolean; reason?: string }> {
    if (
      !payment.id ||
      !payment.storeId ||
      !payment.customerId ||
      !Number.isSafeInteger(payment.amountVnd) ||
      payment.amountVnd <= 0 ||
      (payment.paymentMethod !== 'cash' &&
        payment.paymentMethod !== 'transfer') ||
      Number.isNaN(Date.parse(payment.clientCreatedAt))
    ) {
      return { accepted: false, reason: 'invalid_payment' };
    }
    try {
      this.assertStoreAccess(user, payment.storeId);
    } catch {
      return { accepted: false, reason: 'store_forbidden' };
    }

    const existing = await this.prisma.debtLedgerEntry.findUnique({
      where: { id: payment.id },
    });
    if (existing) {
      return { accepted: true };
    }

    try {
      await this.prisma.$transaction(async (tx) => {
        const customer = await tx.customer.findUnique({
          where: { id: payment.customerId },
        });
        if (!customer || customer.storeId !== payment.storeId) {
          throw new Error('customer_not_found');
        }
        if (payment.amountVnd > customer.balanceVnd) {
          throw new Error('payment_exceeds_balance');
        }
        const updated = await tx.customer.update({
          where: { id: customer.id },
          data: { balanceVnd: { decrement: payment.amountVnd } },
        });
        await tx.debtLedgerEntry.create({
          data: {
            id: payment.id,
            storeId: payment.storeId,
            customerId: payment.customerId,
            type: 'payment',
            amountVnd: payment.amountVnd,
            balanceAfterVnd: updated.balanceVnd,
            shiftId: payment.shiftId ?? null,
            recordedById: user.userId,
            paymentMethod: payment.paymentMethod,
            note: payment.note?.trim() || null,
            clientCreatedAt: new Date(payment.clientCreatedAt),
          },
        });
      });
      await this.ledger.safePost(
        () => this.ledger.postFromDebtPayment(payment.id, user.userId),
        {
          sourceType: 'debt_payment',
          sourceId: payment.id,
          actorUserId: user.userId,
        },
      );
      return { accepted: true };
    } catch (error) {
      if (error instanceof Error) {
        if (error.message === 'payment_exceeds_balance') {
          return { accepted: false, reason: 'payment_exceeds_balance' };
        }
        if (error.message === 'customer_not_found') {
          return { accepted: false, reason: 'customer_not_found' };
        }
      }
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        return { accepted: true };
      }
      throw error;
    }
  }

  private async pushCustomerUpserts(
    user: AuthUser,
    upserts: PushCustomerUpsertDto[],
  ) {
    const acceptedCustomerUpsertIds: string[] = [];
    for (const dto of upserts) {
      try {
        await this.customersService.create(user, dto);
        acceptedCustomerUpsertIds.push(dto.id);
      } catch {
        // soft-reject per item
      }
    }
    return { acceptedCustomerUpsertIds };
  }

  private async pushProductUpserts(
    user: AuthUser,
    upserts: PushProductUpsertDto[],
  ) {
    const acceptedProductUpsertIds: string[] = [];
    const rejectedProductUpserts: { id: string; reason: string }[] = [];
    for (const dto of upserts) {
      const result = await this.productsService.upsertFromSync(user, dto);
      if (result.accepted) {
        acceptedProductUpsertIds.push(dto.id);
      } else {
        rejectedProductUpserts.push({ id: dto.id, reason: result.reason });
      }
    }
    return { acceptedProductUpsertIds, rejectedProductUpserts };
  }

  private async pushProductGroupUpserts(
    user: AuthUser,
    upserts: PushProductGroupUpsertDto[],
  ) {
    const acceptedProductGroupUpsertIds: string[] = [];
    const rejectedProductGroupUpserts: { id: string; reason: string }[] = [];
    for (const dto of upserts) {
      const result = await this.productsService.upsertGroupFromSync(user, dto);
      if (result.accepted) {
        acceptedProductGroupUpsertIds.push(dto.id);
      } else {
        rejectedProductGroupUpserts.push({ id: dto.id, reason: result.reason });
      }
    }
    return { acceptedProductGroupUpsertIds, rejectedProductGroupUpserts };
  }

  private async pushSaleReturns(user: AuthUser, returns: PushSaleReturnDto[]) {
    const acceptedSaleReturnIds: string[] = [];
    const rejectedSaleReturns: { id: string; reason: string }[] = [];
    for (const dto of returns) {
      const result = await this.saleReturns.processFromSync(user, dto);
      if (result.accepted) {
        acceptedSaleReturnIds.push(dto.id);
      } else {
        rejectedSaleReturns.push({ id: dto.id, reason: result.reason });
      }
    }
    return { acceptedSaleReturnIds, rejectedSaleReturns };
  }

  async diagnostics(user: AuthUser) {
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('Diagnostics requires manager or owner');
    }
    const cursors = await this.prisma.syncCursor.findMany({
      orderBy: { lastPullAt: 'desc' },
    });
    const userIds = [...new Set(cursors.map((c) => c.userId))];
    const users = await this.prisma.user.findMany({
      where: { id: { in: userIds } },
      select: { id: true, name: true, phone: true },
    });
    const byId = new Map(users.map((u) => [u.id, u]));
    return {
      devices: cursors.map((c) => ({
        deviceId: c.deviceId,
        userId: c.userId,
        userName: byId.get(c.userId)?.name ?? c.userId,
        storeId: c.storeId,
        lastPullAt: c.lastPullAt.toISOString(),
        lastPushAt: c.lastPushAt?.toISOString() ?? null,
        userAgent: c.userAgent,
      })),
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

  private async processShiftClose(
    user: AuthUser,
    shift: PushShiftCloseDto,
  ): Promise<{ reason: string } | { snapshot: ClosedShiftSnapshot }> {
    if (
      !shift.id ||
      !Number.isSafeInteger(shift.closingCash) ||
      shift.closingCash < 0 ||
      Number.isNaN(Date.parse(shift.closedAt))
    ) {
      return { reason: 'invalid_shift' };
    }
    try {
      const closed = await this.shiftsService.closeFromSync(user, shift.id, {
        closingCash: shift.closingCash,
        note: shift.note ?? undefined,
        closedAt: shift.closedAt,
      });
      if (!closed.closedAt || closed.closingCash == null) {
        return { reason: 'shift_conflict' };
      }
      return {
        snapshot: {
          id: closed.id,
          expectedCashVnd: closed.expectedCashVnd ?? 0,
          varianceVnd: closed.varianceVnd ?? 0,
          transferInShiftVnd: closed.transferInShiftVnd ?? 0,
          closingCash: closed.closingCash,
          closedAt: closed.closedAt.toISOString(),
          note: closed.note,
        },
      };
    } catch {
      return { reason: 'shift_conflict' };
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
      if (
        customer.creditLimitVnd != null &&
        customer.balanceVnd + sale.debtAmount > customer.creditLimitVnd
      ) {
        return { accepted: false, reason: 'credit_limit_exceeded' };
      }
    }

    let largeDebtAlert: LargeDebtAlert | null = null;
    try {
      await this.prisma.$transaction(async (tx) => {
        const storeVatRow = await tx.store.findUnique({
          where: { id: sale.storeId },
          select: {
            vatEnabled: true,
            defaultVatRateBps: true,
            largeDebtThresholdVnd: true,
          },
        });
        const storeVat =
          storeVatRow?.vatEnabled && storeVatRow.defaultVatRateBps > 0
            ? storeVatRow.defaultVatRateBps
            : null;

        const saleLines: {
          id: string;
          productId: string;
          qty: Prisma.Decimal;
          unitPrice: number;
          discountVnd: number;
          lineTotal: number;
          unitCostVnd: number;
          productVatRateBps: number | null;
          vatRateBps: number | null;
          netVnd: number | null;
          vatVnd: number | null;
        }[] = [];

        for (const line of sale.lines) {
          const product = await tx.product.findUnique({
            where: { id: line.productId },
            include: { comboComponents: true },
          });
          let unitCostVnd = 0;
          if (product?.kind === 'combo') {
            if (product.comboComponents.length === 0) {
              throw new Error('invalid_combo');
            }
            for (const c of product.comboComponents) {
              const componentStock = await tx.productStoreStock.findUnique({
                where: {
                  productId_storeId: {
                    productId: c.componentProductId,
                    storeId: sale.storeId,
                  },
                },
              });
              const componentProduct = await tx.product.findUnique({
                where: { id: c.componentProductId },
              });
              const avg =
                (componentStock?.avgCostVnd ?? 0) > 0
                  ? componentStock!.avgCostVnd
                  : (componentProduct?.costVnd ?? 0);
              unitCostVnd += Math.round(avg * Number(c.qtyBase));
            }
          } else {
            const stock = await tx.productStoreStock.findUnique({
              where: {
                productId_storeId: {
                  productId: line.productId,
                  storeId: sale.storeId,
                },
              },
            });
            unitCostVnd =
              (stock?.avgCostVnd ?? 0) > 0
                ? stock!.avgCostVnd
                : (product?.costVnd ?? 0);
          }

          saleLines.push({
            id: randomUUID(),
            productId: line.productId,
            qty: new Prisma.Decimal(line.qty),
            unitPrice: line.unitPrice,
            discountVnd: line.discountVnd ?? 0,
            lineTotal: line.lineTotal,
            unitCostVnd,
            productVatRateBps: product?.vatRateBps ?? null,
            vatRateBps: null,
            netVnd: null,
            vatVnd: null,
          });
        }

        if (storeVat != null) {
          const snaps = computeSaleLineVatSnapshots({
            lines: saleLines.map((l) => ({
              lineTotal: l.lineTotal,
              vatRateBps: l.productVatRateBps ?? storeVat,
            })),
            discountVnd: sale.discountVnd,
            storeVatRateBps: storeVat,
          });
          for (let i = 0; i < saleLines.length; i++) {
            saleLines[i].vatRateBps = snaps[i].vatRateBps;
            saleLines[i].netVnd = snaps[i].netVnd;
            saleLines[i].vatVnd = snaps[i].vatVnd;
          }
        }

        for (const line of saleLines) {
          const product = await tx.product.findUnique({
            where: { id: line.productId },
            include: { comboComponents: true },
          });
          if (product?.kind === 'combo') {
            if (product.comboComponents.length === 0) {
              throw new Error('invalid_combo');
            }
            for (const c of product.comboComponents) {
              const delta = line.qty.mul(c.qtyBase);
              const updated = await tx.$queryRaw<{ productId: string }[]>`
                UPDATE "ProductStoreStock"
                SET "qty" = "qty" - CAST(${delta.toString()} AS DECIMAL),
                    "updatedAt" = CURRENT_TIMESTAMP
                WHERE "productId" = ${c.componentProductId}
                  AND "storeId" = ${sale.storeId}
                  AND "qty" - CAST(${delta.toString()} AS DECIMAL) >= 0
                RETURNING "productId"
              `;
              if (updated.length === 0) {
                throw new Error('insufficient_stock');
              }
            }
          } else {
            const updated = await tx.$queryRaw<{ productId: string }[]>`
              UPDATE "ProductStoreStock"
              SET "qty" = "qty" - CAST(${line.qty.toString()} AS DECIMAL),
                  "updatedAt" = CURRENT_TIMESTAMP
              WHERE "productId" = ${line.productId}
                AND "storeId" = ${sale.storeId}
              RETURNING "productId"
            `;
            if (updated.length === 0) {
              throw new Error('stock_not_found');
            }
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
              create: saleLines.map((line) => ({
                id: line.id,
                productId: line.productId,
                qty: line.qty,
                unitPrice: line.unitPrice,
                discountVnd: line.discountVnd,
                lineTotal: line.lineTotal,
                unitCostVnd: line.unitCostVnd,
                vatRateBps: line.vatRateBps,
                netVnd: line.netVnd,
                vatVnd: line.vatVnd,
              })),
            },
          },
        });

        await this.stockOps.recordSaleMovements(tx, {
          saleId: sale.id,
          storeId: sale.storeId,
          recordedById: user.userId,
          clientCreatedAt,
          lines: saleLines.map((l) => ({
            id: l.id,
            productId: l.productId,
            qty: l.qty,
          })),
        });

        if (sale.debtAmount > 0 && sale.customerId) {
          const previous = await tx.customer.findUniqueOrThrow({
            where: { id: sale.customerId },
            select: { name: true, balanceVnd: true },
          });
          const updated = await tx.customer.update({
            where: { id: sale.customerId },
            data: { balanceVnd: { increment: sale.debtAmount } },
          });
          const threshold = storeVatRow?.largeDebtThresholdVnd ?? null;
          if (
            crossesLargeDebtThreshold({
              thresholdVnd: threshold,
              previousBalanceVnd: previous.balanceVnd,
              nextBalanceVnd: updated.balanceVnd,
            })
          ) {
            largeDebtAlert = {
              storeId: sale.storeId,
              customerId: sale.customerId,
              customerName: previous.name,
              balanceVnd: updated.balanceVnd,
              thresholdVnd: threshold!,
            };
          }
          await tx.debtLedgerEntry.create({
            data: {
              id: randomUUID(),
              storeId: sale.storeId,
              customerId: sale.customerId,
              type: 'sale_debt',
              amountVnd: sale.debtAmount,
              balanceAfterVnd: updated.balanceVnd,
              saleId: sale.id,
              shiftId: sale.shiftId,
              recordedById: user.userId,
              clientCreatedAt,
            },
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
      await this.ledger.safePost(
        () => this.ledger.postFromSale(sale.id, user.userId),
        {
          sourceType: 'sale',
          sourceId: sale.id,
          actorUserId: user.userId,
        },
      );
      if (largeDebtAlert) {
        void this.notifyLargeDebt(largeDebtAlert);
      }
      return { accepted: true };
    } catch (error) {
      if (error instanceof Error && error.message === 'stock_not_found') {
        return { accepted: false, reason: 'stock_not_found' };
      }
      if (error instanceof Error && error.message === 'insufficient_stock') {
        return { accepted: false, reason: 'insufficient_stock' };
      }
      if (error instanceof Error && error.message === 'invalid_combo') {
        return { accepted: false, reason: 'invalid_combo' };
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

  private notifyLargeDebt(alert: LargeDebtAlert) {
    return this.devicesService.notifyStoreManagers(alert.storeId, {
      title: 'Nợ lớn',
      body: `${alert.customerName}: ${alert.balanceVnd.toLocaleString('vi-VN')}đ (ngưỡng ${alert.thresholdVnd.toLocaleString('vi-VN')}đ)`,
      data: {
        type: 'large_debt',
        storeId: alert.storeId,
        customerId: alert.customerId,
        balanceVnd: String(alert.balanceVnd),
        thresholdVnd: String(alert.thresholdVnd),
      },
    });
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
        line.lineTotal < 0 ||
        (line.discountVnd != null &&
          (!Number.isSafeInteger(line.discountVnd) || line.discountVnd < 0))
      ) {
        return 'invalid_money';
      }
      try {
        const qty = new Prisma.Decimal(line.qty);
        if (!qty.isFinite() || qty.lessThanOrEqualTo(0)) {
          return 'invalid_quantity';
        }
        const lineDiscount = line.discountVnd ?? 0;
        const grossLineTotal = qty.times(line.unitPrice).round();
        if (new Prisma.Decimal(lineDiscount).greaterThan(grossLineTotal)) {
          return 'line_total_mismatch';
        }
        const expectedLineTotal = grossLineTotal.minus(lineDiscount);
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
