import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Req,
  StreamableFile,
  UseGuards,
} from '@nestjs/common';
import { EInvoicePermissionGuard } from '../auth/einvoice-permission.guard';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthUser } from '../auth/jwt.strategy';
import { EInvoiceService } from './einvoice.service';

@Controller('einvoices')
@UseGuards(JwtAuthGuard, EInvoicePermissionGuard)
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

  @Post('issue-batch')
  issueBatch(
    @Req() req: { user: AuthUser },
    @Body()
    body: {
      customerId?: string;
      saleIds?: string[];
      buyerTaxCode?: string;
      templateCode?: string;
      serial?: string;
    },
  ) {
    return this.service.issueBatch(req.user, body);
  }

  @Get('by-sale/:saleId')
  bySale(@Req() req: { user: AuthUser }, @Param('saleId') saleId: string) {
    return this.service.getBySale(req.user, saleId);
  }

  @Get(':id/xml')
  async downloadXml(
    @Req() req: { user: AuthUser },
    @Param('id') id: string,
  ) {
    const { buffer, contentType, filename } =
      await this.service.downloadDocument(req.user, id, 'xml');
    return new StreamableFile(buffer, {
      type: contentType,
      disposition: `attachment; filename="${filename}"`,
    });
  }

  @Get(':id/pdf')
  async downloadPdf(
    @Req() req: { user: AuthUser },
    @Param('id') id: string,
  ) {
    const { buffer, contentType, filename } =
      await this.service.downloadDocument(req.user, id, 'pdf');
    return new StreamableFile(buffer, {
      type: contentType,
      disposition: `attachment; filename="${filename}"`,
    });
  }

  @Post(':id/cancel')
  cancel(
    @Req() req: { user: AuthUser },
    @Param('id') id: string,
    @Body() body: { reason?: string },
  ) {
    return this.service.cancel(req.user, id, body);
  }

  @Post(':id/adjust')
  adjust(
    @Req() req: { user: AuthUser },
    @Param('id') id: string,
    @Body() body: { reason?: string },
  ) {
    return this.service.adjust(req.user, id, body);
  }
}
