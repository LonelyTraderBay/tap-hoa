# Phase 1 Foundation + POS MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a working offline-first grocery POS for multiple store points on Windows and mobile: auth, products, sell with cash/transfer/debt stub, local SQLite outbox sync, open/close shift, and basic day sales report.

**Architecture:** Flutter client (Windows + Android + iOS) with Drift/SQLite local DB and an outbox sync queue; NestJS + PostgreSQL central API. Each sale and stock mutation is written locally first, then synced when online. Multi-store via `store_id` on all documents.

**Tech Stack:** Flutter 3.24+, Dart 3.5+, Drift 2.x, flutter_riverpod 2.x; NestJS 10, Prisma 5, PostgreSQL 16, JWT auth; UUID v7 for document IDs.

**Spec:** `docs/superpowers/specs/2026-07-23-tap-hoa-pos-ke-toan-design.md` (Phase 1 only).

## Global Constraints

- Offline-first: never block checkout on network failure.
- Every document has `id` (UUID), `storeId`, `createdAt`, `updatedAt`, `syncedAt` (nullable).
- Roles: `owner` | `store_manager` | `cashier`.
- Money stored as integer **VND** (no floats).
- Quantity: decimal string with scale 3 for weighed goods (e.g. `"1.250"`), integer-like for pieces (`"2"`).
- Phase 2 accounting and e-invoice are out of scope for this plan.
- Follow-up plans will cover: full inventory transfers/stocktake, full customer debt ledger UI polish, cash in/out categories, barcode label printing.

## Scope of this plan (Phase 1 vertical slice)

Included:
1. Monorepo scaffold (`apps/pos_app`, `apps/api`)
2. Auth + stores + shifts
3. Product catalog (CRUD local + sync)
4. POS cart + checkout (cash / transfer / debt flag)
5. Stock decrement on sale
6. Sync outbox push/pull
7. Day sales report (per store + all for owner)
8. Minimal phone-friendly screens (same Flutter app, responsive)

Deferred to next plans (still Phase 1 per spec):
- Inter-store transfer, stocktake, wastage
- Full debt payment history UI + credit limit enforcement
- Cash in/out vouchers
- Receipt thermal printer drivers
- Push notifications

---

## File structure (create)

```text
tap-hoa/
  apps/
    api/                          # NestJS
      prisma/schema.prisma
      src/main.ts
      src/app.module.ts
      src/auth/
      src/stores/
      src/products/
      src/sales/
      src/sync/
      src/shifts/
      test/
    pos_app/                      # Flutter
      lib/
        main.dart
        app.dart
        core/                     # theme, router, env
        data/
          local/database.dart     # Drift
          local/tables.dart
          remote/api_client.dart
          sync/outbox_worker.dart
        domain/                   # pure models + use cases
        features/
          auth/
          stores/
          shifts/
          products/
          pos/
          reports/
          sync_status/
      test/
  packages/
    tap_hoa_shared/               # shared DTO constants if needed later
  docs/superpowers/...
```

---

### Task 1: Monorepo + API hello + Flutter hello

**Files:**
- Create: `apps/api/package.json`
- Create: `apps/api/tsconfig.json`
- Create: `apps/api/src/main.ts`
- Create: `apps/api/src/app.module.ts`
- Create: `apps/api/src/health.controller.ts`
- Create: `apps/api/test/health.e2e-spec.ts`
- Create: `apps/pos_app/pubspec.yaml` (via `flutter create`)
- Create: `apps/pos_app/lib/main.dart`
- Create: `README.md`

**Interfaces:**
- Consumes: none
- Produces: `GET /health` → `{ "ok": true }`; Flutter app launches showing "Tap Hoa POS"

- [ ] **Step 1: Create API folder and package.json**

