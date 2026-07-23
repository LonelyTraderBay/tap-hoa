-- CreateEnum
CREATE TYPE "CashDirection" AS ENUM ('in', 'out');

-- CreateEnum
CREATE TYPE "CashChannel" AS ENUM ('cash', 'transfer');

-- AlterTable
ALTER TABLE "Shift" ADD COLUMN     "expectedCashVnd" INTEGER,
ADD COLUMN     "transferInShiftVnd" INTEGER,
ADD COLUMN     "varianceVnd" INTEGER;

-- CreateTable
CREATE TABLE "CashCategory" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "direction" "CashDirection" NOT NULL,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "CashCategory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CashVoucher" (
    "id" TEXT NOT NULL,
    "storeId" TEXT NOT NULL,
    "shiftId" TEXT NOT NULL,
    "categoryId" TEXT NOT NULL,
    "direction" "CashDirection" NOT NULL,
    "channel" "CashChannel" NOT NULL,
    "amountVnd" INTEGER NOT NULL,
    "note" TEXT,
    "recordedById" TEXT NOT NULL,
    "clientCreatedAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CashVoucher_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "CashCategory_code_key" ON "CashCategory"("code");

-- CreateIndex
CREATE INDEX "CashVoucher_storeId_clientCreatedAt_idx" ON "CashVoucher"("storeId", "clientCreatedAt");

-- CreateIndex
CREATE INDEX "CashVoucher_shiftId_clientCreatedAt_idx" ON "CashVoucher"("shiftId", "clientCreatedAt");

-- AddForeignKey
ALTER TABLE "CashVoucher" ADD CONSTRAINT "CashVoucher_storeId_fkey" FOREIGN KEY ("storeId") REFERENCES "Store"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CashVoucher" ADD CONSTRAINT "CashVoucher_shiftId_fkey" FOREIGN KEY ("shiftId") REFERENCES "Shift"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CashVoucher" ADD CONSTRAINT "CashVoucher_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "CashCategory"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CashVoucher" ADD CONSTRAINT "CashVoucher_recordedById_fkey" FOREIGN KEY ("recordedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
