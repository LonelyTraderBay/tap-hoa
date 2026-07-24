# Product CRUD + Barcode Labels Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver Phase 1 remaining #4 — offline product create/edit via outbox `product_upsert`, seed stock for current store only, and barcode label printing through the OS print dialog.

**Architecture:** Mirror `customer_upsert`. Client writes `Products` + optional `ProductStocks` locally and enqueues outbox; NestJS `ProductsService.upsertFromSync` applies Product + create-once stock seed; pull catalog unchanged. Labels: PDF layout (`printing` + `barcode`) → system print dialog.

**Tech Stack:** NestJS, Prisma, Flutter Drift, outbox sync; `printing`, `pdf`, `barcode` (Flutter).

**Spec:** `docs/superpowers/specs/2026-07-24-product-crud-barcode-labels-design.md`

## Global Constraints

- Offline-first: create/edit must work without network.
- Money: integer VND; qty: Decimal string (`"0"`, `"12.5"`).
- Seed stock **only** for `storeId` in payload; no `StockMovement` for catalog seed.
- On update, if `ProductStoreStock` already exists: never overwrite `qty` (optional `minQty` update only).
- Roles: create/edit = `store_manager` | `owner`; cashier = list + print only.
- Reject reasons (exact): `role_forbidden`, `store_forbidden`, `sku_conflict`, `barcode_conflict`, `invalid_product`.
- Outbox entity type: `product_upsert`.
- Do **not** implement groups/categories, unit conversion, hard delete, ESC/POS.
- Branch: prefer `feat/product-crud-barcode-labels` branched from current inventory work (or merge inventory first); do not mix unrelated `.cursor/settings.json` unless asked.

---

## File structure

```text
apps/api/
  prisma/schema.prisma                    # optional: Product.barcode @unique
  prisma/migrations/<ts>_product_barcode_unique/  # only if adding unique
  src/products/products.service.ts        # + upsertFromSync
  src/sync/dto/push-sale.dto.ts           # PushProductUpsertDto
  src/sync/sync.service.ts                # pushProductUpserts
  test/product-upserts.e2e-spec.ts

apps/pos_app/
  pubspec.yaml                            # printing, pdf, barcode
  lib/data/sync/outbox_worker.dart        # product_upsert batch + accept ids
  lib/data/sync/push_sync_result.dart     # acceptedProductUpsertIds (if separate)
  lib/features/products/product_service.dart
  lib/features/products/product_form_sheet.dart
  lib/features/products/barcode_label.dart
  lib/features/products/product_list_page.dart
  lib/features/pos/pos_page.dart          # pass ProductService + role
  test/product_service_test.dart
  test/barcode_label_test.dart            # optional smoke on pdf build

docs/
  superpowers/plans/2026-07-23-phase1-remaining.md
```

---

### Task 1: API — DTO + `upsertFromSync` + push wire + e2e

**Files:**
- Modify: `apps/api/src/sync/dto/push-sale.dto.ts`
- Modify: `apps/api/src/products/products.service.ts`
- Modify: `apps/api/src/sync/sync.service.ts`
- Optional: `apps/api/prisma/schema.prisma` — `barcode String? @unique`
- Create: `apps/api/test/product-upserts.e2e-spec.ts`

**Interfaces:**
- Consumes: `AuthUser`, `PrismaService`, existing `PushSyncDto`
- Produces:
  - `PushProductUpsertDto` + `PushSyncDto.productUpserts`
  - `ProductsService.upsertFromSync(user, dto): Promise<void>` (throws with reason mapped by sync, **or** returns `{ accepted: true } | { accepted: false; reason: string }` — prefer result object like stock-ops)
  - Push response keys: `acceptedProductUpsertIds: string[]`, `rejectedProductUpserts: { id: string; reason: string }[]`

- [ ] **Step 1: Write failing e2e**

Create `apps/api/test/product-upserts.e2e-spec.ts` (pattern from `inventory-stock-ops.e2e-spec.ts`):

