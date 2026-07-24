# Stock-on-hand Report Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver Phase 1 stock-on-hand report — per-store current stock list with estimated value (qty × costVnd), filters, API + offline Drift, entries from Inventory hub and Day report.

**Architecture:** NestJS `GET /reports/stock-on-hand?storeId=` reuses store access helpers from `ReportsService`. Flutter `StockOnHandRepository` mirrors day/top-sku online→offline pattern. Client-side filters (hide qty=0, below-min, search). UI page shared; primary entry InventoryHub, secondary link DayReportPage.

**Tech Stack:** NestJS, Prisma, Flutter, Drift, Dio

**Spec:** `docs/superpowers/specs/2026-07-24-stock-on-hand-report-design.md`

## Global Constraints

- `storeId` query **required** (400 if missing); `assertStoreAccess` like day report.
- Only `product.active = true` rows with `ProductStoreStock` for that store.
- `estimatedValueVnd = Math.round(qty * costVnd)`; `belowMin = qty < minQty`.
- Server returns full list sorted: belowMin first, then name ASC; `totalEstimatedValueVnd` = sum of all item values.
- Client filters: default hide qty==0; toggles “Hiện hết” / “Dưới định mức”; search name/SKU.
- Offline: Drift `productStocks` ⋈ `products` for given storeId; banner `isOffline`.
- No CSV, no multi-store aggregate table, no schema migration, no debt aging.
- Entry: Kho primary + DayReport link.

## File map

| File | Role |
|------|------|
| `apps/api/src/reports/reports.service.ts` | `stockOnHand(user, storeId)` |
| `apps/api/src/reports/reports.controller.ts` | `GET stock-on-hand` |
| `apps/api/test/reports.e2e-spec.ts` | e2e |
| `apps/pos_app/lib/features/reports/stock_on_hand_repository.dart` | types + fetch + offline |
| `apps/pos_app/lib/features/reports/stock_on_hand_page.dart` | UI + client filters |
| `apps/pos_app/lib/features/inventory/inventory_hub_page.dart` | entry |
| `apps/pos_app/lib/features/reports/day_report_page.dart` | link |
| `apps/pos_app/test/stock_on_hand_repository_test.dart` | unit |
| `docs/superpowers/plans/2026-07-23-phase1-remaining.md` | tick checklist |

---

### Task 1: API `GET /reports/stock-on-hand` + e2e

**Files:** `reports.service.ts`, `reports.controller.ts`, `reports.e2e-spec.ts`

**Interfaces:**
- `StockOnHandItem`: `{ productId, sku, name, unit, qty: number, minQty: number, costVnd: number, estimatedValueVnd: number, belowMin: boolean }`
- `StockOnHandResponse`: `{ storeId, items, totalEstimatedValueVnd }`
- `ReportsService.stockOnHand(user, storeId: string): Promise<StockOnHandResponse>`

- [ ] **Step 1:** Failing e2e — two products with stock at CH1 (one below min); assert values, belowMin, sort; missing storeId → 400; forbidden store → 403

- [ ] **Step 2:** Service implementation:

```typescript
async stockOnHand(user: AuthUser, storeId: string): Promise<StockOnHandResponse> {
  this.assertStoreAccess(user, storeId);
  const rows = await this.prisma.productStoreStock.findMany({
    where: { storeId, product: { active: true } },
    include: { product: { select: { id: true, sku: true, name: true, unit: true, costVnd: true } } },
  });
  const items = rows.map((row) => {
    const qty = Number(row.qty);
    const minQty = Number(row.minQty);
    const estimatedValueVnd = Math.round(qty * row.product.costVnd);
    return {
      productId: row.productId,
      sku: row.product.sku,
      name: row.product.name,
      unit: row.product.unit,
      qty,
      minQty,
      costVnd: row.product.costVnd,
      estimatedValueVnd,
      belowMin: qty < minQty,
    };
  });
  items.sort((a, b) => {
    if (a.belowMin !== b.belowMin) return a.belowMin ? -1 : 1;
    return a.name.localeCompare(b.name, 'vi');
  });
  const totalEstimatedValueVnd = items.reduce((s, i) => s + i.estimatedValueVnd, 0);
  return { storeId, items, totalEstimatedValueVnd };
}
```

- [ ] **Step 3:** Controller — require `storeId`

- [ ] **Step 4:** `npm run test:e2e -- reports.e2e-spec` — PASS

- [ ] **Step 5:** Commit `feat(api): GET /reports/stock-on-hand theo store`

**Note:** Confirm Prisma `ProductStoreStock` has `product` relation; if not, two-step fetch like top-skus.

---

### Task 2: Flutter repository + page + filters

**Files:** `stock_on_hand_repository.dart`, `stock_on_hand_page.dart`, `stock_on_hand_repository_test.dart`

**Interfaces:**
- `StockOnHandRepository.fetch({required String storeId}) → Future<StockOnHandReport>`
- `StockOnHandReport({ storeId, items, totalEstimatedValueVnd, isOffline })`
- Pure helper optional: `List<StockOnHandItem> applyStockOnHandFilters(items, {query, belowMinOnly, showZero})` for testable filter defaults

- [ ] **Step 1:** Failing tests — offline timeout → local aggregate; filter hide zero / belowMin / search

- [ ] **Step 2:** Implement repository (Dio + Drift)

- [ ] **Step 3:** `StockOnHandPage` — total header, switches, search, list, offline banner; constructor `storeId`, `role`, optional `stores` for owner dropdown, `repository`

- [ ] **Step 4:** `flutter test test/stock_on_hand_repository_test.dart` — PASS; analyze clean

- [ ] **Step 5:** Commit `feat(pos): màn tồn hiện tại online + offline`

---

### Task 3: Entry points Kho + DayReport

**Files:** `inventory_hub_page.dart`, `day_report_page.dart` (and PosPage wiring if DayReport needs extra args)

- [ ] **Step 1:** InventoryHub — button/tab **Tồn hiện tại** → push `StockOnHandPage` with storeId from hub session + repository(dio, db)

- [ ] **Step 2:** DayReportPage — link **Xem tồn hiện tại** → same page (`storeId`: owner may use first byStore or current storeId from widget)

- [ ] **Step 3:** Analyze; commit `feat(pos): lối vào tồn hiện tại từ Kho và Báo cáo ngày`

**Wiring note:** Pass `Dio`/`AppDatabase` into InventoryHub/DayReport if not already available — follow existing pattern for DayReportRepository construction from PosPage.

---

### Task 4: Checklist

**Files:** `docs/superpowers/plans/2026-07-23-phase1-remaining.md`

- [ ] Tick “Stock-on-hand report per store”
- [ ] Suggested order note item 7 done
- [ ] Commit `docs: tick báo cáo tồn hiện tại trên Phase 1 remaining`

---

## Spec coverage

| Spec | Task |
|------|------|
| GET stock-on-hand + math/sort | 1 |
| Offline Drift | 2 |
| Filters default A | 2 |
| Kho + DayReport entry | 3 |
| Checklist | 4 |
| No CSV/aging | Global |
