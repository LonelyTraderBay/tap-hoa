-- P1.2: allowNegativeStock — per-store local checkout/stock-decrement override
ALTER TABLE "Store" ADD COLUMN IF NOT EXISTS "allowNegativeStock" BOOLEAN NOT NULL DEFAULT false;
