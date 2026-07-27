import { Module } from '@nestjs/common';
import { LedgerModule } from '../ledger/ledger.module';
import { ReportsController } from './reports.controller';
import { ReportsService } from './reports.service';

@Module({
  imports: [LedgerModule],
  controllers: [ReportsController],
  providers: [ReportsService],
})
export class ReportsModule {}
