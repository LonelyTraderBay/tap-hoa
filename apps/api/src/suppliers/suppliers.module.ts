import { Module } from '@nestjs/common';
import { LedgerModule } from '../ledger/ledger.module';
import { PrismaModule } from '../prisma/prisma.module';
import { SuppliersController } from './suppliers.controller';

@Module({
  imports: [PrismaModule, LedgerModule],
  controllers: [SuppliersController],
})
export class SuppliersModule {}
