# Wave 5 Purchase Orders Plan

**Goal:** Add supplier purchase orders that can be drafted, ordered, partially received, fully received, or closed, while preserving direct purchase receipts.

## State machine

- `draft`: editable PO created locally or from sync.
- `ordered`: confirmed PO sent/placed with supplier; eligible for receiving.
- `partial`: at least one line has been received and at least one ordered quantity remains.
- `received`: all ordered quantities have been received.
- `closed`: manually closed from `draft`, `ordered`, or `partial`; no more receipts.

Receipts are the only operation that increases stock and creates AP. Creating or ordering a PO does not affect stock, WAC, ledger, or supplier payable balances.

## Implementation steps

- [ ] Prisma: add `PurchaseOrderStatus`, `PurchaseOrder`, `PurchaseOrderLine`, and optional `PurchaseReceipt.purchaseOrderId`; add migration indexes for store/status/updatedAt and PO line lookup.
- [ ] Sync API: accept/pull purchase orders; create/update PO status through outbox; allow `purchaseReceipts` to carry optional `purchaseOrderId`; validate PO store/supplier/product lines and reject over-receipt/closed PO.
- [ ] Server receipt processing: keep receipt-without-PO behavior unchanged; on PO receipt, increment only received line quantities, recompute PO status, then create stock movement/AP/ledger from the receipt.
- [ ] Drift/local sync: add PO tables and schema migration; include PO push/pull collections; add local service methods to create/order/close PO and receive against PO.
- [ ] Flutter inventory UI: add PO list/actions, create PO dialog, and receive-against-PO flow alongside existing "Nhập NCC" direct receipt.
- [ ] Tests: API e2e for PO -> partial receive -> AP/stock correctness and direct receipt compatibility; POS service test for PO outbox/local state.

## Constraints

- Money remains integer VND; quantities remain Decimal(18,3) on server and text in Drift.
- Idempotency remains client UUID based.
- AP is created only from `PurchaseReceipt`, never from `PurchaseOrder`.
- Direct receipts without a PO remain valid and synced.