```json
{
  "name": "tap-hoa-api",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "start:dev": "nest start --watch",
    "test:e2e": "jest --config ./test/jest-e2e.json",
    "build": "nest build"
  },
  "dependencies": {
    "@nestjs/common": "^10.4.15",
    "@nestjs/core": "^10.4.15",
    "@nestjs/platform-express": "^10.4.15",
    "reflect-metadata": "^0.2.2",
    "rxjs": "^7.8.1"
  },
  "devDependencies": {
    "@nestjs/cli": "^10.4.9",
    "@nestjs/testing": "^10.4.15",
    "@types/jest": "^29.5.14",
    "@types/node": "^22.10.2",
    "jest": "^29.7.0",
    "ts-jest": "^29.2.5",
    "typescript": "^5.7.2"
  }
}
```

- [ ] **Step 2: Write health controller and e2e test**

```typescript
// apps/api/src/health.controller.ts
import { Controller, Get } from '@nestjs/common';

@Controller('health')
export class HealthController {
  @Get()
  check() {
    return { ok: true };
  }
}
```

```typescript
// apps/api/test/health.e2e-spec.ts
import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('Health', () => {
  let app: INestApplication;
  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    await app.init();
  });
  afterAll(() => app.close());
  it('GET /health', () =>
    request(app.getHttpServer()).get('/health').expect(200).expect({ ok: true }));
});
```

Wire `HealthController` into `AppModule`. Add `test/jest-e2e.json` standard Nest e2e config.

- [ ] **Step 3: Run e2e to verify fail then pass**

```bash
cd apps/api && npm install && npm run test:e2e
```

Expected: PASS for Health.

- [ ] **Step 4: Scaffold Flutter app**

```bash
cd apps && flutter create --org vn.taphoa --platforms=windows,android,ios pos_app
```

Replace `lib/main.dart` body with a `MaterialApp` home `Text('Tap Hoa POS')`.

- [ ] **Step 5: Smoke-run Flutter**

```bash
cd apps/pos_app && flutter test
```

Expected: default counter test may fail after main.dart change — replace `test/widget_test.dart` to pump app and expect `find.text('Tap Hoa POS')`, then PASS.

- [ ] **Step 6: Commit**

```bash
git add apps/api apps/pos_app README.md
git commit -m "chore: scaffold Nest API and Flutter POS app"
```

---

### Task 2: Prisma schema — stores, users, products, sales core

**Files:**
- Create: `apps/api/prisma/schema.prisma`
- Create: `apps/api/.env.example`
- Modify: `apps/api/package.json` (add prisma, @prisma/client, bcrypt, @nestjs/jwt, class-validator)
- Create: `apps/api/prisma/seed.ts`

**Interfaces:**
- Consumes: Task 1 API scaffold
- Produces: Prisma models `Store`, `User`, `Product`, `ProductStoreStock`, `Sale`, `SaleLine`, `Shift`, `SyncCursor`

- [ ] **Step 1: Write schema**

