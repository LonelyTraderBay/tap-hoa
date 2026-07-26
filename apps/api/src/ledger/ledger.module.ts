import { Module } from '@nestjs/common';
import { LedgerPermissionGuard } from '../auth/ledger-permission.guard';
import { PrismaModule } from '../prisma/prisma.module';
import { LedgerController } from './ledger.controller';
import { LedgerService } from './ledger.service';

@Module({
  imports: [PrismaModule],
  controllers: [LedgerController],
  providers: [LedgerPermissionGuard, LedgerService],
  exports: [LedgerService],
})
export class LedgerModule {}
