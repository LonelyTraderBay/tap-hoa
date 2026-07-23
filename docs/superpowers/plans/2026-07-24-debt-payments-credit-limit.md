# Debt Payments + Credit Limit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete Phase 1 customer debt: offline debt payments with ledger history, and credit-limit enforcement at checkout (local + server).

**Architecture:** Extend the existing local-first outbox pattern. Add `DebtLedgerEntry` on Postgres and Drift; debt sales write `sale_debt` rows; payments write `payment` rows via outbox type `debt_payment`. Pull sync returns `customers` + `debtLedger`. Credit limit lives on `Customer.creditLimitVnd` (`null` = unlimited).

**Tech Stack:** NestJS 10, Prisma 6, PostgreSQL; Flutter + Drift; Jest e2e; Flutter tests.

**Spec:** `docs/superpowers/specs/2026-07-24-debt-payments-credit-limit-design.md`

## Global Constraints

- Offline-first: never block thu nợ or checkout on network failure.
- Money is integer VND (no floats).
- Server is source of truth after sync; local may diverge until pull.
- Do not implement aging, reverse payments, or edit/delete of synced payments.
- Reject reasons (exact strings): `credit_limit_exceeded`, `payment_exceeds_balance`.
- Outbox entity types used: `sale`, `debt_payment`, `customer_upsert` (plus existing shift types).

---

## File structure

```text
apps/api/
  prisma/schema.prisma                          # + creditLimitVnd, DebtLedgerEntry, enums
  prisma/migrations/<ts>_debt_ledger/
  src/sync/dto/push-sale.dto.ts                 # + debtPayments, customerUpserts
  src/sync/sync.service.ts                      # sale_debt, payments, pull, credit check
  src/customers/dto/create-customer.dto.ts      # + creditLimitVnd
  src/customers/customers.service.ts            # upsert/list creditLimitVnd
  test/debt-payments.e2e-spec.ts                # new e2e
  test/customers-debt.e2e-spec.ts               # extend credit limit cases

apps/pos_app/
  lib/data/local/tables.dart                    # + creditLimitVnd, DebtLedgerLocal
  lib/data/local/database.dart                  # schemaVersion 3, upsert helpers
  lib/features/customers/credit_limit.dart      # pure exceedsCreditLimit()
  lib/features/customers/debt_payment_service.dart
  lib/features/customers/customer_repository.dart
  lib/features/customers/customer_detail_page.dart
  lib/features/customers/record_debt_payment_sheet.dart
  lib/features/customers/debt_customer_list_page.dart
  lib/features/pos/checkout_service.dart        # sale_debt + credit check
  lib/features/pos/payment_sheet.dart           # UI credit block
  lib/data/sync/outbox_worker.dart              # debt_payment + customer_upsert
  lib/data/sync/pull_catalog.dart               # customers + debtLedger
  test/credit_limit_test.dart
  test/debt_payment_test.dart
```

---

### Task 1: Prisma — creditLimit + DebtLedgerEntry

**Files:**
- Modify: `apps/api/prisma/schema.prisma`
- Create: `apps/api/prisma/migrations/<timestamp>_debt_ledger/migration.sql` (via `prisma migrate`)
- Test: `apps/api/test/debt-payments.e2e-spec.ts` (scaffold only; first real assert in Task 2)

**Interfaces:**
- Consumes: existing `Customer`, `Store`, `Sale`, `User`
- Produces: `Customer.creditLimitVnd: Int?`; model `DebtLedgerEntry`; enums `DebtLedgerType`, `DebtPaymentChannel`

- [ ] **Step 1: Extend Prisma schema**

Add enums and update models (keep existing Customer fields; add relations on Store/User/Sale/Customer):

```prisma
enum DebtLedgerType {
  sale_debt
  payment
}

enum DebtPaymentChannel {
  cash
  transfer
}

model Customer {
  id              String            @id @default(uuid())
  storeId         String
  name            String
  phone           String?
  balanceVnd      Int               @default(0)
  creditLimitVnd  Int?
  updatedAt       DateTime          @updatedAt
  createdAt       DateTime          @default(now())
  store           Store             @relation(fields: [storeId], references: [id])
  sales           Sale[]
  debtLedger      DebtLedgerEntry[]
  @@index([storeId])
}

model DebtLedgerEntry {
  id              String               @id @default(uuid())
  storeId         String
  customerId      String
  type            DebtLedgerType
  amountVnd       Int
  balanceAfterVnd Int
  saleId          String?              @unique
  shiftId         String?
  recordedById    String
  paymentMethod   DebtPaymentChannel?
  note            String?
  clientCreatedAt DateTime
  createdAt       DateTime             @default(now())
  updatedAt       DateTime             @updatedAt
  store           Store                @relation(fields: [storeId], references: [id])
  customer        Customer             @relation(fields: [customerId], references: [id])
  sale            Sale?                @relation(fields: [saleId], references: [id])
  recordedBy      User                 @relation(fields: [recordedById], references: [id])
  @@index([storeId, clientCreatedAt])
  @@index([customerId, clientCreatedAt])
}
```

Also add `debtLedger DebtLedgerEntry[]` on `Store`, `User`, and `Sale`.

