import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthUser } from '../auth/jwt.strategy';
import { PushSyncDto } from './dto/push-sale.dto';
import { SyncService } from './sync.service';

@Controller('sync')
@UseGuards(JwtAuthGuard)
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  @Get('pull')
  pull(
    @Req() req: { user: AuthUser },
    @Query('since') since?: string,
    @Query('storeId') storeId?: string,
  ) {
    const sinceDate = since ? new Date(since) : new Date(0);
    if (!storeId) {
      throw new BadRequestException('storeId is required');
    }
    return this.syncService.pull(req.user, storeId, sinceDate);
  }

  @Post('push')
  push(@Req() req: { user: AuthUser }, @Body() body: PushSyncDto) {
    if (!body?.deviceId) {
      throw new BadRequestException('deviceId is required');
    }
    if (!Array.isArray(body.sales)) {
      throw new BadRequestException('sales must be an array');
    }
    return this.syncService.pushSales(req.user, body.deviceId, body.sales);
  }
}
