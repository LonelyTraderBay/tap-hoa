import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { EInvoiceController } from './einvoice.controller';
import { EInvoiceService } from './einvoice.service';
import { EINVOICE_ADAPTER } from './einvoice.tokens';
import { StubEInvoiceAdapter } from './stub-einvoice.adapter';

@Module({
  imports: [PrismaModule],
  controllers: [EInvoiceController],
  providers: [
    StubEInvoiceAdapter,
    { provide: EINVOICE_ADAPTER, useExisting: StubEInvoiceAdapter },
    EInvoiceService,
  ],
  exports: [EInvoiceService],
})
export class EInvoiceModule {}