- [ ] **Step 2: Migrate**

Run from `apps/api`:

```bash
npx prisma migrate dev --name debt_ledger
npx prisma generate
```

Expected: migration applied; client regenerated.

- [ ] **Step 3: Commit**

```bash
git add apps/api/prisma
git commit -m "feat(api): add debt ledger schema and customer credit limit"
```

---

### Task 2: Server — sale_debt ledger + credit_limit_exceeded

**Files:**
- Modify: `apps/api/src/sync/sync.service.ts` (inside debt sale apply transaction)
- Modify: `apps/api/src/customers/customers.service.ts` (select/return `creditLimitVnd`)
- Modify: `apps/api/src/customers/dto/create-customer.dto.ts`
- Create: `apps/api/test/debt-payments.e2e-spec.ts`
- Modify: `apps/api/test/customers-debt.e2e-spec.ts` (optional credit case)

**Interfaces:**
- Consumes: `PushSaleDto` with `debtAmount`, `customerId`
- Produces: on accepted debt sale, one `DebtLedgerEntry` with `type: sale_debt`, `saleId = sale.id`, `amountVnd = debtAmount`; reject reason `credit_limit_exceeded`

- [ ] **Step 1: Write failing e2e — ledger row + credit reject**

In `apps/api/test/debt-payments.e2e-spec.ts`, mirror setup from `customers-debt.e2e-spec.ts` (`loginAsOwner`, open shift, seed STING-330). Add:

```typescript
it('push debt sale writes sale_debt ledger and rejects over credit limit', async () => {
  const login = await loginAsOwner(app);
  const stores = await request(app.getHttpServer())
    .get('/stores')
    .set('Authorization', `Bearer ${login.accessToken}`);
  const storeId = stores.body[0].id as string;
  const product = await prisma.product.findUnique({ where: { sku: 'STING-330' } });
  if (!product) throw new Error('missing seed product');

  const customerId = randomUUID();
  await request(app.getHttpServer())
    .post('/customers')
    .set('Authorization', `Bearer ${login.accessToken}`)
    .send({
      id: customerId,
      storeId,
      name: 'Limit Anh',
      creditLimitVnd: 15000,
    })
    .expect(201);

  const shiftId = randomUUID();
  await request(app.getHttpServer())
    .post('/shifts/open')
    .set('Authorization', `Bearer ${login.accessToken}`)
    .send({ storeId, openingCash: 500000, clientId: shiftId })
    .expect(201);

  const okSaleId = randomUUID();
  const okSale = {
    id: okSaleId,
    storeId,
    shiftId,
    soldById: login.user.id,
    paymentMethod: 'debt',
    cashAmount: 0,
    transferAmount: 0,
    debtAmount: 10000,
    discountVnd: 0,
    totalVnd: 10000,
    customerId,
    clientCreatedAt: new Date().toISOString(),
    lines: [
      {
        productId: product.id,
        qty: '1',
        unitPrice: 10000,
        lineTotal: 10000,
      },
    ],
  };

  await request(app.getHttpServer())
    .post('/sync/push')
    .set('Authorization', `Bearer ${login.accessToken}`)
    .send({ deviceId: 'dev-ledger', sales: [okSale] })
    .expect(201)
    .expect((res) => {
      expect(res.body.acceptedIds).toContain(okSaleId);
    });

  const ledger = await prisma.debtLedgerEntry.findFirst({
    where: { saleId: okSaleId },
  });
  expect(ledger?.type).toBe('sale_debt');
  expect(ledger?.amountVnd).toBe(10000);
  expect(ledger?.balanceAfterVnd).toBe(10000);

  const overSaleId = randomUUID();
  const overSale = {
    ...okSale,
    id: overSaleId,
    debtAmount: 10000,
    totalVnd: 10000,
    clientCreatedAt: new Date().toISOString(),
  };
  await request(app.getHttpServer())
    .post('/sync/push')
    .set('Authorization', `Bearer ${login.accessToken}`)
    .send({ deviceId: 'dev-ledger', sales: [overSale] })
    .expect(201)
    .expect((res) => {
      expect(res.body.rejected).toEqual(
        expect.arrayContaining([
          { id: overSaleId, reason: 'credit_limit_exceeded' },
        ]),
      );
    });
});
```

Also extend `CreateCustomerDto` usage: POST body may include `creditLimitVnd` (implement in Step 3).

- [ ] **Step 2: Run e2e — expect fail**

```bash
cd apps/api && npm run test:e2e -- --testPathPattern=debt-payments
```

Expected: FAIL (no `DebtLedgerEntry` / credit check / DTO field).

- [ ] **Step 3: Implement customer creditLimit upsert + list select**

`CreateCustomerDto`:

```typescript
export type CreateCustomerDto = {
  id?: string;
  storeId: string;
  name: string;
  phone?: string | null;
  creditLimitVnd?: number | null;
};
```

In `customers.service.ts` `create` / `list` `select` and upsert `create`/`update`, include `creditLimitVnd`. On update, set `creditLimitVnd: dto.creditLimitVnd === undefined ? undefined : dto.creditLimitVnd` (allow explicit `null` to clear).

