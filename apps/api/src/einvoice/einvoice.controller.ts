import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthUser } from '../auth/jwt.strategy';
import { EInvoiceService } from './einvoice.service';

@Controller('einvoices')
@UseGuards(JwtAuthGuard)
export class EInvoiceController {
  constructor(private readonly service: EInvoiceService) {}

  @Post('issue')
  issue(
    @Req() req: { user: AuthUser },
    @Body()
    body: {
      saleId?: string;
      buyerTaxCode?: string;
      templateCode?: string;
      serial?: string;
    },
  ) {
    return this.service.issue(req.user, body);
  }

  @Get('by-sale/:saleId')
  bySale(@Req() req: { user: AuthUser }, @Param('saleId') saleId: string) {
    return this.service.getBySale(req.user, saleId);
  }

  @Post(':id/cancel')
  cancel(
    @Req() req: { user: AuthUser },
    @Param('id') id: string,
    @Body() body: { reason?: string },
  ) {
    return this.service.cancel(req.user, id, body);
  }
}
