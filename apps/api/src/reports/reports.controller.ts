import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Post,
  Query,
  Req,
  StreamableFile,
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
    @Query('storeId') storeId?: string,
  ) {
    if (!periodYm) {
      throw new BadRequestException('periodYm is required');
    }
    return this.reportsService.periodTrialBalance(req.user, periodYm, storeId);
  }

  @Get('period/pnl')
  periodPnl(
    @Req() req: { user: AuthUser },
    @Query('periodYm') periodYm?: string,
    @Query('storeId') storeId?: string,
  ) {
    if (!periodYm) {
      throw new BadRequestException('periodYm is required');
    }
    return this.reportsService.periodPnl(req.user, periodYm, storeId);
  }

  @Get('period/vat')
  periodVat(
    @Req() req: { user: AuthUser },
    @Query('periodYm') periodYm?: string,
    @Query('storeId') storeId?: string,
  ) {
    if (!periodYm) {
      throw new BadRequestException('periodYm is required');
    }
    return this.reportsService.vatSummary(req.user, periodYm, storeId);
  }

  @Get('period/export.csv')
  async periodExport(
    @Req() req: { user: AuthUser },
    @Query('periodYm') periodYm?: string,
    @Query('storeId') storeId?: string,
  ) {
    if (!periodYm) {
      throw new BadRequestException('periodYm is required');
    }
    const csv = await this.reportsService.periodExportCsv(
      req.user,
      periodYm,
      storeId,
    );
    return { periodYm, storeId: storeId ?? null, csv };
  }

  @Get('period/export.xlsx')
  async periodExportXlsx(
    @Req() req: { user: AuthUser },
    @Query('periodYm') periodYm?: string,
    @Query('storeId') storeId?: string,
  ) {
    if (!periodYm) {
      throw new BadRequestException('periodYm is required');
    }
    const buf = await this.reportsService.periodExportXlsx(
      req.user,
      periodYm,
      storeId,
    );
    return new StreamableFile(buf, {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      disposition: `attachment; filename="period-${periodYm}.xlsx"`,
    });
  }

  @Get('period/export.pdf')
  async periodExportPdf(
    @Req() req: { user: AuthUser },
    @Query('periodYm') periodYm?: string,
    @Query('storeId') storeId?: string,
  ) {
    if (!periodYm) {
      throw new BadRequestException('periodYm is required');
    }
    const buf = await this.reportsService.periodExportPdf(
      req.user,
      periodYm,
      storeId,
    );
    return new StreamableFile(buf, {
      type: 'application/pdf',
      disposition: `attachment; filename="period-${periodYm}.pdf"`,
    });
  }

  @Get('period/vat-declaration.csv')
  async vatDeclaration(
    @Req() req: { user: AuthUser },
    @Query('periodYm') periodYm?: string,
    @Query('storeId') storeId?: string,
  ) {
    if (!periodYm) {
      throw new BadRequestException('periodYm is required');
    }
    const csv = await this.reportsService.vatDeclarationAssist(
      req.user,
      periodYm,
      storeId,
    );
    return { periodYm, storeId: storeId ?? null, csv };
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

  @Post('bank-recon/import')
  importBankRecon(
    @Req() req: { user: AuthUser },
    @Body()
    body: {
      storeId?: string;
      periodYm?: string;
      csv?: string;
      bankAccountId?: string;
    },
  ) {
    if (!body.storeId || !body.periodYm || !body.csv) {
      throw new BadRequestException('storeId, periodYm, csv required');
    }
    return this.reportsService.importBankStatement(
      req.user,
      body.storeId,
      body.periodYm,
      body.csv,
      body.bankAccountId,
    );
  }

  @Get('bank-recon')
  bankRecon(
    @Req() req: { user: AuthUser },
    @Query('storeId') storeId?: string,
    @Query('periodYm') periodYm?: string,
  ) {
    if (!storeId || !periodYm) {
      throw new BadRequestException('storeId and periodYm required');
    }
    return this.reportsService.bankReconSummary(req.user, storeId, periodYm);
  }

  @Post('bank-recon/match')
  matchBank(
    @Req() req: { user: AuthUser },
    @Body()
    body: {
      storeId?: string;
      periodYm?: string;
      statementId?: string;
      bookRef?: string;
      matchVersion?: number;
    },
  ) {
    if (!body.storeId || !body.periodYm || !body.statementId || !body.bookRef) {
      throw new BadRequestException(
        'storeId, periodYm, statementId, bookRef required',
      );
    }
    return this.reportsService.matchBankLine(req.user, {
      storeId: body.storeId,
      periodYm: body.periodYm,
      statementId: body.statementId,
      bookRef: body.bookRef,
      matchVersion: body.matchVersion,
    });
  }

  @Post('bank-recon/unmatch')
  unmatchBank(
    @Req() req: { user: AuthUser },
    @Body()
    body: {
      storeId?: string;
      periodYm?: string;
      statementId?: string;
      matchVersion?: number;
    },
  ) {
    if (!body.storeId || !body.periodYm || !body.statementId) {
      throw new BadRequestException(
        'storeId, periodYm, statementId required',
      );
    }
    return this.reportsService.unmatchBankLine(req.user, {
      storeId: body.storeId,
      periodYm: body.periodYm,
      statementId: body.statementId,
      matchVersion: body.matchVersion,
    });
  }

  @Post('bank-recon/auto-match')
  autoMatchBank(
    @Req() req: { user: AuthUser },
    @Body() body: { storeId?: string; periodYm?: string },
  ) {
    if (!body.storeId || !body.periodYm) {
      throw new BadRequestException('storeId and periodYm required');
    }
    return this.reportsService.autoMatchBankRecon(
      req.user,
      body.storeId,
      body.periodYm,
    );
  }

  @Post('bank-recon/lock')
  lockBankRecon(
    @Req() req: { user: AuthUser },
    @Body() body: { storeId?: string; periodYm?: string },
  ) {
    if (!body.storeId || !body.periodYm) {
      throw new BadRequestException('storeId and periodYm required');
    }
    return this.reportsService.lockBankRecon(
      req.user,
      body.storeId,
      body.periodYm,
    );
  }
}
