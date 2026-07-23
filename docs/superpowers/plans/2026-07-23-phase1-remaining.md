# Phase 1 — Remaining items (deferred)

> Follow-up plan after the Phase 1 MVP vertical slice in `2026-07-23-phase1-foundation-pos.md`.  
> These items are still **Phase 1** per the product spec but were intentionally deferred from the foundation + POS MVP.

**Spec:** `docs/superpowers/specs/2026-07-23-tap-hoa-pos-ke-toan-design.md` (§4)

---

## Inventory & stock operations

- [ ] Inter-store stock transfer (create, approve, receive)
- [ ] Stocktake / kiểm kê with variance reasons (tăng/giảm)
- [ ] Wastage / hao hụt / xuất hủy vouchers
- [ ] Supplier purchase receipts (phiếu nhập NCC)
- [ ] Stock movement history UI per store

## Product catalog polish

- [ ] Full product CRUD UI (create/edit on client + sync push)
- [ ] Product groups / categories
- [ ] Unit conversion (thùng ↔ chai)
- [ ] Barcode label printing

## Customer debt (beyond stub)

- [x] Debt payment recording and history
- [x] Credit limit enforcement at checkout
- [ ] Debt aging / overdue views
- [x] Customer search and detail screen polish

## Cash management

- [ ] Cash in/out vouchers with categories
- [ ] Shift close reconciliation vs expected cash
- [ ] Basic thu chi ledger tied to shift/store

## POS hardware & UX

- [ ] Thermal receipt printer drivers (Windows)
- [ ] Return/exchange same-day with role gate
- [ ] Combo/bundle products
- [ ] Push notifications (sync errors, low stock)

## Reports (Phase 1 extensions)

- [ ] Top SKU / best sellers for the day
- [ ] Stock-on-hand report per store
- [ ] Export CSV for day revenue

## Sync & ops

- [ ] Conflict resolution UI for rejected outbox entries
- [ ] Product/stock push from client (not only pull)
- [ ] Multi-device cursor diagnostics for support

---

## Suggested implementation order

1. ~~**Debt payments + history**~~ — done (`feat/debt-payments-credit-limit`)
2. **Cash in/out + shift reconciliation** — daily store ops
3. **Inter-store transfer + stocktake** — multi-store inventory
4. **Product CRUD + barcode labels** — catalog self-service
5. **Thermal print + top SKU report** — counter polish

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
