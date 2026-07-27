export type IssueEInvoiceInput = {
  saleId: string;
  saleIds?: string[];
  totalVnd: number;
  buyerTaxCode?: string | null;
  buyerName?: string | null;
  templateCode?: string | null;
  serial?: string | null;
  lines?: {
    saleId?: string;
    productId: string;
    productName?: string | null;
    qty: number;
    unitPrice: number;
    lineTotal: number;
  }[];
};

export type IssueEInvoiceResult = {
  provider: string;
  providerRef: string;
  invoiceNumber: string;
  status: 'pending_sign' | 'issued';
  xmlPath?: string;
  pdfPath?: string;
  /** Stub-mode only — real PDF/XML bytes persisted to DB by the caller.
   * Provider-hosted results (http adapter) leave these undefined and use
   * xmlPath/pdfPath instead. */
  xmlContent?: Buffer;
  pdfContent?: Buffer;
};

export type CancelEInvoiceInput = {
  invoiceId: string;
  providerRef?: string | null;
  reason: string;
};

export type AdjustEInvoiceInput = {
  invoiceId: string;
  providerRef?: string | null;
  originalInvoiceNumber?: string | null;
  buyerTaxCode?: string | null;
  buyerName?: string | null;
  templateCode?: string | null;
  serial?: string | null;
  saleIds: string[];
  totalVnd: number;
  reason: string;
  lines?: IssueEInvoiceInput['lines'];
};

export interface EInvoiceAdapter {
  readonly providerName: string;
  issue(input: IssueEInvoiceInput): Promise<IssueEInvoiceResult>;
  cancel(input: CancelEInvoiceInput): Promise<void>;
  adjust(input: AdjustEInvoiceInput): Promise<IssueEInvoiceResult>;
}
