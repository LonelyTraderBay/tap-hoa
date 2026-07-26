# Hoàn thiện gap design §4/§5 — Kế hoạch theo thứ tự ưu tiên

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans`. Thực hiện **một Wave / một Task tại một thời điểm**. Epic lớn (PO, sổ cái, HĐĐT gộp/điều chỉnh) → viết **plan con TDD** trước khi code.  
> Checklist nguồn: đối chiếu `docs/superpowers/specs/2026-07-23-tap-hoa-pos-ke-toan-design.md` §4–§5 với `main` @ `01f020f`.  
> Go-live ops đã có: `docs/superpowers/plans/2026-07-25-hoan-thien-con-lai.md` (operator A.2–A.5 / B.1 vẫn cần người).

**Goal:** Đưa các bullet §4/§5 đang 🟡/❌ lên ✅ theo thứ tự ảnh hưởng quầy → kế toán → HĐĐT → audit, không mở YAGNI §7.

**Architecture:** Flutter POS (`apps/pos_app`) + Nest/Prisma API (`apps/api`). Offline-first: mọi chứng từ mới phải Drift + outbox + sync DTO + e2e khi đụng server. Journal mới bám `LedgerService` / `journal-builders` + period lock + replay unlock.

**Tech Stack:** Flutter 3 + Drift; NestJS 10 + Prisma + PostgreSQL; HĐĐT stub|http; WAC (không chuyển FIFO).

**Trạng thái (2026-07-25, Waves 0–9 in-repo trên `feat/design-gaps-hoan-thien`):**

| Hạng mục | Status |
|----------|--------|
| Wave 0 in-repo (checklist + ops docs) | **Done** |
| Wave 0 VPS / smoke thật (A.2–A.5, B.1) | **Chưa** (operator) |
| Wave 1 — POS giỏ + barcode | **Done** in-repo |
| Wave 2 — Bán cân | **Done** in-repo |
| Wave 3 — Transfer journals | **Done** in-repo |
| Wave 4 — Sổ cái | **Done** in-repo |
| Wave 5 — PO | **Done** in-repo |
| Wave 5b — Đối chiếu sao kê NCC | **Deferred** (optional) |
| Wave 6 — HĐĐT gộp + điều chỉnh | **Done** in-repo |
| Wave 7 — Audit | **Done** in-repo |
| Wave 8 — Báo cáo | **Done** in-repo |
| Wave 9.1 Store CRUD / 9.2 push nợ lớn | **Done** in-repo |
| Wave 9.3 camera / 9.4 tách quyền | **Skipped** |
| PR #18 | **Merged via #18** vào `main` (`ab65fcc`) |
| **Kế hoạch tiếp (vận hành)** | `docs/superpowers/plans/2026-07-25-hoan-thien-van-hanh.md` |

## Global Constraints

- Không nộp CQT; không SDK Viettel/MISA nếu HTTP gateway đủ (trừ Wave H khi operator yêu cầu).
- Không `npm audit fix --force`.
- Thay đổi sổ / sync → e2e; Flutter → `flutter analyze` sạch trên path đụng.
- Seed `0900000001`/`123456` chỉ dev/test.
- Prod: `JWT_SECRET` ≥ 32 bytes; `NODE_ENV=production`; chỉ `prisma migrate deploy`.
- Một phương pháp giá vốn: **WAC** (đã chốt).
- Không làm: website bán, loyalty, HR, chuỗi > ~10 điểm.

---

## Bản đồ file / khu vực

| Wave | Mục tiêu | Files neo |
|------|----------|-----------|
| 0 | Operator go-live (không code) | `docs/ops/go-live-checklist.md` |
| 1 | POS UX giỏ + tìm barcode | `pos_page.dart`, `cart.dart` |
| 2 | Bán cân (qty thập phân UI) | `pos_page.dart`, `cart.dart` |
| 3 | Journal chuyển kho | `ledger/*`, `stock-ops.service.ts` |
| 4 | Sổ cái theo TK | `ledger.service.ts`, `ledger_page.dart` |
| 5 | PurchaseOrder + nhập từ PO | Prisma + inventory hub |
| 6 | HĐĐT gộp khách + điều chỉnh | `einvoice/*`, Flutter |
| 7 | Audit sửa giá / xóa đơn / điều chỉnh nợ | `AuditLog`, API + UI |
| 8 | Báo cáo còn thiếu (ca, nợ tổng, AR) | `reports/*`, Flutter |
| 9 | Polish nhỏ (CRUD store, push nợ lớn, FCM) | optional |

---

## Thứ tự ưu tiên (tóm tắt)

```text
Wave 0  Operator prod + smoke 2 máy          [P0 — mở quán; song song với code]
Wave 1  POS: sửa SL / xóa dòng / tìm barcode [P0 — ma sát quầy mỗi ngày]
Wave 2  POS: bán hàng cân (nhập kg)          [P1]
Wave 3  Journal chuyển kho                   [P1 kế toán]
Wave 4  Sổ cái theo tài khoản                [P1 kế toán]
Wave 5  Đơn đặt hàng NCC (PO)                [P2]
Wave 6  HĐĐT gộp theo khách + điều chỉnh     [P2]
Wave 7  Audit nghiệp vụ (giá / xóa đơn / nợ) [P2]
Wave 8  Báo cáo: theo ca, nợ tổng, AR export [P2]
Wave 9  Polish: store CRUD, push nợ lớn      [P3]
```

**Không** bắt Wave 5–9 khi Wave 1 chưa xong (quầy vẫn khó dùng).  
Wave 0 operator có thể chạy **song song** mọi wave code.

---

## Wave 0 — Operator go-live (P0, không chặn code Wave 1)

> **In-repo:** Done (checklist + ops docs). **Operator còn lại:** A.2–A.5 trên VPS, B.1 smoke 2 máy.

**DoD:** API prod healthy; owner thật; backup restore thử; ≥1 máy POS bán+sync; khuyến nghị smoke 2 máy.

Checklist: `docs/ops/go-live-checklist.md`, `production-secrets.md`, `production-deploy.md`, `smoke-multi-device.md`, `windows-prod.md`, `android-release.md`, `einvoice-http.md`.

- [ ] Push `main` nếu còn ahead `origin` (`git push origin main`)
- [ ] A.2–A.5: JWT, migrate, create-owner, backup, HĐĐT stub|http, POS `API_URL`
- [ ] B.1: smoke 2 máy offline→online

---

## Wave 1 — POS giỏ hàng + barcode search (P0)

**DoD:** Trên màn Bán hàng: sửa SL dòng, xóa dòng, tìm theo barcode/SKU/tên; cart unit tests; không phá discount dòng/HĐ.

### Task 1.1: Sửa SL + xóa dòng trên giỏ

**Files:**
- Modify: `apps/pos_app/lib/features/pos/cart.dart` (đã có `update`/`remove` — wire UI)
- Modify: `apps/pos_app/lib/features/pos/pos_page.dart` (ListTile trailing: − / + / qty tap / xóa)
- Test: `apps/pos_app/test/cart_test.dart` + widget/smoke nếu cần

**Hành vi:**
- Qty > 0; hàng cân cho phép thập phân theo rule hiện có trong `cart.dart`
- Xóa dòng: confirm ngắn hoặc swipe/icon; cập nhật tổng + discount HĐ clamp
- Không đụng checkout/outbox schema

- [x] UI sửa SL + xóa dòng
- [x] `flutter test` cart (+ analyze path)
- [x] Commit: `feat(pos): edit cart line qty and remove lines`

### Task 1.2: Tìm sản phẩm theo barcode

**Files:**
- Modify: `pos_page.dart` `_matches` — thêm `product.barcode` (field Drift/API hiện có)
- Optional: khi query khớp **đúng** 1 barcode → auto `add` vào giỏ (scanner keyboard wedge)

- [x] `_matches` gồm barcode (case-insensitive contains hoặc exact)
- [x] Exact barcode → add line (1 unit hoặc pack rule hiện có)
- [x] Commit: `feat(pos): search and scan products by barcode`

**Tick design:** §4.3 quét/tìm; §4.3 giỏ sửa SL/hủy dòng → ✅ (còn cân → Wave 2).

---

## Wave 2 — Bán hàng cân (P1)

**DoD:** Với `isWeighted == true`, dialog nhập kg (Decimal) trước khi add; hiển thị đơn vị trên dòng giỏ.

**Files:** `pos_page.dart`, `cart.dart`, test weigh add.

- [x] Dialog nhập số lượng (kg) khi add SP cân
- [x] Chặn qty ≤ 0; half-up tiền theo pattern hiện có
- [x] Commit: `feat(pos): weigh-sale qty dialog for weighted products`

**Tick:** §4.2/§4.3 bán theo cân → ✅.

---

## Wave 3 — Journal chuyển kho (P1)

> **Trước code:** plan con `docs/superpowers/plans/YYYY-MM-DD-transfer-journals.md`.

**DoD:** Khi transfer receive (hoặc approve—chốt trong plan con) sync thành công → journal không double-COGS; period lock chặn; e2e multi-store; unlock replay hỗ trợ `sourceType` transfer nếu dùng `safePost` pattern.

**Files:**
- `apps/api/src/ledger/journal-builders.ts` + `ledger.service.ts`
- `apps/api/src/sync/stock-ops.service.ts` (hook sau receive)
- `apps/api/test/transfer-journal.e2e-spec.ts`

**Quyết định kế toán (ghi trong plan con):** thường Dr/Cr tồn giữa 2 store cùng TK `156` với `storeId` trên header, hoặc TK trung gian — **không** post COGS hai lần.

- [x] Plan con + CoA
- [x] Builder + `postFromStockTransfer` + hook
- [x] e2e PASS
- [x] CHANGELOG + tick deferred trong hardening docs

**Tick:** chuyển kho đủ sổ; gap “transfer journals” → ✅.

---

## Wave 4 — Sổ cái theo tài khoản (P1)

> Plan con khuyến nghị nếu API mới lớn.

**DoD:** Owner/manager xem sổ cái 1 TK theo kỳ (phát sinh + số dư chạy); export CSV optional.

**API:**
- `GET /ledger/account-ledger?accountCode=&periodYm=&storeId?`
- Trả: opening balance, lines `{postedAt, sourceType, sourceId, memo, debit, credit, runningBalance}`, closing

**Files:**
- `ledger.service.ts` / `ledger.controller.ts`
- Flutter `ledger_page.dart` tab/section **Sổ cái**
- e2e `account-ledger.e2e-spec.ts`

- [x] API + e2e
- [x] Flutter UI chọn TK + kỳ
- [x] Commit: `feat(ledger): account ledger (sổ cái) by period`

**Tick:** §5.1 sổ cái → ✅.

---

## Wave 5 — Đơn đặt hàng NCC (PO) (P2)

> **Plan con bắt buộc:** `docs/superpowers/plans/YYYY-MM-DD-purchase-orders.md`.

**DoD:** Tạo PO (draft→ordered); nhập hàng từ PO (partial OK); đóng PO; tồn/AP chỉ khi có phiếu nhập (như hiện tại).

**Schema (gợi ý):**
- `PurchaseOrder` / `PurchaseOrderLine` (storeId, supplierId, status, clientId)
- `PurchaseReceipt.purchaseOrderId` optional FK

**Files:** Prisma migrate; Drift tables; `inventory_hub_page` / service; sync push types; e2e.

- [x] Plan con (status machine + partial receive)
- [x] Schema + sync + UI
- [x] e2e: PO → partial receive → AP tăng đúng
- [x] Vẫn cho nhập **không** PO

**Tick:** §4.4 có/không đơn đặt hàng → ✅.

---

## Wave 6 — HĐĐT gộp khách + điều chỉnh (P2)

> Plan con bắt buộc. Cancel đã có (E.3).

### Task 6.1: Gộp theo khách

- `POST /einvoices/issue-batch` body `{ customerId, saleIds: string[] }` hoặc `{ customerId, date }`
- Chỉ sale synced, cùng store, chưa có HĐ issued
- Adapter `issue` payload gộp lines; Flutter chọn nhiều đơn

### Task 6.2: Điều chỉnh

- `POST /einvoices/:id/adjust` `{ reason, saleId? }` — tạo HĐ điều chỉnh / liên kết return tùy gateway
- Stub: set status hoặc tạo bản ghi `adjusted` nếu cần mở rộng enum
- HTTP: endpoint riêng + idempotency key
- **Không** làm SDK vendor trừ khi gateway fail compliance

**Tick:** §5.5 gộp + điều chỉnh → ✅ (adapter HTTP vẫn 🟡 chấp nhận được vs SDK).

---

## Wave 7 — Audit nghiệp vụ (P2)

**DoD:** `AuditLog` ghi: đổi giá SP, “xóa/hủy” đơn (nếu có flow), điều chỉnh nợ thủ công; Flutter hoặc API list lọc action.

**Gợi ý action:**
- `product_price_change` — khi `product_upsert` đổi `priceVnd`/`costVnd`
- `sale_void` hoặc cấm xóa — nếu không có xóa đơn: document + chỉ cho return (đã có) thay void
- `debt_adjust` — nếu thêm API điều chỉnh số dư ngoài thu nợ

**Files:** sync/product paths; `ledger` hoặc `audit` module; e2e tối thiểu 1 action.

- [x] Chốt: có cho void sale không? (khuyến nghị: **không void**, chỉ return — audit return đã có trên chứng từ)
- [x] Implement price_change + debt_adjust (nếu có UI)
- [x] Mở rộng `GET /ledger/audit` filter

**Tick:** §5.7 sửa giá / điều chỉnh nợ → ✅; xóa đơn → ✅ qua “không xóa im lặng + return”.

---

## Wave 8 — Báo cáo còn thiếu (P2)

| Task | Design | Deliverable |
|------|--------|-------------|
| 8.1 | §4.7 doanh thu theo **ca** | `GET /reports/day` breakdown by `shiftId` hoặc endpoint riêng; Flutter day report section |
| 8.2 | §4.5 / §4.7 công nợ **tổng** (owner) | Aggregate debt-aging không bắt buộc `storeId` (giống period reports) |
| 8.3 | AR export | CSV công nợ phải thu từ Flutter hoặc API |

- [x] 8.1 e2e + UI
- [x] 8.2 e2e + UI
- [x] 8.3 CSV

---

## Wave 9 — Polish P3 (optional)

| Task | Ghi chú | Status |
|------|---------|--------|
| 9.1 Store CRUD (owner) | Tạo/sửa mã cửa hàng — hiện chỉ seed/API hẹp | **Done** in-repo |
| 9.2 Push “nợ lớn” | Ngưỡng trên store + FCM (cần bật FCM — `docs/ops/fcm.md`) | **Done** in-repo |
| 9.3 Camera barcode | mobile_scanner — chỉ khi wedge/search chưa đủ | **Skipped** |
| 9.4 Tách quyền KT vs HĐĐT | Role mới hoặc permission flags — chỉ khi chủ yêu cầu | **Skipped** |

---

## Ngoài scope (không đưa vào hoàn thiện này)

- Nộp CQT; website; loyalty; HR; chuỗi lớn
- Đổi WAC → FIFO
- SDK Viettel/MISA (Wave riêng khi HTTP không đủ)
- Đối chiếu sao kê **NCC** đầy đủ (§5.3) — có thể gắn Wave 5.5 sau PO nếu cần; mặc định **P3** sau Wave 8

### Wave 5b (optional sau Wave 5): Đối chiếu sao kê NCC

> **Status:** **Deferred** (optional — không chặn hoàn thiện design §4/§5).

- Import CSV công nợ NCC / sao kê phải trả; match payment — mirror bank-recon patterns
- Plan con riêng khi bắt đầu

---

## Tiêu chí “design §4/§5 hoàn thiện tối thiểu”

Coi **đủ theo design vận hành** khi:

1. [ ] Wave 0: prod + smoke (operator — in-repo Done)
2. [x] Wave 1–2: POS giỏ + barcode + cân ✅
3. [x] Wave 3–4: transfer journal + sổ cái ✅
4. [x] Wave 5: PO (nếu quán đặt hàng NCC) — có thể trì hoãn nếu chỉ nhập thẳng
5. [x] Wave 6–7: nếu dùng HĐĐT/audit nặng
6. [x] Wave 8: báo cáo ca + nợ tổng

**MVP quầy+sổ sau gap hiện tại:** xong **Wave 1 + 3 + 4** (+ Wave 0 operator).

---

## Cách chạy

| Cách | Wave |
|------|------|
| Operator checklist | 0 |
| Subagent-Driven | 1–4 (và plan con 3+) |
| Plan con rồi SDD | 5, 6, 7 |
| Sau ổn định quán | 8–9, 5b |

---

## Self-review (coverage checklist → wave)

| Gap §4/§5 | Wave |
|-----------|------|
| Giỏ sửa SL / xóa dòng; barcode search | 1 |
| Bán cân UI | 2 |
| Transfer journals | 3 |
| Sổ cái | 4 |
| PurchaseOrder | 5 |
| HĐĐT gộp + điều chỉnh | 6 |
| Audit giá / nợ / (void) | 7 |
| Báo cáo ca; nợ tổng; AR CSV | 8 |
| Store CRUD; push nợ lớn; camera | 9 |
| Đối chiếu sao kê NCC | 5b |
| CRUD cửa hàng đầy đủ / tách role 3 lối | 9 |
| SDK vendor / CQT | Ngoài scope |

Không còn TBD trong Wave 0–2; Wave 3+ yêu cầu plan con trước khi code khi ghi chú.
)
