import { Module } from '@nestjs/common';
import { AuthModule } from './auth/auth.module';
import { DevicesModule } from './devices/devices.module';
import { HealthController } from './health.controller';
import { PrismaModule } from './prisma/prisma.module';
import { ProductsModule } from './products/products.module';
import { ShiftsModule } from './shifts/shifts.module';
import { StoresModule } from './stores/stores.module';
import { UsersModule } from './users/users.module';
import { CustomersModule } from './customers/customers.module';
import { ReportsModule } from './reports/reports.module';
import { SyncModule } from './sync/sync.module';
import { LedgerModule } from './ledger/ledger.module';
import { SuppliersModule } from './suppliers/suppliers.module';
import { EInvoiceModule } from './einvoice/einvoice.module';

@Module({
  imports: [
    PrismaModule,
    AuthModule,
    StoresModule,
    UsersModule,
    ShiftsModule,
    ProductsModule,
    CustomersModule,
    SyncModule,
    ReportsModule,
    DevicesModule,
    LedgerModule,
    SuppliersModule,
    EInvoiceModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
