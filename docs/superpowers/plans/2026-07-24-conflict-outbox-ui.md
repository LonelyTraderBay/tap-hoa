# Conflict Outbox UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver Phase 1 conflict UI — list rejected outbox entries, retry one/all, friendly edit for stock/SKU conflicts + raw JSON editor for all entity types; POS badge + menu entry.

**Architecture:** Flutter-only on Drift `OutboxEntries`. `OutboxConflictService` owns reason map, requeue, payload updates, and selective local entity sync. UI pages under `features/sync/`. Reuse existing `OutboxWorker.tick()` after requeue. Prefer extending `AppDatabase` helpers + existing `watchSyncStatus()` for error count badge.

**Tech Stack:** Flutter, Drift, existing OutboxWorker

**Spec:** `docs/superpowers/specs/2026-07-24-conflict-outbox-ui-design.md`

## Global Constraints

- No Bỏ qua / delete outbox entries.
- No new NestJS conflict API.
- Retry: `status=pending`, `lastError=null`, then `tick()`.
- Friendly edit A1: `insufficient_stock` on `sale` / `wastage` / stock_transfer_* qty lines — update payload + local when safe; else JSON-only + warning.
- Friendly edit A2: `sku_conflict` / `barcode_conflict` on `product_upsert` — update payload + `products` row.
- All entityTypes: raw JSON editor (valid JSON object) → payload only → requeue; snackbar warns local tables not auto-updated.
- Entry: AppBar badge (error count) + “Đồng bộ lỗi” menu item near Kho.
- Vietnamese reason map per spec §4.6; unknown codes pass through.
- No schemaVersion bump unless a helper needs new columns (not expected).

## File map

| File | Role |
|------|------|
| `apps/pos_app/lib/data/local/database.dart` | `requeueOutbox`, `listOutboxErrors`, `watchOutboxErrorCount` (or reuse `watchSyncStatus`) |
| `apps/pos_app/lib/features/sync/outbox_reason_labels.dart` | reason + entityType VN maps |
| `apps/pos_app/lib/features/sync/outbox_conflict_service.dart` | requeue / edit / tick orchestration |
| `apps/pos_app/lib/features/sync/outbox_conflicts_page.dart` | list UI |
| `apps/pos_app/lib/features/sync/outbox_edit_sheet.dart` | friendly + JSON sheets |
| `apps/pos_app/lib/features/pos/pos_page.dart` | badge + menu |
| `apps/pos_app/test/outbox_conflict_service_test.dart` | unit tests |
| `docs/superpowers/plans/2026-07-23-phase1-remaining.md` | tick conflict UI |

---

### Task 1: DB helpers + reason labels + service (TDD)

**Files:**
- Modify: `apps/pos_app/lib/data/local/database.dart`
- Create: `apps/pos_app/lib/features/sync/outbox_reason_labels.dart`
- Create: `apps/pos_app/lib/features/sync/outbox_conflict_service.dart`
- Create: `apps/pos_app/test/outbox_conflict_service_test.dart`

**Interfaces:**
- `String labelOutboxReason(String? code)`
- `String labelEntityType(String entityType)`
- `OutboxConflictService({required AppDatabase db, required OutboxWorker worker})`
- `Future<List<OutboxEntry>> listErrors()`
- `Future<void> retry(String outboxRowId)` / `retryAll()`
- `Future<void> saveRawJson(String outboxRowId, String jsonText)` — throws on invalid JSON / non-object
- `Future<void> saveProductUpsertIdentity({required String outboxRowId, required String sku, String? barcode})`
- `Future<void> saveInsufficientStockQtys({required String outboxRowId, required Map<String, String> productIdToQty})` — updates payload lines; for `sale`/`wastage` also adjust `saleLinesLocal`/`wastageLinesLocal` + `productStocks` by qty delta when rows exist; if entity unsupported → throw `StateError('use_raw_json')` or apply payload-only and return a flag `localSynced: false`

**Note on outbox PK:** `OutboxEntries.id` is the outbox row id (often same as entity id in payloads — verify inserts). `markOutboxError` matches `payload['id']`. Requeue should update by **outbox row primary key** `OutboxEntries.id`. List UI uses that row id for actions.

- [ ] **Step 1:** Failing tests — reason map; requeue clears error; invalid JSON rejected; product_upsert sku updates products + payload; sale insufficient_stock qty change updates line + stock delta.

