-- Persist transfer cost snapshots used by receive, journals, and period unlock replay.
ALTER TABLE "StockTransferLine"
  ADD COLUMN "unitCostVnd" INTEGER;

UPDATE "StockTransferLine" line
SET "unitCostVnd" = stock."avgCostVnd"
FROM "StockTransfer" transfer, "ProductStoreStock" stock
WHERE line."transferId" = transfer."id"
  AND stock."productId" = line."productId"
  AND stock."storeId" = transfer."fromStoreId"
  AND line."unitCostVnd" IS NULL
  AND stock."avgCostVnd" > 0;

-- Denormalize invoice-sale claim state so Postgres can enforce uniqueness
-- for active non-adjustment claims while still allowing adjustment links.
ALTER TABLE "EInvoiceSale"
  ADD COLUMN "isAdjustment" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "claimActive" BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN "claimKey" TEXT;

UPDATE "EInvoiceSale" link
SET "isAdjustment" = invoice."adjustmentForId" IS NOT NULL,
    "claimActive" = invoice."status" <> 'failed',
    "claimKey" = CASE
      WHEN invoice."adjustmentForId" IS NULL AND invoice."status" <> 'failed'
      THEN link."saleId"
      ELSE NULL
    END
FROM "EInvoice" invoice
WHERE invoice."id" = link."invoiceId";

CREATE UNIQUE INDEX "EInvoiceSale_claimKey_key"
  ON "EInvoiceSale"("claimKey");

CREATE INDEX "EInvoiceSale_saleId_isAdjustment_claimActive_idx"
  ON "EInvoiceSale"("saleId", "isAdjustment", "claimActive");

CREATE UNIQUE INDEX "EInvoiceSale_active_non_adjustment_saleId_key"
  ON "EInvoiceSale"("saleId")
  WHERE "isAdjustment" = false AND "claimActive" = true;
