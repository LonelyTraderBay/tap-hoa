# Thermal Receipt PDF + Top SKU Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver Phase 1 remaining #5 — PDF receipt print after checkout (prompt Có/Không) and Top 10 SKU section on day report (qty rank + estimated gross).

**Architecture:** NestJS `GET /reports/top-skus` reuses ICT date helpers from `ReportsService`; Flutter offline fallback aggregates Drift `saleLinesLocal`⋈`salesLocal`⋈`products`. Receipt PDF via existing `printing`/`pdf` packages; hook after `CheckoutService.complete` in `PaymentSheet`. No ESC/POS, no schema migration.

**Tech Stack:** NestJS, Prisma, Flutter, Drift, `printing` + `pdf`

**Spec:** `docs/superpowers/specs/2026-07-24-thermal-receipt-top-sku-design.md`

## Global Constraints

- Money: integer VND; qty may be Decimal/string — sum/compare carefully (API: Prisma Decimal → number).
- ICT day boundaries: reuse `parseDateRange` / `ictDayRangeUtc` (UTC+7).
- Rank: qty DESC, then revenueVnd DESC; default limit 10, max 50.
- `estimatedGrossVnd = revenueVnd - qty * costVnd`; product `costVnd` null → item `estimatedGrossVnd: null`.
- ESC/POS out of scope; receipt errors must not rollback sale.
- Roles/store access: identical to `dayReport`.

## File map

| File | Role |
|------|------|
| `apps/api/src/reports/reports.service.ts` | `topSkus(...)` |
| `apps/api/src/reports/reports.controller.ts` | `GET top-skus` |
| `apps/api/test/reports.e2e-spec.ts` | e2e top-skus |
| `apps/pos_app/lib/features/reports/day_report_repository.dart` | `TopSku*` types + `fetchTopSkus` (+ offline) |
| `apps/pos_app/lib/features/reports/day_report_page.dart` | Top section UI |
| `apps/pos_app/test/day_report_repository_test.dart` | offline top SKU tests |
| `apps/pos_app/lib/features/pos/receipt_print.dart` | PDF + prompt |
| `apps/pos_app/lib/features/pos/payment_sheet.dart` | post-checkout hook |
| `apps/pos_app/test/receipt_print_test.dart` | PDF bytes smoke |
| `docs/superpowers/plans/2026-07-23-phase1-remaining.md` | tick checklist |

---

### Task 1: API `GET /reports/top-skus` + e2e

**Files:**
- Modify: `apps/api/src/reports/reports.service.ts`
- Modify: `apps/api/src/reports/reports.controller.ts`
- Modify: `apps/api/test/reports.e2e-spec.ts`

**Interfaces:**
- Produces: `ReportsService.topSkus(user, date, storeId?, limit?): Promise<{ date: string; items: TopSkuItem[] }>`
- `TopSkuItem`: `{ productId, sku, name, qty: number, revenueVnd: number, estimatedGrossVnd: number | null }`

- [ ] **Step 1: Add failing e2e** — seed two products with costs; push sales with different qtys same ICT day; assert order by qty and `estimatedGrossVnd`; one product without cost → null gross.

- [ ] **Step 2: Implement service** — find sale lines via:

```typescript
const lines = await this.prisma.saleLine.findMany({
  where: {
    sale: {
      storeId: { in: storeIds },
      clientCreatedAt: { gte: start, lt: end },
    },
  },
  select: {
    productId: true,
    qty: true,
    lineTotal: true,
    product: { select: { sku: true, name: true, costVnd: true } },
  },
});
```

Aggregate in memory by `productId` (qty sum as number from Decimal, revenue sum). Sort + slice. Clamp limit: `Math.min(Math.max(limit ?? 10, 1), 50)`.

- [ ] **Step 3: Controller**

```typescript
@Get('top-skus')
topSkus(
  @Req() req: { user: AuthUser },
  @Query('date') date?: string,
  @Query('storeId') storeId?: string,
  @Query('limit') limitRaw?: string,
) {
  if (!date) throw new BadRequestException('date is required');
  const limit = limitRaw == null ? 10 : Number(limitRaw);
  if (!Number.isInteger(limit) || limit < 1) {
    throw new BadRequestException('limit must be a positive integer');
  }
  return this.reportsService.topSkus(req.user, date, storeId, limit);
}
```

- [ ] **Step 4: Run** `cd apps/api && npm test -- reports.e2e-spec` — expect PASS

- [ ] **Step 5: Commit** `feat(api): GET /reports/top-skus theo qty + lãi ước tính`

---

### Task 2: Flutter top SKU repository + DayReportPage section

**Files:**
- Modify: `apps/pos_app/lib/features/reports/day_report_repository.dart`
- Modify: `apps/pos_app/lib/features/reports/day_report_page.dart`
- Modify: `apps/pos_app/test/day_report_repository_test.dart`

