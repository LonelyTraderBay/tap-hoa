import { Injectable } from '@nestjs/common';
import {
  Prisma,
  Role,
  StockDocType,
  StocktakeLineReason,
  TransferStatus,
  WastageReason,
} from '@prisma/client';
import { randomUUID } from 'crypto';
import { AuthUser } from '../auth/jwt.strategy';
import { PrismaService } from '../prisma/prisma.service';
import {
  PushPurchaseReceiptDto,
  PushStockTransferActionDto,
  PushStockTransferCreateDto,
  PushStocktakeDto,
  PushWastageDto,
} from './dto/push-sale.dto';

type RejectResult = { accepted: false; reason: string };
type AcceptResult = { accepted: true };
type ProcessResult = AcceptResult | RejectResult;

@Injectable()
export class StockOpsService {
  constructor(private readonly prisma: PrismaService) {}

  private canAccessStore(user: AuthUser, storeId: string): boolean {
    return user.role === Role.owner || user.storeIds.includes(storeId);
  }

  private isManagerOrOwner(user: AuthUser): boolean {
    return user.role === Role.owner || user.role === Role.store_manager;
  }

  private parseQty(raw: string): Prisma.Decimal | null {
    try {
      const qty = new Prisma.Decimal(raw);
      if (!qty.isFinite() || qty.lessThanOrEqualTo(0)) {
        return null;
      }
      return qty;
    } catch {
      return null;
    }
  }

  private async adjustStock(
    tx: Prisma.TransactionClient,
    params: {
      storeId: string;
      productId: string;
      delta: Prisma.Decimal;
      requireNonNegative: boolean;
      docType: StockDocType;
      docId: string;
      docLineId: string;
      recordedById: string;
      clientCreatedAt: Date;
      setAbsolute?: Prisma.Decimal;
    },
  ): Promise<void> {
    const stock = await tx.productStoreStock.findUnique({
      where: {
        productId_storeId: {
          productId: params.productId,
          storeId: params.storeId,
        },
      },
    });
    if (!stock) {
      throw new Error('stock_not_found');
    }

    const nextQty =
      params.setAbsolute !== undefined
        ? params.setAbsolute
        : stock.qty.plus(params.delta);

    if (params.requireNonNegative && nextQty.lessThan(0)) {
      throw new Error('insufficient_stock');
    }

    const qtyDelta =
      params.setAbsolute !== undefined
        ? nextQty.minus(stock.qty)
        : params.delta;

    await tx.productStoreStock.update({
      where: {
        productId_storeId: {
          productId: params.productId,
          storeId: params.storeId,
        },
      },
      data: { qty: nextQty },
    });

    if (!qtyDelta.equals(0)) {
      await tx.stockMovement.create({
        data: {
          id: randomUUID(),
          storeId: params.storeId,
          productId: params.productId,
          qtyDelta,
          balanceAfter: nextQty,
          docType: params.docType,
          docId: params.docId,
          docLineId: params.docLineId,
          recordedById: params.recordedById,
          clientCreatedAt: params.clientCreatedAt,
        },
      });
    }
  }

  async recordSaleMovements(
    tx: Prisma.TransactionClient,
    params: {
      saleId: string;
      storeId: string;
      recordedById: string;
      clientCreatedAt: Date;
      lines: { id: string; productId: string; qty: Prisma.Decimal }[];
    },
  ): Promise<void> {
    for (const line of params.lines) {
      const stock = await tx.productStoreStock.findUnique({
        where: {
          productId_storeId: {
            productId: line.productId,
            storeId: params.storeId,
          },
        },
      });
      if (!stock) {
        throw new Error('stock_not_found');
      }
      await tx.stockMovement.create({
        data: {
          id: randomUUID(),
          storeId: params.storeId,
          productId: line.productId,
          qtyDelta: line.qty.negated(),
          balanceAfter: stock.qty,
          docType: StockDocType.sale,
          docId: params.saleId,
          docLineId: line.id,
          recordedById: params.recordedById,
          clientCreatedAt: params.clientCreatedAt,
        },
      });
    }
  }

