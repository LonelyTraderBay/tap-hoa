import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import {
  EInvoiceAdapter,
  IssueEInvoiceInput,
  IssueEInvoiceResult,
} from './einvoice.adapter';

/** Local stub — no external HTTP. Swap via EINVOICE_PROVIDER. */
@Injectable()
export class StubEInvoiceAdapter implements EInvoiceAdapter {
  readonly providerName = 'stub';

  async issue(input: IssueEInvoiceInput): Promise<IssueEInvoiceResult> {
    const num = `STUB-${input.saleId.slice(0, 8).toUpperCase()}`;
    return {
      provider: this.providerName,
      providerRef: randomUUID(),
      invoiceNumber: num,
      status: 'issued',
      xmlPath: `stub://${num}.xml`,
      pdfPath: `stub://${num}.pdf`,
    };
  }
}
