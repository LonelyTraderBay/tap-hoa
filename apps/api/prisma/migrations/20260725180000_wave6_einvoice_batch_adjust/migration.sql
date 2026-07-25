-- Wave 6: e-invoice batches and adjustments

DO $$ BEGIN
  ALTER TYPE "EInvoiceStatus" ADD VALUE IF NOT EXISTS 'adjusted';
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DROP INDEX IF EXISTS "EInvoice_saleId_key";

ALTER TABLE "EInvoice" ADD COLUMN IF NOT EXISTS "adjustmentForId" TEXT;
ALTER TABLE "EInvoice" ADD COLUMN IF NOT EXISTS "adjustmentReason" TEXT;

CREATE TABLE IF NOT EXISTS "EInvoiceSale" (
  "invoiceId" TEXT NOT NULL,
  "saleId" TEXT NOT NULL,
  CONSTRAINT "EInvoiceSale_pkey" PRIMARY KEY ("invoiceId", "saleId")
);

INSERT INTO "EInvoiceSale" ("invoiceId", "saleId")
SELECT "id", "saleId" FROM "EInvoice"
ON CONFLICT DO NOTHING;

CREATE INDEX IF NOT EXISTS "EInvoice_saleId_idx" ON "EInvoice"("saleId");
CREATE INDEX IF NOT EXISTS "EInvoice_adjustmentForId_idx" ON "EInvoice"("adjustmentForId");
CREATE INDEX IF NOT EXISTS "EInvoiceSale_saleId_idx" ON "EInvoiceSale"("saleId");

DO $$ BEGIN
  ALTER TABLE "EInvoice" ADD CONSTRAINT "EInvoice_adjustmentForId_fkey"
    FOREIGN KEY ("adjustmentForId") REFERENCES "EInvoice"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  ALTER TABLE "EInvoiceSale" ADD CONSTRAINT "EInvoiceSale_invoiceId_fkey"
    FOREIGN KEY ("invoiceId") REFERENCES "EInvoice"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  ALTER TABLE "EInvoiceSale" ADD CONSTRAINT "EInvoiceSale_saleId_fkey"
    FOREIGN KEY ("saleId") REFERENCES "Sale"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;
