-- Phase 2 Epic 1: per-store WAC + sale line COGS snapshot
ALTER TABLE "ProductStoreStock" ADD COLUMN IF NOT EXISTS "avgCostVnd" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "SaleLine" ADD COLUMN IF NOT EXISTS "unitCostVnd" INTEGER;

-- Seed avg from catalog cost where stock already exists
UPDATE "ProductStoreStock" AS s
SET "avgCostVnd" = p."costVnd"
FROM "Product" AS p
WHERE s."productId" = p."id" AND s."avgCostVnd" = 0 AND p."costVnd" > 0;
