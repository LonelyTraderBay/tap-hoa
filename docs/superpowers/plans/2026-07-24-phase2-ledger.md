# Phase 2 Epic 2 — Ledger Implementation Plan (outline)

> Implement only after Epic 1 merged. Full TDD tasks in follow-up when starting this epic.

**Goal:** Auto journals from synced Phase 1 docs + period lock.

**Suggested tasks:**
1. Prisma: Account, JournalEntry, JournalLine, PeriodLock, AuditLog + migration
2. `LedgerService.postSale(saleId)` using SaleLine.unitCostVnd
3. Hook after successful sync push (sales, debt payments, cash vouchers)
4. API: GET journal / ledger / trial-balance; POST period-lock
5. Flutter: read-only sổ views for owner
6. e2e: sale → journal lines balanced; locked period rejects post
