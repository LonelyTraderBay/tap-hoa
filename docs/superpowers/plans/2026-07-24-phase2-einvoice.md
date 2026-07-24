# Phase 2 Epic 4 — E-Invoice Plan

- [x] Prisma EInvoice + status enum; adapter module
- [x] POST /einvoices/issue { saleId }; only for existing synced Sale
- [x] StubEInvoiceAdapter behind EINVOICE_ADAPTER token
- [x] e2e: missing sale 404; stub issues for synced sale

**Gate:** unsynced/missing → reject; adapter swap không đụng checkout — PASS (`einvoice.e2e-spec.ts`).
