# Cash Vouchers + Shift Reconciliation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete Phase 1 remaining #2 — offline cash in/out vouchers with seeded categories, shift-close cash reconciliation (expected vs counted), and a per-shift/store thu chi ledger.

**Architecture:** Mirror the debt-payment outbox pattern. Add `CashCategory` (seed) + `CashVoucher` on Postgres/Drift; push via outbox `cash_voucher`; pull categories + vouchers. On shift close, server recomputes `expectedCashVnd`, `varianceVnd`, `transferInShiftVnd` from sales + debt payments + vouchers (never trust client snapshots). Hybrid UI: POS app-bar actions for Thu chi (ledger + create) and Đóng ca (breakdown sheet).

**Tech Stack:** NestJS 10, Prisma 6, PostgreSQL; Flutter + Drift; Jest e2e; Flutter tests.

**Spec:** `docs/superpowers/specs/2026-07-24-cash-vouchers-shift-reconciliation-design.md`

## Global Constraints

- Offline-first: never block creating vouchers or closing a shift on network failure.
- Money is integer VND (no floats).
- Server is source of truth after sync; local may diverge until pull.
- Do not implement edit/delete vouchers, category CRUD, or blocking close on variance.
- Reject reasons (exact strings): `shift_not_open`, `category_direction_mismatch`, `invalid_amount`, `invalid_voucher`, `store_forbidden`.
- Outbox entity types: existing + `cash_voucher` (extend `shift_close` payload).
- Navigation: no new bottom-nav shell — add POS `AppBar` actions (same pattern as Khách nợ / Hàng hóa).

---

## File structure

```text
apps/api/
  prisma/schema.prisma
  prisma/seed.ts
  prisma/migrations/<ts>_cash_vouchers/
  src/cash/expected-cash.ts                    # pure formula
  src/cash/expected-cash.spec.ts               # unit
  src/shifts/shifts.service.ts                 # recompute on close
  src/sync/dto/push-sale.dto.ts                # + cashVouchers; extend shift close
  src/sync/sync.service.ts                     # push/pull vouchers + categories
  test/cash-vouchers.e2e-spec.ts
  test/shifts.e2e-spec.ts                      # extend close snapshot asserts

apps/pos_app/
  lib/data/local/tables.dart                   # CashCategories, CashVouchers; Shift cols
  lib/data/local/database.dart                 # schemaVersion 4
  lib/features/cash/expected_cash.dart         # pure formula + breakdown
  lib/features/cash/cash_voucher_service.dart
  lib/features/cash/cash_ledger_page.dart
  lib/features/cash/record_cash_voucher_sheet.dart
  lib/features/cash/close_shift_page.dart
  lib/features/shifts/shift_repository.dart    # closeShift snapshot fields
  lib/features/pos/pos_page.dart               # Thu chi + Đóng ca actions
  lib/data/sync/outbox_worker.dart
  lib/data/sync/pull_catalog.dart
  test/expected_cash_test.dart
  test/cash_voucher_service_test.dart

docs/
  superpowers/plans/2026-07-23-phase1-remaining.md  # tick #2 items
  CHANGELOG-vi.md
```

**Stable seed category IDs** (must match seed + Flutter tests):

| id | code | name | direction | sortOrder |
|---|---|---|---|---|
| `a1000000-0000-4000-8000-000000000001` | `other_in` | Thu khác | `in` | 10 |
| `a1000000-0000-4000-8000-000000000002` | `electricity` | Điện | `out` | 20 |
| `a1000000-0000-4000-8000-000000000003` | `rent` | Thuê mặt bằng | `out` | 30 |
| `a1000000-0000-4000-8000-000000000004` | `salary_advance` | Ứng lương | `out` | 40 |
| `a1000000-0000-4000-8000-000000000005` | `other_out` | Chi khác | `out` | 50 |

---

### Task 1: Prisma — CashCategory, CashVoucher, Shift snapshots + seed

