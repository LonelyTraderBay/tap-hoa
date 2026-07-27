import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import {
  AdjustEInvoiceInput,
  CancelEInvoiceInput,
  EInvoiceAdapter,
  IssueEInvoiceInput,
  IssueEInvoiceResult,
} from './einvoice.adapter';
import {
  buildStubInvoicePdf,
  buildStubInvoiceXml,
  StubInvoiceData,
} from './einvoice-stub-document';

/** Local stub — no external HTTP. Swap via EINVOICE_PROVIDER.
 *
 * P2.4: generates a REAL, downloadable PDF (NotoSans, Vietnamese-diacritic
 * capable — same font pattern as period reports) and a simple structured XML
 * for every stub issue/adjust, returned as in-memory bytes for the caller to
 * persist on the EInvoice row (xmlContent/pdfContent). This is explicitly NOT
 * the official CQT e-invoice schema (Thông tư 78/Nghị định 123) — see
 * einvoice-stub-document.ts header. xmlPath/pdfPath are left undefined here
 * (no external URL exists for stub-issued content); the download endpoint
 * serves xmlContent/pdfContent directly from the DB in that case.
 */
@Injectable()
export class StubEInvoiceAdapter implements EInvoiceAdapter {
  readonly providerName = 'stub';

  private async buildDocuments(
    data: StubInvoiceData,
  ): Promise<{ pdfContent: Buffer; xmlContent: Buffer }> {
    const [pdfContent, xmlContent] = await Promise.all([
      buildStubInvoicePdf(data),
      Promise.resolve(buildStubInvoiceXml(data)),
    ]);
    return { pdfContent, xmlContent };
  }

  async issue(input: IssueEInvoiceInput): Promise<IssueEInvoiceResult> {
    const saleIds = input.saleIds?.length ? input.saleIds : [input.saleId];
    const prefix = saleIds.length > 1 ? 'STUB-BATCH' : 'STUB';
    const num = `${prefix}-${saleIds[0].slice(0, 8).toUpperCase()}`;
    const { pdfContent, xmlContent } = await this.buildDocuments({
      invoiceNumber: num,
      issuedAt: new Date(),
      templateCode: input.templateCode,
      serial: input.serial,
      buyerName: input.buyerName,
      buyerTaxCode: input.buyerTaxCode,
      totalVnd: input.totalVnd,
      lines: input.lines ?? [],
    });
    return {
      provider: this.providerName,
      providerRef: randomUUID(),
      invoiceNumber: num,
      status: 'issued',
      pdfContent,
      xmlContent,
    };
  }

  async cancel(_input: CancelEInvoiceInput): Promise<void> {
    return;
  }

  async adjust(input: AdjustEInvoiceInput): Promise<IssueEInvoiceResult> {
    const num = `STUB-ADJ-${input.invoiceId.slice(0, 8).toUpperCase()}`;
    const { pdfContent, xmlContent } = await this.buildDocuments({
      invoiceNumber: num,
      issuedAt: new Date(),
      templateCode: input.templateCode,
      serial: input.serial,
      buyerName: input.buyerName,
      buyerTaxCode: input.buyerTaxCode,
      totalVnd: input.totalVnd,
      lines: input.lines ?? [],
    });
    return {
      provider: this.providerName,
      providerRef: randomUUID(),
      invoiceNumber: num,
      status: 'issued',
      pdfContent,
      xmlContent,
    };
  }
}
