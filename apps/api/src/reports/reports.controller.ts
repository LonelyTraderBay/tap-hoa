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
}