**Files:**
- Modify: `apps/api/prisma/schema.prisma`
- Modify: `apps/api/prisma/seed.ts`
- Create: migration via `npx prisma migrate dev --name cash_vouchers`
- Test: migration applies; seed lists 5 categories (`npx prisma db seed`)

**Interfaces:**
- Consumes: existing `Store`, `Shift`, `User`
- Produces: enums `CashDirection`, `CashChannel`; models `CashCategory`, `CashVoucher`; `Shift.expectedCashVnd`, `varianceVnd`, `transferInShiftVnd`; relation `Shift.cashVouchers`

- [ ] **Step 1: Extend Prisma schema**

Add enums and models; update `Store`, `User`, `Shift`:

```prisma
enum CashDirection {
  in
  out
}

enum CashChannel {
  cash
  transfer
}

model CashCategory {
  id        String        @id @default(uuid())
  code      String        @unique
  name      String
  direction CashDirection
  sortOrder Int           @default(0)
  vouchers  CashVoucher[]
}

model CashVoucher {
  id              String        @id @default(uuid())
  storeId         String
  shiftId         String
  categoryId      String
  direction       CashDirection
  channel         CashChannel
  amountVnd       Int
  note            String?
  recordedById    String
  clientCreatedAt DateTime
  createdAt       DateTime      @default(now())
  updatedAt       DateTime      @updatedAt
  store           Store         @relation(fields: [storeId], references: [id])
  shift           Shift         @relation(fields: [shiftId], references: [id])
  category        CashCategory  @relation(fields: [categoryId], references: [id])
  recordedBy      User          @relation(fields: [recordedById], references: [id])
  @@index([storeId, clientCreatedAt])
  @@index([shiftId, clientCreatedAt])
}
```

On `Shift` add:

```prisma
  expectedCashVnd     Int?
  varianceVnd         Int?
  transferInShiftVnd  Int?
  cashVouchers        CashVoucher[]
```

On `Store` / `User` add `cashVouchers CashVoucher[]`.

- [ ] **Step 2: Migrate**

Run: `cd apps/api && npx prisma migrate dev --name cash_vouchers`  
Expected: migration created and applied; client generated.

- [ ] **Step 3: Seed categories**

In `seed.ts`, after stores, upsert the five categories with the stable IDs in the table above (`prisma.cashCategory.upsert({ where: { id }, ... })` or `where: { code }`).

Run: `npx prisma db seed`  
Expected: no error; DB has 5 rows in `CashCategory`.

- [ ] **Step 4: Commit**

```bash
git add apps/api/prisma
git commit -m "feat(api): schema and seed for cash vouchers"
```

---

### Task 2: Pure expected-cash formula (server) + unit tests

**Files:**
- Create: `apps/api/src/cash/expected-cash.ts`
- Create: `apps/api/src/cash/expected-cash.spec.ts`

**Interfaces:**
- Consumes: plain number inputs (no Prisma)
- Produces:

```ts
export type ShiftCashInputs = {
  openingCash: number;
  saleCashTotal: number;
  saleTransferTotal: number;
  debtPaymentCashTotal: number;
  debtPaymentTransferTotal: number;
  voucherCashInTotal: number;
  voucherCashOutTotal: number;
  voucherTransferInTotal: number;
  voucherTransferOutTotal: number;
};

export type ShiftCashSnapshot = {
  expectedCashVnd: number;
  transferInShiftVnd: number;
  varianceVnd: number; // closingCash - expected
};

export function computeShiftCashSnapshot(
  inputs: ShiftCashInputs,
  closingCash: number,
): ShiftCashSnapshot;
```

- [ ] **Step 1: Write failing unit tests**

