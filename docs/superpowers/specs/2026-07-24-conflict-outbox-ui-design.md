# Thiết kế: Conflict UI — outbox bị reject (Phase 1 Sync & ops)

**Ngày:** 2026-07-24  
**Dự án:** `tap-hoa`  
**Trạng thái:** Đã duyệt  
**Spec gốc:** `docs/superpowers/specs/2026-07-23-tap-hoa-pos-ke-toan-design.md` (sync / conflict)  
**Checklist:** `docs/superpowers/plans/2026-07-23-phase1-remaining.md`  
**Roadmap sau #5:** Conflict UI → Báo cáo tồn → Debt aging (vòng này chỉ Conflict UI)

## 1. Mục tiêu

Cho phép nhân viên / chủ cửa hàng **thấy và xử lý** các bản ghi outbox bị server reject (`status = error`):

- Xem danh sách + lý do (tiếng Việt)
- **Retry** từng dòng hoặc tất cả
- **Sửa** payload rồi retry: form thân thiện cho case phổ biến + JSON thô cho mọi `entityType`

**Không làm lần này:** Bỏ qua / xóa outbox; rollback local khi discard; API conflict mới; push notification; multi-device cursor diagnostics; báo cáo tồn; debt aging.

## 2. Quyết định đã chốt

| Hạng mục | Quyết định |
|---|---|
| Phạm vi hành động | C — Retry + Sửa; **không** Bỏ qua |
| Sửa payload | B — JSON thô mọi entity + form thân thiện cho case A |
| Case thân thiện | `insufficient_stock` trên sale / wastage / stock_transfer_*; `sku_conflict` / `barcode_conflict` trên `product_upsert` |
| Bỏ qua | C — không có (tránh orphan outbox vs local lệch có chủ đích) |
| Entry | C — badge số lỗi AppBar POS **và** mục “Đồng bộ lỗi” (menu / gần Kho) |
| Kiến trúc | Approach 1 — Flutter-only trên Drift outbox; không endpoint resolve mới |

## 3. Dữ liệu hiện có

Bảng Drift `OutboxEntries`: `id`, `entityType`, `payloadJson`, `createdAt`, `status` (`pending` \| `error` \| `done`), `lastError`.

Worker đã gọi `markOutboxError(id, reason)` khi sync push trả rejected lists.

Không migration bắt buộc. Có thể thêm helper DB: `requeueOutbox(id)`, `updateOutboxPayload(id, json)`, `watchErrorCount()`.

## 4. UI / UX

### 4.1 Entry

- AppBar POS: icon (vd. `sync_problem`) + badge count `status = error`; tap → `OutboxConflictsPage`
- Mục “Đồng bộ lỗi” cạnh Kho / trong overflow menu POS (cùng page)

### 4.2 List

Mỗi dòng:

- Nhãn `entityType` (map VN: bán hàng, phiếu xuất hủy, SP, …)
- Id rút gọn
- `lastError` đã map VN (fallback raw code)
- `createdAt` ICT ngắn

Actions per row: **Sửa** | **Thử lại**  
AppBar list: **Thử lại tất cả**

Empty: “Không có lỗi đồng bộ”.

### 4.3 Retry

1. `status = pending`, `lastError = null`
2. `OutboxWorker.tick()` (hoặc enqueue tick đang chạy)
3. Refresh list; nếu vẫn error → giữ trên list với reason mới

Retry tất cả: áp dụng cho mọi `error` hiện tại, rồi một `tick()`.

### 4.4 Sửa — form thân thiện

**A1 — `insufficient_stock`** (`sale`, `wastage`, entity transfer liên quan qty trong payload):

- Hiển thị dòng hàng (tên từ products local nếu có) + qty hiện tại trong payload
- User chỉnh qty (> 0)
- **Transaction local bắt buộc trước khi requeue:**
  - Cập nhật `payloadJson` (qty / lineTotal nếu sale)
  - Cập nhật bảng local tương ứng (`saleLinesLocal` + điều chỉnh `productStocks` theo delta qty; wastage / transfer lines tương tự theo model hiện có)
  - Nếu không thể suy delta an toàn → chỉ cho sửa JSON thô + cảnh báo “chỉ sửa payload; kiểm tra tồn local thủ công”
- Sau lưu: requeue + tick

**A2 — `sku_conflict` / `barcode_conflict`** (`product_upsert`):

- Field sku và/hoặc barcode
- Cập nhật `payloadJson` + hàng `products` local (cùng id)
- Requeue + tick

### 4.5 Sửa — JSON thô

- `TextField` multiline `payloadJson`
- Validate: parse được JSON object
- Lưu → `payloadJson` mới → requeue (`pending`, clear error) → tick
- Không tự sửa bảng local khác (user chịu trách nhiệm; snackbar cảnh báo)

### 4.6 Reason map (VN)

| Code | Hiển thị |
|---|---|
| `insufficient_stock` | Không đủ tồn kho |
| `sku_conflict` | Trùng mã SKU |
| `barcode_conflict` | Trùng mã vạch |
| `credit_limit_exceeded` | Vượt hạn mức nợ |
| `store_forbidden` / `role_forbidden` | Không có quyền / cửa hàng |
| `shift_not_open` / `shift_not_found` | Ca chưa mở / không tìm thấy ca |
| `invalid_payload` / `invalid_qty` | Dữ liệu không hợp lệ |
| (khác) | Giữ nguyên `lastError` |

## 5. Files gợi ý

| File | Vai trò |
|---|---|
| `apps/pos_app/lib/features/sync/outbox_conflicts_page.dart` | List + actions |
| `apps/pos_app/lib/features/sync/outbox_edit_sheet.dart` | Form thân thiện + JSON |
| `apps/pos_app/lib/features/sync/outbox_conflict_service.dart` | requeue / edit / reason map |
| `apps/pos_app/lib/features/pos/pos_page.dart` | Badge + menu entry |
| `apps/pos_app/test/outbox_conflict_service_test.dart` | Unit |

Không đổi NestJS trừ khi phát hiện thiếu reason code (không dự kiến).

## 6. Tests

- Reason map
- Requeue: error → pending, lastError null
- JSON invalid bị từ chối
- product_upsert friendly: đổi sku cập nhật payload + products
- insufficient_stock sale: nếu implement delta stock — assert stock/line; nếu fallback JSON-only — document trong test skip

## 7. Rủi ro

| Rủi ro | Giảm nhẹ |
|---|---|
| Sửa qty sale lệch tồn local | Transaction payload + local; fallback JSON + cảnh báo nếu entity phức tạp |
| JSON thô làm hỏng payload | Validate JSON; retry sẽ reject lại nếu sai |
| Badge stale | Stream/watch count từ Drift |
| User muốn “xóa lỗi” | Ngoài scope; hướng dẫn Retry sau sửa hoặc hỗ trợ sau |

## 8. Done when

- [ ] Badge + mục menu mở list lỗi
- [ ] Retry một / tất cả
- [ ] Form thân thiện A1/A2 + JSON editor
- [ ] Unit tests service
- [ ] Tick checklist “Conflict resolution UI” trong phase1-remaining
- [ ] Không có hành động Bỏ qua / xóa outbox

## 9. Next (roadmap)

Sau vòng này: **Báo cáo tồn (stock-on-hand)** → **Debt aging**.
