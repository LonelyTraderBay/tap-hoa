CREATE TABLE IF NOT EXISTS "BankStatementLine" (
    "id" TEXT NOT NULL,
    "storeId" TEXT NOT NULL,
    "bankAccountId" TEXT,
    "periodYm" TEXT NOT NULL,
    "bookedAt" TIMESTAMP(3) NOT NULL,
    "amountVnd" INTEGER NOT NULL,
    "memo" TEXT,
    "matchedRef" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "BankStatementLine_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "BankReconLock" (
    "id" TEXT NOT NULL,
    "storeId" TEXT NOT NULL,
    "periodYm" TEXT NOT NULL,
    "lockedById" TEXT NOT NULL,
    "lockedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "BankReconLock_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "BankStatementLine_storeId_periodYm_idx" ON "BankStatementLine"("storeId", "periodYm");
CREATE UNIQUE INDEX IF NOT EXISTS "BankReconLock_storeId_periodYm_key" ON "BankReconLock"("storeId", "periodYm");

ALTER TABLE "BankStatementLine" ADD CONSTRAINT "BankStatementLine_storeId_fkey" FOREIGN KEY ("storeId") REFERENCES "Store"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "BankStatementLine" ADD CONSTRAINT "BankStatementLine_bankAccountId_fkey" FOREIGN KEY ("bankAccountId") REFERENCES "BankAccount"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "BankReconLock" ADD CONSTRAINT "BankReconLock_storeId_fkey" FOREIGN KEY ("storeId") REFERENCES "Store"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
