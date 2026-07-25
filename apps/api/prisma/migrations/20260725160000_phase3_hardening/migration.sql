-- Phase 3 hardening: tax snapshots, bank recon fingerprint, e-invoice retry

DO $$ BEGIN
  ALTER TYPE "EInvoiceStatus" ADD VALUE IF NOT EXISTS 'failed';
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

ALTER TABLE "SaleLine" ADD COLUMN IF NOT EXISTS "vatRateBps" INTEGER;
ALTER TABLE "SaleLine" ADD COLUMN IF NOT EXISTS "netVnd" INTEGER;
ALTER TABLE "SaleLine" ADD COLUMN IF NOT EXISTS "vatVnd" INTEGER;

ALTER TABLE "PurchaseReceiptLine" ADD COLUMN IF NOT EXISTS "vatRateBps" INTEGER;
ALTER TABLE "PurchaseReceiptLine" ADD COLUMN IF NOT EXISTS "netVnd" INTEGER;
ALTER TABLE "PurchaseReceiptLine" ADD COLUMN IF NOT EXISTS "vatVnd" INTEGER;

ALTER TABLE "SupplierReturnLine" ADD COLUMN IF NOT EXISTS "purchaseReceiptLineId" TEXT;
ALTER TABLE "SupplierReturnLine" ADD COLUMN IF NOT EXISTS "vatRateBps" INTEGER;
ALTER TABLE "SupplierReturnLine" ADD COLUMN IF NOT EXISTS "netVnd" INTEGER;
ALTER TABLE "SupplierReturnLine" ADD COLUMN IF NOT EXISTS "vatVnd" INTEGER;

ALTER TABLE "BankStatementLine" ADD COLUMN IF NOT EXISTS "fingerprint" TEXT;
ALTER TABLE "BankStatementLine" ADD COLUMN IF NOT EXISTS "matchVersion" INTEGER NOT NULL DEFAULT 0;

CREATE UNIQUE INDEX IF NOT EXISTS "BankStatementLine_storeId_fingerprint_key"
  ON "BankStatementLine"("storeId", "fingerprint");

ALTER TABLE "EInvoice" ADD COLUMN IF NOT EXISTS "retryCount" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "EInvoice" ADD COLUMN IF NOT EXISTS "lastAttemptAt" TIMESTAMP(3);

ALTER TABLE "SupplierReturn" ADD COLUMN IF NOT EXISTS "clientId" TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS "SupplierReturn_storeId_clientId_key"
  ON "SupplierReturn"("storeId", "clientId");
CREATE INDEX IF NOT EXISTS "SupplierReturn_purchaseReceiptId_idx"
  ON "SupplierReturn"("purchaseReceiptId");
