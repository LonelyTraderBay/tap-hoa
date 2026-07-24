import { Module } from '@nestjs/common';
import { CustomersModule } from '../customers/customers.module';
import { DevicesModule } from '../devices/devices.module';
import { PrismaModule } from '../prisma/prisma.module';
import { ProductsModule } from '../products/products.module';
import { ShiftsModule } from '../shifts/shifts.module';
import { SaleReturnsService } from './sale-returns.service';
import { StockOpsService } from './stock-ops.service';
import { SyncController } from './sync.controller';
import { SyncService } from './sync.service';

@Module({
  imports: [
    PrismaModule,
    ProductsModule,
    CustomersModule,
    ShiftsModule,
    DevicesModule,
  ],
  controllers: [SyncController],
  providers: [SyncService, StockOpsService, SaleReturnsService],
})
export class SyncModule {}
