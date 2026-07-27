-- P2.2: map danh mục chi/thu -> TK sổ cái + cho phép CashVoucher không gắn ca
-- (bút toán tạo trực tiếp từ đối chiếu ngân hàng, channel='transfer').
ALTER TABLE "CashCategory" ADD COLUMN IF NOT EXISTS "accountCode" TEXT;
ALTER TABLE "CashVoucher" ALTER COLUMN "shiftId" DROP NOT NULL;
