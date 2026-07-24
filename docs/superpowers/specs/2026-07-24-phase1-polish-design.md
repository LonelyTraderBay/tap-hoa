# Phase 1 polish design (2026-07-24)

Closes stub/UX gaps after Phase 1 Remaining Nine so Phase 1 is usable end-to-end.

## Combo

- Product form lists combo components (name + qty base), picker excludes self/combo SKUs.
- Client + API reject `kind=combo` with empty components (`invalid_combo`).
- Checkout / sync sale decrement component stock only.

## Product groups

- `ProductGroupPage` CRUD via `ProductGroupService` → outbox `product_group_upsert`.
- Soft-delete: `active=false` hides from POS chips (`watchGroups(activeOnly: true)`).

## Sale returns

- Refund split: cash / transfer / debtCredit must equal line refund total.
- Debt credit requires original sale customer.
- UI shows product names; POS entry role-gated (`owner` | `store_manager`).

## Debt overdue

- Settings sheet patches `PATCH /stores/:id/debt-overdue-days` and updates `storesLocal`.
- Debt list shows `daysOutstanding` and Quá hạn badge.

## ESC/POS (Windows)

- Meta: `receiptPrintMode` = `pdf | escpos | ask`, `receiptPrinterName`.
- Raw bytes via Win32 `OpenPrinter` / `WritePrinter`; failure offers PDF.
- Settings page under POS print menu.

## FCM

- Client: optional `firebase_core` / `firebase_messaging`; token → meta → `POST /devices/push-token`.
- API: optional `firebase-admin` from `FIREBASE_SERVICE_ACCOUNT` JSON path.
- Triggers: sync push rejects → `notifyUser`; post-pull low stock → `POST /devices/low-stock-alert` (dedupe meta `lowStockNotified:$productId:$ictDate`).
- Missing Firebase config: log / skip, no crash.

## Ops / Definition of Done

- Migration `20260724160000_phase1_remaining_nine` tracked + deployable.
- CSV day report maps `storeCode` / `storeName` from `storesLocal`.
- Unit: combo checkout, group upsert/hide inactive, return refund split + role gate.
- API e2e: `product_group_upsert`, `sale_return` same-day reject (`phase1-polish.e2e-spec.ts`).