- [ ] **Step 4: Implement credit check + sale_debt write in `sync.service.ts`**

After loading customer for debt sales (existing block ~201–213), add:

```typescript
if (
  customer.creditLimitVnd != null &&
  customer.balanceVnd + sale.debtAmount > customer.creditLimitVnd
) {
  return { accepted: false, reason: 'credit_limit_exceeded' };
}
```

Inside the same transaction that increments balance, after `customer.update` increment:

```typescript
const updated = await tx.customer.findUniqueOrThrow({
  where: { id: sale.customerId },
});
await tx.debtLedgerEntry.create({
  data: {
    id: randomUUID(),
    storeId: sale.storeId,
    customerId: sale.customerId,
    type: 'sale_debt',
    amountVnd: sale.debtAmount,
    balanceAfterVnd: updated.balanceVnd,
    saleId: sale.id,
    shiftId: sale.shiftId,
    recordedById: user.userId,
    clientCreatedAt,
  },
});
```

On P2002 for duplicate sale, still return `{ accepted: true }` (existing race handling). If ledger unique on `saleId` races, treat as accepted when sale exists.

- [ ] **Step 5: Re-run e2e**

```bash
cd apps/api && npm run test:e2e -- --testPathPattern=debt-payments
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add apps/api/src apps/api/test
git commit -m "feat(api): write sale_debt ledger and enforce credit limit"
```

---

### Task 3: Server — push debt payments + pull customers/ledger

**Files:**
- Modify: `apps/api/src/sync/dto/push-sale.dto.ts`
- Modify: `apps/api/src/sync/sync.service.ts`
- Modify: `apps/api/src/sync/sync.controller.ts` (only if validation needs `debtPayments` array default)
- Modify: `apps/api/test/debt-payments.e2e-spec.ts`

**Interfaces:**
- Consumes:

```typescript
export type PushDebtPaymentDto = {
  id: string;
  storeId: string;
  customerId: string;
  amountVnd: number;
  paymentMethod: 'cash' | 'transfer';
  note?: string | null;
  shiftId?: string | null;
  clientCreatedAt: string;
  recordedById?: string;
};

export type PushCustomerUpsertDto = {
  id: string;
  storeId: string;
  name: string;
  phone?: string | null;
  creditLimitVnd?: number | null;
};

export type PushSyncDto = {
  deviceId: string;
  shiftOpens?: PushShiftOpenDto[];
  shiftCloses?: PushShiftCloseDto[];
  sales: PushSaleDto[];
  debtPayments?: PushDebtPaymentDto[];
  customerUpserts?: PushCustomerUpsertDto[];
};
```

- Produces: push response fields `acceptedDebtPaymentIds: string[]`, `rejectedDebtPayments: { id: string; reason: string }[]`, `acceptedCustomerUpsertIds: string[]`; pull adds `customers` and `debtLedger` arrays.

- [ ] **Step 1: Failing e2e — payment idempotent + exceeds balance + pull**

Append to `debt-payments.e2e-spec.ts`:

```typescript
it('push debt payment is idempotent and rejects over balance; pull returns ledger', async () => {
  // setup: customer with balanceVnd 20000 (create + sale_debt 20000 OR direct prisma update)
  // ...
  const paymentId = randomUUID();
  const payment = {
    id: paymentId,
    storeId,
    customerId,
    amountVnd: 5000,
    paymentMethod: 'cash',
    note: 'tra mot phan',
    shiftId,
    clientCreatedAt: new Date().toISOString(),
  };

  const pushOnce = () =>
    request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${login.accessToken}`)
      .send({ deviceId: 'dev-pay', sales: [], debtPayments: [payment] })
      .expect(201);

  const first = await pushOnce();
  expect(first.body.acceptedDebtPaymentIds).toContain(paymentId);
  const second = await pushOnce();
  expect(second.body.acceptedDebtPaymentIds).toContain(paymentId);

  const customer = await prisma.customer.findUnique({ where: { id: customerId } });
  expect(customer?.balanceVnd).toBe(15000);

  const overId = randomUUID();
  await request(app.getHttpServer())
    .post('/sync/push')
    .set('Authorization', `Bearer ${login.accessToken}`)
    .send({
      deviceId: 'dev-pay',
      sales: [],
      debtPayments: [
        {
          ...payment,
          id: overId,
          amountVnd: 999999,
          clientCreatedAt: new Date().toISOString(),
        },
      ],
    })
    .expect(201)
    .expect((res) => {
      expect(res.body.rejectedDebtPayments).toEqual(
        expect.arrayContaining([
          { id: overId, reason: 'payment_exceeds_balance' },
        ]),
      );
    });

  const pull = await request(app.getHttpServer())
    .get('/sync/pull')
    .query({ storeId, since: new Date(0).toISOString() })
    .set('Authorization', `Bearer ${login.accessToken}`)
    .expect(200);
  expect(pull.body.customers.some((c: { id: string }) => c.id === customerId)).toBe(
    true,
  );
  expect(
    pull.body.debtLedger.some((e: { id: string }) => e.id === paymentId),
  ).toBe(true);
});
```

(Fill setup identically to Task 2: login, store, shift, customer balance 20000 via prior debt sale or `prisma.customer.update`.)

- [ ] **Step 2: Run — expect fail**

```bash
cd apps/api && npm run test:e2e -- --testPathPattern=debt-payments
```

Expected: FAIL (`debtPayments` ignored / pull missing fields).

- [ ] **Step 3: Implement DTOs + `push` orchestration**

In `sync.controller.ts` `push`, keep `sales` required as today OR allow empty array (tests send `sales: []`). Update controller validation:

```typescript
if (!Array.isArray(body.sales)) {
  throw new BadRequestException('sales must be an array');
}
```

In `SyncService.push`, after sales processing:

```typescript
const debtResult = await this.pushDebtPayments(
  user,
  body.debtPayments ?? [],
);
const customerResult = await this.pushCustomerUpserts(
  user,
  body.customerUpserts ?? [],
);
return {
  acceptedShiftIds,
  acceptedShiftCloseIds,
  rejectedShifts,
  ...salesResult,
  ...debtResult,
  ...customerResult,
};
```

- [ ] **Step 4: Implement `pushDebtPayments`**

```typescript
private async pushDebtPayments(
  user: AuthUser,
  payments: PushDebtPaymentDto[],
) {
  const acceptedDebtPaymentIds: string[] = [];
  const rejectedDebtPayments: { id: string; reason: string }[] = [];
  for (const payment of payments) {
    const result = await this.processDebtPayment(user, payment);
    if (result.accepted) {
      acceptedDebtPaymentIds.push(payment.id);
    } else {
      rejectedDebtPayments.push({
        id: payment.id,
        reason: result.reason ?? 'invalid_payment',
      });
    }
  }
  return { acceptedDebtPaymentIds, rejectedDebtPayments };
}

