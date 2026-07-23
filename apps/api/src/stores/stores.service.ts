import { Injectable } from '@nestjs/common';
import { Role } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class StoresService {
  constructor(private readonly prisma: PrismaService) {}

  async findForUser(role: Role, storeIds: string[]) {
    if (role === Role.owner) {
      return this.prisma.store.findMany({
        where: { active: true },
        select: { id: true, code: true, name: true },
        orderBy: { code: 'asc' },
      });
    }
    return this.prisma.store.findMany({
      where: { active: true, id: { in: storeIds } },
      select: { id: true, code: true, name: true },
      orderBy: { code: 'asc' },
    });
  }
}
