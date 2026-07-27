/**
 * Sổ quỹ tiền mặt — TK 111 trong sổ cái là nguồn sự thật duy nhất.
 *
 * Mọi loại chứng từ có bút toán chạm TK 111 phải xuất hiện ở đây. Danh sách
 * bám sát `ledger/journal-builders.ts`:
 *  - buildSaleJournal:            Nợ 111 = sale.cashAmount
 *  - buildSaleReturnJournal:      Có 111 = saleReturn.cashRefundVnd
 *  - buildDebtPaymentJournal:     Nợ 111 = thu nợ khách (kênh ≠ transfer)
 *  - buildCashVoucherJournal:     Nợ 111 phiếu thu / Có 111 phiếu chi (kênh ≠ transfer)
 *  - buildSupplierPaymentJournal: Có 111 = chi trả NCC (kênh ≠ transfer)
 *
 * Thêm loại chứng từ tiền mặt mới ⇒ thêm cả builder lẫn nhánh tương ứng ở đây,
 * nếu không `netCashVnd` sẽ lệch số dư TK 111.
 */

/**
 * Journal builders chỉ tách riêng 'transfer' sang TK 112; mọi giá trị khác
 * (kể cả null/undefined trên chứng từ cũ) đều rơi vào TK 111 — tiền mặt.
 */
export function isCashChannel(channel: string | null | undefined): boolean {
  return channel !== 'transfer';
}

export type CashFundDocs = {
  /** Sale trong kỳ/điểm bán. */
  sales: { cashAmount: number; transferAmount: number }[];
  /** Trả hàng bán — hoàn tiền làm giảm quỹ. */
  saleReturns: { cashRefundVnd: number; transferRefundVnd: number }[];
  /** Phiếu thu / phiếu chi. */
  vouchers: { direction: string; channel: string; amountVnd: number }[];
  /** DebtLedgerEntry type='payment' — thu nợ khách. */
  debtPayments: { paymentMethod: string | null; amountVnd: number }[];
  /** Chi trả NCC. */
  supplierPayments: { channel: string; amountVnd: number }[];
};

export type CashFundTotals = {
  saleCashVnd: number;
  saleTransferVnd: number;
  saleReturnCashVnd: number;
  saleReturnTransferVnd: number;
  voucherInVnd: number;
  voucherOutVnd: number;
  voucherTransferInVnd: number;
  voucherTransferOutVnd: number;
  debtPaymentCashVnd: number;
  debtPaymentTransferVnd: number;
  supplierPaymentCashVnd: number;
  supplierPaymentTransferVnd: number;
  /** Phát sinh ròng TK 111 (Nợ − Có) trong kỳ. */
  netCashVnd: number;
  /** Phát sinh ròng TK 112 (Nợ − Có) — đối chiếu ngân hàng. */
  netTransferVnd: number;
};

export function computeCashFundTotals(docs: CashFundDocs): CashFundTotals {
  let saleCashVnd = 0;
  let saleTransferVnd = 0;
  for (const s of docs.sales) {
    saleCashVnd += s.cashAmount;
    saleTransferVnd += s.transferAmount;
  }

  let saleReturnCashVnd = 0;
  let saleReturnTransferVnd = 0;
  for (const r of docs.saleReturns) {
    saleReturnCashVnd += r.cashRefundVnd;
    saleReturnTransferVnd += r.transferRefundVnd;
  }

  let voucherInVnd = 0;
  let voucherOutVnd = 0;
  let voucherTransferInVnd = 0;
  let voucherTransferOutVnd = 0;
  for (const v of docs.vouchers) {
    const cash = isCashChannel(v.channel);
    if (v.direction === 'in') {
      if (cash) voucherInVnd += v.amountVnd;
      else voucherTransferInVnd += v.amountVnd;
    } else {
      if (cash) voucherOutVnd += v.amountVnd;
      else voucherTransferOutVnd += v.amountVnd;
    }
  }

  let debtPaymentCashVnd = 0;
  let debtPaymentTransferVnd = 0;
  for (const p of docs.debtPayments) {
    if (isCashChannel(p.paymentMethod)) debtPaymentCashVnd += p.amountVnd;
    else debtPaymentTransferVnd += p.amountVnd;
  }

  let supplierPaymentCashVnd = 0;
  let supplierPaymentTransferVnd = 0;
  for (const p of docs.supplierPayments) {
    if (isCashChannel(p.channel)) supplierPaymentCashVnd += p.amountVnd;
    else supplierPaymentTransferVnd += p.amountVnd;
  }

  return {
    saleCashVnd,
    saleTransferVnd,
    saleReturnCashVnd,
    saleReturnTransferVnd,
    voucherInVnd,
    voucherOutVnd,
    voucherTransferInVnd,
    voucherTransferOutVnd,
    debtPaymentCashVnd,
    debtPaymentTransferVnd,
    supplierPaymentCashVnd,
    supplierPaymentTransferVnd,
    netCashVnd:
      saleCashVnd +
      debtPaymentCashVnd +
      voucherInVnd -
      voucherOutVnd -
      supplierPaymentCashVnd -
      saleReturnCashVnd,
    netTransferVnd:
      saleTransferVnd +
      debtPaymentTransferVnd +
      voucherTransferInVnd -
      voucherTransferOutVnd -
      supplierPaymentTransferVnd -
      saleReturnTransferVnd,
  };
}

/** Phát sinh ròng của một tài khoản từ sổ cái (Nợ − Có). */
export function sumLedgerMovement(
  lines: { debitVnd: number; creditVnd: number }[],
): number {
  return lines.reduce((sum, l) => sum + l.debitVnd - l.creditVnd, 0);
}