- [ ] **Step 2:** Implement DB:

```dart
Future<void> requeueOutbox(String outboxId) async {
  await (update(outboxEntries)..where((r) => r.id.equals(outboxId))).write(
    const OutboxEntriesCompanion(
      status: Value('pending'),
      lastError: Value(null),
    ),
  );
}

Future<List<OutboxEntry>> listOutboxErrors() {
  return (select(outboxEntries)
        ..where((r) => r.status.equals('error'))
        ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
      .get();
}

Stream<int> watchOutboxErrorCount() {
  return (select(outboxEntries)..where((r) => r.status.equals('error')))
      .watch()
      .map((rows) => rows.length);
}
```

Also `updateOutboxPayload(String outboxId, String payloadJson)`.

- [ ] **Step 3:** Implement service methods; after successful edit/requeue call `await worker.tick()`.

- [ ] **Step 4:** `flutter test test/outbox_conflict_service_test.dart` — PASS

- [ ] **Step 5:** Commit `feat(pos): service Conflict UI — requeue, sửa payload, reason VN`

**Pragmatic A1 stock delta (sale):**
- Parse payload `lines`; for each productId with newQty: find `saleLinesLocal` by saleId+productId; oldQty = parse(line.qty); delta = newQty - oldQty; update line qty + lineTotal (= qty * unitPrice rounded); `productStocks` qty -= delta (sale decreases stock further if qty↑). Recalc sale `totalVnd` / payment fields proportionally OR keep payment split and only fix line totals + totalVnd (prefer update `totalVnd` = sum lines; leave cash/transfer/debt as-is if they still sum — if mismatch, set cashAmount = totalVnd, others 0 for retry simplicity — **document in code comment**).

**Wastage:** similar on wastage lines; stock += delta when wastage qty decreases.

**stock_transfer_***: if create payload has lines — update transfer lines local + stock if already applied; if unsure → `use_raw_json` path only in Phase 1 (acceptable per spec fallback).

---

### Task 2: Conflicts page + edit sheets

**Files:**
- Create: `apps/pos_app/lib/features/sync/outbox_conflicts_page.dart`
- Create: `apps/pos_app/lib/features/sync/outbox_edit_sheet.dart`

**Interfaces:**
- `OutboxConflictsPage({required OutboxConflictService service})`
- Edit sheet chooses mode: if A2 reasons → identity fields; else if A1 + supported entity → qty list; always offer “Sửa JSON” secondary action.

- [ ] **Step 1:** List from `service.listErrors()`; pull-to-refresh; empty copy “Không có lỗi đồng bộ”
- [ ] **Step 2:** Row actions Sửa / Thử lại; AppBar Thử lại tất cả
- [ ] **Step 3:** Edit sheet UX + validation messages VN
- [ ] **Step 4:** `flutter analyze` on new files — clean
- [ ] **Step 5:** Commit `feat(pos): màn Đồng bộ lỗi + sửa payload`

---

### Task 3: POS badge + menu entry

**Files:**
- Modify: `apps/pos_app/lib/features/pos/pos_page.dart`

- [ ] **Step 1:** `StreamBuilder` / listen `watchOutboxErrorCount()` — badge on `Icons.sync_problem` (hide badge when 0; icon still visible or only show icon when >0 — **show icon always when count>0**, optional always-visible muted icon; prefer **icon+badge only when count > 0** to reduce clutter)
- [ ] **Step 2:** TextButton/Icon “Đồng bộ lỗi” next to Kho (or PopupMenu) → push `OutboxConflictsPage` with `OutboxConflictService(db: database, worker: outboxWorker)`
- [ ] **Step 3:** Manual smoke via analyze; commit `feat(pos): badge + lối vào Đồng bộ lỗi`

---

### Task 4: Checklist

**Files:**
- Modify: `docs/superpowers/plans/2026-07-23-phase1-remaining.md`

- [ ] Tick “Conflict resolution UI for rejected outbox entries”
- [ ] Add suggested order item 6 done note
- [ ] Commit `docs: tick Conflict UI outbox trên Phase 1 remaining`

---

## Spec coverage

| Spec | Task |
|------|------|
| List + VN reasons | 1–2 |
| Retry one/all | 1–2 |
| Friendly A1/A2 + JSON | 1–2 |
| No dismiss | Global |
| Badge + menu | 3 |
| Checklist | 4 |
| Unit tests | 1 |
