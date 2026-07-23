-- CreateEnum
CREATE TYPE "DebtLedgerType" AS ENUM ('sale_debt', 'payment');

-- CreateEnum
CREATE TYPE "DebtPaymentChannel" AS ENUM ('cash', 'transfer');

-- AlterTable
ALTER TABLE "Customer" ADD COLUMN     "creditLimitVnd" INTEGER;

-- CreateTable
CREATE TABLE "DebtLedgerEntry" (
    "id" TEXT NOT NULL,
    "storeId" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "type" "DebtLedgerType" NOT NULL,
    "amountVnd" INTEGER NOT NULL,
    "balanceAfterVnd" INTEGER NOT NULL,
    "saleId" TEXT,
    "shiftId" TEXT,
    "recordedById" TEXT NOT NULL,
    "paymentMethod" "DebtPaymentChannel",
    "note" TEXT,
    "clientCreatedAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "DebtLedgerEntry_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "DebtLedgerEntry_saleId_key" ON "DebtLedgerEntry"("saleId");

-- CreateIndex
CREATE INDEX "DebtLedgerEntry_storeId_clientCreatedAt_idx" ON "DebtLedgerEntry"("storeId", "clientCreatedAt");

-- CreateIndex
CREATE INDEX "DebtLedgerEntry_customerId_clientCreatedAt_idx" ON "DebtLedgerEntry"("customerId", "clientCreatedAt");

-- AddForeignKey
ALTER TABLE "DebtLedgerEntry" ADD CONSTRAINT "DebtLedgerEntry_storeId_fkey" FOREIGN KEY ("storeId") REFERENCES "Store"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DebtLedgerEntry" ADD CONSTRAINT "DebtLedgerEntry_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DebtLedgerEntry" ADD CONSTRAINT "DebtLedgerEntry_saleId_fkey" FOREIGN KEY ("saleId") REFERENCES "Sale"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DebtLedgerEntry" ADD CONSTRAINT "DebtLedgerEntry_recordedById_fkey" FOREIGN KEY ("recordedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