```prisma
// apps/api/prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum Role {
  owner
  store_manager
  cashier
}

enum PaymentMethod {
  cash
  transfer
  mixed
  debt
}

model Store {
  id        String   @id @default(uuid())
  code      String   @unique
  name      String
  active    Boolean  @default(true)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  users     UserStore[]
  products  ProductStoreStock[]
  sales     Sale[]
  shifts    Shift[]
}

model User {
  id           String   @id @default(uuid())
  phone        String   @unique
  name         String
  passwordHash String
  role         Role
  active       Boolean  @default(true)
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt
  stores       UserStore[]
  shifts       Shift[]
  sales        Sale[]   @relation("SoldBy")
}

model UserStore {
  userId  String
  storeId String
  user    User  @relation(fields: [userId], references: [id])
  store   Store @relation(fields: [storeId], references: [id])
  @@id([userId, storeId])
}

model Product {
  id           String   @id @default(uuid())
  sku          String   @unique
  barcode      String?
  name         String
  unit         String
  isWeighted   Boolean  @default(false)
  basePriceVnd Int
  costVnd      Int      @default(0)
  active       Boolean  @default(true)
  updatedAt    DateTime @updatedAt
  createdAt    DateTime @default(now())
  stocks       ProductStoreStock[]
}

model ProductStoreStock {
  productId      String
  storeId        String
  qty            Decimal  @db.Decimal(18, 3)
  minQty         Decimal  @default(0) @db.Decimal(18, 3)
  updatedAt      DateTime @updatedAt
  product        Product  @relation(fields: [productId], references: [id])
  store          Store    @relation(fields: [storeId], references: [id])
  @@id([productId, storeId])
}

model Shift {
  id           String    @id @default(uuid())
  storeId      String
  userId       String
  openedAt     DateTime
  closedAt     DateTime?
  openingCash  Int
  closingCash  Int?
  note         String?
  store        Store     @relation(fields: [storeId], references: [id])
  user         User      @relation(fields: [userId], references: [id])
  sales        Sale[]
}

model Sale {
  id             String        @id @default(uuid())
  storeId        String
  shiftId        String
  soldById       String
  paymentMethod  PaymentMethod
  cashAmount     Int           @default(0)
  transferAmount Int           @default(0)
  debtAmount     Int           @default(0)
  discountVnd    Int           @default(0)
  totalVnd       Int
  customerId     String?
  clientCreatedAt DateTime
  createdAt      DateTime      @default(now())
  updatedAt      DateTime      @updatedAt
  store          Store         @relation(fields: [storeId], references: [id])
  shift          Shift         @relation(fields: [shiftId], references: [id])
  soldBy         User          @relation("SoldBy", fields: [soldById], references: [id])
  lines          SaleLine[]
  @@index([storeId, clientCreatedAt])
}

model SaleLine {
  id          String  @id @default(uuid())
  saleId      String
  productId   String
  qty         Decimal @db.Decimal(18, 3)
  unitPrice   Int
  lineTotal   Int
  sale        Sale    @relation(fields: [saleId], references: [id])
}

model SyncCursor {
  deviceId   String   @id
  userId     String
  lastPullAt DateTime
}
```

- [ ] **Step 2: Add `.env.example`**

```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/tap_hoa?schema=public
JWT_SECRET=dev-change-me
PORT=3000
```

- [ ] **Step 3: Seed owner + 2 stores + 3 products**

```typescript
// apps/api/prisma/seed.ts
import { PrismaClient, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const passwordHash = await bcrypt.hash('123456', 10);
  const s1 = await prisma.store.upsert({
    where: { code: 'CH1' },
    update: {},
    create: { code: 'CH1', name: 'Cua hang 1' },
  });
  const s2 = await prisma.store.upsert({
    where: { code: 'CH2' },
    update: {},
    create: { code: 'CH2', name: 'Cua hang 2' },
  });
  const owner = await prisma.user.upsert({
    where: { phone: '0900000001' },
    update: {},
    create: {
      phone: '0900000001',
      name: 'Chu quan',
      passwordHash,
      role: Role.owner,
      stores: { create: [{ storeId: s1.id }, { storeId: s2.id }] },
    },
  });
  const p1 = await prisma.product.upsert({
    where: { sku: 'STING-330' },
    update: {},
    create: {
      sku: 'STING-330',
      barcode: '8934588012345',
      name: 'Sting do 330ml',
      unit: 'chai',
      basePriceVnd: 10000,
      costVnd: 7500,
    },
  });
  for (const storeId of [s1.id, s2.id]) {
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId: p1.id, storeId } },
      update: { qty: 100 },
      create: { productId: p1.id, storeId, qty: 100, minQty: 10 },
    });
  }
  console.log({ owner: owner.phone, stores: [s1.code, s2.code] });
}

main().finally(() => prisma.$disconnect());
```

- [ ] **Step 4: Migrate**

```bash
cd apps/api && npx prisma migrate dev --name init && npx prisma db seed
```

Expected: migration applied; seed prints owner phone.

- [ ] **Step 5: Commit**

```bash
git add apps/api/prisma apps/api/.env.example apps/api/package.json
git commit -m "feat(api): add Prisma schema for stores products sales"
```

---

### Task 3: Auth API — login JWT + store list

