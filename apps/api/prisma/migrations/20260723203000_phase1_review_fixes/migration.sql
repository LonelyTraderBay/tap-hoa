-- Scope customers to the store where their balance is maintained.
ALTER TABLE "Customer" ADD COLUMN "storeId" TEXT;

UPDATE "Customer" AS customer
SET "storeId" = COALESCE(
  (
    SELECT sale."storeId"
    FROM "Sale" AS sale
    WHERE sale."customerId" = customer."id"
    ORDER BY sale."createdAt" ASC
    LIMIT 1
  ),
  (
    SELECT store."id"
    FROM "Store" AS store
    ORDER BY store."createdAt" ASC
    LIMIT 1
  )
);

ALTER TABLE "Customer" ALTER COLUMN "storeId" SET NOT NULL;

CREATE INDEX "Customer_storeId_idx" ON "Customer"("storeId");

ALTER TABLE "Customer"
ADD CONSTRAINT "Customer_storeId_fkey"
FOREIGN KEY ("storeId") REFERENCES "Store"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;

-- PostgreSQL partial unique index: only one open shift per user/store.
CREATE UNIQUE INDEX "Shift_storeId_userId_open_key"
ON "Shift"("storeId", "userId")
WHERE "closedAt" IS NULL;