```typescript
it('creates product + seeds stock for one store only', async () => {
  const login = await loginAsOwner(app);
  const id = randomUUID();
  const sku = `NEW-${id.slice(0, 8)}`;
  const payload = {
    id,
    sku,
    barcode: null,
    name: 'SP moi',
    unit: 'chai',
    isWeighted: false,
    basePriceVnd: 12000,
    costVnd: 9000,
    active: true,
    storeId: storeCh1,
    seedStock: { qty: '5', minQty: '1' },
  };
  const res = await request(app.getHttpServer())
    .post('/sync/push')
    .set('Authorization', `Bearer ${login.accessToken}`)
    .send({ deviceId: 'prod-1', sales: [], productUpserts: [payload] })
    .expect(201);
  expect(res.body.acceptedProductUpsertIds).toContain(id);
  const product = await prisma.product.findUniqueOrThrow({ where: { id } });
  expect(product.sku).toBe(sku);
  const stock1 = await prisma.productStoreStock.findUnique({
    where: { productId_storeId: { productId: id, storeId: storeCh1 } },
  });
  expect(stock1?.qty.toString()).toBe('5');
  const stock2 = await prisma.productStoreStock.findUnique({
    where: { productId_storeId: { productId: id, storeId: storeCh2 } },
  });
  expect(stock2).toBeNull();
});

it('update without seedStock does not overwrite qty', async () => {
  // create with qty 5, then push update name + omit seedStock; qty stays 5
});

it('update with seedStock when stock exists ignores qty', async () => {
  // create qty 5; second push seedStock qty 99 → still 5; minQty may update
});

it('rejects sku_conflict and role_forbidden', async () => {
  // sku of STING-330 with new id → sku_conflict
  // create Role.cashier user + login → role_forbidden
});

it('idempotent retry accepts same id', async () => {
  // push twice → accepted both times; one Product row; one stock row
});
```

- [ ] **Step 2: Run e2e — expect FAIL**

```bash
cd apps/api && npx jest --config ./test/jest-e2e.json test/product-upserts.e2e-spec.ts
```

Expected: FAIL (DTO/handler missing or empty accepted lists).

- [ ] **Step 3: Add DTO**

In `push-sale.dto.ts`:

```typescript
export type PushProductSeedStockDto = {
  qty: string;
  minQty?: string;
};

export type PushProductUpsertDto = {
  id: string;
  sku: string;
  barcode?: string | null;
  name: string;
  unit: string;
  isWeighted: boolean;
  basePriceVnd: number;
  costVnd?: number;
  active: boolean;
  storeId: string;
  seedStock?: PushProductSeedStockDto | null;
};

// on PushSyncDto:
productUpserts?: PushProductUpsertDto[];
```

- [ ] **Step 4: Implement `ProductsService.upsertFromSync`**

```typescript
async upsertFromSync(
  user: AuthUser,
  dto: PushProductUpsertDto,
): Promise<{ accepted: true } | { accepted: false; reason: string }> {
  // 1) store access: owner OK; else user.storeIds includes dto.storeId → else store_forbidden
  // 2) role: owner | store_manager only → else role_forbidden
  // 3) validate sku/name/unit trim; basePriceVnd/costVnd >= 0 ints; seed qty/minQty >= 0 → else invalid_product
  // 4) sku conflict: findFirst where sku=trim AND id != dto.id → sku_conflict
  // 5) barcode conflict: if barcode trimmed non-empty, findFirst barcode=AND id != → barcode_conflict
  // 6) prisma.$transaction:
  //    upsert Product
  //    if seedStock:
  //      existing = findUnique productId_storeId
  //      if !existing: create qty/minQty
  //      else if seedStock.minQty != null: update minQty only
  // 7) return { accepted: true }
}
```

Map thrown Prisma unique violations to `sku_conflict` / `barcode_conflict` if using `@unique` on barcode.

Optional migration: `barcode String? @unique` on `Product`.

- [ ] **Step 5: Wire `SyncService.push`**

After customer upserts (or nearby):