**Files:**
- Create: `apps/api/src/auth/auth.module.ts`
- Create: `apps/api/src/auth/auth.service.ts`
- Create: `apps/api/src/auth/auth.controller.ts`
- Create: `apps/api/src/auth/jwt.strategy.ts`
- Create: `apps/api/src/auth/dto/login.dto.ts`
- Create: `apps/api/test/auth.e2e-spec.ts`
- Create: `apps/api/src/prisma/prisma.service.ts`
- Create: `apps/api/src/prisma/prisma.module.ts`

**Interfaces:**
- Consumes: `User`, `Store` models
- Produces:
  - `POST /auth/login` body `{ phone, password }` → `{ accessToken, user: { id, name, role, storeIds: string[] } }`
  - `GET /stores` (Bearer) → `{ id, code, name }[]` filtered by membership (owner sees all active)

- [ ] **Step 1: Write failing e2e**

```typescript
it('login returns token', async () => {
  const res = await request(app.getHttpServer())
    .post('/auth/login')
    .send({ phone: '0900000001', password: '123456' })
    .expect(201);
  expect(res.body.accessToken).toBeDefined();
  expect(res.body.user.role).toBe('owner');
});
```

- [ ] **Step 2: Implement AuthService.login**

```typescript
async login(phone: string, password: string) {
  const user = await this.prisma.user.findUnique({
    where: { phone },
    include: { stores: true },
  });
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    throw new UnauthorizedException('Invalid credentials');
  }
  const storeIds = user.stores.map((s) => s.storeId);
  const accessToken = await this.jwt.signAsync({
    sub: user.id,
    role: user.role,
    storeIds,
  });
  return {
    accessToken,
    user: { id: user.id, name: user.name, role: user.role, storeIds },
  };
}
```

- [ ] **Step 3: Run e2e**

```bash
cd apps/api && npm run test:e2e -- auth.e2e-spec.ts
```

Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add apps/api/src/auth apps/api/src/prisma apps/api/test/auth.e2e-spec.ts
git commit -m "feat(api): JWT login and store membership"
```

---

### Task 4: Flutter local DB (Drift) + auth session

**Files:**
- Create: `apps/pos_app/lib/data/local/tables.dart`
- Create: `apps/pos_app/lib/data/local/database.dart`
- Create: `apps/pos_app/lib/features/auth/auth_repository.dart`
- Create: `apps/pos_app/lib/features/auth/login_page.dart`
- Create: `apps/pos_app/lib/data/remote/api_client.dart`
- Create: `apps/pos_app/test/auth_repository_test.dart`
- Modify: `apps/pos_app/pubspec.yaml` (drift, drift_dev, riverpod, dio, flutter_secure_storage, uuid)

**Interfaces:**
- Consumes: `POST /auth/login`
- Produces: `AuthRepository.login(phone, password)` stores token; `AppDatabase` with tables mirroring server subset + `OutboxEntries`

- [ ] **Step 1: Define Drift tables**

```dart
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get sku => text()();
  TextColumn get barcode => text().nullable()();
  TextColumn get name => text()();
  TextColumn get unit => text()();
  BoolColumn get isWeighted => boolean().withDefault(const Constant(false))();
  IntColumn get basePriceVnd => integer()();
  IntColumn get costVnd => integer().withDefault(const Constant(0))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class ProductStocks extends Table {
  TextColumn get productId => text()();
  TextColumn get storeId => text()();
  TextColumn get qty => text()(); // decimal as string
  TextColumn get minQty => text()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {productId, storeId};
}

class OutboxEntries extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()(); // sale | product | stock_adjust
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get status => text()(); // pending | error | done
  TextColumn get lastError => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class SalesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  TextColumn get shiftId => text()();
  TextColumn get paymentMethod => text()();
  IntColumn get totalVnd => integer()();
  IntColumn get cashAmount => integer()();
  IntColumn get transferAmount => integer()();
  IntColumn get debtAmount => integer()();
  TextColumn get customerId => text().nullable()();
  DateTimeColumn get clientCreatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}
