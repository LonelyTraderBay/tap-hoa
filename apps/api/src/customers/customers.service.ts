import {
  BadRequestException,
  ForbiddenException,
  Injectable,
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
      },
      update: {
        name: dto.name.trim(),
        phone: dto.phone?.trim() || null,
      },
      select: {
        id: true,
        storeId: true,
        name: true,
        phone: true,
        balanceVnd: true,
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
        updatedAt: true,
        createdAt: true,
      },
      orderBy: [{ balanceVnd: 'desc' }, { name: 'asc' }],
    });
  }
}