```typescript
const productResult = await this.pushProductUpserts(
  user,
  body.productUpserts ?? [],
);
// spread ...productResult into return

private async pushProductUpserts(user: AuthUser, upserts: PushProductUpsertDto[]) {
  const acceptedProductUpsertIds: string[] = [];
  const rejectedProductUpserts: { id: string; reason: string }[] = [];
  for (const dto of upserts) {
    const result = await this.productsService.upsertFromSync(user, dto);
    if (result.accepted) acceptedProductUpsertIds.push(dto.id);
    else rejectedProductUpserts.push({ id: dto.id, reason: result.reason });
  }
  return { acceptedProductUpsertIds, rejectedProductUpserts };
}
```

- [ ] **Step 6: Run e2e — expect PASS**

```bash
cd apps/api && npx jest --config ./test/jest-e2e.json test/product-upserts.e2e-spec.ts
```

- [ ] **Step 7: Commit**

```bash
git add apps/api/src/products apps/api/src/sync apps/api/test/product-upserts.e2e-spec.ts apps/api/prisma
git commit -m "$(cat <<'EOF'
feat(api): sync product_upsert with per-store stock seed

EOF
)"
```

---

### Task 2: Flutter — `ProductService` + outbox + unit tests

**Files:**
- Create: `apps/pos_app/lib/features/products/product_service.dart`
- Modify: `apps/pos_app/lib/data/sync/outbox_worker.dart` (+ `PushSyncResult` if defined there)
- Create: `apps/pos_app/test/product_service_test.dart`
- Wire: `main.dart` / `pos_page.dart` constructors as needed

**Interfaces:**
- Consumes: `AppDatabase`, tables `products`, `productStocks`, `outboxEntries`
- Produces:
  - `ProductService.create({...})` / `ProductService.update({...})`
  - Outbox `entityType: 'product_upsert'`, `entityId: productId`
  - Payload JSON matching `PushProductUpsertDto` (include `seedStock` on create; omit on update when stock row exists)

- [ ] **Step 1: Write failing unit test**

```dart
test('create inserts product, stock for store, and product_upsert outbox', () async {
  final service = ProductService(db);
  final id = await service.create(
    storeId: 's1',
    sku: 'ABC-1',
    name: 'Test',
    unit: 'chai',
    isWeighted: false,
    basePriceVnd: 10000,
    costVnd: 7000,
    active: true,
    initialQty: '3',
    minQty: '0',
  );
  final product = await (db.select(db.products)..where((t) => t.id.equals(id))).getSingle();
  expect(product.sku, 'ABC-1');
  final stock = await (db.select(db.productStocks)
        ..where((t) => t.productId.equals(id) & t.storeId.equals('s1')))
      .getSingle();
  expect(stock.qty, '3');
  final outbox = await db.pendingOutbox();
  expect(outbox.single.entityType, 'product_upsert');
  final payload = jsonDecode(outbox.single.payloadJson) as Map<String, dynamic>;
  expect(payload['seedStock']['qty'], '3');
});

test('update changes fields and omits seedStock when stock exists', () async {
  // create then update name/price; outbox payload has no seedStock (or null)
});
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
cd apps/pos_app && flutter test test/product_service_test.dart
```

- [ ] **Step 3: Implement `ProductService`**

