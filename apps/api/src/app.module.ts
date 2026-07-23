import { Module } from '@nestjs/common';
import { AuthModule } from './auth/auth.module';
import { HealthController } from './health.controller';
import { PrismaModule } from './prisma/prisma.module';
import { StoresModule } from './stores/stores.module';

@Module({
  imports: [PrismaModule, AuthModule, StoresModule],
  controllers: [HealthController],
})
export class AppModule {}
