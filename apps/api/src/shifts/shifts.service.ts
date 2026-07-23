import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, Role, Shift } from '@prisma/client';
import { AuthUser } from '../auth/jwt.strategy';
import { PrismaService } from '../prisma/prisma.service';

type OpenShiftDto = {
  storeId: string;
  openingCash: number;
  clientId: string;
};

type CloseShiftDto = {
  closingCash: number;
  note?: string;
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

    // Partial unique on (storeId, userId) WHERE closedAt IS NULL may be added later.
    try {
      return await this.prisma.shift.create({
        data: {
          id: dto.clientId,
          storeId: dto.storeId,
          userId: user.userId,
          openedAt: new Date(),
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

  async close(user: AuthUser, shiftId: string, dto: CloseShiftDto) {
    const shift = await this.prisma.shift.findUnique({ where: { id: shiftId } });
    if (!shift) {
      throw new NotFoundException('Shift not found');
    }
    if (shift.userId !== user.userId) {
      throw new ForbiddenException('Cannot close another user shift');
    }
    if (shift.closedAt) {
      throw new ConflictException('Shift already closed');
    }

    return this.prisma.shift.update({
      where: { id: shiftId },
      data: {
        closedAt: new Date(),
        closingCash: dto.closingCash,
        note: dto.note,
      },
    });
  }
}
