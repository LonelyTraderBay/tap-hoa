import { Module } from '@nestjs/common';
import { AuthModule } from './auth/auth.module';
import { HealthController } from './health.controller';
import { PrismaModule } from './prisma/prisma.module';
import { ProductsModule } from './products/products.module';
import { ShiftsModule } from './shifts/shifts.module';
import { StoresModule } from './stores/stores.module';
import { ReportsModule } from './reports/reports.module';
import { SyncModule } from './sync/sync.module';

@Module({
  imports: [
    PrismaModule,
    AuthModule,
    StoresModule,
    ShiftsModule,
    ProductsModule,
    SyncModule,
    ReportsModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
