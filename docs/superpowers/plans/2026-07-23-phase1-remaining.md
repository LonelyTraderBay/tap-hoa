# Phase 1 — Remaining items (deferred)

> Follow-up plan after the Phase 1 MVP vertical slice in `2026-07-23-phase1-foundation-pos.md`.  
> These items are still **Phase 1** per the product spec but were intentionally deferred from the foundation + POS MVP.

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
- [ ] Product groups / categories
- [ ] Unit conversion (thùng ↔ chai)
- [x] Barcode label printing

## Customer debt (beyond stub)

- [x] Debt payment recording and history
- [x] Credit limit enforcement at checkout
- [ ] Debt aging / overdue views
- [x] Customer search and detail screen polish

## Cash management

- [x] Cash in/out vouchers with categories
- [x] Shift close reconciliation vs expected cash
- [x] Basic thu chi ledger tied to shift/store

## POS hardware & UX

- [ ] Thermal receipt printer drivers (Windows) — ESC/POS deferred
- [x] PDF receipt via OS print dialog
- [ ] Return/exchange same-day with role gate
- [ ] Combo/bundle products
- [ ] Push notifications (sync errors, low stock)

## Reports (Phase 1 extensions)

- [x] Top SKU / best sellers for the day
- [ ] Stock-on-hand report per store
- [ ] Export CSV for day revenue

## Sync & ops

- [x] Conflict resolution UI for rejected outbox entries
- [x] Product/stock push from client (not only pull)
- [ ] Multi-device cursor diagnostics for support

---

## Suggested implementation order

1. ~~**Debt payments + history**~~ — done (`feat/debt-payments-credit-limit`)
2. ~~**Cash in/out + shift reconciliation**~~ — done (`feat/cash-vouchers-shift-reconciliation`)
3. ~~**Inter-store transfer + stocktake**~~ — done (`feat/inventory-stock-ops`)
4. ~~**Product CRUD + barcode labels**~~ — done (`feat/product-crud-barcode-labels`)
5. ~~**Thermal print + top SKU report**~~ — done (`feat/thermal-receipt-top-sku`; PDF receipt via OS print; ESC/POS drivers deferred)
6. ~~**Conflict resolution UI (outbox reject)**~~ — done (`feat/conflict-outbox-ui`)

## Dependencies on MVP (done)

- Auth, stores, shifts
- Local Drift DB + outbox sync (push sales, pull catalog/stock)
- Offline checkout with stock decrement
- Day sales report (store + owner consolidated)
- Customer debt stub on checkout + balance sync

## Not in Phase 1 (Phase 2)

- Full accounting ledger, COGS, supplier AP
- E-invoice integration (Viettel, MISA, EasyInvoice, …)
- Tax reporting, period close / khóa sổ