  async processTransferCreate(
    user: AuthUser,
    dto: PushStockTransferCreateDto,
  ): Promise<ProcessResult> {
    if (!dto.id || !dto.fromStoreId || !dto.toStoreId) {
      return { accepted: false, reason: 'invalid_payload' };
    }
    if (dto.fromStoreId === dto.toStoreId) {
      return { accepted: false, reason: 'invalid_payload' };
    }
    if (!Array.isArray(dto.lines) || dto.lines.length === 0) {
      return { accepted: false, reason: 'invalid_payload' };
    }
    if (Number.isNaN(Date.parse(dto.clientCreatedAt))) {
      return { accepted: false, reason: 'invalid_payload' };
    }
    if (!this.canAccessStore(user, dto.fromStoreId)) {
      return { accepted: false, reason: 'store_forbidden' };
    }
    if (!this.isManagerOrOwner(user)) {
      return { accepted: false, reason: 'role_forbidden' };
    }

    const existing = await this.prisma.stockTransfer.findUnique({
      where: { id: dto.id },
    });
    if (existing) {
      return { accepted: true };
    }

    const lines: { id: string; productId: string; qty: Prisma.Decimal }[] = [];
    for (const line of dto.lines) {
      const qty = this.parseQty(line.qty);
      if (!line.productId || !qty) {
        return { accepted: false, reason: 'invalid_qty' };
      }
      lines.push({
        id: line.id?.trim() || randomUUID(),
        productId: line.productId,
        qty,
      });
    }

    try {
      await this.prisma.stockTransfer.create({
        data: {
          id: dto.id,
          fromStoreId: dto.fromStoreId,
          toStoreId: dto.toStoreId,
          status: TransferStatus.draft,
          note: dto.note ?? null,
          createdById: user.userId,
          clientCreatedAt: new Date(dto.clientCreatedAt),
          lines: {
            create: lines.map((l) => ({
              id: l.id,
              productId: l.productId,
              qty: l.qty,
            })),
          },
        },
      });
      return { accepted: true };
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        return { accepted: true };
      }
      throw error;
    }
  }

  async processTransferApprove(
    user: AuthUser,
    dto: PushStockTransferActionDto,
  ): Promise<ProcessResult> {
    if (!dto.id) {
      return { accepted: false, reason: 'invalid_payload' };
    }
    if (!this.isManagerOrOwner(user)) {
      return { accepted: false, reason: 'role_forbidden' };
    }

    const transfer = await this.prisma.stockTransfer.findUnique({
      where: { id: dto.id },
      include: { lines: true },
    });
    if (!transfer) {
      return { accepted: false, reason: 'not_found' };
    }
    if (transfer.status === TransferStatus.approved) {
      return { accepted: true };
    }
    if (transfer.status === TransferStatus.received) {
      return { accepted: true };
    }
    if (transfer.status !== TransferStatus.draft) {
      return { accepted: false, reason: 'invalid_status' };
    }
    if (!this.canAccessStore(user, transfer.fromStoreId)) {
      return { accepted: false, reason: 'store_forbidden' };
    }

    const actionAt = dto.actionAt
      ? new Date(dto.actionAt)
      : new Date();

    try {
      await this.prisma.$transaction(async (tx) => {
        for (const line of transfer.lines) {
          await this.adjustStock(tx, {
            storeId: transfer.fromStoreId,
            productId: line.productId,
            delta: line.qty.negated(),
            requireNonNegative: true,
            docType: StockDocType.transfer,
            docId: transfer.id,
            docLineId: line.id,
            recordedById: user.userId,
            clientCreatedAt: actionAt,
          });
        }
        await tx.stockTransfer.update({
          where: { id: transfer.id },
          data: {
            status: TransferStatus.approved,
            approvedById: user.userId,
            approvedAt: actionAt,
          },
        });
      });
      return { accepted: true };
    } catch (error) {
      if (error instanceof Error) {
        if (error.message === 'stock_not_found') {
          return { accepted: false, reason: 'stock_not_found' };
        }
        if (error.message === 'insufficient_stock') {
          return { accepted: false, reason: 'insufficient_stock' };
        }
      }
      throw error;
    }
  }

  async processTransferReject(
    user: AuthUser,
    dto: PushStockTransferActionDto,
  ): Promise<ProcessResult> {
    if (!dto.id) {
      return { accepted: false, reason: 'invalid_payload' };
    }
    if (!this.isManagerOrOwner(user)) {
      return { accepted: false, reason: 'role_forbidden' };
    }

    const transfer = await this.prisma.stockTransfer.findUnique({
      where: { id: dto.id },
    });
    if (!transfer) {
      return { accepted: false, reason: 'not_found' };
    }
    if (transfer.status === TransferStatus.rejected) {
      return { accepted: true };
    }
    if (transfer.status !== TransferStatus.draft) {
      return { accepted: false, reason: 'invalid_status' };
    }
    if (!this.canAccessStore(user, transfer.fromStoreId)) {
      return { accepted: false, reason: 'store_forbidden' };
    }

    await this.prisma.stockTransfer.update({
      where: { id: transfer.id },
      data: {
        status: TransferStatus.rejected,
        approvedById: user.userId,
        approvedAt: dto.actionAt ? new Date(dto.actionAt) : new Date(),
      },
    });
    return { accepted: true };
  }

  async processTransferReceive(
    user: AuthUser,
    dto: PushStockTransferActionDto,
  ): Promise<ProcessResult> {
    if (!dto.id) {
      return { accepted: false, reason: 'invalid_payload' };
    }

    const transfer = await this.prisma.stockTransfer.findUnique({
      where: { id: dto.id },
      include: { lines: true },
    });
    if (!transfer) {
      return { accepted: false, reason: 'not_found' };
    }
    if (transfer.status === TransferStatus.received) {
      return { accepted: true };
    }
    if (transfer.status !== TransferStatus.approved) {
      return { accepted: false, reason: 'invalid_status' };
    }
    if (!this.canAccessStore(user, transfer.toStoreId)) {
      return { accepted: false, reason: 'store_forbidden' };
    }

    const actionAt = dto.actionAt ? new Date(dto.actionAt) : new Date();

    try {
      await this.prisma.$transaction(async (tx) => {
        for (const line of transfer.lines) {
          const stock = await tx.productStoreStock.findUnique({
            where: {
              productId_storeId: {
                productId: line.productId,
                storeId: transfer.toStoreId,
              },
            },
          });
          if (!stock) {
            await tx.productStoreStock.create({
              data: {
                productId: line.productId,
                storeId: transfer.toStoreId,
                qty: 0,
                minQty: 0,
              },
            });
          }
          await this.adjustStock(tx, {
            storeId: transfer.toStoreId,
            productId: line.productId,
            delta: line.qty,
            requireNonNegative: false,
            docType: StockDocType.transfer,
            docId: transfer.id,
            docLineId: line.id,
            recordedById: user.userId,
            clientCreatedAt: actionAt,
          });
        }
        await tx.stockTransfer.update({
          where: { id: transfer.id },
          data: {
            status: TransferStatus.received,
            receivedById: user.userId,
            receivedAt: actionAt,
          },
        });
      });
      return { accepted: true };
    } catch (error) {
      if (error instanceof Error && error.message === 'stock_not_found') {
        return { accepted: false, reason: 'stock_not_found' };
      }
      throw error;
    }
  }

  async processStocktake(
    user: AuthUser,
    dto: PushStocktakeDto,
  ): Promise<ProcessResult> {
    if (!dto.id || !dto.storeId) {
      return { accepted: false, reason: 'invalid_payload' };
    }
    if (!Array.isArray(dto.lines) || dto.lines.length === 0) {
      return { accepted: false, reason: 'invalid_payload' };
    }
    if (Number.isNaN(Date.parse(dto.clientCreatedAt))) {
      return { accepted: false, reason: 'invalid_payload' };
    }
    if (!this.canAccessStore(user, dto.storeId)) {
      return { accepted: false, reason: 'store_forbidden' };
    }

    const existing = await this.prisma.stocktake.findUnique({
      where: { id: dto.id },
    });
    if (existing) {
      return { accepted: true };
    }

    const reasons = new Set(Object.values(StocktakeLineReason));
    const lines: {
      id: string;
      productId: string;
      systemQty: Prisma.Decimal;
      countedQty: Prisma.Decimal;
      varianceQty: Prisma.Decimal;
      reason: StocktakeLineReason;
      reasonNote: string | null;
    }[] = [];

    for (const line of dto.lines) {
      if (!line.productId || !reasons.has(line.reason as StocktakeLineReason)) {
        return { accepted: false, reason: 'invalid_payload' };
      }
      try {
        const systemQty = new Prisma.Decimal(line.systemQty);
        const countedQty = new Prisma.Decimal(line.countedQty);
        const varianceQty = new Prisma.Decimal(line.varianceQty);
        if (
          !systemQty.isFinite() ||
          !countedQty.isFinite() ||
          countedQty.lessThan(0) ||
          !varianceQty.equals(countedQty.minus(systemQty))
        ) {
          return { accepted: false, reason: 'invalid_qty' };
        }
        lines.push({
          id: line.id?.trim() || randomUUID(),
          productId: line.productId,
          systemQty,
          countedQty,
          varianceQty,
          reason: line.reason as StocktakeLineReason,
          reasonNote: line.reasonNote ?? null,
        });
      } catch {
        return { accepted: false, reason: 'invalid_qty' };
      }
    }

    const clientCreatedAt = new Date(dto.clientCreatedAt);
    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.stocktake.create({
          data: {
            id: dto.id,
            storeId: dto.storeId,
            note: dto.note ?? null,
            recordedById: user.userId,
            clientCreatedAt,
            lines: {
              create: lines.map((l) => ({
                id: l.id,
                productId: l.productId,
                systemQty: l.systemQty,
                countedQty: l.countedQty,
                varianceQty: l.varianceQty,
                reason: l.reason,
                reasonNote: l.reasonNote,
              })),
            },
          },
        });
        for (const line of lines) {
          await this.adjustStock(tx, {
            storeId: dto.storeId,
            productId: line.productId,
            delta: line.varianceQty,
            requireNonNegative: false,
            setAbsolute: line.countedQty,
            docType: StockDocType.stocktake,
            docId: dto.id,
            docLineId: line.id,
            recordedById: user.userId,
            clientCreatedAt,
          });
        }
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
        return { accepted: true };
      }
      throw error;
    }
  }

  async processPurchaseReceipt(
    user: AuthUser,
    dto: PushPurchaseReceiptDto,
  ): Promise<ProcessResult> {
    if (!dto.id || !dto.storeId || !dto.supplierName?.trim()) {
      return { accepted: false, reason: 'invalid_payload' };
    }
    if (!Array.isArray(dto.lines) || dto.lines.length === 0) {
      return { accepted: false, reason: 'invalid_payload' };
    }
    if (Number.isNaN(Date.parse(dto.clientCreatedAt))) {
      return { accepted: false, reason: 'invalid_payload' };
    }
    if (!this.canAccessStore(user, dto.storeId)) {
      return { accepted: false, reason: 'store_forbidden' };
    }

    const existing = await this.prisma.purchaseReceipt.findUnique({
      where: { id: dto.id },
    });
    if (existing) {
      return { accepted: true };
    }

    const lines: {
      id: string;
      productId: string;
      qty: Prisma.Decimal;
      unitCostVnd: number | null;
    }[] = [];
    for (const line of dto.lines) {
      const qty = this.parseQty(line.qty);
      if (!line.productId || !qty) {
        return { accepted: false, reason: 'invalid_qty' };
      }
      if (
        line.unitCostVnd != null &&
        (!Number.isSafeInteger(line.unitCostVnd) || line.unitCostVnd < 0)
      ) {
        return { accepted: false, reason: 'invalid_money' };
      }
      lines.push({
        id: line.id?.trim() || randomUUID(),
        productId: line.productId,
        qty,
        unitCostVnd: line.unitCostVnd ?? null,
      });
    }

    const clientCreatedAt = new Date(dto.clientCreatedAt);
    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.purchaseReceipt.create({
          data: {
            id: dto.id,
            storeId: dto.storeId,
            supplierName: dto.supplierName.trim(),
            supplierPhone: dto.supplierPhone ?? null,
            note: dto.note ?? null,
            recordedById: user.userId,
            clientCreatedAt,
            lines: {
              create: lines.map((l) => ({
                id: l.id,
                productId: l.productId,
                qty: l.qty,
                unitCostVnd: l.unitCostVnd,
              })),
            },
          },
        });
        for (const line of lines) {
          const stock = await tx.productStoreStock.findUnique({
            where: {
              productId_storeId: {
                productId: line.productId,
                storeId: dto.storeId,
              },
            },
          });
          if (!stock) {
            await tx.productStoreStock.create({
              data: {
                productId: line.productId,
                storeId: dto.storeId,
                qty: 0,
                minQty: 0,
              },
            });
          }
          await this.adjustStock(tx, {
            storeId: dto.storeId,
            productId: line.productId,
            delta: line.qty,
            requireNonNegative: false,
            docType: StockDocType.purchase,
            docId: dto.id,
            docLineId: line.id,
            recordedById: user.userId,
            clientCreatedAt,
          });
          if (line.unitCostVnd != null) {
            await tx.product.update({
              where: { id: line.productId },
              data: { costVnd: line.unitCostVnd },
            });
          }
        }
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
        return { accepted: true };
      }
      throw error;
    }
  }

  async processWastage(
    user: AuthUser,
    dto: PushWastageDto,
  ): Promise<ProcessResult> {
    if (!dto.id || !dto.storeId) {
      return { accepted: false, reason: 'invalid_payload' };
    }
    if (!Object.values(WastageReason).includes(dto.reasonCode as WastageReason)) {
      return { accepted: false, reason: 'invalid_payload' };
    }
    if (!Array.isArray(dto.lines) || dto.lines.length === 0) {
      return { accepted: false, reason: 'invalid_payload' };
    }
    if (Number.isNaN(Date.parse(dto.clientCreatedAt))) {
      return { accepted: false, reason: 'invalid_payload' };
    }
    if (!this.canAccessStore(user, dto.storeId)) {
      return { accepted: false, reason: 'store_forbidden' };
    }

    const existing = await this.prisma.wastageVoucher.findUnique({
      where: { id: dto.id },
    });
    if (existing) {
      return { accepted: true };
    }

    const lines: { id: string; productId: string; qty: Prisma.Decimal }[] = [];
    for (const line of dto.lines) {
      const qty = this.parseQty(line.qty);
      if (!line.productId || !qty) {
        return { accepted: false, reason: 'invalid_qty' };
      }
      lines.push({
        id: line.id?.trim() || randomUUID(),
        productId: line.productId,
        qty,
      });
    }

    const clientCreatedAt = new Date(dto.clientCreatedAt);
    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.wastageVoucher.create({
          data: {
            id: dto.id,
            storeId: dto.storeId,
            reasonCode: dto.reasonCode as WastageReason,
            note: dto.note ?? null,
            recordedById: user.userId,
            clientCreatedAt,
            lines: {
              create: lines.map((l) => ({
                id: l.id,
                productId: l.productId,
                qty: l.qty,
              })),
            },
          },
        });
        for (const line of lines) {
          await this.adjustStock(tx, {
            storeId: dto.storeId,
            productId: line.productId,
            delta: line.qty.negated(),
            requireNonNegative: true,
            docType: StockDocType.wastage,
            docId: dto.id,
            docLineId: line.id,
            recordedById: user.userId,
            clientCreatedAt,
          });
        }
      });
      return { accepted: true };
    } catch (error) {
      if (error instanceof Error) {
        if (error.message === 'stock_not_found') {
          return { accepted: false, reason: 'stock_not_found' };
        }
        if (error.message === 'insufficient_stock') {
          return { accepted: false, reason: 'insufficient_stock' };
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

  async pullInventory(storeId: string, since: Date) {
    const [
      stockTransfers,
      stocktakes,
      purchaseReceipts,
      wastageVouchers,
      stockMovements,
    ] = await Promise.all([
      this.prisma.stockTransfer.findMany({
        where: {
          updatedAt: { gt: since },
          OR: [{ fromStoreId: storeId }, { toStoreId: storeId }],
        },
        include: { lines: true },
        orderBy: { updatedAt: 'asc' },
      }),
      this.prisma.stocktake.findMany({
        where: { storeId, updatedAt: { gt: since } },
        include: { lines: true },
        orderBy: { clientCreatedAt: 'asc' },
      }),
      this.prisma.purchaseReceipt.findMany({
        where: { storeId, updatedAt: { gt: since } },
        include: { lines: true },
        orderBy: { clientCreatedAt: 'asc' },
      }),
      this.prisma.wastageVoucher.findMany({
        where: { storeId, updatedAt: { gt: since } },
        include: { lines: true },
        orderBy: { clientCreatedAt: 'asc' },
      }),
      this.prisma.stockMovement.findMany({
        where: { storeId, updatedAt: { gt: since } },
        orderBy: { clientCreatedAt: 'asc' },
      }),
    ]);

    return {
      stockTransfers: stockTransfers.map((t) => ({
        id: t.id,
        fromStoreId: t.fromStoreId,
        toStoreId: t.toStoreId,
        status: t.status,
        note: t.note,
        createdById: t.createdById,
        approvedById: t.approvedById,
        receivedById: t.receivedById,
        clientCreatedAt: t.clientCreatedAt.toISOString(),
        approvedAt: t.approvedAt?.toISOString() ?? null,
        receivedAt: t.receivedAt?.toISOString() ?? null,
        updatedAt: t.updatedAt.toISOString(),
        lines: t.lines.map((l) => ({
          id: l.id,
          productId: l.productId,
          qty: l.qty.toString(),
        })),
      })),
      stocktakes: stocktakes.map((s) => ({
        id: s.id,
        storeId: s.storeId,
        note: s.note,
        recordedById: s.recordedById,
        clientCreatedAt: s.clientCreatedAt.toISOString(),
        updatedAt: s.updatedAt.toISOString(),
        lines: s.lines.map((l) => ({
          id: l.id,
          productId: l.productId,
          systemQty: l.systemQty.toString(),
          countedQty: l.countedQty.toString(),
          varianceQty: l.varianceQty.toString(),
          reason: l.reason,
          reasonNote: l.reasonNote,
        })),
      })),
      purchaseReceipts: purchaseReceipts.map((r) => ({
        id: r.id,
        storeId: r.storeId,
        supplierName: r.supplierName,
        supplierPhone: r.supplierPhone,
        note: r.note,
        recordedById: r.recordedById,
        clientCreatedAt: r.clientCreatedAt.toISOString(),
        updatedAt: r.updatedAt.toISOString(),
        lines: r.lines.map((l) => ({
          id: l.id,
          productId: l.productId,
          qty: l.qty.toString(),
          unitCostVnd: l.unitCostVnd,
        })),
      })),
      wastageVouchers: wastageVouchers.map((w) => ({
        id: w.id,
        storeId: w.storeId,
        reasonCode: w.reasonCode,
        note: w.note,
        recordedById: w.recordedById,
        clientCreatedAt: w.clientCreatedAt.toISOString(),
        updatedAt: w.updatedAt.toISOString(),
        lines: w.lines.map((l) => ({
          id: l.id,
          productId: l.productId,
          qty: l.qty.toString(),
        })),
      })),
      stockMovements: stockMovements.map((m) => ({
        id: m.id,
        storeId: m.storeId,
        productId: m.productId,
        qtyDelta: m.qtyDelta.toString(),
        balanceAfter: m.balanceAfter.toString(),
        docType: m.docType,
        docId: m.docId,
        docLineId: m.docLineId,
        recordedById: m.recordedById,
        clientCreatedAt: m.clientCreatedAt.toISOString(),
        updatedAt: m.updatedAt.toISOString(),
      })),
    };
  }
}