```dart
class ProductService {
  ProductService(this._db);
  final AppDatabase _db;

  Future<String> create({
    required String storeId,
    required String sku,
    String? barcode,
    required String name,
    required String unit,
    required bool isWeighted,
    required int basePriceVnd,
    int costVnd = 0,
    bool active = true,
    String initialQty = '0',
    String minQty = '0',
    String? id,
  }) async {
    final productId = id ?? const Uuid().v4();
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await _db.into(_db.products).insert(
        ProductsCompanion.insert(
          id: productId,
          sku: sku.trim(),
          barcode: Value(barcode?.trim().isEmpty == true ? null : barcode?.trim()),
          name: name.trim(),
          unit: unit.trim(),
          isWeighted: isWeighted,
          basePriceVnd: basePriceVnd,
          costVnd: costVnd,
          active: active,
          updatedAt: now,
        ),
      );
      await _db.into(_db.productStocks).insert(
        ProductStocksCompanion.insert(
          productId: productId,
          storeId: storeId,
          qty: initialQty,
          minQty: minQty,
          updatedAt: now,
        ),
      );
      await _db.into(_db.outboxEntries).insert(
        OutboxEntriesCompanion.insert(
          id: const Uuid().v4(),
          entityType: 'product_upsert',
          entityId: productId,
          payloadJson: jsonEncode({
            'id': productId,
            'sku': sku.trim(),
            'barcode': barcode?.trim().isEmpty == true ? null : barcode?.trim(),
            'name': name.trim(),
            'unit': unit.trim(),
            'isWeighted': isWeighted,
            'basePriceVnd': basePriceVnd,
            'costVnd': costVnd,
            'active': active,
            'storeId': storeId,
            'seedStock': {'qty': initialQty, 'minQty': minQty},
          }),
          createdAt: now,
        ),
      );
    });
    return productId;
  }

  Future<void> update({
    required String id,
    required String storeId,
    // same product fields...
  }) async {
    // update products row
    // if no ProductStocks for (id, storeId): insert stock + include seedStock in outbox
    // else: outbox without seedStock
  }
}
```

Align companion field names with generated Drift (`ProductsCompanion`, `ProductStocksCompanion`) — read `tables.dart` / `database.g.dart` before coding.

- [ ] **Step 4: Extend `OutboxWorker`**

- Collect `productUpserts` from `entityType == 'product_upsert'`
- Include in POST body `productUpserts`
- `markOutboxEntitiesDone('product_upsert', result.acceptedProductUpsertIds)`
- Extend `PushSyncResult.fromJson` to parse `acceptedProductUpsertIds` (default `[]`)

- [ ] **Step 5: Run unit tests — PASS**

```bash
cd apps/pos_app && flutter test test/product_service_test.dart
```

- [ ] **Step 6: Commit**

```bash
git add apps/pos_app/lib/features/products/product_service.dart apps/pos_app/lib/data/sync apps/pos_app/test/product_service_test.dart
git commit -m "$(cat <<'EOF'
feat(pos): product create/update with product_upsert outbox

EOF
)"
```

---

### Task 3: Flutter UI — form create/edit + role gate

**Files:**
- Create: `apps/pos_app/lib/features/products/product_form_sheet.dart`
- Modify: `apps/pos_app/lib/features/products/product_list_page.dart`
- Modify: `apps/pos_app/lib/features/pos/pos_page.dart` (pass `ProductService`, `canEditCatalog`)
- Modify: DI in `main.dart` / login navigation as needed

**Interfaces:**
- Consumes: `ProductService`, `ProductRepository`, `user.role` (`owner` | `store_manager` → can edit)
- Produces: FAB Thêm + tap row → sheet; cashier sees list only (no FAB / no edit on tap — tap may open read-only or print only)

- [ ] **Step 1: `ProductFormSheet`**

Bottom sheet / dialog with controllers for: sku*, barcode, name*, unit*, isWeighted switch, basePriceVnd*, costVnd, active switch; if `isCreate`: initialQty (default 0), minQty (default 0).

On save → `create` or `update` → `Navigator.pop(true)`.

- [ ] **Step 2: Extend `ProductListPage`**

Constructor add: `ProductService productService`, `bool canEditCatalog`.

- AppBar: keep sync.
- `floatingActionButton`: if `canEditCatalog` → Thêm → open form create.
- List tile `onTap`: if can edit → form update (prefill from `ProductWithStock`); else no-op or show snackbar.

- [ ] **Step 3: Wire from POS**

```dart
ProductListPage(
  repository: widget.productRepository,
  pullCatalog: widget.pullCatalog,
  storeId: widget.storeId,
  productService: widget.productService,
  canEditCatalog: widget.role == 'owner' || widget.role == 'store_manager',
)
```

Ensure `role` string available on `PosPage` (from login session — reuse existing field if present; otherwise pass from auth).

- [ ] **Step 4: Manual smoke** (or light widget test optional)

