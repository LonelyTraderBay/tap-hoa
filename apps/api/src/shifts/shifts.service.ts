import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, Role, Shift } from '@prisma/client';
import { AuthUser } from '../auth/jwt.strategy';
import {
  ShiftCashInputs,
  computeShiftCashSnapshot,
} from '../cash/expected-cash';
import { PrismaService } from '../prisma/prisma.service';

export type OpenShiftDto = {
  storeId: string;
  openingCash: number;
  clientId: string;
  openedAt?: string;
};

export type CloseShiftDto = {
  closingCash: number;
  note?: string;
  closedAt?: string;
};

@Injectable()
export class ShiftsService {
  constructor(private readonly prisma: PrismaService) {}

  private assertStoreAccess(user: AuthUser, storeId: string) {
    if (user.role === Role.owner) {
      return;
    }
    if (!user.storeIds.includes(storeId)) {
      throw new ForbiddenException('No access to this store');
    }
  }

  private validateExistingShiftForOpen(
    user: AuthUser,
    dto: OpenShiftDto,
    shift: Shift,
  ) {
    if (shift.userId !== user.userId) {
      throw new ForbiddenException('Cannot open another user shift');
    }
    this.assertStoreAccess(user, shift.storeId);
    if (dto.storeId !== shift.storeId) {
      throw new ForbiddenException('Store mismatch for shift');
    }
    if (shift.closedAt != null) {
      throw new ConflictException('Shift already closed');
    }
  }

  private async loadShiftCashInputsWithClient(
    client: Prisma.TransactionClient,
    shiftId: string,
  ): Promise<ShiftCashInputs> {
    const shift = await client.shift.findUniqueOrThrow({
      where: { id: shiftId },
    });

    const salesAgg = await client.sale.aggregate({
      where: { shiftId },
      _sum: { cashAmount: true, transferAmount: true },
    });

    const debtPayments = await client.debtLedgerEntry.findMany({
      where: { shiftId, type: 'payment' },
      select: { paymentMethod: true, amountVnd: true },
    });

    const vouchers = await client.cashVoucher.findMany({
      where: { shiftId },
      select: { direction: true, channel: true, amountVnd: true },
    });

    let debtPaymentCashTotal = 0;
    let debtPaymentTransferTotal = 0;
    for (const entry of debtPayments) {
      if (entry.paymentMethod === 'cash') {
        debtPaymentCashTotal += entry.amountVnd;
      } else if (entry.paymentMethod === 'transfer') {
        debtPaymentTransferTotal += entry.amountVnd;
      }
    }

    let voucherCashInTotal = 0;
    let voucherCashOutTotal = 0;
    let voucherTransferInTotal = 0;
    let voucherTransferOutTotal = 0;
    for (const voucher of vouchers) {
      if (voucher.direction === 'in' && voucher.channel === 'cash') {
        voucherCashInTotal += voucher.amountVnd;
      } else if (voucher.direction === 'out' && voucher.channel === 'cash') {
        voucherCashOutTotal += voucher.amountVnd;
      } else if (voucher.direction === 'in' && voucher.channel === 'transfer') {
        voucherTransferInTotal += voucher.amountVnd;
      } else if (voucher.direction === 'out' && voucher.channel === 'transfer') {
        voucherTransferOutTotal += voucher.amountVnd;
      }
    }

    return {
      openingCash: shift.openingCash,
      saleCashTotal: salesAgg._sum.cashAmount ?? 0,
      saleTransferTotal: salesAgg._sum.transferAmount ?? 0,
      debtPaymentCashTotal,
      debtPaymentTransferTotal,
      voucherCashInTotal,
      voucherCashOutTotal,
      voucherTransferInTotal,
      voucherTransferOutTotal,
    };
  }

  async loadShiftCashInputs(shiftId: string): Promise<ShiftCashInputs> {
    return this.prisma.$transaction((tx) =>
      this.loadShiftCashInputsWithClient(tx, shiftId),
    );
  }

  async open(user: AuthUser, dto: OpenShiftDto) {
    this.assertStoreAccess(user, dto.storeId);

    const existingById = await this.prisma.shift.findUnique({
      where: { id: dto.clientId },
    });
    if (existingById) {
      this.validateExistingShiftForOpen(user, dto, existingById);
      return existingById;
    }

    const existing = await this.prisma.shift.findFirst({
      where: { storeId: dto.storeId, userId: user.userId, closedAt: null },
    });
    if (existing) {
      throw new ConflictException('Shift already open');
    }

    try {
      return await this.prisma.shift.create({
        data: {
          id: dto.clientId,
          storeId: dto.storeId,
          userId: user.userId,
          openedAt: dto.openedAt ? new Date(dto.openedAt) : new Date(),
          openingCash: dto.openingCash,
        },
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        const raced = await this.prisma.shift.findUnique({
          where: { id: dto.clientId },
        });
        if (raced) {
          this.validateExistingShiftForOpen(user, dto, raced);
          return raced;
        }
        throw new ConflictException('Shift already open');
      }
      throw error;
    }
  }

  async upsertFromSync(user: AuthUser, dto: OpenShiftDto) {
    this.assertStoreAccess(user, dto.storeId);
    const existing = await this.prisma.shift.findUnique({
      where: { id: dto.clientId },
    });
    if (existing) {
      if (
        existing.userId !== user.userId ||
        existing.storeId !== dto.storeId
      ) {
        throw new ForbiddenException('Shift ownership mismatch');
      }
      return existing;
    }
    return this.open(user, dto);
  }

  async close(user: AuthUser, shiftId: string, dto: CloseShiftDto) {
    // Sequential ops in one transaction: re-read open shift, aggregate, close atomically.
    return this.prisma.$transaction(async (tx) => {
      const shift = await tx.shift.findUnique({ where: { id: shiftId } });
      if (!shift) {
        throw new NotFoundException('Shift not found');
      }
      if (shift.userId !== user.userId) {
        throw new ForbiddenException('Cannot close another user shift');
      }
      if (shift.closedAt) {
        throw new ConflictException('Shift already closed');
      }

      const inputs = await this.loadShiftCashInputsWithClient(tx, shiftId);
      const snapshot = computeShiftCashSnapshot(inputs, dto.closingCash);
      const closedAt = dto.closedAt ? new Date(dto.closedAt) : new Date();

      const updated = await tx.shift.updateMany({
        where: { id: shiftId, closedAt: null },
        data: {
          closedAt,
          closingCash: dto.closingCash,
          note: dto.note,
          expectedCashVnd: snapshot.expectedCashVnd,
          varianceVnd: snapshot.varianceVnd,
          transferInShiftVnd: snapshot.transferInShiftVnd,
        },
      });
      if (updated.count === 0) {
        throw new ConflictException('Shift already closed');
      }

      return tx.shift.findUniqueOrThrow({ where: { id: shiftId } });
    });
  }

  async closeFromSync(user: AuthUser, shiftId: string, dto: CloseShiftDto) {
    const shift = await this.prisma.shift.findUnique({ where: { id: shiftId } });
    if (!shift) {
      throw new NotFoundException('Shift not found');
    }
    if (shift.userId !== user.userId) {
      throw new ForbiddenException('Cannot close another user shift');
    }
    this.assertStoreAccess(user, shift.storeId);
    if (shift.closedAt) {
      return shift;
    }
    return this.close(user, shiftId, dto);
  }
}
