export type CreateCustomerDto = {
  id?: string;
  storeId: string;
  name: string;
  phone?: string | null;
};
