import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthUser } from '../auth/jwt.strategy';
import { StoresService } from './stores.service';

@Controller('stores')
@UseGuards(JwtAuthGuard)
export class StoresController {
  constructor(private readonly storesService: StoresService) {}

  @Get()
  list(@Req() req: { user: AuthUser }) {
    return this.storesService.findForUser(
      req.user.role as Role,
      req.user.storeIds,
    );
  }

  @Patch(':id/debt-overdue-days')
  setDebtOverdueDays(
    @Req() req: { user: AuthUser },
    @Param('id') id: string,
    @Body() body: { debtOverdueDays?: number },
  ) {
    if (
      body.debtOverdueDays == null ||
      !Number.isInteger(body.debtOverdueDays) ||
      body.debtOverdueDays < 1
    ) {
      throw new BadRequestException(
        'debtOverdueDays must be a positive integer',
      );
    }
    return this.storesService.setDebtOverdueDays(
      req.user,
      id,
      body.debtOverdueDays,
    );
  }

  @Patch(':id/vat')
  setVat(
    @Req() req: { user: AuthUser },
    @Param('id') id: string,
    @Body()
    body: { vatEnabled?: boolean; defaultVatRateBps?: number },
  ) {
    if (body.vatEnabled === undefined && body.defaultVatRateBps === undefined) {
      throw new BadRequestException(
        'vatEnabled or defaultVatRateBps is required',
      );
    }
    if (
      body.defaultVatRateBps !== undefined &&
      (!Number.isInteger(body.defaultVatRateBps) ||
        body.defaultVatRateBps < 0 ||
        body.defaultVatRateBps > 10000)
    ) {
      throw new BadRequestException(
        'defaultVatRateBps must be an integer 0..10000',
      );
    }
    return this.storesService.setVatSettings(req.user, id, body);
  }
}
