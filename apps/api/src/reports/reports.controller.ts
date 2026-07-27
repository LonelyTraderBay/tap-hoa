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
import { LedgerPermissionGuard } from '../auth/ledger-permission.guard';
import { ReportsService } from './reports.service';

/**
 * Tách quyền (spec §5.7): bán hàng ≠ kế toán.
 *
 * - Nhóm VẬN HÀNH (day, top-skus, stock-on-hand, debt-aging, ar.csv): chỉ cần
 *   đăng nhập + scope cửa hàng — thu ngân/quản lý quầy dùng hằng ngày.
 * - Nhóm KẾ TOÁN (period/*, cash-fund, bank-recon/*, ap-recon/*): bắt buộc
 *   `canLedger` qua `LedgerPermissionGuard` gắn ở method level.
 */
@Controller('reports')
@UseGuards(JwtAuthGuard)
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  // ---------------------------------------------------------------------
  // Nhóm VẬN HÀNH — KHÔNG gắn LedgerPermissionGuard.
  // ---------------------------------------------------------------------

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
    return this.reportsService.debtAging(req.user, storeId);
  }

  @Get('ar.csv')
  async arExportCsv(
    @Req() req: { user: AuthUser },
    @Query('storeId') storeId?: string,
  ) {
    const result = await this.reportsService.arExportCsv(req.user, storeId);
    return {
      storeId: result.storeId,
      scope: result.scope,
      storeIds: result.storeIds,
      csv: result.csv,
    };
  }

  // ---------------------------------------------------------------------
  // Nhóm KẾ TOÁN — bắt buộc canLedger.
  // ---------------------------------------------------------------------

  @Get('period/trial-balance')
  @UseGuards(LedgerPermissionGuard)
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
  @UseGuards(LedgerPermissionGuard)
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
  @UseGuards(LedgerPermissionGuard)
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
  @UseGuards(LedgerPermissionGuard)
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
  @UseGuards(LedgerPermissionGuard)
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
  @UseGuards(LedgerPermissionGuard)
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
  @UseGuards(LedgerPermissionGuard)
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
  @UseGuards(LedgerPermissionGuard)
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
  @UseGuards(LedgerPermissionGuard)
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
  @UseGuards(LedgerPermissionGuard)
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
  @UseGuards(LedgerPermissionGuard)
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
  @UseGuards(LedgerPermissionGuard)
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
  @UseGuards(LedgerPermissionGuard)
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
  @UseGuards(LedgerPermissionGuard)
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

  @Post('ap-recon/import')
  @UseGuards(LedgerPermissionGuard)
  importApRecon(
    @Req() req: { user: AuthUser },
    @Body()
    body: {
      storeId?: string;
      supplierId?: string;
      periodYm?: string;
      csv?: string;
    },
  ) {
    if (!body.storeId || !body.supplierId || !body.periodYm || !body.csv) {
      throw new BadRequestException('storeId, supplierId, periodYm, csv required');
    }
    return this.reportsService.importApStatement(
      req.user,
      body.storeId,
      body.supplierId,
      body.periodYm,
      body.csv,
    );
  }

  @Get('ap-recon')
  @UseGuards(LedgerPermissionGuard)
  apRecon(
    @Req() req: { user: AuthUser },
    @Query('storeId') storeId?: string,
    @Query('supplierId') supplierId?: string,
    @Query('periodYm') periodYm?: string,
  ) {
    if (!storeId || !supplierId || !periodYm) {
      throw new BadRequestException('storeId, supplierId and periodYm required');
    }
    return this.reportsService.apReconSummary(
      req.user,
      storeId,
      supplierId,
      periodYm,
    );
  }

  @Post('ap-recon/match')
  @UseGuards(LedgerPermissionGuard)
  matchAp(
    @Req() req: { user: AuthUser },
    @Body()
    body: {
      storeId?: string;
      supplierId?: string;
      periodYm?: string;
      statementId?: string;
      bookRef?: string;
      matchVersion?: number;
    },
  ) {
    if (
      !body.storeId ||
      !body.supplierId ||
      !body.periodYm ||
      !body.statementId ||
      !body.bookRef
    ) {
      throw new BadRequestException(
        'storeId, supplierId, periodYm, statementId, bookRef required',
      );
    }
    return this.reportsService.matchApLine(req.user, {
      storeId: body.storeId,
      supplierId: body.supplierId,
      periodYm: body.periodYm,
      statementId: body.statementId,
      bookRef: body.bookRef,
      matchVersion: body.matchVersion,
    });
  }

  @Post('ap-recon/unmatch')
  @UseGuards(LedgerPermissionGuard)
  unmatchAp(
    @Req() req: { user: AuthUser },
    @Body()
    body: {
      storeId?: string;
      supplierId?: string;
      periodYm?: string;
      statementId?: string;
      matchVersion?: number;
    },
  ) {
    if (!body.storeId || !body.supplierId || !body.periodYm || !body.statementId) {
      throw new BadRequestException(
        'storeId, supplierId, periodYm, statementId required',
      );
    }
    return this.reportsService.unmatchApLine(req.user, {
      storeId: body.storeId,
      supplierId: body.supplierId,
      periodYm: body.periodYm,
      statementId: body.statementId,
      matchVersion: body.matchVersion,
    });
  }

  @Post('ap-recon/auto-match')
  @UseGuards(LedgerPermissionGuard)
  autoMatchAp(
    @Req() req: { user: AuthUser },
    @Body() body: { storeId?: string; supplierId?: string; periodYm?: string },
  ) {
    if (!body.storeId || !body.supplierId || !body.periodYm) {
      throw new BadRequestException('storeId, supplierId and periodYm required');
    }
    return this.reportsService.autoMatchApRecon(
      req.user,
      body.storeId,
      body.supplierId,
      body.periodYm,
    );
  }

  @Post('ap-recon/lock')
  @UseGuards(LedgerPermissionGuard)
  lockApRecon(
    @Req() req: { user: AuthUser },
    @Body() body: { storeId?: string; supplierId?: string; periodYm?: string },
  ) {
    if (!body.storeId || !body.supplierId || !body.periodYm) {
      throw new BadRequestException('storeId, supplierId and periodYm required');
    }
    return this.reportsService.lockApRecon(
      req.user,
      body.storeId,
      body.supplierId,
      body.periodYm,
    );
  }
}