private async processDebtPayment(
  user: AuthUser,
  payment: PushDebtPaymentDto,
): Promise<{ accepted: boolean; reason?: string }> {
  if (
    !payment.id ||
    !payment.storeId ||
    !payment.customerId ||
    !Number.isSafeInteger(payment.amountVnd) ||
    payment.amountVnd <= 0 ||
    (payment.paymentMethod !== 'cash' &&
      payment.paymentMethod !== 'transfer') ||
    Number.isNaN(Date.parse(payment.clientCreatedAt))
  ) {
    return { accepted: false, reason: 'invalid_payment' };
  }
  this.assertStoreAccess(user, payment.storeId);

  const existing = await this.prisma.debtLedgerEntry.findUnique({
    where: { id: payment.id },
  });
  if (existing) {
    return { accepted: true };
  }

  try {
    await this.prisma.$transaction(async (tx) => {
      const customer = await tx.customer.findUnique({
        where: { id: payment.customerId },
      });
      if (!customer || customer.storeId !== payment.storeId) {
        throw new Error('customer_not_found');
      }
      if (payment.amountVnd > customer.balanceVnd) {
        throw new Error('payment_exceeds_balance');
      }
      const updated = await tx.customer.update({
        where: { id: customer.id },
        data: { balanceVnd: { decrement: payment.amountVnd } },
      });
      await tx.debtLedgerEntry.create({
        data: {
          id: payment.id,
          storeId: payment.storeId,
          customerId: payment.customerId,
          type: 'payment',
          amountVnd: payment.amountVnd,
          balanceAfterVnd: updated.balanceVnd,
          shiftId: payment.shiftId ?? null,
          recordedById: user.userId,
          paymentMethod: payment.paymentMethod,
          note: payment.note?.trim() || null,
          clientCreatedAt: new Date(payment.clientCreatedAt),
        },
      });
    });
    return { accepted: true };
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'payment_exceeds_balance') {
        return { accepted: false, reason: 'payment_exceeds_balance' };
      }
      if (error.message === 'customer_not_found') {
        return { accepted: false, reason: 'customer_not_found' };
      }
    }
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    ) {
      return { accepted: true };
    }
    throw error;
  }
}
```

- [ ] **Step 5: Implement `pushCustomerUpserts`**

Loop `customerUpserts`, call `customersService.create(user, dto)` (already upserts). Collect ids; on failure push to a soft-reject list or throw — prefer try/catch per item with reason `customer_upsert_failed`. Return `{ acceptedCustomerUpsertIds }`.

- [ ] **Step 6: Extend `pull`**

```typescript
const [products, stocks, customers, debtLedger] = await Promise.all([
  this.productsService.findUpdatedSince(since),
  this.productsService.findStocksForStoreSince(storeId, since),
  this.prisma.customer.findMany({
    where: { storeId, updatedAt: { gt: since } },
  }),
  this.prisma.debtLedgerEntry.findMany({
    where: { storeId, updatedAt: { gt: since } },
    orderBy: { clientCreatedAt: 'asc' },
  }),
]);

