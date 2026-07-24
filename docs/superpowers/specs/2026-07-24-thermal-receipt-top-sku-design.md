# Thiết kế: In hóa đơn PDF + Top SKU (Phase 1 remaining #5)

**Ngày:** 2026-07-24  
**Dự án:** `tap-hoa`  
**Trạng thái:** Đã duyệt  
**Spec gốc:** `docs/superpowers/specs/2026-07-23-tap-hoa-pos-ke-toan-design.md` (§4.3 in hóa đơn; §4.7 báo cáo)  
**Checklist:** `docs/superpowers/plans/2026-07-23-phase1-remaining.md`

## 1. Mục tiêu

Hoàn thiện remaining #5 (counter polish):

- **In hóa đơn** sau bán: layout PDF khổ nhiệt (~58mm) → Print dialog hệ thống Windows
- **Top hàng bán chạy** trong ngày trên trang Báo cáo ngày (qty + doanh thu + lãi gộp ước tính)

**Không làm lần này:** ESC/POS / driver nhiệt USB-COM, auto-print không hỏi, gửi ảnh hóa đơn qua mạng, export CSV, stock-on-hand report, conflict UI, debt aging.

Checklist còn lại sau vòng này (liên quan in): Thermal receipt printer drivers (Windows) — ESC/POS deferred.

## 2. Quyết định đã chốt

| Hạng mục | Quyết định |
|---|---|
| In hóa đơn | C — PDF ngay; ESC/POS sau (không trong PR này) |
| UX sau bán | B — hỏi “In hóa đơn?” (Có / Không) rồi mới mở Print dialog |
| Top SKU UI | A — section trên `DayReportPage` (cùng ngày / cùng store filter) |
| Xếp hạng | C — theo **qty DESC**, tie-break **revenueVnd DESC**; top 10; kèm lãi gộp ước tính |
| Lãi gộp | `estimatedGrossVnd = revenueVnd − qty × costVnd`; thiếu `costVnd` → `null` (UI “—”) |
| Kiến trúc báo cáo | Approach 1 — endpoint riêng `GET /reports/top-skus` + offline Drift; không gộp vào `/reports/day` |

## 3. In hóa đơn (PDF)

### 3.1 Package & pattern

Tái dùng `printing` + `pdf` như `barcode_label.dart`. Không thêm package ESC/POS.

File mới gợi ý: `apps/pos_app/lib/features/pos/receipt_print.dart`

- `buildReceiptPdf(...)` → `Uint8List`
- `promptAndPrintReceipt(BuildContext, ...)` → dialog Có/Không → `Printing.layoutPdf`

### 3.2 Nội dung layout (~58mm width)

- Tên cửa hàng (từ `storesLocal` / meta)
- Thời gian ICT (`clientCreatedAt` hoặc now)
- Mã đơn rút gọn (8–12 ký tự đầu `saleId` hoặc full nếu ngắn)
- Dòng hàng: tên (truncate), qty, đơn giá, thành tiền
- Tổng cộng
- Phân bổ thanh toán: tiền mặt / chuyển khoản / nợ (chỉ dòng > 0)
- Tên khách nếu có `customerId`

Không in barcode trên hóa đơn Phase 1. Không logo bắt buộc.

### 3.3 Hook checkout

Trong `PaymentSheet._complete` sau `CheckoutService.complete` thành công:

1. Giữ snapshot cart + payment + `saleId` trả về (đổi `complete` trả `String saleId` nếu chưa)
2. `Navigator.pop` sheet (hoặc giữ context parent)
3. Gọi `promptAndPrintReceipt` với snapshot (không đọc lại DB bắt buộc)
4. Sau đó `onCompleted()` clear cart

In lỗi / user hủy Print dialog → không rollback sale; snackbar tùy chọn.

### 3.4 ESC/POS (out of scope)

Ghi rõ trong checklist remaining: driver nhiệt Windows vẫn `[ ]`. Vòng sau: package ESC/POS + cấu hình máy in trong meta; cùng `buildReceipt*` abstraction nếu tách interface.

## 4. Top SKU

### 4.1 API

`GET /reports/top-skus?date=YYYY-MM-DD&storeId=&limit=10`

- Auth + quyền store giống `dayReport` (`parseDateRange` ICT, `resolveStoreIds`, `assertStoreAccess`)
- `limit` default 10, max 50
- Aggregate `SaleLine` ⋈ `Sale` where `clientCreatedAt ∈ [start, end)` và `storeId ∈ storeIds`
- Group by `productId`: `sum(qty)`, `sum(lineTotal)` as `revenueVnd`
- Join `Product`: `sku`, `name`, `costVnd`
- Sort: qty DESC, revenueVnd DESC; take `limit`

Response:

```json
{
  "date": "2026-07-24",
  "items": [
    {
      "productId": "...",
      "sku": "...",
      "name": "...",
      "qty": 12,
      "revenueVnd": 240000,
      "estimatedGrossVnd": 60000
    }
  ]
}
```

`estimatedGrossVnd`: số nguyên nếu mọi dòng group có `costVnd` usable; nếu `costVnd` null trên product → `null` cho item đó (không ước tính từng phần).

Owner không truyền `storeId`: aggregate **gộp tất cả store được phép** (một bảng xếp hạng toàn hệ thống active stores), cùng semantics day report khi không filter — hoặc nếu day report hiện tại luôn per-store cards, top SKU owner không filter = gộp multi-store. **Chốt:** giống resolveStoreIds của day — không `storeId` → mọi store user được xem; một list xếp hạng gộp.

### 4.2 Flutter

- Mở rộng `DayReportRepository` hoặc `TopSkuRepository` cạnh đó:
  - Online: `GET /reports/top-skus`
  - Offline network error: aggregate local `saleLinesLocal` ⋈ `salesLocal` ⋈ `products` với `ictDayRangeUtc`; chỉ store hiện tại (như offline day report)
- `DayReportPage`: sau khối doanh thu, section **“Top hàng bán chạy”** — list rank #1…n, cột qty / doanh thu / lãi ước tính
- Cùng date picker; reload khi đổi ngày
- Banner offline dùng chung nếu top SKU offline (hoặc `isOffline` trên response)

### 4.3 Tests

- API e2e: hai SP khác qty → thứ tự đúng; ICT boundary; `estimatedGrossVnd` khi có/không `costVnd`
- Flutter unit: offline aggregate + sort; PDF builder smoke (bytes non-empty) tùy chọn

## 5. Không đụng schema

Không migration Prisma/Drift mới. Dùng `Sale`, `SaleLine`, `Product`, bảng local tương ứng đã có.

## 6. Rủi ro

| Rủi ro | Giảm nhẹ |
|---|---|
| Máy in nhiệt cần ESC/POS raw | PDF + OS dialog đủ Windows driver phổ biến; ESC/POS vòng sau |
| costVnd lỗi thời → lãi sai | Label “ước tính”; null khi thiếu cost |
| Offline top SKU lệch server (chưa sync sale) | Banner offline; chấp nhận như day report |
| Dialog in làm chậm quầy | Hỏi Có/Không — mặc định user có thể bấm Không nhanh |

## 7. Done when

- [ ] Sau bán thành công: dialog “In hóa đơn?” → Có mở Print PDF
- [ ] `GET /reports/top-skus` + e2e
- [ ] Section Top trên `DayReportPage` online + offline
- [ ] Spec/plan trong docs; ESC/POS vẫn deferred trên checklist
- [ ] Không regress day report / checkout

## 8. Next

Sau #5: **conflict UI / báo cáo tồn / debt aging** (theo roadmap remaining).
