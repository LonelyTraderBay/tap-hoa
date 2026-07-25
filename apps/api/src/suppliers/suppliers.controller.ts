import {
  BadRequestException,
  Body,
  Controller,
  ForbiddenException,
  Get,
  Param,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { CashChannel, Prisma, Role, StockDocType } from '@prisma/client';
import { randomUUID } from 'crypto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthUser } from '../auth/jwt.strategy';
import { LedgerService } from '../ledger/ledger.service';
import { PrismaService } from '../prisma/prisma.service';

@Controller('suppliers')
@UseGuards(JwtAuthGuard)
export class SuppliersController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ledger: LedgerService,
  ) {}

  @Get()
  list(@Req() req: { user: AuthUser }) {
    this.assertOwnerOrManager(req.user);
    return this.prisma.supplier.findMany({
      where: { active: true },
      orderBy: { name: 'asc' },
    });
  }

  @Post()
  create(
    @Req() req: { user: AuthUser },
    @Body() body: { name?: string; phone?: string; note?: string },
  ) {
    this.assertOwnerOrManager(req.user);
    if (!body?.name?.trim()) {
      throw new BadRequestException('name required');
    }
    return this.prisma.supplier.create({
      data: {
        id: randomUUID(),
        name: body.name.trim(),
        phone: body.phone ?? null,
        note: body.note ?? null,
      },
    });
  }

  @Get('bank-accounts')
  banks(@Req() req: { user: AuthUser }) {
    this.assertOwnerOrManager(req.user);
    return this.prisma.bankAccount.findMany({
      where: { active: true },
      orderBy: { name: 'asc' },
    });
  }

  @Post('bank-accounts')
  createBank(
    @Req() req: { user: AuthUser },
    @Body() body: { name?: string; bankName?: string; accountNo?: string },
  ) {
    if (req.user.role !== Role.owner) {
      throw new ForbiddenException('owner_required');
    }
    if (!body?.name?.trim()) {
      throw new BadRequestException('name required');
    }
    return this.prisma.bankAccount.create({
      data: {
        id: randomUUID(),
        name: body.name.trim(),
        bankName: body.bankName ?? null,
        accountNo: body.accountNo ?? null,
      },
    });
  }

  @Get(':id/payables')
  payables(@Req() req: { user: AuthUser }, @Param('id') id: string) {
    this.assertOwnerOrManager(req.user);
    return this.prisma.supplierPayable.findMany({
      where: { supplierId: id, balanceVnd: { gt: 0 } },
      orderBy: { clientCreatedAt: 'asc' },
    });
  }

  @Post(':id/payments')
  async pay(
    @Req() req: { user: AuthUser },
    @Param('id') supplierId: string,
    @Body()
    body: {
      storeId?: string;
      amountVnd?: number;
      channel?: 'cash' | 'transfer';
      bankAccountId?: string;
      note?: string;
      clientCreatedAt?: string;
    },
  ) {
    this.assertOwnerOrManager(req.user);
    if (!body.storeId || !body.amountVnd || body.amountVnd <= 0) {
      throw new BadRequestException('storeId and amountVnd required');
    }
    if (
      req.user.role !== Role.owner &&
      !req.user.storeIds.includes(body.storeId)
    ) {
      throw new ForbiddenException('store_forbidden');
    }
    const supplier = await this.prisma.supplier.findUnique({
      where: { id: supplierId },
    });
    if (!supplier) {
      throw new BadRequestException('supplier_not_found');
    }
    const channel =
      body.channel === 'transfer' ? CashChannel.transfer : CashChannel.cash;
    const id = randomUUID();
    const at = body.clientCreatedAt
      ? new Date(body.clientCreatedAt)
      : new Date();

    await this.prisma.$transaction(async (tx) => {
      let remaining = body.amountVnd!;
      const payables = await tx.supplierPayable.findMany({
        where: {
          supplierId,
          storeId: body.storeId,
          balanceVnd: { gt: 0 },
        },
        orderBy: { clientCreatedAt: 'asc' },
      });
      for (const p of payables) {
        if (remaining <= 0) break;
        const take = Math.min(remaining, p.balanceVnd);
        await tx.supplierPayable.update({
          where: { id: p.id },
          data: { balanceVnd: p.balanceVnd - take },
        });
        remaining -= take;
      }
      await tx.supplierPayment.create({
        data: {
          id,
          supplierId,
          storeId: body.storeId!,
          amountVnd: body.amountVnd!,
          channel,
          bankAccountId: body.bankAccountId ?? null,
          note: body.note ?? null,
          recordedById: req.user.userId,
          clientCreatedAt: at,
        },
      });
    });

    await this.ledger.safePost(
      () => this.ledger.postFromSupplierPayment(id, req.user.userId),
      {
        sourceType: 'supplier_payment',
        sourceId: id,
        actorUserId: req.user.userId,
      },
    );

    return { id };
  }

  /**
   * Return goods to supplier: decrease stock, reduce AP FIFO, reverse purchase journal.
   * unitCostVnd is VAT-inclusive gross (same as purchase).
   */
  @Post(':id/returns')
  async createReturn(
    @Req() req: { user: AuthUser },
    @Param('id') supplierId: string,
    @Body()
    body: {
      storeId?: string;
      note?: string;
      clientCreatedAt?: string;
      lines?: {
        productId?: string;
        qty?: string | number;
        unitCostVnd?: number;
      }[];
    },
  ) {
    this.assertOwnerOrManager(req.user);
    if (!body.storeId || !Array.isArray(body.lines) || body.lines.length === 0) {
      throw new BadRequestException('storeId and lines required');
    }
    if (
      req.user.role !== Role.owner &&
      !req.user.storeIds.includes(body.storeId)
    ) {
      throw new ForbiddenException('store_forbidden');
    }
    const supplier = await this.prisma.supplier.findUnique({
      where: { id: supplierId },
    });
    if (!supplier) {
      throw new BadRequestException('supplier_not_found');
    }

    const lines: {
      id: string;
      productId: string;
      qty: Prisma.Decimal;
      unitCostVnd: number;
    }[] = [];
    let amountVnd = 0;
    for (const line of body.lines) {
      if (!line.productId || line.unitCostVnd == null || line.unitCostVnd < 0) {
        throw new BadRequestException('invalid_line');
      }
      const qty = new Prisma.Decimal(String(line.qty ?? ''));
      if (qty.lte(0)) {
        throw new BadRequestException('invalid_qty');
      }
      amountVnd += Math.round(Number(qty) * line.unitCostVnd);
      lines.push({
        id: randomUUID(),
        productId: line.productId,
        qty,
        unitCostVnd: line.unitCostVnd,
      });
    }
    if (amountVnd <= 0) {
      throw new BadRequestException('invalid_amount');
    }

    const id = randomUUID();
    const at = body.clientCreatedAt
      ? new Date(body.clientCreatedAt)
      : new Date();

    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.supplierReturn.create({
          data: {
            id,
            storeId: body.storeId!,
            supplierId,
            note: body.note ?? null,
            amountVnd,
            recordedById: req.user.userId,
            clientCreatedAt: at,
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
                storeId: body.storeId!,
              },
            },
          });
          if (!stock) {
            throw new Error('stock_not_found');
          }
          const nextQty = stock.qty.minus(line.qty);
          if (nextQty.lessThan(0)) {
            throw new Error('insufficient_stock');
          }
          await tx.productStoreStock.update({
            where: {
              productId_storeId: {
                productId: line.productId,
                storeId: body.storeId!,
              },
            },
            data: { qty: nextQty },
          });
          await tx.stockMovement.create({
            data: {
              id: randomUUID(),
              storeId: body.storeId!,
              productId: line.productId,
              qtyDelta: line.qty.negated(),
              balanceAfter: nextQty,
              docType: StockDocType.supplier_return,
              docId: id,
              docLineId: line.id,
              recordedById: req.user.userId,
              clientCreatedAt: at,
            },
          });
        }

        let remaining = amountVnd;
        const payables = await tx.supplierPayable.findMany({
          where: {
            supplierId,
            storeId: body.storeId,
            balanceVnd: { gt: 0 },
          },
          orderBy: { clientCreatedAt: 'asc' },
        });
        for (const p of payables) {
          if (remaining <= 0) break;
          const take = Math.min(remaining, p.balanceVnd);
          await tx.supplierPayable.update({
            where: { id: p.id },
            data: { balanceVnd: p.balanceVnd - take },
          });
          remaining -= take;
        }
      });
    } catch (error) {
      if (error instanceof Error) {
        if (error.message === 'stock_not_found') {
          throw new BadRequestException('stock_not_found');
        }
        if (error.message === 'insufficient_stock') {
          throw new BadRequestException('insufficient_stock');
        }
      }
      throw error;
    }

    await this.ledger.safePost(
      () => this.ledger.postFromSupplierReturn(id, req.user.userId),
      {
        sourceType: 'supplier_return',
        sourceId: id,
        actorUserId: req.user.userId,
      },
    );

    return { id, amountVnd };
  }

  private assertOwnerOrManager(user: AuthUser) {
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
  }
}