```ts
import { computeShiftCashSnapshot } from './expected-cash';

describe('computeShiftCashSnapshot', () => {
  it('matches spec formula', () => {
    const snap = computeShiftCashSnapshot(
      {
        openingCash: 500_000,
        saleCashTotal: 900_000,
        saleTransferTotal: 300_000,
        debtPaymentCashTotal: 100_000,
        debtPaymentTransferTotal: 50_000,
        voucherCashInTotal: 50_000,
        voucherCashOutTotal: 300_000,
        voucherTransferInTotal: 30_000,
        voucherTransferOutTotal: 0,
      },
      1_230_000,
    );
    expect(snap.expectedCashVnd).toBe(1_250_000);
    expect(snap.transferInShiftVnd).toBe(380_000);
    expect(snap.varianceVnd).toBe(-20_000);
  });

  it('ignores debt sale amounts (not in inputs)', () => {
    const snap = computeShiftCashSnapshot(
      {
        openingCash: 100,
        saleCashTotal: 0,
        saleTransferTotal: 0,
        debtPaymentCashTotal: 0,
        debtPaymentTransferTotal: 0,
        voucherCashInTotal: 0,
        voucherCashOutTotal: 0,
        voucherTransferInTotal: 0,
        voucherTransferOutTotal: 0,
      },
      100,
    );
    expect(snap.expectedCashVnd).toBe(100);
    expect(snap.varianceVnd).toBe(0);
  });
});
```

- [ ] **Step 2: Run tests — expect FAIL**

Run: `cd apps/api && npx jest src/cash/expected-cash.spec.ts`  
Expected: FAIL (module not found).

- [ ] **Step 3: Implement**

```ts
export function computeShiftCashSnapshot(
  inputs: ShiftCashInputs,
  closingCash: number,
): ShiftCashSnapshot {
  const expectedCashVnd =
    inputs.openingCash +
    inputs.saleCashTotal +
    inputs.debtPaymentCashTotal +
    inputs.voucherCashInTotal -
    inputs.voucherCashOutTotal;
  const transferInShiftVnd =
    inputs.saleTransferTotal +
    inputs.debtPaymentTransferTotal +
    inputs.voucherTransferInTotal -
    inputs.voucherTransferOutTotal;
  return {
    expectedCashVnd,
    transferInShiftVnd,
    varianceVnd: closingCash - expectedCashVnd,
  };
}
```

- [ ] **Step 4: Run tests — expect PASS**

Run: `cd apps/api && npx jest src/cash/expected-cash.spec.ts`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/api/src/cash
git commit -m "feat(api): expected cash formula for shift close"
```

---

### Task 3: Server — push/pull cash vouchers + recompute on shift close

**Files:**
- Modify: `apps/api/src/sync/dto/push-sale.dto.ts`
- Modify: `apps/api/src/sync/sync.service.ts`
- Modify: `apps/api/src/shifts/shifts.service.ts`
- Create: `apps/api/test/cash-vouchers.e2e-spec.ts`
- Modify: `apps/api/test/shifts.e2e-spec.ts` (assert snapshot fields on close)

**Interfaces:**
- Consumes: `computeShiftCashSnapshot`; Prisma models from Task 1
- Produces:
  - `PushCashVoucherDto`; `PushSyncDto.cashVouchers?: PushCashVoucherDto[]`
  - `PushShiftCloseDto` may include optional client snapshot fields (ignored for truth)
  - pull adds `cashCategories`, `cashVouchers`
  - push returns `acceptedCashVoucherIds`, `rejectedCashVouchers: { id, reason }[]`
  - `ShiftsService.close` / `closeFromSync` load aggregates and set snapshot columns

- [ ] **Step 1: Extend DTOs**

```ts
export type PushCashVoucherDto = {
  id: string;
  storeId: string;
  shiftId: string;
  categoryId: string;
  direction: 'in' | 'out';
  channel: 'cash' | 'transfer';
  amountVnd: number;
  note?: string | null;
  recordedById?: string;
  clientCreatedAt: string;
};

// PushShiftCloseDto — keep closingCash, note, closedAt; optional client hints ignored:
// expectedCashVnd?, varianceVnd?, transferInShiftVnd?

