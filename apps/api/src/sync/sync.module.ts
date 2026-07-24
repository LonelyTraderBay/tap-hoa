import { Module } from '@nestjs/common';
import { CustomersModule } from '../customers/customers.module';
import { PrismaModule } from '../prisma/prisma.module';
import { ProductsModule } from '../products/products.module';
import { ShiftsModule } from '../shifts/shifts.module';
import { StockOpsService } from './stock-ops.service';
import { SyncController } from './sync.controller';
import { SyncService } from './sync.service';

@Module({
  imports: [PrismaModule, ProductsModule, CustomersModule, ShiftsModule],
  controllers: [SyncController],
  providers: [SyncService, StockOpsService],
})
export class SyncModule {}
