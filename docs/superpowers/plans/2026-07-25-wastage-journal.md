# Wastage Journal TDD Implementation Plan

> **For agentic workers:** This is a TDD plan only. Implement it task-by-task in Task C.1; do not add feature code while completing Task C.0.

**Goal:** Posting a synced wastage voucher creates a ledger journal that decreases inventory at weighted average cost (WAC), matching the stocktake decrease accounting pattern.

**Locked CoA decision:**

- Wastage decreases inventory at WAC, same as stocktake decrease.
- Per costed line: `amount = round(qty * avgCostVnd)`.
- Aggregate journal:
  - Dr `642`
  - Cr `156`
- Ignore lines where `avgCostVnd` is `null` or `<= 0`.
- Return/post an empty journal when no lines are costed, same as `buildStocktakeJournal`.
- Use `sourceType: 'wastage'`.
- Posting must be fail-soft after the wastage voucher persists, matching the stocktake hook.
- Period lock must block posting.
- Stock transfer journals are out of scope for this plan; Task C.2 stays deferred.

## Current patterns to mirror

**Files already inspected:**

- `apps/api/src/ledger/journal-builders.ts`
  - `buildStocktakeJournal` at the bottom of the file.
  - Stocktake decrease already posts Dr `642` / Cr `156`.
- `apps/api/src/ledger/journal-builders.spec.ts`
  - Existing unit tests cover balanced stocktake increase/decrease and empty no-cost variance.
- `apps/api/src/ledger/ledger.service.ts`
  - `postEntry` handles idempotency, empty journals, period locks, account seeding, and audit for blocked periods.
  - `postFromStocktake` fetches stocktake lines and `ProductStoreStock.avgCostVnd`, builds the journal, then calls `postEntry`.
  - `JournalEntry.sourceType` is currently a `String` in Prisma; no source-type enum or allowlist is present today.
- `apps/api/src/sync/stock-ops.service.ts`
  - `processStocktake` calls `ledger.safePost(() => ledger.postFromStocktake(...), { sourceType: 'stocktake', ... })` after the transaction succeeds.
  - `processWastage` persists `WastageVoucher`, creates negative `StockMovement` rows, and currently returns `{ accepted: true }` immediately after the transaction.
- `apps/api/test/ledger-returns-stocktake.e2e-spec.ts`
  - Existing e2e pattern for stocktake journal and period lock blocking.

## Files for Task C.1

- Modify: `apps/api/src/ledger/journal-builders.ts`
- Modify: `apps/api/src/ledger/journal-builders.spec.ts`
- Modify: `apps/api/src/ledger/ledger.service.ts`
- Modify: `apps/api/src/sync/stock-ops.service.ts`
- Add: `apps/api/test/wastage-journal.e2e-spec.ts`
- Likely no Prisma migration:
  - `apps/api/prisma/schema.prisma` has `JournalEntry.sourceType String`.
  - Re-check this before coding; only extend a Prisma enum or allowlist if one has been added by another branch.

## TDD tasks

### Task 1: RED - builder unit tests

**Files:** `apps/api/src/ledger/journal-builders.spec.ts`

- [ ] Import the future `buildWastageJournal`.
- [ ] Add `buildWastageJournal posts wastage at WAC`:
  - Input lines:
    - `{ qty: 2, avgCostVnd: 8000 }`
    - `{ qty: 1.5, avgCostVnd: 10000 }`
    - `{ qty: 1, avgCostVnd: null }`
    - `{ qty: 1, avgCostVnd: 0 }`
  - Expected total: `round(2 * 8000) + round(1.5 * 10000) = 31000`.
  - Assert balanced with `assertBalanced`.
  - Assert Dr `642` = `31000`.
  - Assert Cr `156` = `31000`.
- [ ] Add `buildWastageJournal returns empty when no costed lines`:
  - Include `avgCostVnd: null`, `0`, and negative cost cases.
  - Expect `[]`.
- [ ] Add a rounding assertion:
  - Example: `{ qty: 0.333, avgCostVnd: 1000 }` posts `333`.