return {
  products: /* existing */,
  stocks: /* existing */,
  customers: customers.map((c) => ({
    id: c.id,
    storeId: c.storeId,
    name: c.name,
    phone: c.phone,
    balanceVnd: c.balanceVnd,
    creditLimitVnd: c.creditLimitVnd,
    updatedAt: c.updatedAt.toISOString(),
  })),
  debtLedger: debtLedger.map((e) => ({
    id: e.id,
    storeId: e.storeId,
    customerId: e.customerId,
    type: e.type,
    amountVnd: e.amountVnd,
    balanceAfterVnd: e.balanceAfterVnd,
    saleId: e.saleId,
    shiftId: e.shiftId,
    recordedById: e.recordedById,
    paymentMethod: e.paymentMethod,
    note: e.note,
    clientCreatedAt: e.clientCreatedAt.toISOString(),
    updatedAt: e.updatedAt.toISOString(),
  })),
  serverTime: serverTime.toISOString(),
};
```

- [ ] **Step 7: Re-run e2e — PASS + commit**

```bash
cd apps/api && npm run test:e2e -- --testPathPattern=debt-payments
```

```bash
git add apps/api/src apps/api/test
git commit -m "feat(api): sync debt payments and pull customers/ledger"
```

---

### Task 4: Flutter Drift schema v3 + credit_limit helper

**Files:**
- Modify: `apps/pos_app/lib/data/local/tables.dart`
- Modify: `apps/pos_app/lib/data/local/database.dart`
- Create: `apps/pos_app/lib/features/customers/credit_limit.dart`
- Create: `apps/pos_app/test/credit_limit_test.dart`
- Run: `dart run build_runner build --delete-conflicting-outputs` in `apps/pos_app`

**Interfaces:**
- Produces:

```dart
bool exceedsCreditLimit({
  required int balanceVnd,
  required int debtAmount,
  int? creditLimitVnd,
});
```

- Drift: `CustomersLocal.creditLimitVnd` nullable int; table `DebtLedgerLocal` mirroring server fields needed for UI/sync.

- [ ] **Step 1: Failing unit tests for credit helper**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/customers/credit_limit.dart';

void main() {
  test('null limit never exceeds', () {
    expect(
      exceedsCreditLimit(balanceVnd: 100, debtAmount: 999999, creditLimitVnd: null),
      isFalse,
    );
  });

  test('equal to limit is allowed', () {
    expect(
      exceedsCreditLimit(balanceVnd: 10000, debtAmount: 5000, creditLimitVnd: 15000),
      isFalse,
    );
  });

  test('over limit is blocked', () {
    expect(
      exceedsCreditLimit(balanceVnd: 10000, debtAmount: 5001, creditLimitVnd: 15000),
      isTrue,
    );
  });
}
```

- [ ] **Step 2: Run — fail**

```bash
cd apps/pos_app && flutter test test/credit_limit_test.dart
```

Expected: FAIL (library missing).

- [ ] **Step 3: Implement helper + Drift tables**

`credit_limit.dart`:

```dart
bool exceedsCreditLimit({
  required int balanceVnd,
  required int debtAmount,
  int? creditLimitVnd,
}) {
  if (creditLimitVnd == null) return false;
  return balanceVnd + debtAmount > creditLimitVnd;
}
```

`tables.dart` — add to `CustomersLocal`:

```dart
IntColumn get creditLimitVnd => integer().nullable()();
```

New table:

```dart
class DebtLedgerLocal extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  TextColumn get customerId => text()();
  TextColumn get type => text()(); // sale_debt | payment
  IntColumn get amountVnd => integer()();
  IntColumn get balanceAfterVnd => integer()();
  TextColumn get saleId => text().nullable()();
  TextColumn get shiftId => text().nullable()();
  TextColumn get recordedById => text()();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get clientCreatedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

`database.dart`: add `DebtLedgerLocal` to `@DriftDatabase`; `schemaVersion => 3`; in `onUpgrade`:

```dart
if (from < 3) {
  await migrator.addColumn(customersLocal, customersLocal.creditLimitVnd);
  await migrator.createTable(debtLedgerLocal);
}
```

Add helper:

```dart
Future<void> upsertCustomersAndDebtLedger({
  required List<Map<String, dynamic>> customers,
  required List<Map<String, dynamic>> debtLedger,
}) async {
  await transaction(() async {
    for (final c in customers) {
      await into(customersLocal).insertOnConflictUpdate(
        CustomersLocalCompanion.insert(
          id: c['id'] as String,
          name: c['name'] as String,
          phone: Value(c['phone'] as String?),
          balanceVnd: Value(c['balanceVnd'] as int),
          creditLimitVnd: Value(c['creditLimitVnd'] as int?),
          updatedAt: DateTime.parse(c['updatedAt'] as String),
        ),
      );
    }
    for (final e in debtLedger) {
      await into(debtLedgerLocal).insertOnConflictUpdate(
        DebtLedgerLocalCompanion.insert(
          id: e['id'] as String,
          storeId: e['storeId'] as String,
          customerId: e['customerId'] as String,
          type: e['type'] as String,
          amountVnd: e['amountVnd'] as int,
          balanceAfterVnd: e['balanceAfterVnd'] as int,
          saleId: Value(e['saleId'] as String?),
          shiftId: Value(e['shiftId'] as String?),
          recordedById: e['recordedById'] as String,
          paymentMethod: Value(e['paymentMethod'] as String?),
          note: Value(e['note'] as String?),
          clientCreatedAt: DateTime.parse(e['clientCreatedAt'] as String),
          updatedAt: DateTime.parse(e['updatedAt'] as String),
        ),
      );
    }
  });
}
```

- [ ] **Step 4: Codegen + tests PASS**

```bash
cd apps/pos_app && dart run build_runner build --delete-conflicting-outputs
cd apps/pos_app && flutter test test/credit_limit_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add apps/pos_app/lib/data/local apps/pos_app/lib/features/customers/credit_limit.dart apps/pos_app/test/credit_limit_test.dart
git commit -m "feat(pos): drift debt ledger and credit limit helper"
```

---

### Task 5: Flutter — DebtPaymentService + outbox + checkout ledger/credit

**Files:**
- Create: `apps/pos_app/lib/features/customers/debt_payment_service.dart`
- Modify: `apps/pos_app/lib/features/pos/checkout_service.dart`
- Modify: `apps/pos_app/lib/data/sync/outbox_worker.dart`
- Modify: `apps/pos_app/lib/features/customers/customer_repository.dart`
- Create: `apps/pos_app/test/debt_payment_test.dart`
- Modify: `apps/pos_app/test/debt_checkout_test.dart`

**Interfaces:**
- Produces:

```dart
class DebtPaymentService {
  Future<String> recordPayment({
    required String customerId,
    required int amountVnd,
    required String paymentMethod, // cash | transfer
    String? note,
  });
}

