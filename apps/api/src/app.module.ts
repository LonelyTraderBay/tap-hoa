import { Module } from '@nestjs/common';
import { AuthModule } from './auth/auth.module';
import { HealthController } from './health.controller';
import { PrismaModule } from './prisma/prisma.module';
import { ShiftsModule } from './shifts/shifts.module';
import { StoresModule } from './stores/stores.module';

@Module({
  imports: [PrismaModule, AuthModule, StoresModule, ShiftsModule],
  controllers: [HealthController],
})
export class AppModule {}