// PushSyncDto += cashVouchers?: PushCashVoucherDto[];
```

- [ ] **Step 2: Write failing e2e (scaffold in `cash-vouchers.e2e-spec.ts`)**

Cover:
1. Push voucher twice → one row; second accepted (idempotent).
2. Push with wrong category direction → `category_direction_mismatch`.
3. Push with no open shift (closed shift id) → `shift_not_open`.
4. After sales + cash debt payment + vouchers, close shift → `expectedCashVnd` / `varianceVnd` / `transferInShiftVnd` match formula.
5. Pull returns seeded categories and pushed vouchers.

Follow existing e2e helpers in `test/debt-payments.e2e-spec.ts` (login, open shift, push).

- [ ] **Step 3: Run e2e — expect FAIL**

Run: `cd apps/api && npm run test:e2e -- --testPathPattern=cash-vouchers`  
Expected: FAIL.

- [ ] **Step 4: Implement `ShiftsService` recompute helper**

Before update in `close` / reuse from sync:

1. Load shift (must be open).
2. Aggregate:
   - `saleCashTotal` / `saleTransferTotal` from `Sale` where `shiftId`
   - debt payments: `DebtLedgerEntry` where `shiftId` and `type = payment`, split by `paymentMethod`
   - vouchers: `CashVoucher` where `shiftId`, split by direction+channel
3. `const snap = computeShiftCashSnapshot(..., dto.closingCash)`
4. Update shift with `closingCash`, `note`, `closedAt`, `expectedCashVnd`, `varianceVnd`, `transferInShiftVnd`

- [ ] **Step 5: Implement sync push/pull vouchers**

`processCashVoucher`:
- validate id, store access, amount > 0, direction/channel enums, parse dates
- load category; if missing → `invalid_voucher`; if `category.direction !== dto.direction` → `category_direction_mismatch`
- load shift; if missing or `closedAt != null` or `shift.storeId !== dto.storeId` → `shift_not_open`
- if exists by id → accept (idempotent return)
- else create row with `recordedById: dto.recordedById ?? user.userId`

Pull: include all `CashCategory` ordered by `sortOrder`; `CashVoucher` where `storeId` and `updatedAt > since`.

Process cash vouchers **before** shift closes in `push()` (so close aggregates include them).

- [ ] **Step 6: Run e2e — expect PASS**

Run: `cd apps/api && npm run test:e2e -- --testPathPattern='cash-vouchers|shifts'`  
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add apps/api/src apps/api/test
git commit -m "feat(api): sync cash vouchers and shift close snapshots"
```

---

### Task 4: Drift schema v4 — categories, vouchers, shift snapshot columns

**Files:**
- Modify: `apps/pos_app/lib/data/local/tables.dart`
- Modify: `apps/pos_app/lib/data/local/database.dart` (`schemaVersion => 4`, migration, upsert helpers)
- Run: `cd apps/pos_app && dart run build_runner build --delete-conflicting-outputs`

**Interfaces:**
- Produces: tables `CashCategoriesLocal`, `CashVouchersLocal`; `ShiftsLocal` + `expectedCashVnd`, `varianceVnd`, `transferInShiftVnd` (nullable ints)
- Helpers: `upsertCashCategory`, `upsertCashVoucher` (by id)

- [ ] **Step 1: Add tables**

