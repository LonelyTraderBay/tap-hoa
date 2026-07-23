import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { PrismaService } from '../prisma/prisma.service';
import { getJwtSecret } from './jwt.config';

export type JwtPayload = {
  sub: string;
  role: string;
  storeIds: string[];
};

export type AuthUser = {
  userId: string;
  role: string;
  storeIds: string[];
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
    return {
      userId: user.id,
      role: user.role,
      storeIds: user.stores.map((store) => store.storeId),
    };
  }
}
