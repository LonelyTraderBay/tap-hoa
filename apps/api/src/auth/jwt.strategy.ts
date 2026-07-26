import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { PrismaService } from '../prisma/prisma.service';
import { getJwtSecret } from './jwt.config';
import { effectivePermissions } from './permission-flags';

export type JwtPayload = {
  sub: string;
  role: string;
  storeIds: string[];
  canLedger?: boolean;
  canEinvoice?: boolean;
};

export type AuthUser = {
  userId: string;
  role: string;
  storeIds: string[];
  canLedger: boolean;
  canEinvoice: boolean;
};

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private readonly prisma: PrismaService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: getJwtSecret(),
    });
  }

  async validate(payload: JwtPayload): Promise<AuthUser> {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      include: { stores: true },
    });
    if (!user?.active) {
      throw new UnauthorizedException('User is inactive');
    }
    const permissions = effectivePermissions(user);
    return {
      userId: user.id,
      role: user.role,
      storeIds: user.stores.map((store) => store.storeId),
      ...permissions,
    };
  }
}