```dart
class CashCategoriesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn get direction => text()(); // in | out
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class CashVouchersLocal extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  TextColumn get shiftId => text()();
  TextColumn get categoryId => text()();
  TextColumn get direction => text()();
  TextColumn get channel => text()(); // cash | transfer
  IntColumn get amountVnd => integer()();
  TextColumn get note => text().nullable()();
  TextColumn get recordedById => text()();
  DateTimeColumn get clientCreatedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

Extend `ShiftsLocal` with nullable `expectedCashVnd`, `varianceVnd`, `transferInShiftVnd`.

Register tables on `AppDatabase`; bump `schemaVersion` to 4; in `onUpgrade` from 3→4 create tables + alter shifts (Drift `Migrator.addColumn`).

- [ ] **Step 2: Codegen**

Run: `cd apps/pos_app && dart run build_runner build --delete-conflicting-outputs`  
Expected: `database.g.dart` updated.

- [ ] **Step 3: Commit**

```bash
git add apps/pos_app/lib/data/local
git commit -m "feat(pos): drift schema v4 for cash vouchers"
```

---

### Task 5: Flutter expected-cash formula + CashVoucherService + outbox/pull

**Files:**
- Create: `apps/pos_app/lib/features/cash/expected_cash.dart`
- Create: `apps/pos_app/test/expected_cash_test.dart`
- Create: `apps/pos_app/lib/features/cash/cash_voucher_service.dart`
- Create: `apps/pos_app/test/cash_voucher_service_test.dart`
- Modify: `apps/pos_app/lib/features/shifts/shift_repository.dart` (`closeShift` writes snapshot cols + outbox payload)
- Modify: `apps/pos_app/lib/data/sync/outbox_worker.dart`
- Modify: `apps/pos_app/lib/data/sync/pull_catalog.dart`

**Interfaces:**
- Produces:

```dart
class ShiftCashBreakdown {
  final int openingCash;
  final int saleCash;
  final int debtPaymentCash;
  final int voucherCashIn;
  final int voucherCashOut;
  final int expectedCash;
  final int saleTransfer;
  final int debtPaymentTransfer;
  final int voucherTransferIn;
  final int voucherTransferOut;
  final int transferInShift;
  int variance(int closingCash) => closingCash - expectedCash;
}

ShiftCashBreakdown computeBreakdown({...totals...});

class CashVoucherService {
  Future<String> recordVoucher({
    required String direction, // in|out
    required String categoryId,
    required String channel, // cash|transfer
    required int amountVnd,
    String? note,
  });
}
```

- [ ] **Step 1: Failing formula test** — same numbers as server (1_250_000 / 380_000 / −20_000)

- [ ] **Step 2: Implement `expected_cash.dart`** — mirror server math; expose breakdown fields for UI

- [ ] **Step 3: Failing `CashVoucherService` test**

Using in-memory Drift (same pattern as `debt_payment_test.dart`):
- seed open shift + one category
- `recordVoucher` inserts voucher + outbox `cash_voucher`
- fails with no open shift
- fails when `amountVnd <= 0`

- [ ] **Step 4: Implement service** — require open shift; validate channel/direction; insert voucher + outbox payload matching `PushCashVoucherDto`

- [ ] **Step 5: Extend `closeShift`**

```dart
Future<void> closeShift({
  required String shiftId,
  required int closingCash,
  required int expectedCashVnd,
  required int varianceVnd,
  required int transferInShiftVnd,
  String? note,
}) async { /* write all fields + outbox shift_close with same keys */ }
```

Add helper on repository or service: `Future<ShiftCashBreakdown> breakdownForOpenShift(...)` querying local sales, debt_ledger payments, cash_vouchers for shift.

- [ ] **Step 6: Outbox worker** — batch `cash_voucher` into push body; mark done using `acceptedCashVoucherIds`; handle `rejectedCashVouchers` like debt rejects

- [ ] **Step 7: Pull catalog** — upsert `cashCategories` + `cashVouchers` from pull JSON

- [ ] **Step 8: Run Flutter tests**

Run: `cd apps/pos_app && flutter test test/expected_cash_test.dart test/cash_voucher_service_test.dart`  
Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add apps/pos_app/lib apps/pos_app/test
git commit -m "feat(pos): cash voucher service and expected cash"
```

---

### Task 6: UI — sổ thu chi, sheet tạo phiếu, đóng ca breakdown

**Files:**
- Create: `apps/pos_app/lib/features/cash/cash_ledger_page.dart`
- Create: `apps/pos_app/lib/features/cash/record_cash_voucher_sheet.dart`
- Create: `apps/pos_app/lib/features/cash/close_shift_page.dart`
- Modify: `apps/pos_app/lib/features/pos/pos_page.dart` (+ wire deps from `main.dart` / open-shift navigation)
- Modify: `apps/pos_app/lib/main.dart` (or wherever `PosPage` is constructed) to pass `CashVoucherService` / repos