```

Also add `SaleLinesLocal`, `ShiftsLocal`, `StoresLocal`, `MetaLocal` (current user/token/store).

- [ ] **Step 2: Write AuthRepository test with mocked Dio**

```dart
test('login stores access token', () async {
  final repo = AuthRepository(dio: mockDio, secureStorage: memoryStorage, db: db);
  whenMockLoginSuccess();
  final user = await repo.login('0900000001', '123456');
  expect(user.role, 'owner');
  expect(await memoryStorage.read(key: 'accessToken'), isNotNull);
});
```

- [ ] **Step 3: Implement login page + ApiClient**

`ApiClient` base URL from `--dart-define=API_URL=http://10.0.2.2:3000` (Android emulator) / `http://localhost:3000` (Windows).

- [ ] **Step 4: Run tests**

```bash
cd apps/pos_app && flutter test test/auth_repository_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add apps/pos_app
git commit -m "feat(pos): Drift schema and login session"
```

---

### Task 5: Shifts — open/close ca

**Files:**
- Create: `apps/api/src/shifts/shifts.controller.ts`
- Create: `apps/api/src/shifts/shifts.service.ts`
- Create: `apps/pos_app/lib/features/shifts/shift_repository.dart`
- Create: `apps/pos_app/lib/features/shifts/open_shift_page.dart`
- Create: `apps/pos_app/test/shift_repository_test.dart`
- Create: `apps/api/test/shifts.e2e-spec.ts`

**Interfaces:**
- Consumes: auth JWT, `Shift` model
- Produces:
  - `POST /shifts/open` `{ storeId, openingCash, clientId }` → shift
  - `POST /shifts/:id/close` `{ closingCash, note? }`
  - Local: cannot start sale without open shift for selected store

- [ ] **Step 1: Failing API test — open shift**

```typescript
it('opens shift', async () => {
  const login = await loginAsOwner(app);
  const stores = await request(app.getHttpServer())
    .get('/stores')
    .set('Authorization', `Bearer ${login.accessToken}`);
  const storeId = stores.body[0].id;
  const res = await request(app.getHttpServer())
    .post('/shifts/open')
    .set('Authorization', `Bearer ${login.accessToken}`)
    .send({ storeId, openingCash: 500000, clientId: '11111111-1111-1111-1111-111111111111' })
    .expect(201);
  expect(res.body.openingCash).toBe(500000);
});
```

- [ ] **Step 2: Implement service — reject second open shift for same store+user**

```typescript
const existing = await this.prisma.shift.findFirst({
  where: { storeId, userId, closedAt: null },
});
if (existing) throw new ConflictException('Shift already open');
```

Use client-provided `clientId` as Shift.id for idempotent sync.

- [ ] **Step 3: Flutter — OpenShiftPage requires store picker + opening cash**

Persist to `ShiftsLocal` and enqueue outbox `entityType: 'shift_open'`.

- [ ] **Step 4: Tests pass + commit**

```bash
git commit -m "feat: open and close cashier shifts"
```

---

### Task 6: Products sync pull + local product list

**Files:**
- Create: `apps/api/src/products/products.controller.ts`
- Create: `apps/api/src/products/products.service.ts`
- Create: `apps/api/src/sync/sync.controller.ts`
- Create: `apps/api/src/sync/sync.service.ts`
- Create: `apps/pos_app/lib/features/products/product_list_page.dart`
- Create: `apps/pos_app/lib/data/sync/pull_catalog.dart`
- Create: `apps/pos_app/test/pull_catalog_test.dart`

**Interfaces:**
- Consumes: Product + ProductStoreStock
- Produces:
  - `GET /sync/pull?since=ISO&storeId=` → `{ products, stocks, serverTime }`
  - `ProductRepository.watchByStore(storeId)` stream from Drift

- [ ] **Step 1: API pull returns seeded Sting product for store**

```typescript
expect(res.body.products.some((p) => p.sku === 'STING-330')).toBe(true);
expect(res.body.stocks[0].qty).toBeDefined();
```

- [ ] **Step 2: Flutter PullCatalog upserts Drift rows**

