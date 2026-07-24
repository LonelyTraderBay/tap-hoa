import { Body, Controller, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthUser } from '../auth/jwt.strategy';
import { DevicesService } from './devices.service';

@Controller('devices')
@UseGuards(JwtAuthGuard)
export class DevicesController {
  constructor(private readonly devicesService: DevicesService) {}

  @Post('push-token')
  register(
    @Req() req: { user: AuthUser },
    @Body()
    body: { deviceId?: string; token?: string; platform?: string },
  ) {
    return this.devicesService.registerToken(req.user, {
      deviceId: body.deviceId ?? '',
      token: body.token ?? '',
      platform: body.platform ?? 'unknown',
    });
  }

  @Post('low-stock-alert')
  lowStock(
    @Req() req: { user: AuthUser },
    @Body()
    body: {
      storeId?: string;
      productId?: string;
      productName?: string;
      qty?: string;
    },
  ) {
    return this.devicesService.notifyLowStock(req.user, {
      storeId: body.storeId ?? '',
      productId: body.productId ?? '',
      productName: body.productName ?? '',
      qty: body.qty ?? '',
    });
  }
}
