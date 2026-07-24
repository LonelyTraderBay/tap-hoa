# Phase 2 Epic 2 — Ledger Implementation Plan

> **For agentic workers:** Use subagent-driven-development or executing-plans.

**Goal:** Auto journals from synced Phase 1 docs + period lock.

## Status: Implementing / Done in code

### Tasks

- [x] Prisma Account, JournalEntry, JournalLine, PeriodLock, AuditLog + migration
- [x] Seed CoA (111–711)
- [x] `journal-builders` + LedgerService + hooks (sale, debt, cash, purchase)
- [x] API GET journal / trial-balance / period-locks; POST lock (owner)
- [x] Flutter owner **Sổ kế toán** (nhật ký + CĐPS)
- [x] e2e `ledger.e2e-spec.ts`
