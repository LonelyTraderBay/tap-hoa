import {
  BadRequestException,
  Body,
  Controller,
  ForbiddenException,
  Get,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthUser } from '../auth/jwt.strategy';
import { SuppliersService } from './suppliers.service';

@Controller('suppliers')
@UseGuards(JwtAuthGuard)
export class SuppliersController {
  constructor(private readonly suppliers: SuppliersService) {}

  @Get()
  list(@Req() req: { user: AuthUser }) {
    this.suppliers.assertOwnerOrManager(req.user);
    return this.suppliers.list();
  }

  @Post()
  create(
    @Req() req: { user: AuthUser },
    @Body() body: { name?: string; phone?: string; note?: string },
  ) {
    this.suppliers.assertOwnerOrManager(req.user);
    if (!body?.name?.trim()) {
      throw new BadRequestException('name required');
    }
    return this.suppliers.create({
      name: body.name,
      phone: body.phone,
      note: body.note,
    });
  }

  @Get('bank-accounts')
  banks(@Req() req: { user: AuthUser }) {
    this.suppliers.assertOwnerOrManager(req.user);
    return this.suppliers.bankAccounts();
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
    return this.suppliers.createBank({
      name: body.name,
      bankName: body.bankName,
      accountNo: body.accountNo,
    });
  }

  @Get(':id/payables')
  payables(
    @Req() req: { user: AuthUser },
    @Param('id') id: string,
    @Query('storeId') storeId?: string,
  ) {
    this.suppliers.assertOwnerOrManager(req.user);
    return this.suppliers.payables(id, storeId);
  }

  @Get(':id/returnable-receipts')
  returnable(
    @Req() req: { user: AuthUser },
    @Param('id') id: string,
    @Query('storeId') storeId?: string,
  ) {
    this.suppliers.assertOwnerOrManager(req.user);
    if (!storeId) throw new BadRequestException('storeId required');
    this.suppliers.assertStoreAccess(req.user, storeId);
    return this.suppliers.returnableReceipts(id, storeId);
  }

  @Post(':id/payments')
  pay(
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
    if (!body.storeId || !body.amountVnd) {
      throw new BadRequestException('storeId and amountVnd required');
    }
    return this.suppliers.pay(req.user, supplierId, {
      storeId: body.storeId,
      amountVnd: body.amountVnd,
      channel: body.channel,
      bankAccountId: body.bankAccountId,
      note: body.note,
      clientCreatedAt: body.clientCreatedAt,
    });
  }

  @Post(':id/returns')
  createReturn(
    @Req() req: { user: AuthUser },
    @Param('id') supplierId: string,
    @Body()
    body: {
      storeId?: string;
      purchaseReceiptId?: string;
      clientId?: string;
      note?: string;
      clientCreatedAt?: string;
      lines?: {
        productId?: string;
        qty?: string | number;
        unitCostVnd?: number;
        purchaseReceiptLineId?: string;
      }[];
    },
  ) {
    if (!body.storeId || !body.purchaseReceiptId || !body.lines?.length) {
      throw new BadRequestException(
        'storeId, purchaseReceiptId and lines required',
      );
    }
    for (const l of body.lines) {
      if (!l.productId || l.unitCostVnd == null) {
        throw new BadRequestException('invalid_line');
      }
    }
    return this.suppliers.createReturn(req.user, supplierId, {
      storeId: body.storeId,
      purchaseReceiptId: body.purchaseReceiptId,
      clientId: body.clientId,
      note: body.note,
      clientCreatedAt: body.clientCreatedAt,
      lines: body.lines.map((l) => ({
        productId: l.productId!,
        qty: l.qty ?? 0,
        unitCostVnd: l.unitCostVnd!,
        purchaseReceiptLineId: l.purchaseReceiptLineId,
      })),
    });
  }
}
