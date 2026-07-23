import { Body, Controller, HttpCode, Param, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthUser } from '../auth/jwt.strategy';
import { ShiftsService } from './shifts.service';

@Controller('shifts')
@UseGuards(JwtAuthGuard)
export class ShiftsController {
  constructor(private readonly shiftsService: ShiftsService) {}

  @Post('open')
  @HttpCode(201)
  open(
    @Req() req: { user: AuthUser },
    @Body() body: { storeId: string; openingCash: number; clientId: string },
  ) {
    return this.shiftsService.open(req.user, body);
  }

  @Post(':id/close')
  @HttpCode(201)
  close(
    @Req() req: { user: AuthUser },
    @Param('id') id: string,
    @Body() body: { closingCash: number; note?: string },
  ) {
    return this.shiftsService.close(req.user, id, body);
  }
}
