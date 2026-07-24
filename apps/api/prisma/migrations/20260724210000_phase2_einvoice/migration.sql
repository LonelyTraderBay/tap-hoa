-- Phase 2 Epic 4: e-invoice
CREATE TYPE "EInvoiceStatus" AS ENUM ('draft', 'pending_sign', 'issued', 'cancelled');

CREATE TABLE "EInvoice" (
    "id" TEXT NOT NULL,
    "saleId" TEXT NOT NULL,
    "status" "EInvoiceStatus" NOT NULL DEFAULT 'draft',
    "buyerTaxCode" TEXT,
    "templateCode" TEXT,
    "serial" TEXT,
    "invoiceNumber" TEXT,
    "provider" TEXT NOT NULL,
    "providerRef" TEXT,
    "xmlPath" TEXT,
    "pdfPath" TEXT,
    "errorMessage" TEXT,
    "issuedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "EInvoice_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "EInvoice_saleId_key" ON "EInvoice"("saleId");
CREATE INDEX "EInvoice_status_idx" ON "EInvoice"("status");
ALTER TABLE "EInvoice" ADD CONSTRAINT "EInvoice_saleId_fkey"
  FOREIGN KEY ("saleId") REFERENCES "Sale"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
