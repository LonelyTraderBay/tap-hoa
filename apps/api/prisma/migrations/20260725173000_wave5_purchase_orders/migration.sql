CREATE TYPE "PurchaseOrderStatus" AS ENUM ('draft', 'ordered', 'partial', 'received', 'closed');

CREATE TABLE "PurchaseOrder" (
  "id" TEXT NOT NULL,
  "storeId" TEXT NOT NULL,
  "supplierName" TEXT NOT NULL,
  "supplierPhone" TEXT,
  "supplierId" TEXT,
  "status" "PurchaseOrderStatus" NOT NULL DEFAULT 'draft',
  "note" TEXT,
  "createdById" TEXT NOT NULL,
  "clientCreatedAt" TIMESTAMP(3) NOT NULL,
  "orderedAt" TIMESTAMP(3),
  "closedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "PurchaseOrder_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "PurchaseOrderLine" (
  "id" TEXT NOT NULL,
  "purchaseOrderId" TEXT NOT NULL,
  "productId" TEXT NOT NULL,
  "qty" DECIMAL(18,3) NOT NULL,
  "receivedQty" DECIMAL(18,3) NOT NULL DEFAULT 0,
  "unitCostVnd" INTEGER,

  CONSTRAINT "PurchaseOrderLine_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "PurchaseReceipt" ADD COLUMN "purchaseOrderId" TEXT;

CREATE INDEX "PurchaseOrder_storeId_updatedAt_idx" ON "PurchaseOrder"("storeId", "updatedAt");
CREATE INDEX "PurchaseOrder_storeId_status_idx" ON "PurchaseOrder"("storeId", "status");
CREATE INDEX "PurchaseOrder_supplierId_idx" ON "PurchaseOrder"("supplierId");
CREATE INDEX "PurchaseOrderLine_purchaseOrderId_idx" ON "PurchaseOrderLine"("purchaseOrderId");
CREATE INDEX "PurchaseOrderLine_productId_idx" ON "PurchaseOrderLine"("productId");
CREATE INDEX "PurchaseReceipt_purchaseOrderId_idx" ON "PurchaseReceipt"("purchaseOrderId");

ALTER TABLE "PurchaseOrder"
  ADD CONSTRAINT "PurchaseOrder_storeId_fkey"
  FOREIGN KEY ("storeId") REFERENCES "Store"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "PurchaseOrder"
  ADD CONSTRAINT "PurchaseOrder_supplierId_fkey"
  FOREIGN KEY ("supplierId") REFERENCES "Supplier"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "PurchaseOrder"
  ADD CONSTRAINT "PurchaseOrder_createdById_fkey"
  FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "PurchaseOrderLine"
  ADD CONSTRAINT "PurchaseOrderLine_purchaseOrderId_fkey"
  FOREIGN KEY ("purchaseOrderId") REFERENCES "PurchaseOrder"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "PurchaseOrderLine"
  ADD CONSTRAINT "PurchaseOrderLine_productId_fkey"
  FOREIGN KEY ("productId") REFERENCES "Product"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "PurchaseReceipt"
  ADD CONSTRAINT "PurchaseReceipt_purchaseOrderId_fkey"
  FOREIGN KEY ("purchaseOrderId") REFERENCES "PurchaseOrder"("id") ON DELETE SET NULL ON UPDATE CASCADE;
