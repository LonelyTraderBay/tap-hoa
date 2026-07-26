import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { effectivePermissions } from './permission-flags';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async login(phone: string, password: string) {
    const user = await this.prisma.user.findUnique({
      where: { phone },
      include: { stores: true },
    });
    if (
      !user?.active ||
      !(await bcrypt.compare(password, user.passwordHash))
    ) {
      throw new UnauthorizedException('Invalid credentials');
    }
    const storeIds = user.stores.map((s) => s.storeId);
    const permissions = effectivePermissions(user);
    const accessToken = await this.jwt.signAsync({
      sub: user.id,
      role: user.role,
      storeIds,
      ...permissions,
    });
    return {
      accessToken,
      user: {
        id: user.id,
        name: user.name,
        role: user.role,
        storeIds,
        ...permissions,
      },
    };
  }
}
