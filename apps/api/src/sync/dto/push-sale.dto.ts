export type PushSaleLineDto = {
  productId: string;
  qty: string;
  unitPrice: number;
  discountVnd?: number;
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

export type PushProductSeedStockDto = {
  qty: string;
  minQty?: string;
};

export type PushProductUpsertDto = {
  id: string;
  sku: string;
  barcode?: string | null;
  name: string;
  unit: string;
  sellUnit?: string | null;
  packSize?: string | null;
  kind?: 'normal' | 'combo';
  groupId?: string | null;
  isWeighted: boolean;
  basePriceVnd: number;
  costVnd?: number;
  active: boolean;
  storeId: string;
  seedStock?: PushProductSeedStockDto | null;
  components?: PushComboComponentDto[] | null;
};

export type PushComboComponentDto = {
  id?: string;
  componentProductId: string;
  qtyBase: string;
};

export type PushProductGroupUpsertDto = {
  id: string;
  name: string;
  sortOrder?: number;
  active?: boolean;
};

export type PushSaleReturnLineDto = {
  id?: string;
  productId: string;
  qty: string;
  unitPrice: number;
  lineRefundVnd: number;
};

export type PushSaleReturnDto = {
  id: string;
  storeId: string;
  originalSaleId: string;
  shiftId?: string | null;
  cashRefundVnd: number;
  transferRefundVnd: number;
  debtCreditVnd: number;
  totalRefundVnd: number;
  note?: string | null;
  clientCreatedAt: string;
  lines: PushSaleReturnLineDto[];
};

export type PushStockLineDto = {
  id?: string;
  productId: string;
  qty: string;
};

export type PushStockTransferCreateDto = {
  id: string;
  fromStoreId: string;
  toStoreId: string;
  note?: string | null;
  clientCreatedAt: string;
  lines: PushStockLineDto[];
};

export type PushStockTransferActionDto = {
  id: string;
  actionAt?: string;
};

export type PushStocktakeLineDto = {
  id?: string;
  productId: string;
  systemQty: string;
  countedQty: string;
  varianceQty: string;
  reason: 'increase' | 'decrease' | 'match';
  reasonNote?: string | null;
};

export type PushStocktakeDto = {
  id: string;
  storeId: string;
  note?: string | null;
  clientCreatedAt: string;
  lines: PushStocktakeLineDto[];
};

export type PushPurchaseLineDto = {
  id?: string;
  productId: string;
  qty: string;
  unitCostVnd?: number | null;
};

export type PushPurchaseReceiptDto = {
  id: string;
  storeId: string;
  supplierName: string;
  supplierPhone?: string | null;
  supplierId?: string | null;
  note?: string | null;
  clientCreatedAt: string;
  lines: PushPurchaseLineDto[];
};

export type PushWastageDto = {
  id: string;
  storeId: string;
  reasonCode: 'spoilage' | 'damage' | 'other';
  note?: string | null;
  clientCreatedAt: string;
  lines: PushStockLineDto[];
};

export type PushSyncDto = {
  deviceId: string;
  shiftOpens?: PushShiftOpenDto[];
  shiftCloses?: PushShiftCloseDto[];
  sales: PushSaleDto[];
  debtPayments?: PushDebtPaymentDto[];
  cashVouchers?: PushCashVoucherDto[];
  customerUpserts?: PushCustomerUpsertDto[];
  stockTransferCreates?: PushStockTransferCreateDto[];
  stockTransferApproves?: PushStockTransferActionDto[];
  stockTransferRejects?: PushStockTransferActionDto[];
  stockTransferReceives?: PushStockTransferActionDto[];
  stocktakes?: PushStocktakeDto[];
  purchaseReceipts?: PushPurchaseReceiptDto[];
  wastages?: PushWastageDto[];
  productUpserts?: PushProductUpsertDto[];
  productGroupUpserts?: PushProductGroupUpsertDto[];
  saleReturns?: PushSaleReturnDto[];
};
