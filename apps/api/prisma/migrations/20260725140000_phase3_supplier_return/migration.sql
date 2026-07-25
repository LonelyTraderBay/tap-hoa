-- Phase 3: supplier returns (reduce stock + AP)
ALTER TYPE "StockDocType" ADD VALUE IF NOT EXISTS 'supplier_return';

CREATE TABLE IF NOT EXISTS "SupplierReturn" (
    "id" TEXT NOT NULL,
    "storeId" TEXT NOT NULL,
    "supplierId" TEXT NOT NULL,
    "purchaseReceiptId" TEXT,
    "note" TEXT,
    "amountVnd" INTEGER NOT NULL,
    "recordedById" TEXT NOT NULL,
    "clientCreatedAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "SupplierReturn_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "SupplierReturnLine" (
    "id" TEXT NOT NULL,
    "returnId" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "qty" DECIMAL(18,3) NOT NULL,
    "unitCostVnd" INTEGER NOT NULL,
    CONSTRAINT "SupplierReturnLine_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "SupplierReturn_storeId_clientCreatedAt_idx" ON "SupplierReturn"("storeId", "clientCreatedAt");
CREATE INDEX IF NOT EXISTS "SupplierReturn_supplierId_idx" ON "SupplierReturn"("supplierId");
CREATE INDEX IF NOT EXISTS "SupplierReturnLine_returnId_idx" ON "SupplierReturnLine"("returnId");

ALTER TABLE "SupplierReturn" ADD CONSTRAINT "SupplierReturn_storeId_fkey" FOREIGN KEY ("storeId") REFERENCES "Store"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "SupplierReturn" ADD CONSTRAINT "SupplierReturn_supplierId_fkey" FOREIGN KEY ("supplierId") REFERENCES "Supplier"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "SupplierReturn" ADD CONSTRAINT "SupplierReturn_recordedById_fkey" FOREIGN KEY ("recordedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "SupplierReturnLine" ADD CONSTRAINT "SupplierReturnLine_returnId_fkey" FOREIGN KEY ("returnId") REFERENCES "SupplierReturn"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "SupplierReturnLine" ADD CONSTRAINT "SupplierReturnLine_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