class CreditLimitExceededException implements Exception {
  const CreditLimitExceededException({
    required this.balanceVnd,
    required this.creditLimitVnd,
    required this.debtAmount,
  });
  final int balanceVnd;
  final int creditLimitVnd;
  final int debtAmount;
}
```

- Outbox payloads: `entityType: 'debt_payment'` with PushDebtPaymentDto fields; `entityType: 'customer_upsert'` with customer fields including `creditLimitVnd`.

- [ ] **Step 1: Failing tests**

`test/debt_payment_test.dart`:

```dart
test('recordPayment decreases balance and enqueues debt_payment outbox', () async {
  // seed session, customer balance 20000, optional open shift
  final service = DebtPaymentService(db: db, shiftRepository: shiftRepository);
  final id = await service.recordPayment(
    customerId: 'c1',
    amountVnd: 5000,
    paymentMethod: 'cash',
    note: 'tra',
  );
  final customer = await (db.select(db.customersLocal)..where((t) => t.id.equals('c1'))).getSingle();
  expect(customer.balanceVnd, 15000);
  final ledger = await (db.select(db.debtLedgerLocal)..where((t) => t.id.equals(id))).getSingle();
  expect(ledger.type, 'payment');
  expect(ledger.amountVnd, 5000);
  final outbox = await db.pendingOutbox();
  expect(outbox.any((e) => e.entityType == 'debt_payment'), isTrue);
});

test('recordPayment rejects amount over balance', () async {
  final service = DebtPaymentService(db: db, shiftRepository: shiftRepository);
  expect(
    () => service.recordPayment(customerId: 'c1', amountVnd: 999999, paymentMethod: 'cash'),
    throwsA(isA<StateError>()),
  );
});
```

Extend `debt_checkout_test.dart`:

```dart
test('checkout debt writes sale_debt ledger and blocks over credit limit', () async {
  // customer creditLimitVnd 15000, balance 0, cart 20000 debt → throws CreditLimitExceededException
  // customer unlimited, debt 20000 → balance 20000 and debt_ledger_local type sale_debt with saleId
});
```

- [ ] **Step 2: Run — fail**

```bash
cd apps/pos_app && flutter test test/debt_payment_test.dart test/debt_checkout_test.dart
```

- [ ] **Step 3: Implement `DebtPaymentService`**

```dart
class DebtPaymentService {
  DebtPaymentService({required AppDatabase db, required ShiftRepository shiftRepository})
      : _db = db, _shiftRepository = shiftRepository;

  final AppDatabase _db;
  final ShiftRepository _shiftRepository;
  final _uuid = const Uuid();

