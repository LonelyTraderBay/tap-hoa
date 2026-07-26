import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { randomUUID } from 'crypto';
import { AuthUser } from '../auth/jwt.strategy';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCustomerDto } from './dto/create-customer.dto';

@Injectable()
export class CustomersService {
  constructor(private readonly prisma: PrismaService) {}

  private assertStoreAccess(user: AuthUser, storeId: string) {
    if (user.role === Role.owner) {
      return;
    }
    if (!storeId || !user.storeIds.includes(storeId)) {
      throw new ForbiddenException('No access to this store');
    }
  }

  private assertOwnerOrManager(user: AuthUser, storeId: string) {
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
    this.assertStoreAccess(user, storeId);
  }

  async create(user: AuthUser, dto: CreateCustomerDto) {
    this.assertStoreAccess(user, dto.storeId);
    if (!dto.name?.trim()) {
      throw new BadRequestException('name is required');
    }
    const id = dto.id ?? randomUUID();
    const existing = await this.prisma.customer.findUnique({ where: { id } });
    if (existing && existing.storeId !== dto.storeId) {
      throw new ForbiddenException('Customer belongs to another store');
    }
    return this.prisma.customer.upsert({
      where: { id },
      create: {
        id,
        storeId: dto.storeId,
        name: dto.name.trim(),
        phone: dto.phone?.trim() || null,
        creditLimitVnd: dto.creditLimitVnd ?? null,
      },
      update: {
        name: dto.name.trim(),
        phone: dto.phone?.trim() || null,
        creditLimitVnd:
          dto.creditLimitVnd === undefined ? undefined : dto.creditLimitVnd,
      },
      select: {
        id: true,
        storeId: true,
        name: true,
        phone: true,
        balanceVnd: true,
        creditLimitVnd: true,
        updatedAt: true,
        createdAt: true,
      },
    });
  }

  async list(user: AuthUser, storeId: string, withDebt: boolean) {
    this.assertStoreAccess(user, storeId);
    return this.prisma.customer.findMany({
      where: {
        storeId,
        ...(withDebt ? { balanceVnd: { gt: 0 } } : {}),
      },
      select: {
        id: true,
        storeId: true,
        name: true,
        phone: true,
        balanceVnd: true,
        creditLimitVnd: true,
        updatedAt: true,
        createdAt: true,
      },
      orderBy: [{ balanceVnd: 'desc' }, { name: 'asc' }],
    });
  }

  async adjustDebt(
    user: AuthUser,
    customerId: string,
    dto: { amountVnd?: number; reason?: string },
  ) {
    if (!Number.isSafeInteger(dto.amountVnd) || dto.amountVnd === 0) {
      throw new BadRequestException('amountVnd must be a non-zero integer');
    }
    const reason = dto.reason?.trim();
    if (!reason) {
      throw new BadRequestException('reason is required');
    }
    if (reason.length > 500) {
      throw new BadRequestException('reason is too long');
    }

    const now = new Date();
    return this.prisma.$transaction(async (tx) => {
      const customer = await tx.customer.findUnique({
        where: { id: customerId },
      });
      if (!customer) {
        throw new NotFoundException('customer_not_found');
      }
      this.assertOwnerOrManager(user, customer.storeId);

      const nextBalance = customer.balanceVnd + dto.amountVnd!;
      if (nextBalance < 0) {
        throw new BadRequestException('debt_adjust_negative_balance');
      }

      const updated = await tx.customer.update({
        where: { id: customer.id },
        data: { balanceVnd: nextBalance },
        select: {
          id: true,
          storeId: true,
          name: true,
          phone: true,
          balanceVnd: true,
          creditLimitVnd: true,
          updatedAt: true,
          createdAt: true,
        },
      });
      const ledgerEntryId = randomUUID();
      await tx.debtLedgerEntry.create({
        data: {
          id: ledgerEntryId,
          storeId: customer.storeId,
          customerId: customer.id,
          type: 'debt_adjust',
          amountVnd: dto.amountVnd!,
          balanceAfterVnd: updated.balanceVnd,
          recordedById: user.userId,
          note: reason,
          clientCreatedAt: now,
        },
      });
      await tx.auditLog.create({
        data: {
          id: randomUUID(),
          actorUserId: user.userId,
          action: 'debt_adjust',
          entityType: 'customer',
          entityId: customer.id,
          detailJson: JSON.stringify({
            storeId: customer.storeId,
            amountVnd: dto.amountVnd,
            reason,
            balanceBeforeVnd: customer.balanceVnd,
            balanceAfterVnd: updated.balanceVnd,
            debtLedgerEntryId: ledgerEntryId,
          }),
        },
      });
      return {
        ...updated,
        debtLedgerEntryId: ledgerEntryId,
      };
    });
  }
}
