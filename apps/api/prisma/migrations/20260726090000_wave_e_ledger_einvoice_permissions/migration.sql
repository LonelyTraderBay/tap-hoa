-- Wave E: split accounting ledger and e-invoice permissions.
ALTER TABLE "User" ADD COLUMN "canLedger" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "User" ADD COLUMN "canEinvoice" BOOLEAN NOT NULL DEFAULT false;

UPDATE "User"
SET "canLedger" = true,
    "canEinvoice" = true
WHERE "role" = 'owner';
