# Thiết kế: Product CRUD + in tem barcode (Phase 1 remaining #4)

**Ngày:** 2026-07-24  
**Dự án:** `tap-hoa`  
**Trạng thái:** Đã duyệt  
**Spec gốc:** `docs/superpowers/specs/2026-07-23-tap-hoa-pos-ke-toan-design.md` (§4 catalog / in tem)  
**Checklist:** `docs/superpowers/plans/2026-07-23-phase1-remaining.md`  
**Liên quan:** `docs/superpowers/specs/2026-07-24-inventory-stock-ops-design.md` (tồn theo chứng từ; không sửa tồn trên form SP)

## 1. Mục tiêu

Hoàn thiện remaining #4 (một phần checklist Product catalog polish):

- **CRUD sản phẩm** trên POS: tạo / sửa + sync push offline-first
- **Seed tồn** chỉ cho store hiện tại khi tạo (qty = 0 hoặc số nhập)
- **In tem mã vạch** qua Print dialog hệ thống (layout PDF → máy in OS)

**Không làm lần này:** nhóm / category, quy đổi thùng↔chai, xóa cứng SP, ESC/POS / driver nhiệt trực tiếp, sửa tồn trên form SP (dùng nhập NCC / chuyển kho / kiểm kê / xuất hủy), REST online-only CRUD.

Checklist còn lại sau vòng này: Product groups / categories; Unit conversion.

## 2. Quyết định đã chốt

| Hạng mục | Quyết định |
|---|---|
| Phạm vi | A — CRUD + in tem; bỏ groups & unit conversion |
| In tem | A — Print hệ thống (`printing` + layout PDF/barcode); không ESC/POS |
| Tồn khi tạo | A — chỉ store hiện tại; điểm khác chưa có `ProductStoreStock` đến khi NCC / chuyển kho / tạo lúc bán |
| Sync | Outbox `product_upsert` → `POST /sync/push` (giống `customer_upsert`) |
| Schema Product | Giữ model hiện có; không migration bảng mới bắt buộc |
| Stock seed | Upsert `ProductStoreStock` **chỉ** `(productId, storeId)` trong payload; **không** ghi `StockMovement` cho seed catalog |
| Sửa SP | Cập nhật fields Product; **không** ghi đè `qty` nếu dòng tồn đã tồn tại |
| Quyền | Tạo/sửa: `store_manager` \| `owner`; cashier: xem list + in tem |
| Soft delete | `active = false` — không hard delete Phase 1 |

## 3. Dữ liệu & sync

### 3.1 Schema (đã có)

**`Product`:** `id`, `sku` (unique), `barcode?`, `name`, `unit`, `isWeighted`, `basePriceVnd`, `costVnd`, `active`, timestamps.

**`ProductStoreStock`:** PK `(productId, storeId)`, `qty`, `minQty`.

Bổ sung ràng buộc ứng dụng / DB (nếu chưa có):

- `sku` trim, non-empty; unique toàn hệ thống (đã có `@unique`).
- `barcode` khi non-null / non-empty: unique toàn hệ thống (app check + unique index nếu cần; PostgreSQL UNIQUE cho phép nhiều `NULL`).

Không thêm bảng mới. Drift: dùng bảng products / stocks hiện có; không bắt buộc bump `schemaVersion` trừ khi thêm cột (không dự kiến).

### 3.2 Outbox & DTO

Outbox type: `product_upsert`.

`PushProductUpsertDto`:

| Field | Bắt buộc | Ý nghĩa |
|---|---|---|
| `id` | Có | UUID client; khóa idempotent |
| `sku` | Có | |
| `barcode` | Không | null / omit = không barcode |
| `name`, `unit` | Có | |
| `isWeighted` | Có | bool |
| `basePriceVnd` | Có | ≥ 0 |
| `costVnd` | Không | mặc định 0 |
| `active` | Có | |
| `storeId` | Có | store ngữ cảnh (quyền + seed) |
| `seedStock` | Không* | `{ qty: string, minQty?: string }` — **bắt buộc khi tạo mới** trên client; khi sửa có thể omit |

\* Client **luôn** gửi `seedStock` khi insert local lần đầu; khi edit fields-only thì omit `seedStock`.

`PushSyncDto` thêm: `productUpserts?: PushProductUpsertDto[]`.

Push response: `acceptedProductUpsertIds`, `rejectedProductUpserts: { id, reason }[]`.

### 3.3 Server `processProductUpsert`

1. User phải thuộc `storeId`; role ∈ `store_manager` \| `owner` — else `role_forbidden` / `store_forbidden`.
2. Validate: sku/name/unit non-empty; prices ≥ 0; nếu `seedStock` thì `qty` ≥ 0, `minQty` ≥ 0.
3. Conflict:
   - SKU thuộc product `id` khác → `sku_conflict`
   - Barcode non-null thuộc product `id` khác → `barcode_conflict`
