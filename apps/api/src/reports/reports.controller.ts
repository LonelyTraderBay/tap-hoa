import {
  BadRequestException,
  Controller,
  Get,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthUser } from '../auth/jwt.strategy';
import { ReportsService } from './reports.service';

@Controller('reports')
@UseGuards(JwtAuthGuard)
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get('day')
  day(
    @Req() req: { user: AuthUser },
    @Query('date') date?: string,
    @Query('storeId') storeId?: string,
  ) {
    if (!date) {
      throw new BadRequestException('date is required');
    }
    return this.reportsService.dayReport(req.user, date, storeId);
  }

  @Get('top-skus')
  topSkus(
    @Req() req: { user: AuthUser },
    @Query('date') date?: string,
    @Query('storeId') storeId?: string,
    @Query('limit') limitRaw?: string,
  ) {
    if (!date) {
      throw new BadRequestException('date is required');
    }
    const limit = limitRaw == null ? 10 : Number(limitRaw);
    if (!Number.isInteger(limit) || limit < 1) {
      throw new BadRequestException('limit must be a positive integer');
    }
    return this.reportsService.topSkus(req.user, date, storeId, limit);
  }

  @Get('stock-on-hand')
  stockOnHand(
    @Req() req: { user: AuthUser },
    @Query('storeId') storeId?: string,
  ) {
    if (!storeId) {
      throw new BadRequestException('storeId is required');
    }
    return this.reportsService.stockOnHand(req.user, storeId);
  }

  @Get('debt-aging')
  debtAging(
    @Req() req: { user: AuthUser },
    @Query('storeId') storeId?: string,
  ) {
    if (!storeId) {
      throw new BadRequestException('storeId is required');
    }
    return this.reportsService.debtAging(req.user, storeId);
  }

  @Get('period/trial-balance')
  periodTrial(
    @Req() req: { user: AuthUser },
    @Query('periodYm') periodYm?: string,
  ) {
    if (!periodYm) {
      throw new BadRequestException('periodYm is required');
    }
    return this.reportsService.periodTrialBalance(req.user, periodYm);
  }

  @Get('period/pnl')
  periodPnl(
    @Req() req: { user: AuthUser },
    @Query('periodYm') periodYm?: string,
  ) {
    if (!periodYm) {
      throw new BadRequestException('periodYm is required');
    }
    return this.reportsService.periodPnl(req.user, periodYm);
  }

  @Get('period/vat')
  periodVat(
    @Req() req: { user: AuthUser },
    @Query('periodYm') periodYm?: string,
  ) {
    if (!periodYm) {
      throw new BadRequestException('periodYm is required');
    }
    return this.reportsService.vatSummary(req.user, periodYm);
  }

  @Get('period/export.csv')
  async periodExport(
    @Req() req: { user: AuthUser },
    @Query('periodYm') periodYm?: string,
  ) {
    if (!periodYm) {
      throw new BadRequestException('periodYm is required');
    }
    const csv = await this.reportsService.periodExportCsv(req.user, periodYm);
    return { periodYm, csv };
  }

  @Get('cash-fund')
  cashFund(
    @Req() req: { user: AuthUser },
    @Query('storeId') storeId?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    if (!storeId || !from || !to) {
      throw new BadRequestException('storeId, from, to required');
    }
    return this.reportsService.cashFundSummary(req.user, storeId, from, to);
  }
}