  Future<String> recordPayment({
    required String customerId,
    required int amountVnd,
    required String paymentMethod,
    String? note,
  }) async {
    if (amountVnd <= 0) throw StateError('amount must be positive');
    if (paymentMethod != 'cash' && paymentMethod != 'transfer') {
      throw StateError('invalid payment method');
    }
    final storeId = await _db.metaValue('currentStoreId');
    final userJson = await _db.metaValue('currentUser');
    if (storeId == null || userJson == null) {
      throw StateError('Missing store or user session');
    }
    final userId = (jsonDecode(userJson) as Map<String, dynamic>)['id'] as String;
    final shift = await _shiftRepository.requireOpenShift(storeId: storeId, userId: userId);
    final paymentId = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      final customer = await (_db.select(_db.customersLocal)
            ..where((r) => r.id.equals(customerId)))
          .getSingleOrNull();
      if (customer == null) throw StateError('customer not found');
      if (amountVnd > customer.balanceVnd) {
        throw StateError('payment exceeds balance');
      }
      final newBalance = customer.balanceVnd - amountVnd;
      await (_db.update(_db.customersLocal)..where((r) => r.id.equals(customerId)))
          .write(CustomersLocalCompanion(
            balanceVnd: Value(newBalance),
            updatedAt: Value(now),
          ));
      await _db.into(_db.debtLedgerLocal).insert(DebtLedgerLocalCompanion.insert(
            id: paymentId,
            storeId: storeId,
            customerId: customerId,
            type: 'payment',
            amountVnd: amountVnd,
            balanceAfterVnd: newBalance,
            shiftId: Value(shift.id),
            recordedById: userId,
            paymentMethod: Value(paymentMethod),
            note: Value(note),
            clientCreatedAt: now,
            updatedAt: now,
          ));
      await _db.into(_db.outboxEntries).insert(OutboxEntriesCompanion.insert(
            id: _uuid.v4(),
            entityType: 'debt_payment',
            payloadJson: jsonEncode({
              'id': paymentId,
              'storeId': storeId,
              'customerId': customerId,
              'amountVnd': amountVnd,
              'paymentMethod': paymentMethod,
              'note': note,
              'shiftId': shift.id,
              'clientCreatedAt': now.toUtc().toIso8601String(),
              'recordedById': userId,
            }),
            createdAt: now,
          ));
    });
    return paymentId;
  }
}
```

- [ ] **Step 4: Update `CheckoutService.complete`**

Before writing sale, if `payment.debt > 0`:

```dart
final customer = await (_db.select(_db.customersLocal)
      ..where((r) => r.id.equals(customerId!)))
    .getSingleOrNull();
if (customer == null) throw StateError('customer not found');
if (exceedsCreditLimit(
  balanceVnd: customer.balanceVnd,
  debtAmount: payment.debt,
  creditLimitVnd: customer.creditLimitVnd,
)) {
  throw CreditLimitExceededException(
    balanceVnd: customer.balanceVnd,
    creditLimitVnd: customer.creditLimitVnd!,
    debtAmount: payment.debt,
  );
}
```

After balance increment on debt, insert `debt_ledger_local` with `type: 'sale_debt'`, `saleId: saleId`, `amountVnd: payment.debt`, `balanceAfterVnd: debtCustomer.balanceVnd + payment.debt`.

- [ ] **Step 5: Update `OutboxWorker.tick`**

Collect `debtPayments` and `customerUpserts` arrays from pending outbox; include in POST body. Parse `acceptedDebtPaymentIds` / `rejectedDebtPayments` / `acceptedCustomerUpsertIds`; call `markOutboxEntitiesDone('debt_payment', …)` and `markOutboxEntitiesDone('customer_upsert', …)`; mark errors with `entityType`.

Extend `PushSyncResult.fromJson` accordingly.

- [ ] **Step 6: `CustomerRepository` — creditLimit on record + updateCreditLimit**

```dart
class CustomerRecord {
  const CustomerRecord({
    required this.id,
    required this.name,
    this.phone,
    required this.balanceVnd,
    this.creditLimitVnd,
  });
  final int? creditLimitVnd;
  // ...
}

Future<void> updateCreditLimit({
  required String customerId,
  required int? creditLimitVnd,
}) async {
  final now = DateTime.now();
  final row = await (_db.select(_db.customersLocal)
        ..where((r) => r.id.equals(customerId)))
      .getSingle();
  await (_db.update(_db.customersLocal)..where((r) => r.id.equals(customerId)))
      .write(CustomersLocalCompanion(
        creditLimitVnd: Value(creditLimitVnd),
        updatedAt: Value(now),
      ));
  final storeId = await _db.metaValue('currentStoreId');
  if (storeId == null) return;
  await _db.into(_db.outboxEntries).insert(OutboxEntriesCompanion.insert(
        id: _uuid.v4(),
        entityType: 'customer_upsert',
        payloadJson: jsonEncode({
          'id': row.id,
          'storeId': storeId,
          'name': row.name,
          'phone': row.phone,
          'creditLimitVnd': creditLimitVnd,
        }),
        createdAt: now,
      ));
}
```

Also map `creditLimitVnd` in all `CustomerRecord` constructors from Drift rows; include in `create()` insert as `Value(null)`.

- [ ] **Step 7: Tests PASS + commit**

```bash
cd apps/pos_app && flutter test test/debt_payment_test.dart test/debt_checkout_test.dart test/credit_limit_test.dart
```

```bash
git add apps/pos_app
git commit -m "feat(pos): offline debt payment and credit-limit checkout"
```

---

### Task 6: Flutter — pull sync + UI (detail, thu nợ, payment sheet)

**Files:**
- Modify: `apps/pos_app/lib/data/sync/pull_catalog.dart`
- Modify: `apps/pos_app/lib/features/customers/debt_customer_list_page.dart`
- Create: `apps/pos_app/lib/features/customers/customer_detail_page.dart`
- Create: `apps/pos_app/lib/features/customers/record_debt_payment_sheet.dart`
- Modify: `apps/pos_app/lib/features/pos/payment_sheet.dart`
- Modify: `apps/pos_app/lib/features/pos/pos_page.dart` (wire `DebtPaymentService` if needed via repository/detail)
- Modify: `apps/pos_app/lib/main.dart` / constructors that construct repos (pass `DebtPaymentService` where UI needs it)

**Interfaces:**
- `PullCatalog.pullCatalog` upserts `customers` + `debtLedger` from pull response.
- UI Vietnamese copy:
  - List → detail: title khách name
  - Thu nợ button: `Thu nợ`
  - Credit block: `Vượt hạn mức nợ (còn được nợ: X VND)`

- [ ] **Step 1: Extend pull**

```dart
final customers = (data['customers'] as List<dynamic>? ?? [])
    .cast<Map<String, dynamic>>();
