import { Module } from '@nestjs/common';
import { EInvoicePermissionGuard } from '../auth/einvoice-permission.guard';
import { PrismaModule } from '../prisma/prisma.module';
import { EInvoiceAdapter } from './einvoice.adapter';
import { EInvoiceController } from './einvoice.controller';
import { EInvoiceService } from './einvoice.service';
import { EINVOICE_ADAPTER } from './einvoice.tokens';
import { HttpEInvoiceAdapter } from './http-einvoice.adapter';
import { StubEInvoiceAdapter } from './stub-einvoice.adapter';

function selectAdapter(
  stub: StubEInvoiceAdapter,
  http: HttpEInvoiceAdapter,
): EInvoiceAdapter {
  const provider = (process.env.EINVOICE_PROVIDER ?? 'stub').toLowerCase();
  return provider === 'http' ? http : stub;
}

@Module({
  imports: [PrismaModule],
  controllers: [EInvoiceController],
  providers: [
    StubEInvoiceAdapter,
    HttpEInvoiceAdapter,
    {
      provide: EINVOICE_ADAPTER,
      useFactory: selectAdapter,
      inject: [StubEInvoiceAdapter, HttpEInvoiceAdapter],
    },
    EInvoicePermissionGuard,
    EInvoiceService,
  ],
  exports: [EInvoiceService],
})
export class EInvoiceModule {}