- [ ] Run only the unit spec and confirm it fails because the builder does not exist yet.

Suggested command:

```powershell
npm --workspace apps/api test -- journal-builders.spec.ts
```

### Task 2: GREEN - builder implementation

**Files:** `apps/api/src/ledger/journal-builders.ts`

- [ ] Add `buildWastageJournal(input: { lines: { qty: number; avgCostVnd: number | null }[] }): JournalLineDraft[]`.
- [ ] For each line, skip when `avgCostVnd == null || avgCostVnd <= 0`.
- [ ] Sum `Math.round(line.qty * line.avgCostVnd)` for costed lines.
- [ ] If total is `<= 0`, return `[]`.
- [ ] Otherwise push Dr `642` and Cr `156`, then `assertBalanced(out)`.
- [ ] Run the builder unit tests and confirm they pass.

### Task 3: RED - ledger service posting tests by e2e

**Files:** `apps/api/test/wastage-journal.e2e-spec.ts`

- [ ] Create a new e2e spec instead of extending `ledger-returns-stocktake.e2e-spec.ts`.
- [ ] Mirror setup from `ledger-returns-stocktake.e2e-spec.ts`:
  - Bootstrap `AppModule`.
  - `seedChartOfAccounts(prisma)`.
  - Login via `/auth/login` using dev seed credentials.
  - Resolve `storeId` from store code `CH1`.
  - Resolve `productId` from SKU `STING-330`.
- [ ] Clean rows for `sourceType: 'wastage'` before each test:
  - `journalLine` where `entry.sourceType = 'wastage'`.
  - `journalEntry` where `sourceType = 'wastage'`.
  - Relevant `periodLock` rows.
  - Relevant wastage rows for the chosen store if needed.
- [ ] Seed `productStoreStock` with enough stock and an `avgCostVnd`.
- [ ] Push a wastage voucher through `POST /sync/push` using the existing payload field `wastages`.
- [ ] Assert accepted response contains the voucher id in `acceptedWastageIds`.
- [ ] Assert one `journalEntry` exists by compound key:
  - `sourceType: 'wastage'`
  - `sourceId: wastageId`
- [ ] Assert lines:
  - Dr `642` equals `round(qty * avgCostVnd)`.
  - Cr `156` equals the same amount.
- [ ] Push the same payload again and assert journal remains idempotent with one entry.
- [ ] Run e2e and confirm it fails because no `postFromWastage` hook exists yet.

Suggested command:

```powershell
npm --workspace apps/api test:e2e -- wastage-journal.e2e-spec.ts
```

### Task 4: GREEN - `LedgerService.postFromWastage`

**Files:** `apps/api/src/ledger/ledger.service.ts`

- [ ] Import `buildWastageJournal`.
- [ ] Add `postFromWastage(wastageId: string, actorUserId?: string)`.
- [ ] Fetch `wastageVoucher.findUnique({ where: { id: wastageId }, include: { lines: true } })`.
- [ ] Return early if no voucher exists.
- [ ] For each line, fetch matching `productStoreStock` by `productId_storeId`.
- [ ] Build cost lines with:
  - `qty: Number(line.qty)`
  - `avgCostVnd: stock?.avgCostVnd ?? null`
- [ ] Call `buildWastageJournal({ lines: costLines })`.
- [ ] Call `postEntry` with:
  - `storeId: row.storeId`
  - `sourceType: 'wastage'`
  - `sourceId: row.id`
  - `postedAt: row.clientCreatedAt`
  - `memo: row.note ?? undefined`
  - `lines`
  - `actorUserId`
- [ ] Do not throw for empty journals; rely on `postEntry` returning `skipped_empty`.

### Task 5: GREEN - fail-soft sync hook

**Files:** `apps/api/src/sync/stock-ops.service.ts`

- [ ] After the `processWastage` transaction succeeds, before returning `{ accepted: true }`, add:

```ts
await this.ledger.safePost(
  () => this.ledger.postFromWastage(dto.id, user.userId),
  {
    sourceType: 'wastage',
    sourceId: dto.id,
    actorUserId: user.userId,
  },
);
```