```dart
Future<void> pullCatalog(String storeId) async {
  final since = await db.lastPullAt() ?? DateTime.fromMillisecondsSinceEpoch(0);
  final data = await api.getSyncPull(since: since, storeId: storeId);
  await db.upsertProductsAndStocks(data);
  await db.setLastPullAt(DateTime.parse(data.serverTime));
}
```

- [ ] **Step 3: UI list shows product name and stock qty**

- [ ] **Step 4: Commit**

```bash
git commit -m "feat: pull products and stock into local DB"
```

---

### Task 7: POS cart domain — pure Dart TDD

**Files:**
- Create: `apps/pos_app/lib/features/pos/cart.dart`
- Create: `apps/pos_app/test/cart_test.dart`

**Interfaces:**
- Consumes: none (pure)
- Produces: `Cart` with `add/update/remove`, `discountVnd`, `totalVnd`, `toSaleDraft()`

- [ ] **Step 1: Failing tests**

```dart
test('line total and cart total', () {
  final cart = Cart();
  cart.add(CartLine(productId: 'p1', name: 'Sting', unitPrice: 10000, qty: Decimal.parse('2')));
  expect(cart.totalVnd, 20000);
  cart.discountVnd = 2000;
  expect(cart.totalVnd, 18000);
});

test('weighted qty', () {
  final cart = Cart();
  cart.add(CartLine(productId: 'p2', name: 'Duong', unitPrice: 25000, qty: Decimal.parse('0.500')));
  expect(cart.totalVnd, 12500);
});
```

Use `decimal` package.

- [ ] **Step 2: Implement Cart**

```dart
class Cart {
  final lines = <CartLine>[];
  int discountVnd = 0;
  int get subtotalVnd => lines.fold(0, (s, l) => s + l.lineTotal);
  int get totalVnd => subtotalVnd - discountVnd;
}
```

`CartLine.lineTotal = (unitPrice * qty).round()` with explicit rounding half-up to VND integer.

- [ ] **Step 3: flutter test PASS + commit**

```bash
git commit -m "feat(pos): cart domain with discount and weighted qty"
```

---

### Task 8: Checkout use case — local sale + stock + outbox

**Files:**
- Create: `apps/pos_app/lib/features/pos/checkout_service.dart`
- Create: `apps/pos_app/test/checkout_service_test.dart`
- Create: `apps/pos_app/lib/features/pos/pos_page.dart`
- Create: `apps/pos_app/lib/features/pos/payment_sheet.dart`

**Interfaces:**
- Consumes: `Cart`, `AppDatabase`, open `Shift`
- Produces: `CheckoutService.complete({cart, payment, customerId?})` → local `Sale` id; decrements `ProductStocks`; inserts `OutboxEntries` with `entityType: 'sale'`

- [ ] **Step 1: Test checkout decreases stock and enqueues outbox**

```dart
test('checkout writes sale and decrements stock', () async {
  await seedProductStock(db, qty: '10');
  await openShift(db);
  final id = await checkout.complete(
    cart: cartWithStingQty2(),
    payment: PaymentSplit(cash: 20000),
  );
  final stock = await db.stock('p1', storeId);
  expect(stock, '8');
  final outbox = await db.pendingOutbox();
  expect(outbox.single.entityType, 'sale');
  expect(id, isNotEmpty);
});
```

- [ ] **Step 2: Implement in a single Drift transaction**

```dart
await db.transaction(() async {
  await db.into(db.salesLocal).insert(sale);
  for (final line in lines) {
    await db.into(db.saleLinesLocal).insert(line);
    await db.customUpdate(
      'UPDATE product_stocks SET qty = CAST(qty AS REAL) - ? WHERE product_id = ? AND store_id = ?',
      updates: {db.productStocks},
    );
  }
  await db.into(db.outboxEntries).insert(outboxRow);
});
```

Prefer reading qty as Decimal, subtract in Dart, write string back — avoid SQL float.

If `allowNegativeStock` meta is false and qty would go negative → throw `InsufficientStockException` (still allow override flag for owner later).

- [ ] **Step 3: POS UI — search by barcode/name, add to cart, pay**

