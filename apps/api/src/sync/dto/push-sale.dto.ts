export type PushSaleLineDto = {
  productId: string;
  qty: string;
  unitPrice: number;
  lineTotal: number;
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
  clientCreatedAt: string;
  lines: PushSaleLineDto[];
};

export type PushSyncDto = {
  deviceId: string;
  sales: PushSaleDto[];
};