- [ ] Keep the hook outside the transaction, same as stocktake.
- [ ] Preserve current behavior for invalid payload, insufficient stock, duplicate id, and transaction errors.
- [ ] Run the wastage e2e and confirm the posting/idempotency test passes.

### Task 6: RED/GREEN - period lock e2e

**Files:** `apps/api/test/wastage-journal.e2e-spec.ts`

- [ ] Add or complete a period-lock test in the same spec.
- [ ] Compute `periodYm` from `clientCreatedAt` using the same ICT logic as the stocktake e2e.
- [ ] Create the lock through `POST /ledger/period-locks`.
- [ ] Push a new wastage voucher in the locked period.
- [ ] Assert sync still accepts the persisted voucher because posting is fail-soft.
- [ ] Assert no `journalEntry` exists for `sourceType: 'wastage'` and the locked voucher id.
- [ ] Assert an `auditLog` row exists:
  - `action: 'journal_blocked_period_lock'`
  - `entityType: 'wastage'`
  - `entityId: blockedWastageId`
- [ ] Delete the period lock at the end of the test to avoid cross-test pollution.

### Task 7: no-cost e2e coverage

**Files:** `apps/api/test/wastage-journal.e2e-spec.ts`

- [ ] Add a small test or assertion for no-cost stock:
  - Set `avgCostVnd` to `0` or `null`.
  - Push wastage.
  - Assert accepted.
  - Assert no `journalEntry` is created for the voucher.
- [ ] This verifies the "empty journal if no costed lines" behavior through `postEntry`.

### Task 8: refactor and full verification

- [ ] Keep the builder small and parallel to `buildStocktakeJournal`; avoid new abstractions unless duplication becomes noisy.
- [ ] Confirm `sourceType: 'wastage'` needs no Prisma migration in the current schema.
- [ ] Run focused tests:

```powershell
npm --workspace apps/api test -- journal-builders.spec.ts
npm --workspace apps/api test:e2e -- wastage-journal.e2e-spec.ts
```

- [ ] If time permits, run the existing stocktake closeout e2e to ensure the mirrored path still passes:

```powershell
npm --workspace apps/api test:e2e -- ledger-returns-stocktake.e2e-spec.ts
```

- [ ] Commit Task C.1 with a message like `feat: post wastage journals at WAC`.

## E2E sketch

```ts
it('wastage posts Dr 642 Cr 156 and remains idempotent', async () => {
  await prisma.productStoreStock.upsert({
    where: { productId_storeId: { productId, storeId } },
    create: { productId, storeId, qty: 20, minQty: 0, avgCostVnd: 8000 },
    update: { qty: 20, avgCostVnd: 8000 },
  });

  const wastageId = randomUUID();
  const at = new Date();
  const push = () =>
    request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'wastage-journal',
        sales: [],
        wastages: [
          {
            id: wastageId,
            storeId,
            reasonCode: 'damage',
            clientCreatedAt: at.toISOString(),
            lines: [{ id: randomUUID(), productId, qty: '2' }],
          },
        ],
      })
      .expect(201);

  expect((await push()).body.acceptedWastageIds).toContain(wastageId);
  expect((await push()).body.acceptedWastageIds).toContain(wastageId);

  const journal = await prisma.journalEntry.findUnique({
    where: {
      sourceType_sourceId: {
        sourceType: 'wastage',
        sourceId: wastageId,
      },
    },
    include: { lines: true },
  });
  expect(journal).toBeTruthy();
  expect(journal!.lines.find((l) => l.accountCode === '642')?.debitVnd).toBe(16000);
  expect(journal!.lines.find((l) => l.accountCode === '156')?.creditVnd).toBe(16000);
});
```

## Definition of done for Task C.1

- [ ] Builder unit tests cover costed, uncosted, and rounding cases.
- [ ] `wastage-journal.e2e-spec.ts` covers posting, idempotency, period lock blocking, and empty no-cost journal behavior.
- [ ] Wastage sync persists successfully even when ledger posting is blocked or fails.
- [ ] No stock transfer journal code is included.
- [ ] Focused tests pass.
