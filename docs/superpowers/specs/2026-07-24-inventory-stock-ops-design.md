# Thiết kế: Kho vận hành (Phase 1 remaining #3)

**Ngày:** 2026-07-24  
**Dự án:** `tap-hoa`  
**Trạng thái:** Đã duyệt  
**Spec gốc:** `docs/superpowers/specs/2026-07-23-tap-hoa-pos-ke-toan-design.md` (§4.4)  
**Checklist:** `docs/superpowers/plans/2026-07-23-phase1-remaining.md`

## 1. Mục tiêu

Hoàn thiện remaining #3 đầy đủ:

- **Chuyển kho** giữa điểm bán: tạo → duyệt → nhận
- **Kiểm kê** với lý do lệch tăng/giảm
- **Xuất hủy / hao hụt**
- **Phiếu nhập NCC** (không PO, không công nợ NCC)
- **Sổ xuất nhập tồn** theo điểm (từ `StockMovement`)

**Không làm lần này:** catalog CRUD, nhóm SP, quy đổi đơn vị, in tem, báo cáo top SKU, PO/đặt hàng NCC, AP nhà cung cấp (GĐ2).

## 2. Quyết định đã chốt

| Hạng mục | Quyết định |
|---|---|
| Phạm vi | Đủ 5 hạng mục Inventory trong remaining |
| Kiến trúc | Header + lines theo loại chứng từ + `StockMovement` append-only |
| Chuyển kho | 3 bước: `draft` → `approved` (trừ nguồn) → `received` (cộng đích); `rejected` không đụng tồn |
| Offline | Ghi local + outbox; server nguồn đúng sau sync |
| NCC | `supplierName` + `supplierPhone?` trên phiếu — không model `Supplier` |
| PO | Không |
| Quyền | cashier+: kiểm kê / xuất hủy / nhập NCC cùng store; chuyển kho tạo/duyệt: `store_manager` \| `owner`; nhận: user thuộc store đích |
| Âm tồn | Server reject khi approve transfer / xuất hủy nếu không đủ tồn; local giữ `allowNegativeStock` |
| Ca | Không bắt buộc `shiftId` |
| Sale movements | Có — `processSale` + checkout local ghi `StockMovement` (`docType=sale`) |

## 3. Dữ liệu & sync

### 3.1 Enums

- `StockDocType`: `sale` \| `transfer` \| `stocktake` \| `purchase` \| `wastage`
- `TransferStatus`: `draft` \| `approved` \| `rejected` \| `received`
- `StocktakeLineReason`: `increase` \| `decrease` \| `match`
- `WastageReason`: `spoilage` \| `damage` \| `other`

### 3.2 Models

**`StockTransfer` + `StockTransferLine`**

| Cột | Ý nghĩa |
|---|---|
| `id` | UUID client; khóa idempotent |
| `fromStoreId` / `toStoreId` | Điểm nguồn / đích |
| `status` | `TransferStatus` |
| `note` | Nullable |
| `createdById` / `approvedById?` / `receivedById?` | User |
| `clientCreatedAt` / `approvedAt?` / `receivedAt?` | |
| line: `productId`, `qty` | Decimal > 0 |

**`Stocktake` + `StocktakeLine`:** `storeId`, `recordedById`, `note?`, `clientCreatedAt`; line: `productId`, `systemQty`, `countedQty`, `varianceQty`, `reason`, `reasonNote?`. Apply: set tồn = `countedQty`.

**`PurchaseReceipt` + lines:** `storeId`, `supplierName`, `supplierPhone?`, `note?`, `recordedById`; line: `productId`, `qty`, `unitCostVnd?` (nếu có → cập nhật `Product.costVnd`). Apply: +qty.

**`WastageVoucher` + lines:** `storeId`, `reasonCode`, `note?`, `recordedById`; line: `productId`, `qty`. Apply: −qty.

**`StockMovement`:** `id`, `storeId`, `productId`, `qtyDelta` (signed), `balanceAfter`, `docType`, `docId`, `docLineId?`, `recordedById`, `clientCreatedAt`. Index `(storeId, clientCreatedAt)`, `(productId, clientCreatedAt)`.

### 3.3 Local (Drift)

Mirror tất cả bảng trên; `schemaVersion` 5+. Outbox types:

- `stock_transfer_create` \| `stock_transfer_approve` \| `stock_transfer_reject` \| `stock_transfer_receive`
- `stocktake` \| `purchase_receipt` \| `wastage`

### 3.4 Luồng chuyển kho

1. **Tạo** (store nguồn): local `draft` + outbox `stock_transfer_create` — chưa đụng tồn.
2. **Duyệt** (manager/owner nguồn hoặc owner): local trừ tồn nguồn + outbox `stock_transfer_approve` → server trừ nguồn, status `approved`, ghi movements `qtyDelta < 0` tại nguồn.
3. **Từ chối**: status `rejected`; không đụng tồn.
4. **Nhận** (user store đích, sau khi pull thấy `approved`): local cộng tồn đích + outbox `stock_transfer_receive` → server cộng đích, status `received`, movements tại đích.

Idempotent theo `id` + action (approve/receive không apply hai lần).

### 3.5 Push / pull

Push order: sau `sales`, trước `shiftCloses` (cùng nhóm với cash/debt). Mỗi `process*` trong `$transaction` cập nhật `ProductStoreStock.updatedAt`.

Pull theo `storeId` + cursor: chứng từ kho liên quan store + `stockMovements`; transfer pull nếu `fromStoreId` hoặc `toStoreId` khớp store đang sync.

Reject reasons: `store_forbidden`, `role_forbidden`, `insufficient_stock`, `invalid_status`, `invalid_qty`, `stock_not_found`.

## 4. UI

- Hub **Kho** từ app bar POS.
- Tab/list: Chuyển kho / Kiểm kê / Nhập NCC / Xuất hủy / Lịch sử tồn.
- Sheet tạo từng loại; màn chuyển kho: chờ duyệt / chờ nhận.
- Lịch sử: lọc theo ngày hoặc sản phẩm (stream local movements).

## 5. Acceptance

1. Nhập / xuất hủy / kiểm kê offline → tồn local đổi; sync → server + máy khác khớp.
2. Chuyển kho 3 bước đúng; reject không đụng tồn; idempotent.
3. Sổ xuất nhập tồn có movements từ kho + bán hàng.
4. Sai store / thiếu quyền → reject rõ.
5. e2e API + unit Flutter xanh.

## 6. Liên quan tiếp theo

Sau #3: **#4 Product CRUD + tem mã vạch**, rồi in nhiệt / báo cáo.
