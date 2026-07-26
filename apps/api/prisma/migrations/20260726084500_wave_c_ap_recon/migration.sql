CREATE TABLE IF NOT EXISTS "ApStatementLine" (
    "id" TEXT NOT NULL,
    "storeId" TEXT NOT NULL,
    "supplierId" TEXT NOT NULL,
    "periodYm" TEXT NOT NULL,
    "bookedAt" TIMESTAMP(3) NOT NULL,
    "amountVnd" INTEGER NOT NULL,
    "memo" TEXT,
    "matchedRef" TEXT,
    "fingerprint" TEXT,
    "matchVersion" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ApStatementLine_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "ApReconLock" (
    "id" TEXT NOT NULL,
    "storeId" TEXT NOT NULL,
    "supplierId" TEXT NOT NULL,
    "periodYm" TEXT NOT NULL,
    "lockedById" TEXT NOT NULL,
    "lockedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ApReconLock_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "ApStatementLine_storeId_supplierId_fingerprint_key"
    ON "ApStatementLine"("storeId", "supplierId", "fingerprint");
CREATE INDEX IF NOT EXISTS "ApStatementLine_storeId_supplierId_periodYm_idx"
    ON "ApStatementLine"("storeId", "supplierId", "periodYm");
CREATE UNIQUE INDEX IF NOT EXISTS "ApReconLock_storeId_supplierId_periodYm_key"
    ON "ApReconLock"("storeId", "supplierId", "periodYm");

ALTER TABLE "ApStatementLine"
    ADD CONSTRAINT "ApStatementLine_storeId_fkey"
    FOREIGN KEY ("storeId") REFERENCES "Store"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ApStatementLine"
    ADD CONSTRAINT "ApStatementLine_supplierId_fkey"
    FOREIGN KEY ("supplierId") REFERENCES "Supplier"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ApReconLock"
    ADD CONSTRAINT "ApReconLock_storeId_fkey"
    FOREIGN KEY ("storeId") REFERENCES "Store"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ApReconLock"
    ADD CONSTRAINT "ApReconLock_supplierId_fkey"
    FOREIGN KEY ("supplierId") REFERENCES "Supplier"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
