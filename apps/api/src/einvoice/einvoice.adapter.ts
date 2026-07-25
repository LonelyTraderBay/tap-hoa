export type IssueEInvoiceInput = {
  saleId: string;
  totalVnd: number;
  buyerTaxCode?: string | null;
  templateCode?: string | null;
  serial?: string | null;
  lines?: {
    productId: string;
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
};

export type CancelEInvoiceInput = {
  invoiceId: string;
  providerRef?: string | null;
  reason: string;
};

export interface EInvoiceAdapter {
  readonly providerName: string;
  issue(input: IssueEInvoiceInput): Promise<IssueEInvoiceResult>;
  cancel(input: CancelEInvoiceInput): Promise<void>;
}