**Interfaces:**
- Produces: `DayReportRepository.fetchTopSkus({ required DateTime date, String? storeId, int limit = 10 }) → Future<TopSkuReport>`
- `TopSkuReport({ required List<TopSkuItem> items, required bool isOffline })`

- [ ] **Step 1: Failing test** — seed product + sale + sale lines; mock Dio connectionTimeout on `/reports/top-skus`; assert offline items sorted by qty and gross.

- [ ] **Step 2: Implement fetch + offline aggregate** — online `GET /reports/top-skus`; offline: sales in ICT range for current/meta store → lines → join products → sort/limit; `qty` from `double.parse` / num on line.

- [ ] **Step 3: UI** — in `_loadReport`, also `fetchTopSkus` (same storeId rule as day); show section “Top hàng bán chạy” under revenue; rows `#rank name`, `qty`, revenue, lãi (or “—”); empty → “Chưa có bán trong ngày”.

- [ ] **Step 4: Run** `flutter test test/day_report_repository_test.dart` — PASS

- [ ] **Step 5: Commit** `feat(pos): top SKU trên báo cáo ngày (online + offline)`

---

### Task 3: Receipt PDF + PaymentSheet prompt

**Files:**
- Create: `apps/pos_app/lib/features/pos/receipt_print.dart`
- Modify: `apps/pos_app/lib/features/pos/payment_sheet.dart`
- Create: `apps/pos_app/test/receipt_print_test.dart`

**Interfaces:**
- Produces: `Future<Uint8List> buildReceiptPdf({ required String storeName, required String saleId, required DateTime soldAt, required List<ReceiptLine> lines, required int totalVnd, required int cashVnd, required int transferVnd, required int debtVnd, String? customerName })`
- Produces: `Future<void> promptAndPrintReceipt(BuildContext context, { ... same fields ... })` — `showDialog` Có/Không → `Printing.layoutPdf`

`ReceiptLine`: `{ name, qtyLabel, unitPriceVnd, lineTotalVnd }`

- [ ] **Step 1: Test** — `buildReceiptPdf` returns non-empty bytes for sample lines.

- [ ] **Step 2: Implement PDF** — page width `PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 4)`; monospace-ish `pw.Text` stack; truncate names ~24 chars; format VND with dots.

- [ ] **Step 3: Hook PaymentSheet** — capture `saleId` from `complete`; pop sheet; resolve `storeName` from caller props **or** pass `storeName` into `PaymentSheet` / `show` from `PosPage` (prefer add optional `storeName` + optional `customerName` from selected customer); then:

```dart
final saleId = await widget.checkoutService.complete(...);
if (!mounted) return;
Navigator.of(context).pop();
await promptAndPrintReceipt(
  context, // use parent: after pop, use root navigator context carefully — call prompt BEFORE pop, or pass BuildContext from PosPage via callback
  ...
);
widget.onCompleted();
```

**Preferred hook order (avoid disposed context):** ask print **before** `Navigator.pop` of the sheet (dialog overlays sheet), then pop, then `onCompleted`. Or change `onCompleted` to `FutureOr<void> Function(String saleId)` and print from `PosPage`. Use **print before pop** for minimal API churn:

```dart
final saleId = await widget.checkoutService.complete(...);
if (!mounted) return;
final lines = widget.cart.lines.map((l) => ReceiptLine(...)).toList();
await promptAndPrintReceipt(context, saleId: saleId, lines: lines, ...);
if (!mounted) return;
Navigator.of(context).pop();
widget.onCompleted();
```

Pass `storeName` into `PaymentSheet` from `PosPage` (already has store).

- [ ] **Step 4: Run** `flutter test test/receipt_print_test.dart` + analyze payment_sheet — PASS

- [ ] **Step 5: Commit** `feat(pos): hỏi in hóa đơn PDF sau thanh toán`

---

### Task 4: Checklist + plan docs

**Files:**
- Modify: `docs/superpowers/plans/2026-07-23-phase1-remaining.md` — tick Top SKU; leave Thermal ESC/POS drivers `[ ]`; note PDF receipt done in comment or add line “PDF receipt via OS print — done”
- This plan file already at `docs/superpowers/plans/2026-07-24-thermal-receipt-top-sku.md`

- [ ] Update remaining checklist suggested order (mark #5 done)
- [ ] Commit `docs: tick Phase 1 #5 PDF receipt + top SKU`

---

## Spec coverage (self-review)

| Spec item | Task |
|-----------|------|
| PDF ~58mm + printing package | Task 3 |
| Hỏi In hóa đơn? | Task 3 |
| No ESC/POS | Global + Task 4 |
| GET /reports/top-skus | Task 1 |
| Rank qty + gross | Task 1–2 |
| Section on DayReportPage | Task 2 |
| Offline fallback | Task 2 |
| No schema change | Global |
| e2e + flutter tests | Task 1–3 |
