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
}