Open Hàng hóa as owner → Thêm → save → row appears with qty.

- [ ] **Step 5: Commit**

```bash
git add apps/pos_app/lib/features/products apps/pos_app/lib/features/pos apps/pos_app/lib/main.dart
git commit -m "$(cat <<'EOF'
feat(pos): product create/edit UI with role gate

EOF
)"
```

---

### Task 4: Barcode label PDF + print

**Files:**
- Modify: `apps/pos_app/pubspec.yaml` — add `printing: ^5.x`, `pdf: ^3.x`, `barcode: ^2.x` (compatible versions)
- Create: `apps/pos_app/lib/features/products/barcode_label.dart`
- Modify: `product_list_page.dart` / form — **In tem** action
- Create: `apps/pos_app/test/barcode_label_test.dart`

**Interfaces:**
- Produces: `Future<Uint8List> buildProductLabelPdf({required String title, required String priceLabel, required String code, required int copies})`
- `Future<void> printProductLabels(...)` → `Printing.layoutPdf(onLayout: ...)`

- [ ] **Step 1: Add deps**

```bash
cd apps/pos_app && flutter pub add printing pdf barcode
```

- [ ] **Step 2: Failing test — PDF builds non-empty bytes**

```dart
test('buildProductLabelPdf returns non-empty pdf', () async {
  final bytes = await buildProductLabelPdf(
    title: 'Sting do 330ml',
    priceLabel: '10.000đ',
    code: '8934588012345',
    copies: 1,
  );
  expect(bytes.length, greaterThan(100));
});
```

- [ ] **Step 3: Implement label layout**

Small page (e.g. 50×30mm or A4 with N labels): barcode from `code` (Code128); if `code` empty use SKU as text-only + human-readable; name truncated; price line.

Use `pw.BarcodeWidget` / `barcode` package per current `pdf` docs.

- [ ] **Step 4: UI entry**

On list tile trailing IconButton print, or form button **In tem**: dialog copies 1–20 → `Printing.layoutPdf`.

- [ ] **Step 5: `flutter test test/barcode_label_test.dart` — PASS**

- [ ] **Step 6: Commit**

```bash
git add apps/pos_app/pubspec.yaml apps/pos_app/pubspec.lock apps/pos_app/lib/features/products apps/pos_app/test/barcode_label_test.dart
git commit -m "$(cat <<'EOF'
feat(pos): print barcode labels via system dialog

EOF
)"
```

---

### Task 5: Checklist + CHANGELOG

**Files:**
- Modify: `docs/superpowers/plans/2026-07-23-phase1-remaining.md`
- Modify: `CHANGELOG-vi.md` (if project keeps one — follow existing style)

- [x] Tick:
  - [x] Full product CRUD UI (create/edit on client + sync push)
  - [x] Barcode label printing
  - [x] Product/stock push from client (not only pull) — under Sync & ops
- Leave unchecked: Product groups / categories; Unit conversion
- Update suggested order note for #4 done

- [x] Commit docs

```bash
git add docs/superpowers/plans/2026-07-23-phase1-remaining.md CHANGELOG-vi.md
git commit -m "$(cat <<'EOF'
docs: mark product CRUD + barcode labels done in Phase 1 remaining

EOF
)"
```

---

## Spec coverage (self-review)

| Spec requirement | Task |
|---|---|
| Outbox `product_upsert` + push/pull | 1, 2 |
| Seed stock current store only | 1, 2 |
| No StockMovement on seed | 1 (assert no movement row in e2e optional) |
| Update does not overwrite qty | 1, 2 |
| Role gate manager/owner | 1, 3 |
| Soft active flag | 2, 3 (form field) |
| OS print dialog labels | 4 |
| No groups / unit conversion / ESC/POS | Global — not in tasks |
| Checklist ticks | 5 |

**Type consistency:** `seedStock.qty` / `minQty` as **strings** everywhere (API + Flutter). Response keys `acceptedProductUpsertIds` / `rejectedProductUpserts` shared by API e2e and `PushSyncResult`.