Payment sheet fields: cash, transfer, debt (sum must equal `cart.totalVnd`).

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(pos): offline checkout with stock and outbox"
```

---

### Task 9: Sync push sales to API

**Files:**
- Create: `apps/api/src/sync/dto/push-sale.dto.ts`
- Modify: `apps/api/src/sync/sync.service.ts` — `pushSales`
- Create: `apps/api/test/sync-push.e2e-spec.ts`
- Create: `apps/pos_app/lib/data/sync/outbox_worker.dart`
- Create: `apps/pos_app/test/outbox_worker_test.dart`

**Interfaces:**
- Consumes: outbox payloads
- Produces:
  - `POST /sync/push` `{ deviceId, sales: SaleDto[] }` → `{ acceptedIds: string[], rejected: { id, reason }[] }`
  - Idempotent on `Sale.id`
  - Server applies stock decrement if sale new; if duplicate id → accept no-op

- [ ] **Step 1: E2E push one sale**

```typescript
const saleId = '22222222-2222-2222-2222-222222222222';
await request(app.getHttpServer())
  .post('/sync/push')
  .set('Authorization', `Bearer ${token}`)
  .send({ deviceId: 'dev1', sales: [makeSaleDto(saleId)] })
  .expect(201);
await request(app.getHttpServer())
  .post('/sync/push')
  .set('Authorization', `Bearer ${token}`)
  .send({ deviceId: 'dev1', sales: [makeSaleDto(saleId)] })
  .expect(201); // idempotent
const stock = await prisma.productStoreStock.findUnique(...);
// qty reduced only once
```

- [ ] **Step 2: Conflict — debt overpay rejection path**

For this task, only implement sale push. Debt payment conflicts come in follow-up plan.

- [ ] **Step 3: OutboxWorker**

```dart
Future<void> tick() async {
  final pending = await db.pendingOutbox(limit: 50);
  final sales = pending.where((e) => e.entityType == 'sale').map(decode).toList();
  if (sales.isEmpty) return;
  try {
    final res = await api.pushSync(deviceId: deviceId, sales: sales);
    await db.markOutboxDone(res.acceptedIds);
    for (final r in res.rejected) {
      await db.markOutboxError(r.id, r.reason);
    }
  } on DioException {
    // stay pending; do not throw to UI
  }
}
```

Run worker on timer (15s) + app resume + manual "Dong bo" button.

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(sync): push local sales idempotently to server"
```

---

### Task 10: Two-device stock pull after sale

**Files:**
- Modify: `apps/api/src/sync/sync.service.ts` (include stock changes in pull `since`)
- Create: `apps/api/test/sync-multi-device.e2e-spec.ts`
- Create: `apps/pos_app/lib/features/sync_status/sync_status_banner.dart`

**Interfaces:**
- Consumes: Task 9 push
- Produces: Device B pull sees reduced qty after Device A sale synced

- [ ] **Step 1: E2E**

```typescript
// A pushes sale qty 2 from stock 100
// B pulls since T0 for same store
// expect stock qty 98
```

- [ ] **Step 2: Banner shows pending outbox count and last error**

- [ ] **Step 3: Commit**

```bash
git commit -m "feat(sync): pull stock changes across devices"
```

---

### Task 11: Day sales report (store + owner total)

**Files:**
- Create: `apps/api/src/reports/reports.controller.ts`
- Create: `apps/api/src/reports/reports.service.ts`
- Create: `apps/api/test/reports.e2e-spec.ts`
- Create: `apps/pos_app/lib/features/reports/day_report_page.dart`
- Create: `apps/pos_app/lib/features/reports/day_report_repository.dart`

**Interfaces:**
- Consumes: Sale rows
- Produces:
  - `GET /reports/day?date=YYYY-MM-DD&storeId?=optional`
  - Response: `{ storeId, revenueVnd, orderCount, cashVnd, transferVnd, debtVnd }[]` plus `{ totalRevenueVnd }` for owner when storeId omitted
  - Offline: compute from `SalesLocal` for current store when API unreachable

- [ ] **Step 1: E2E with two sales across two stores**