4. Upsert `Product` theo `id` (create hoặc update fields).
5. Stock:
   - Nếu **không** có `seedStock` → bỏ qua stock.
   - Nếu có `seedStock` và **chưa** có `ProductStoreStock` cho `(id, storeId)` → `create` với `qty` / `minQty` (default minQty `0`).
   - Nếu đã có dòng tồn → **chỉ** cập nhật `minQty` khi client gửi `minQty`; **không** đổi `qty` (tránh ghi đè tồn vận hành).
6. Không tạo `StockMovement` cho seed.
7. Idempotent: push lại cùng `id` + cùng fields → accept; không nhân đôi stock row.

Pull: giữ `products` + `stocks` theo store như hiện tại (sau upsert, `updatedAt` đổi → máy khác kéo được).

Thứ tự push gợi ý: cùng nhóm catalog với `customerUpserts` (sau sales / inventory hoặc trước — không phụ thuộc ca).

### 3.4 Client local

1. Form tạo: generate `id` UUID; ghi `products_local` + `product_store_stocks_local` (store hiện tại, qty/minQty); enqueue `product_upsert` kèm `seedStock`.
2. Form sửa: cập nhật product local; enqueue `product_upsert` **không** `seedStock` (trừ khi store hiện tại chưa có dòng tồn — khi đó gửi seed để tạo dòng, qty do user nhập hoặc 0).
3. Cashier: UI ẩn Thêm/Sửa; vẫn mở list + In tem.
4. Reject outbox: giữ pattern failed outbox như sale/customer (`sku_conflict`, …).

## 4. UI

### 4.1 Catalog

- Mở rộng **Danh sách SP** hiện có: FAB / nút **Thêm** (manager+); tap dòng → sheet/form **Sửa**.
- Form fields: sku*, barcode, name*, unit*, isWeighted, basePriceVnd*, costVnd, active; khi **tạo** (và khi seed lần đầu): initialQty (≥0, mặc định 0), minQty (≥0, mặc định 0).
- Không có field “sửa tồn” khi đã có stock — hướng user sang hub Kho nếu cần điều chỉnh qty.

### 4.2 In tem

- Từ list hoặc form: **In tem**.
- Nội dung tem tối thiểu: barcode (Code128 hoặc EAN nếu hợp lệ; fallback text sku nếu không có barcode), tên SP (rút gọn), giá bán.
- Chọn số bản 1–N → preview layout → `Printing.layoutPdf` / share print → OS print dialog.
- Không kết nối driver nhiệt riêng trong vòng này.

## 5. Biên & xung đột

| Tình huống | Xử lý |
|---|---|
| Retry outbox cùng `id` | Idempotent upsert Product; stock create-once |
| Hai máy tạo sku trùng, id khác | Server reject máy sau `sku_conflict` |
| Edit offline rồi pull đè | Pull sau sync là nguồn đúng (last-write theo server `updatedAt` / upsert push thắng tạm thời — Phase 1 không conflict UI chi tiết) |
| Cashier push (bug / cũ) | `role_forbidden` |
| `seedStock` khi đã có tồn | Bỏ qua `qty`; có thể cập nhật `minQty` |
| Tồn điểm khác | Không tạo dòng đến khi chứng từ kho / bán tạo stock |
| Hard delete | Ngoài scope |

## 6. Acceptance

1. Manager tạo SP offline với qty 0 hoặc N → list local có SP + tồn store hiện tại; sync → server Product + một `ProductStoreStock`; store khác không có dòng tồn.
2. Sửa giá/tên offline → sync cập nhật Product; qty store không bị reset.
3. Cashier không thấy (hoặc bị chặn) Thêm/Sửa; vẫn in tem được.
4. SKU / barcode trùng → reject rõ ràng; outbox failed.
5. In tem: preview + mở print dialog hệ thống với barcode + tên + giá.
6. e2e API: upsert create+seed; upsert update no qty overwrite; role/sku/barcode reject; idempotent.
7. Flutter test: create enqueue outbox + local stock; edit không gửi seed khi đã có stock.

## 7. Thứ tự triển khai gợi ý (sau khi duyệt file → plan)

1. DTO + `processProductUpsert` + wire `push` / response + e2e
2. Flutter: `ProductService` (create/update + outbox) + unit tests
3. UI form tạo/sửa trên product list (role gate)
4. Label PDF + print flow
5. Tick checklist: Full product CRUD UI; Barcode label printing; Product/stock push from client (sync & ops)

## 8. Liên quan tiếp theo

Sau #4: **#5 Thermal receipt + top SKU** (gợi ý remaining). Groups / unit conversion vẫn deferred trong Product catalog polish.
