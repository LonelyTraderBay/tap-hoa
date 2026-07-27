import {
  BadRequestException,
  Body,
  Controller,
  ForbiddenException,
  Get,
  HttpCode,
  NotFoundException,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthUser } from '../auth/jwt.strategy';
import { LedgerPermissionGuard } from '../auth/ledger-permission.guard';
import { LedgerService } from './ledger.service';

@Controller('ledger')
@UseGuards(JwtAuthGuard, LedgerPermissionGuard)
export class LedgerController {
  constructor(private readonly ledger: LedgerService) {}

  @Get('journal')
  async journal(
    @Req() req: { user: AuthUser },
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('storeId') storeId?: string,
  ) {
    if (!from || !to) {
      throw new BadRequestException('from and to are required');
    }
    try {
      return await this.ledger.listJournal(req.user, from, to, storeId);
    } catch (e) {
      this.mapError(e);
    }
  }

  @Get('trial-balance')
  async trialBalance(
    @Req() req: { user: AuthUser },
    @Query('periodYm') periodYm?: string,
    @Query('storeId') storeId?: string,
  ) {
    if (!periodYm) {
      throw new BadRequestException('periodYm is required');
    }
    try {
      return await this.ledger.trialBalance(req.user, periodYm, storeId);
    } catch (e) {
      this.mapError(e);
    }
  }

  @Get('account-ledger')
  async accountLedger(
    @Req() req: { user: AuthUser },
    @Query('accountCode') accountCode?: string,
    @Query('periodYm') periodYm?: string,
    @Query('storeId') storeId?: string,
  ) {
    if (!accountCode) {
      throw new BadRequestException('accountCode is required');
    }
    if (!periodYm) {
      throw new BadRequestException('periodYm is required');
    }
    try {
      return await this.ledger.accountLedger(
        req.user,
        accountCode,
        periodYm,
        storeId,
      );
    } catch (e) {
      this.mapError(e);
    }
  }

  @Get('period-locks')
  async periodLocks(@Req() req: { user: AuthUser }) {
    try {
      return await this.ledger.listPeriodLocks(req.user);
    } catch (e) {
      this.mapError(e);
    }
  }

  @Post('period-locks')
  async lockPeriod(
    @Req() req: { user: AuthUser },
    @Body() body: { periodYm?: string },
  ) {
    if (!body?.periodYm) {
      throw new BadRequestException('periodYm is required');
    }
    try {
      return await this.ledger.lockPeriod(req.user, body.periodYm);
    } catch (e) {
      this.mapError(e);
    }
  }

  @Post('period-locks/:periodYm/unlock')
  @HttpCode(200)
  async unlockPeriod(
    @Req() req: { user: AuthUser },
    @Param('periodYm') periodYm: string,
    @Body() body: { reason?: string },
  ) {
    try {
      return await this.ledger.unlockPeriod(
        req.user,
        periodYm,
        body?.reason ?? '',
      );
    } catch (e) {
      this.mapError(e);
    }
  }

  @Get('cash-categories')
  async cashCategories(@Req() req: { user: AuthUser }) {
    try {
      return await this.ledger.listCashCategories(req.user);
    } catch (e) {
      this.mapError(e);
    }
  }

  @Post('cash-categories/:id/account')
  @HttpCode(200)
  async setCashCategoryAccount(
    @Req() req: { user: AuthUser },
    @Param('id') id: string,
    @Body() body: { accountCode?: string | null },
  ) {
    if (body.accountCode !== null && !body.accountCode) {
      throw new BadRequestException(
        'accountCode is required (or null to clear the mapping)',
      );
    }
    try {
      return await this.ledger.setCashCategoryAccount(
        req.user,
        id,
        body.accountCode ?? null,
      );
    } catch (e) {
      this.mapError(e);
    }
  }

  @Get('audit')
  async audit(
    @Req() req: { user: AuthUser },
    @Query('limit') limit?: string,
    @Query('action') action?: string,
    @Query('entityType') entityType?: string,
    @Query('entityId') entityId?: string,
    @Query('storeId') storeId?: string,
  ) {
    try {
      return await this.ledger.listAudit(req.user, {
        limit: limit ? Number(limit) : 50,
        action,
        entityType,
        entityId,
        storeId,
      });
    } catch (e) {
      this.mapError(e);
    }
  }

  private mapError(e: unknown): never {
    const msg = e instanceof Error ? e.message : String(e);
    if (
      msg === 'forbidden' ||
      msg === 'owner_required' ||
      msg === 'store_forbidden'
    ) {
      throw new ForbiddenException(msg);
    }
    if (
      msg === 'invalid_date' ||
      msg === 'invalid_period' ||
      msg === 'invalid_account' ||
      msg === 'invalid_reason' ||
      msg === 'account_not_found'
    ) {
      throw new BadRequestException(msg);
    }
    if (msg === 'category_not_found') {
      throw new NotFoundException(msg);
    }
    throw e;
  }
}