```typescript
expect(body.totalRevenueVnd).toBe(50000);
expect(body.byStore).toHaveLength(2);
```

- [ ] **Step 2: Flutter DayReportPage — phone-friendly layout (large numbers)**

- [ ] **Step 3: Commit**

```bash
git commit -m "feat: day sales report per store and consolidated"
```

---

### Task 12: Customer stub for debt checkout + basic debt list

**Files:**
- Create: `apps/api/prisma/migrations/..._customers` (or edit schema + migrate)
- Add model `Customer { id, name, phone?, storeId?, balanceVnd }`
- Create: `apps/api/src/customers/...`
- Create: `apps/pos_app/lib/features/customers/...`
- Create: `apps/pos_app/test/debt_checkout_test.dart`

**Interfaces:**
- Consumes: Checkout with `debtAmount > 0` requires `customerId`
- Produces: On sync sale with debt, server increases `Customer.balanceVnd` by `debtAmount`
- Local list: customers with balance > 0 (full payment history UI = next plan)

- [ ] **Step 1: Schema + migrate Customer**

```prisma
model Customer {
  id         String   @id @default(uuid())
  name       String
  phone      String?
  balanceVnd Int      @default(0)
  updatedAt  DateTime @updatedAt
  createdAt  DateTime @default(now())
}
```

- [ ] **Step 2: Checkout validation**

```dart
if (payment.debt > 0 && (customerId == null || customerId!.isEmpty)) {
  throw StateError('customer required for debt');
}
```

- [ ] **Step 3: Sync applies balance += debtAmount idempotently with sale**

- [ ] **Step 4: Commit**

```bash
git commit -m "feat: customer debt on checkout with balance sync"
```

---

### Task 13: README runbook + Phase 1 MVP acceptance checklist

**Files:**
- Modify: `README.md`
- Create: `docs/superpowers/plans/2026-07-23-phase1-remaining.md` (outline only for deferred Phase 1 items)

- [ ] **Step 1: Document how to run Postgres, API, Flutter Windows**

```markdown
## Dev setup
1. Start Postgres 16, create DB tap_hoa
2. cd apps/api && cp .env.example .env && npm i && npx prisma migrate dev && npm run start:dev
3. cd apps/pos_app && flutter pub get && flutter run -d windows --dart-define=API_URL=http://localhost:3000
4. Login 0900000001 / 123456
```

- [ ] **Step 2: Acceptance checklist in README**

- [ ] Login and select store
- [ ] Open shift
- [ ] Pull products
- [ ] Sell offline (disable network) then sync
- [ ] Second device sees new stock after pull
- [ ] Day report shows revenue
- [ ] Debt sale increases customer balance after sync

- [ ] **Step 3: Commit**

```bash
git commit -m "docs: Phase 1 MVP runbook and acceptance checklist"
```

---

## Self-review (plan vs spec Phase 1)

| Spec section | Covered by tasks |
|---|---|
| Hệ thống & điểm bán | 3, 5 |
| Danh mục hàng hóa | 2, 6 (create-on-server seed; full CRUD UI polish deferred) |
| POS bán hàng | 7, 8 (printer deferred) |
| Kho & nhập hàng | Stock decrement on sale only; transfer/stocktake → next plan |
| Công nợ khách | 12 stub; full payment history → next plan |
| Thu chi cơ bản | Deferred next plan |
| Báo cáo GĐ1 | 11 (day revenue); top SKU deferred |
| App điện thoại | Same Flutter app responsive report/POS (Task 11) |
| Offline sync | 8, 9, 10 |

Gaps intentionally deferred are listed in Task 13 follow-up outline — not blockers for MVP vertical slice.

## Type/name consistency

- `storeId`, `openingCash`, `debtAmount`, `OutboxEntries.status` ∈ {pending, error, done}
- Sale id client-generated UUID used as server primary key
- Money: `*Vnd` int fields everywhere

---

## After this plan

Next Phase 1 plan: inventory transfers, stocktake, cash in/out, debt repayments history, barcode labels, thermal print.
