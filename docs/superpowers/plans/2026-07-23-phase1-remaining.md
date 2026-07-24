# Phase 1 — Remaining items (complete)

> Follow-up after the Phase 1 MVP vertical slice in `2026-07-23-phase1-foundation-pos.md`.  
> Originally deferred from foundation MVP; **polish closed 2026-07-24** (`docs/superpowers/specs/2026-07-24-phase1-polish-design.md`).

**Spec:** `docs/superpowers/specs/2026-07-23-tap-hoa-pos-ke-toan-design.md` (§4)

---

## Inventory & stock operations

- [x] Inter-store stock transfer (create, approve, receive)
- [x] Stocktake / kiểm kê with variance reasons (tăng/giảm)
- [x] Wastage / hao hụt / xuất hủy vouchers
- [x] Supplier purchase receipts (phiếu nhập NCC)
- [x] Stock movement history UI per store

## Product catalog polish

- [x] Full product CRUD UI (create/edit on client + sync push)
- [x] Product groups / categories
- [x] Unit conversion (thùng ↔ chai)
- [x] Barcode label printing

## Customer debt

- [x] Debt payment recording and history
- [x] Credit limit enforcement at checkout
- [x] Debt aging / overdue views (+ `debtOverdueDays` settings UI)
- [x] Customer search and detail screen polish

## Cash management

- [x] Cash in/out vouchers with categories
- [x] Shift close reconciliation vs expected cash
- [x] Basic thu chi ledger tied to shift/store

## POS hardware & UX

- [x] Thermal receipt printer drivers (Windows) — ESC/POS raw Win32 + PDF fallback
- [x] PDF receipt via OS print dialog
- [x] Return/exchange same-day with role gate
- [x] Combo/bundle products
- [x] Push notifications (sync errors, low stock) — FCM token register + optional firebase-admin send

## Reports (Phase 1 extensions)

- [x] Top SKU / best sellers for the day
- [x] Stock-on-hand report per store
- [x] Export CSV for day revenue (store code/name from `storesLocal`)

## Sync & ops

- [x] Conflict resolution UI for rejected outbox entries
- [x] Product/stock push from client (not only pull)
- [x] Multi-device cursor diagnostics for support

---

## Suggested implementation order

1. ~~**Debt payments + history**~~ — done (`feat/debt-payments-credit-limit`)
2. ~~**Cash in/out + shift reconciliation**~~ — done (`feat/cash-vouchers-shift-reconciliation`)
3. ~~**Inter-store transfer + stocktake**~~ — done (`feat/inventory-stock-ops`)
4. ~~**Product CRUD + barcode labels**~~ — done (`feat/product-crud-barcode-labels`)
5. ~~**Thermal print + top SKU report**~~ — done (PDF + Windows ESC/POS raw; see polish design)
6. ~~**Conflict resolution UI (outbox reject)**~~ — done (`feat/conflict-outbox-ui`)
7. ~~**Stock-on-hand report per store**~~ — done (`feat/stock-on-hand-report`)
8. ~~**Phase 1 polish**~~ — combo picker, group CRUD, return refund channels, debt overdue UI, FCM e2e (`docs/superpowers/specs/2026-07-24-phase1-polish-design.md`)

## Dependencies on MVP (done)

- Auth, stores, shifts
- Local Drift DB + outbox sync (push sales, pull catalog/stock)
- Offline checkout with stock decrement
- Day sales report (store + owner consolidated)
- Customer debt on checkout + balance sync (payments / aging / overdue settings in polish)

## Not in Phase 1 (Phase 2)

See roadmap: `docs/superpowers/plans/2026-07-24-phase2-roadmap.md`

- Full accounting ledger, COGS (Epic 1 WAC done), supplier AP
- E-invoice integration (Viettel, MISA, EasyInvoice, …)
- Tax reporting, period close / khóa sổ
