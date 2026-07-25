# Transfer Journal TDD Implementation Plan

> **Wave 3 plan commit:** implement only after this plan is committed. Mirror the existing stocktake/wastage journal paths and keep posting fail-soft after the stock transfer receive transaction succeeds.

**Goal:** Posting a completed stock transfer receive creates an idempotent ledger journal that moves inventory value from the source store to the destination store without recognizing COGS.

## Locked CoA decision

- Use the same inventory account `156` for both sides of the transfer.
- Post on **receive** completion only; draft/create and approve/shipment do not post ledger entries.
- Header `JournalEntry.storeId` is the destination store (`StockTransfer.toStoreId`) because the posting is triggered by destination receipt.
- Lines use a dual `156` entry to preserve store-scoped movement without touching revenue/expense:
  - Dr `156` for received inventory value.
  - Cr `156` for transferred-out inventory value.
- No COGS (`632`) and no wastage/adjustment expense (`642`) on transfer.
- Per line amount is `round(qty * avgCostVnd)` using source-store WAC at posting time; skip lines where source stock cost is `null` or `<= 0`.
- Empty journals are allowed to skip through `postEntry`, same as wastage/stocktake.
- Use `sourceType: 'stock_transfer'` for idempotency and period unlock replay.

## Current patterns to mirror

- `apps/api/src/ledger/journal-builders.ts`
  - `buildStocktakeJournal` and `buildWastageJournal` aggregate costed lines and return `[]` for no-cost input.
- `apps/api/src/ledger/ledger.service.ts`
  - `postEntry` already handles balanced lines, idempotency, account seeding, empty journal skip, period locks, and blocked-period audit.
  - `postFromStocktake` / `postFromWastage` fetch persisted document lines, read `ProductStoreStock.avgCostVnd`, build lines, then call `postEntry`.
  - `replayJournalSource` is the period unlock source-type allowlist.
- `apps/api/src/sync/stock-ops.service.ts`
  - `processTransferReceive` updates destination stock and marks the transfer received inside a transaction.
  - Stocktake/wastage hooks call `ledger.safePost(...)` after the transaction succeeds.

## Hook point

- Add the transfer journal hook immediately after the successful `processTransferReceive` transaction and before returning `{ accepted: true }`.
- Keep it outside the transaction:

```ts
await this.ledger.safePost(
  () => this.ledger.postFromStockTransfer(dto.id, user.userId),
  {
    sourceType: 'stock_transfer',
    sourceId: dto.id,
    actorUserId: user.userId,
  },
);
```

## Implementation tasks

### 1. RED - builder unit tests

- File: `apps/api/src/ledger/journal-builders.spec.ts`
- Import future `buildStockTransferJournal`.
- Add coverage for:
  - Costed transfer lines post balanced Dr `156` / Cr `156`.
  - No `632` COGS line exists.
  - No-cost lines return `[]`.
  - Rounding is per line.

### 2. GREEN - builder

- File: `apps/api/src/ledger/journal-builders.ts`
- Add `buildStockTransferJournal(input: { lines: { qty: number; avgCostVnd: number | null }[] }): JournalLineDraft[]`.
- Sum `Math.round(qty * avgCostVnd)` for source-costed lines.
- Return `[]` if total is `<= 0`.
- Otherwise push Dr `156`, Cr `156`, and assert balance.

### 3. RED - e2e transfer journal spec

- Add `apps/api/test/transfer-journal.e2e-spec.ts`.
- Bootstrap `AppModule`, seed chart of accounts, login as owner, resolve CH1/CH2 and SKU `STING-330`.
- Clean transfer journals, blocked-period audit rows, transfer rows, movements, and relevant stock rows per test.
- Scenarios:
  1. Create -> approve -> receive posts one `sourceType: 'stock_transfer'` journal at source WAC, with `storeId` = destination, Dr `156` = Cr `156`, no `632`, and duplicate receive remains idempotent.
  2. Locked receive period accepts the transfer receive, creates no journal, and writes `journal_blocked_period_lock` audit for `entityType: 'stock_transfer'`; unlock replays the blocked journal.
  3. Source stock with no cost accepts receive but creates no journal.

### 4. GREEN - ledger service

- Import `buildStockTransferJournal`.
- Add `postFromStockTransfer(stockTransferId: string, actorUserId?: string)`.
- Fetch `stockTransfer.findUnique({ include: { lines: true } })`; return if missing or not `received`.
- For each line, read source stock by `productId` + `fromStoreId`.
- Build lines with `qty: Number(line.qty)` and `avgCostVnd: sourceStock?.avgCostVnd ?? null`.
- Call `postEntry` with:
  - `storeId: row.toStoreId`
  - `sourceType: 'stock_transfer'`
  - `sourceId: row.id`
  - `postedAt: row.receivedAt ?? row.updatedAt`
  - `memo: row.note ?? undefined`

### 5. GREEN - period unlock replay

- Extend `replayJournalSource` with `case 'stock_transfer': await this.postFromStockTransfer(...)`.

### 6. Docs and verification

- Update `CHANGELOG.md` under Unreleased / Phase 2 closeout follow-up.
- Tick the deferred transfer journal note in `docs/superpowers/plans/2026-07-25-phase2-hardening.md`.
- Run focused tests:

```powershell
npm --workspace apps/api test -- journal-builders.spec.ts
npm --workspace apps/api test:e2e -- transfer-journal.e2e-spec.ts
```

## Definition of done

- Plan is committed before implementation.
- Transfer receives post fail-soft, idempotent journals using `sourceType: 'stock_transfer'`.
- Period unlock replay supports transfer journals.
- E2E coverage proves happy path, period lock + replay, and no-cost skip.
- `.superpowers/` remains uncommitted.
