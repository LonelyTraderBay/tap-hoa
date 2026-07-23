export type PushSaleLineDto = {
  productId: string;
  qty: string;
  unitPrice: number;
  lineTotal: number;
};

export type PushSaleCustomerDto = {
  id: string;
  name: string;
  phone?: string | null;
};

export type PushSaleDto = {
  id: string;
  storeId: string;
  shiftId: string;
  soldById: string;
  paymentMethod: string;
  cashAmount: number;
  transferAmount: number;
  debtAmount: number;
  discountVnd: number;
  totalVnd: number;
  customerId?: string | null;
  customer?: PushSaleCustomerDto | null;
  clientCreatedAt: string;
  lines: PushSaleLineDto[];
};

export type PushShiftOpenDto = {
  id: string;
  storeId: string;
  userId?: string;
  openingCash: number;
  openedAt: string;
};

export type PushShiftCloseDto = {
  id: string;
  closingCash: number;
  note?: string | null;
  closedAt: string;
  expectedCashVnd?: number;
  varianceVnd?: number;
  transferInShiftVnd?: number;
};

export type PushCashVoucherDto = {
  id: string;
  storeId: string;
  shiftId: string;
  categoryId: string;
  direction: 'in' | 'out';
  channel: 'cash' | 'transfer';
  amountVnd: number;
  note?: string | null;
  recordedById?: string;
  clientCreatedAt: string;
};

export type PushDebtPaymentDto = {
  id: string;
  storeId: string;
  customerId: string;
  amountVnd: number;
  paymentMethod: 'cash' | 'transfer';
  note?: string | null;
  shiftId?: string | null;
  clientCreatedAt: string;
  recordedById?: string;
};

export type PushCustomerUpsertDto = {
  id: string;
  storeId: string;
  name: string;
  phone?: string | null;
  creditLimitVnd?: number | null;
};

export type PushSyncDto = {
  deviceId: string;
  shiftOpens?: PushShiftOpenDto[];
  shiftCloses?: PushShiftCloseDto[];
  sales: PushSaleDto[];
  debtPayments?: PushDebtPaymentDto[];
  cashVouchers?: PushCashVoucherDto[];
  customerUpserts?: PushCustomerUpsertDto[];
};
