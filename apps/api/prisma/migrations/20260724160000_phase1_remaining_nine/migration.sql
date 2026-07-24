-- Phase 1 remaining: groups, packSize, combo, debt overdue, returns, push, sync cursor
ALTER TABLE "Store" ADD COLUMN IF NOT EXISTS "debtOverdueDays" INTEGER NOT NULL DEFAULT 30;

CREATE TABLE IF NOT EXISTS "ProductGroup" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ProductGroup_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "Product" ADD COLUMN IF NOT EXISTS "sellUnit" TEXT;
ALTER TABLE "Product" ADD COLUMN IF NOT EXISTS "packSize" DECIMAL(18,3);
ALTER TABLE "Product" ADD COLUMN IF NOT EXISTS "kind" TEXT NOT NULL DEFAULT 'normal';
ALTER TABLE "Product" ADD COLUMN IF NOT EXISTS "groupId" TEXT;

DO $$ BEGIN
  ALTER TABLE "Product" ADD CONSTRAINT "Product_groupId_fkey"
    FOREIGN KEY ("groupId") REFERENCES "ProductGroup"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS "ProductComboComponent" (
    "id" TEXT NOT NULL,
    "comboProductId" TEXT NOT NULL,
    "componentProductId" TEXT NOT NULL,
    "qtyBase" DECIMAL(18,3) NOT NULL,
    CONSTRAINT "ProductComboComponent_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "ProductComboComponent_comboProductId_componentProductId_key"
  ON "ProductComboComponent"("comboProductId", "componentProductId");
CREATE INDEX IF NOT EXISTS "ProductComboComponent_comboProductId_idx"
  ON "ProductComboComponent"("comboProductId");

DO $$ BEGIN
  ALTER TABLE "ProductComboComponent" ADD CONSTRAINT "ProductComboComponent_comboProductId_fkey"
    FOREIGN KEY ("comboProductId") REFERENCES "Product"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE "ProductComboComponent" ADD CONSTRAINT "ProductComboComponent_componentProductId_fkey"
    FOREIGN KEY ("componentProductId") REFERENCES "Product"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Extend DebtLedgerType
DO $$ BEGIN
  ALTER TYPE "DebtLedgerType" ADD VALUE 'sale_return_credit';
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Extend StockDocType
DO $$ BEGIN
  ALTER TYPE "StockDocType" ADD VALUE 'sale_return';
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS "SaleReturn" (
    "id" TEXT NOT NULL,
    "storeId" TEXT NOT NULL,
    "originalSaleId" TEXT NOT NULL,
    "shiftId" TEXT,
    "recordedById" TEXT NOT NULL,
    "cashRefundVnd" INTEGER NOT NULL DEFAULT 0,
    "transferRefundVnd" INTEGER NOT NULL DEFAULT 0,
    "debtCreditVnd" INTEGER NOT NULL DEFAULT 0,
    "totalRefundVnd" INTEGER NOT NULL,
    "note" TEXT,
    "clientCreatedAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "SaleReturn_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "SaleReturn_storeId_clientCreatedAt_idx" ON "SaleReturn"("storeId", "clientCreatedAt");
CREATE INDEX IF NOT EXISTS "SaleReturn_originalSaleId_idx" ON "SaleReturn"("originalSaleId");

DO $$ BEGIN
  ALTER TABLE "SaleReturn" ADD CONSTRAINT "SaleReturn_storeId_fkey"
    FOREIGN KEY ("storeId") REFERENCES "Store"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE "SaleReturn" ADD CONSTRAINT "SaleReturn_originalSaleId_fkey"
    FOREIGN KEY ("originalSaleId") REFERENCES "Sale"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE "SaleReturn" ADD CONSTRAINT "SaleReturn_recordedById_fkey"
    FOREIGN KEY ("recordedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS "SaleReturnLine" (
    "id" TEXT NOT NULL,
    "returnId" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "qty" DECIMAL(18,3) NOT NULL,
    "unitPrice" INTEGER NOT NULL,
    "lineRefundVnd" INTEGER NOT NULL,
    CONSTRAINT "SaleReturnLine_pkey" PRIMARY KEY ("id")
);

DO $$ BEGIN
  ALTER TABLE "SaleReturnLine" ADD CONSTRAINT "SaleReturnLine_returnId_fkey"
    FOREIGN KEY ("returnId") REFERENCES "SaleReturn"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE "SyncCursor" ADD COLUMN IF NOT EXISTS "storeId" TEXT;
ALTER TABLE "SyncCursor" ADD COLUMN IF NOT EXISTS "lastPushAt" TIMESTAMP(3);
ALTER TABLE "SyncCursor" ADD COLUMN IF NOT EXISTS "userAgent" TEXT;

CREATE TABLE IF NOT EXISTS "DevicePushToken" (
    "id" TEXT NOT NULL,
    "deviceId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "platform" TEXT NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "DevicePushToken_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "DevicePushToken_deviceId_key" ON "DevicePushToken"("deviceId");
CREATE INDEX IF NOT EXISTS "DevicePushToken_userId_idx" ON "DevicePushToken"("userId");

DO $$ BEGIN
  ALTER TABLE "DevicePushToken" ADD CONSTRAINT "DevicePushToken_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
