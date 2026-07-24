export type IssueEInvoiceInput = {
  saleId: string;
  totalVnd: number;
  buyerTaxCode?: string | null;
  templateCode?: string | null;
  serial?: string | null;
};

export type IssueEInvoiceResult = {
  provider: string;
  providerRef: string;
  invoiceNumber: string;
  status: 'pending_sign' | 'issued';
  xmlPath?: string;
  pdfPath?: string;
};

export interface EInvoiceAdapter {
  readonly providerName: string;
  issue(input: IssueEInvoiceInput): Promise<IssueEInvoiceResult>;
}