**Interfaces:**
- Consumes: `CashVoucherService`, `ShiftRepository`, `AppDatabase`, breakdown helper
- Produces: navigable pages from POS app bar

- [ ] **Step 1: `CashLedgerPage`**

- Stream/list vouchers for current open shift (join category name)
- FAB / buttons: Phiếu thu → sheet `direction=in`; Phiếu chi → `direction=out`
- Empty state text when none
- Show channel + amount formatted VND

- [ ] **Step 2: `RecordCashVoucherSheet`**

- Dropdown categories filtered by direction
- Toggle cash / transfer
- Amount + optional note
- On confirm: call service; pop; snackbar on error (`Không có ca đang mở`, etc.)

- [ ] **Step 3: `CloseShiftPage`**

- Load breakdown for current open shift
- Show lines: Mở ca, Bán TM, Thu nợ TM, Phiếu thu TM, Phiếu chi TM, **Kỳ vọng**, **CK trong ca**
- TextField closing cash → live variance
- Optional note
- Confirm → `closeShift(...)` with computed snapshot → pop to login/open-shift flow (same as product expectation: cannot sell without open shift — navigate back to `OpenShiftPage` or clear shift UI)

- [ ] **Step 4: POS app bar**

Add icons:
- `Icons.account_balance_wallet_outlined` → `CashLedgerPage` (tooltip `Thu chi`)
- `Icons.lock_clock_outlined` → `CloseShiftPage` (tooltip `Đóng ca`)

- [ ] **Step 5: Manual smoke** (document in commit body)

1. Open shift → create chi TM → appears in ledger  
2. Close shift with wrong count → variance shown; close succeeds  
3. Sync → server shift snapshot matches  

- [ ] **Step 6: Commit**

```bash
git add apps/pos_app
git commit -m "feat(pos): thu chi ledger and close-shift reconciliation UI"
```

---

### Task 7: Docs — tick remaining #2 + CHANGELOG

**Files:**
- Modify: `docs/superpowers/plans/2026-07-23-phase1-remaining.md`
- Modify: `docs/CHANGELOG-vi.md`
- Modify: `README.md` if API surface table should list nothing new (sync-only) — optional note under Phase 1

- [ ] **Step 1: Tick checklist**

Under Cash management:

```markdown
- [x] Cash in/out vouchers with categories
- [x] Shift close reconciliation vs expected cash
- [x] Basic thu chi ledger tied to shift/store
```

Update suggested order item 2 as done (`feat/cash-vouchers-shift-reconciliation` or main).

- [ ] **Step 2: CHANGELOG**

Add section: phiếu thu/chi offline, sổ ca, đóng ca đối chiếu TM + hiển thị CK; remove “Thu chi quỹ” from “cố ý chưa làm” or mark done.

- [ ] **Step 3: Commit**

```bash
git add docs README.md
git commit -m "docs: mark cash vouchers remaining #2 complete"
```

---

## Spec coverage (self-review)

| Spec requirement | Task |
|---|---|
| CashCategory seed, no CRUD | 1 |
| CashVoucher model + outbox | 1, 3, 5 |
| Shift expected/variance/transfer snapshots; server recompute | 2, 3, 5 |
| Formula (cash vs transfer split; debtAmount excluded) | 2, 5 |
| Reject shift_not_open / category_direction_mismatch | 3, 5 |
| Idempotent voucher push | 3 |
| Pull categories + vouchers | 3, 5 |
| Hybrid UI: ledger tab-like + close from POS | 6 |
| Close UI with breakdown | 6 |
| Allow close with variance + note | 3, 6 |
| e2e + Flutter tests | 2, 3, 5 |
| Docs tick remaining #2 | 7 |

**Out of scope (intentionally no task):** edit/delete voucher, category CRUD, block on variance, bank ledger GĐ2.

---

## Execution notes

- Prefer feature branch `feat/cash-vouchers-shift-reconciliation`.
- Process `cashVouchers` in sync **before** `shiftCloses`.
- Prisma enum value `in` / `out` is intentional; map to strings `'in'` / `'out'` on Flutter.