final debtLedger = (data['debtLedger'] as List<dynamic>? ?? [])
    .cast<Map<String, dynamic>>();
await _db.upsertCustomersAndDebtLedger(
  customers: customers,
  debtLedger: debtLedger,
);
// keep existing product/stock upsert; either call both or merge into one transaction helper
```

Ensure products/stocks still upsert (call existing method then ledger method, or expand `upsertProductsAndStocks`).

- [ ] **Step 2: `CustomerDetailPage`**

- Shows name, phone, `balanceVnd`, `creditLimitVnd` (or `Không hạn mức`).
- Stream/list ledger for `customerId` ordered by `clientCreatedAt` desc: show type label `Bán nợ` / `Thu nợ`, amount, balance after, time.
- Actions: `Thu nợ` → `RecordDebtPaymentSheet`; `Sửa hạn mức` → dialog with int? field (empty = null).

- [ ] **Step 3: `RecordDebtPaymentSheet`**

- Default amount = current balance.
- Radio/toggle: Tiền mặt / Chuyển khoản.
- Optional note.
- On confirm call `DebtPaymentService.recordPayment`; pop + snackbar `Đã thu nợ (chờ sync)`.

- [ ] **Step 4: Wire list → detail**

In `DebtCustomerListPage` `onTap` → `Navigator.push` `CustomerDetailPage`.

- [ ] **Step 5: Payment sheet credit UX**

Before calling checkout, if debt > 0 and selected customer:

```dart
if (exceedsCreditLimit(
  balanceVnd: _selectedCustomer!.balanceVnd,
  debtAmount: debt,
  creditLimitVnd: _selectedCustomer!.creditLimitVnd,
)) {
  final limit = _selectedCustomer!.creditLimitVnd!;
  final remaining = limit - _selectedCustomer!.balanceVnd;
  setState(() {
    _error =
        'Vượt hạn mức nợ (còn được nợ: ${remaining < 0 ? 0 : remaining} VND)';
  });
  return;
}
```

Also catch `CreditLimitExceededException` from checkout.

- [ ] **Step 6: Manual smoke (optional automated widget smoke)**

```bash
cd apps/pos_app && flutter test
cd apps/api && npm run test:e2e -- --testPathPattern='customers-debt|debt-payments'
```

Expected: all PASS.

- [ ] **Step 7: Commit**

```bash
git add apps/pos_app
git commit -m "feat(pos): debt payment UI and pull customers/ledger"
```

---

### Task 7: Docs — mark remaining #1 done

**Files:**
- Modify: `docs/superpowers/plans/2026-07-23-phase1-remaining.md`
- Modify: `docs/CHANGELOG-vi.md` (short bullet under Phase 1)

- [ ] **Step 1: Check off remaining items**

In `2026-07-23-phase1-remaining.md` Customer debt section:

```markdown
- [x] Debt payment recording and history
- [x] Credit limit enforcement at checkout
- [ ] Debt aging / overdue views
- [x] Customer search and detail screen polish
```

(Only polish that this plan delivered: detail + history + limit edit. Leave aging unchecked.)

- [ ] **Step 2: CHANGELOG-vi.md**

Add under Phase 1:

```markdown
- Thu nợ offline (một phần/toàn phần) + sổ công nợ; hạn mức tín dụng khi bán nợ
```

- [ ] **Step 3: Commit**

```bash
git add docs
git commit -m "docs: mark debt payments and credit limit as done"
```

---

## Spec coverage self-review

| Spec requirement | Task |
|---|---|
| `creditLimitVnd` on Customer | 1, 2, 4 |
| `DebtLedgerEntry` sale_debt + payment | 1, 2, 3, 5 |
| Offline thu nợ + outbox `debt_payment` | 5, 6 |
| Pull customers + ledger | 3, 6 |
| Credit limit local + server | 2, 5, 6 |
| UI detail / thu nợ / payment block | 6 |
| `customer_upsert` for limit | 3, 5 |
| Idempotent payment / exceeds balance | 3, 5 |
| Acceptance e2e + Flutter tests | 2, 3, 5, 6 |
| Aging / reverse payment | Out of scope (no task) |

## Placeholder / type consistency check

- Reject strings fixed: `credit_limit_exceeded`, `payment_exceeds_balance`.
- Outbox types: `debt_payment`, `customer_upsert`.
- Ledger types: `sale_debt`, `payment`.
- Payment channels: `cash`, `transfer`.
- Pull keys: `customers`, `debtLedger`.
- Push keys: `debtPayments`, `customerUpserts`, response `acceptedDebtPaymentIds`, `rejectedDebtPayments`, `acceptedCustomerUpsertIds`.
