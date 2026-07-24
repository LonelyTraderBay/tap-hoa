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
import { CashChannel, Role } from '@prisma/client';
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

  private assertOwnerOrManager(user: AuthUser) {
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
  }
}
