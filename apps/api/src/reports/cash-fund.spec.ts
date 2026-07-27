import {
  buildCashVoucherJournal,
  buildDebtPaymentJournal,
  buildSaleJournal,
  buildSaleReturnJournal,
  buildSupplierPaymentJournal,
} from '../ledger/journal-builders';
import {
  CashFundDocs,
  computeCashFundTotals,
  isCashChannel,
  sumLedgerMovement,
} from './cash-fund';

const emptyDocs: CashFundDocs = {
  sales: [],
  saleReturns: [],
  vouchers: [],
  debtPayments: [],
  supplierPayments: [],
};

describe('isCashChannel', () => {
  it('chỉ transfer là TK 112, còn lại là tiền mặt', () => {
    expect(isCashChannel('transfer')).toBe(false);
    expect(isCashChannel('cash')).toBe(true);
    // Chứng từ cũ có thể null — journal builder mặc định về 111
    expect(isCashChannel(null)).toBe(true);
    expect(isCashChannel(undefined)).toBe(true);
  });
});

describe('computeCashFundTotals', () => {
  it('cộng đủ mọi nguồn tiền mặt chạm TK 111', () => {
    const totals = computeCashFundTotals({
      sales: [
        { cashAmount: 900_000, transferAmount: 300_000 },
        { cashAmount: 0, transferAmount: 0 },
      ],
      saleReturns: [{ cashRefundVnd: 15_000, transferRefundVnd: 5_000 }],
      vouchers: [
        { direction: 'in', channel: 'cash', amountVnd: 50_000 },
        { direction: 'out', channel: 'cash', amountVnd: 300_000 },
        { direction: 'in', channel: 'transfer', amountVnd: 30_000 },
        { direction: 'out', channel: 'transfer', amountVnd: 10_000 },
      ],
      debtPayments: [
        { paymentMethod: 'cash', amountVnd: 100_000 },
        { paymentMethod: 'transfer', amountVnd: 50_000 },
      ],
      supplierPayments: [
        { channel: 'cash', amountVnd: 80_000 },
        { channel: 'transfer', amountVnd: 20_000 },
      ],
    });

    expect(totals.saleCashVnd).toBe(900_000);
    expect(totals.saleTransferVnd).toBe(300_000);
    expect(totals.saleReturnCashVnd).toBe(15_000);
    expect(totals.voucherInVnd).toBe(50_000);
    expect(totals.voucherOutVnd).toBe(300_000);
    expect(totals.voucherTransferInVnd).toBe(30_000);
    expect(totals.voucherTransferOutVnd).toBe(10_000);
    expect(totals.debtPaymentCashVnd).toBe(100_000);
    expect(totals.supplierPaymentCashVnd).toBe(80_000);
    // 900k + 100k + 50k - 300k - 80k - 15k
    expect(totals.netCashVnd).toBe(655_000);
    // 300k + 50k + 30k - 10k - 20k - 5k
    expect(totals.netTransferVnd).toBe(345_000);
  });

  it('không tính phiếu thu/chi chuyển khoản vào tiền mặt', () => {
    const totals = computeCashFundTotals({
      ...emptyDocs,
      vouchers: [
        { direction: 'in', channel: 'transfer', amountVnd: 70_000 },
        { direction: 'out', channel: 'transfer', amountVnd: 20_000 },
      ],
    });
    expect(totals.netCashVnd).toBe(0);
    expect(totals.voucherInVnd).toBe(0);
    expect(totals.voucherOutVnd).toBe(0);
    expect(totals.netTransferVnd).toBe(50_000);
  });

  it('thu nợ không ghi kênh vẫn là tiền mặt (khớp buildDebtPaymentJournal)', () => {
    const totals = computeCashFundTotals({
      ...emptyDocs,
      debtPayments: [{ paymentMethod: null, amountVnd: 25_000 }],
    });
    expect(totals.debtPaymentCashVnd).toBe(25_000);
    expect(totals.netCashVnd).toBe(25_000);
  });

  it('rỗng thì bằng 0', () => {
    expect(computeCashFundTotals(emptyDocs).netCashVnd).toBe(0);
    expect(computeCashFundTotals(emptyDocs).netTransferVnd).toBe(0);
  });
});

describe('bất biến: netCashVnd == phát sinh ròng TK 111', () => {
  it('khớp đúng bút toán do journal-builders sinh ra', () => {
    const docs: CashFundDocs = {
      sales: [{ cashAmount: 120_000, transferAmount: 40_000 }],
      saleReturns: [{ cashRefundVnd: 15_000, transferRefundVnd: 0 }],
      vouchers: [
        { direction: 'in', channel: 'cash', amountVnd: 50_000 },
        { direction: 'out', channel: 'cash', amountVnd: 30_000 },
        { direction: 'in', channel: 'transfer', amountVnd: 11_000 },
      ],
      debtPayments: [
        { paymentMethod: 'cash', amountVnd: 60_000 },
        { paymentMethod: 'transfer', amountVnd: 7_000 },
      ],
      supplierPayments: [
        { channel: 'cash', amountVnd: 25_000 },
        { channel: 'transfer', amountVnd: 9_000 },
      ],
    };

    const journalLines = [
      ...docs.sales.flatMap((s) =>
        buildSaleJournal({
          cashAmount: s.cashAmount,
          transferAmount: s.transferAmount,
          debtAmount: 0,
          totalVnd: s.cashAmount + s.transferAmount,
          lines: [{ qty: 1, unitCostVnd: 90_000 }],
        }),
      ),
      ...docs.saleReturns.flatMap((r) =>
        buildSaleReturnJournal({
          cashRefundVnd: r.cashRefundVnd,
          transferRefundVnd: r.transferRefundVnd,
          debtCreditVnd: 0,
          totalRefundVnd: r.cashRefundVnd + r.transferRefundVnd,
          lines: [{ qty: 1, unitCostVnd: 9_000 }],
        }),
      ),
      ...docs.vouchers.flatMap((v) =>
        buildCashVoucherJournal({
          direction: v.direction,
          channel: v.channel,
          amountVnd: v.amountVnd,
        }),
      ),
      ...docs.debtPayments.flatMap((p) =>
        buildDebtPaymentJournal({
          amountVnd: p.amountVnd,
          paymentMethod: p.paymentMethod ?? 'cash',
        }),
      ),
      ...docs.supplierPayments.flatMap((p) =>
        buildSupplierPaymentJournal({
          amountVnd: p.amountVnd,
          channel: p.channel,
        }),
      ),
    ];

    const totals = computeCashFundTotals(docs);
    const ledger111 = sumLedgerMovement(
      journalLines.filter((l) => l.accountCode === '111'),
    );
    const ledger112 = sumLedgerMovement(
      journalLines.filter((l) => l.accountCode === '112'),
    );

    expect(totals.netCashVnd).toBe(ledger111);
    expect(totals.netTransferVnd).toBe(ledger112);
  });
});
