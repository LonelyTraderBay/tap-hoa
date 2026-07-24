# Inventory Stock Ops Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver Phase 1 remaining #3 — inter-store transfer (create/approve/receive), stocktake, purchase receipts, wastage, and stock movement history — offline-first via outbox.

**Architecture:** Prisma document headers+lines + append-only `StockMovement`; NestJS sync push/pull handlers; Flutter Drift mirrors + inventory feature services/UI. Pattern mirrors `cash_voucher` / `sale`.

**Tech Stack:** NestJS 10, Prisma 5, Flutter Drift, outbox sync.

**Spec:** `docs/superpowers/specs/2026-07-24-inventory-stock-ops-design.md`

## Global Constraints

- Money: integer VND; qty: Decimal(18,3) / text on Drift.
- Idempotent by client UUID `id`.
- Server authoritative after sync; reject `insufficient_stock` on transfer approve / wastage.
- Roles: cashier+ same-store for stocktake/purchase/wastage; transfer create/approve = store_manager|owner; receive = destination store member.
- No Supplier model / no PO / no shift required.

---

### Task 1: Prisma schema + migration

**Files:** `apps/api/prisma/schema.prisma`, new migration

- [ ] Add enums + models: StockTransfer(+Line), Stocktake(+Line), PurchaseReceipt(+Line), WastageVoucher(+Line), StockMovement; wire Store/User/Product relations
- [ ] `npx prisma migrate dev --name inventory_stock_ops`
- [ ] Commit

### Task 2: Push DTOs + sync process* + pull + e2e

**Files:** `apps/api/src/sync/dto/push-sale.dto.ts`, `sync.service.ts`, `apps/api/test/inventory-*.e2e-spec.ts`

- [ ] DTOs for all inventory push payloads; extend `PushSyncDto` + response accepted/rejected lists
- [ ] Implement process helpers (stock adjust + StockMovement in transaction)
- [ ] Pull collections; extend `processSale` to write sale movements
- [ ] e2e: purchase/wastage/stocktake/transfer happy path + rejects
- [ ] Commit

### Task 3: Drift v5 + pull/outbox + services

**Files:** `tables.dart`, `database.dart`, `pull_catalog.dart`, `outbox_worker.dart`, `features/inventory/*`

- [ ] Local tables + schemaVersion 5 migration + upsert helpers
- [ ] PullCatalog + OutboxWorker entity types
- [ ] Services: purchase, wastage, stocktake, transfer (+ sale movement in checkout)
- [ ] Unit tests
- [ ] Commit

### Task 4: Inventory UI + POS entry

**Files:** `features/inventory/*`, `pos_page.dart`, `main.dart`

- [ ] Hub page + create sheets + transfer queues + movement history
- [ ] App bar entry from POS
- [ ] Commit

### Task 5: Checklist + docs

- [ ] Tick 5 Inventory items in `phase1-remaining.md`; update suggested order
- [ ] Commit
