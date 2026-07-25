-- Phase 3 hardening A1: tax snapshots on sale return lines
-- + SaleLine -> Product relation (index/FK) declared in schema

ALTER TABLE "SaleReturnLine" ADD COLUMN IF NOT EXISTS "vatRateBps" INTEGER;
ALTER TABLE "SaleReturnLine" ADD COLUMN IF NOT EXISTS "netVnd" INTEGER;
ALTER TABLE "SaleReturnLine" ADD COLUMN IF NOT EXISTS "vatVnd" INTEGER;

CREATE INDEX IF NOT EXISTS "SaleLine_productId_idx" ON "SaleLine"("productId");

DO $$ BEGIN
  ALTER TABLE "SaleLine"
    ADD CONSTRAINT "SaleLine_productId_fkey"
    FOREIGN KEY ("productId") REFERENCES "Product"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;
