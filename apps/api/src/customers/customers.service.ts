import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCustomerDto } from './dto/create-customer.dto';

@Injectable()
export class CustomersService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateCustomerDto) {
    const id = dto.id ?? randomUUID();
    return this.prisma.customer.upsert({
      where: { id },
      create: {
        id,
        name: dto.name.trim(),
        phone: dto.phone?.trim() || null,
      },
      update: {
        name: dto.name.trim(),
        phone: dto.phone?.trim() || null,
      },
      select: {
        id: true,
        name: true,
        phone: true,
        balanceVnd: true,
        updatedAt: true,
        createdAt: true,
      },
    });
  }

  async listWithDebt() {
    return this.prisma.customer.findMany({
      where: { balanceVnd: { gt: 0 } },
      select: {
        id: true,
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
