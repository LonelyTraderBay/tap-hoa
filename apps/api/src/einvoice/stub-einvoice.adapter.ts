import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import {
  AdjustEInvoiceInput,
  CancelEInvoiceInput,
  EInvoiceAdapter,
  IssueEInvoiceInput,
  IssueEInvoiceResult,
} from './einvoice.adapter';

/** Local stub — no external HTTP. Swap via EINVOICE_PROVIDER. */
@Injectable()
export class StubEInvoiceAdapter implements EInvoiceAdapter {
  readonly providerName = 'stub';

  async issue(input: IssueEInvoiceInput): Promise<IssueEInvoiceResult> {
    const saleIds = input.saleIds?.length ? input.saleIds : [input.saleId];
    const prefix = saleIds.length > 1 ? 'STUB-BATCH' : 'STUB';
    const num = `${prefix}-${saleIds[0].slice(0, 8).toUpperCase()}`;
    return {
      provider: this.providerName,
      providerRef: randomUUID(),
      invoiceNumber: num,
      status: 'issued',
      xmlPath: `stub://${num}.xml`,
      pdfPath: `stub://${num}.pdf`,
    };
  }

  async cancel(_input: CancelEInvoiceInput): Promise<void> {
    return;
  }

  async adjust(input: AdjustEInvoiceInput): Promise<IssueEInvoiceResult> {
    const num = `STUB-ADJ-${input.invoiceId.slice(0, 8).toUpperCase()}`;
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
