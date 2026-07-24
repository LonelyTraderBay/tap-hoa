# Thiết kế: Báo cáo tồn hiện tại / stock-on-hand (Phase 1 Reports)

**Ngày:** 2026-07-24  
**Dự án:** `tap-hoa`  
**Trạng thái:** Đã duyệt  
**Spec gốc:** `docs/superpowers/specs/2026-07-23-tap-hoa-pos-ke-toan-design.md` (§4 tồn theo điểm)  
**Checklist:** `docs/superpowers/plans/2026-07-23-phase1-remaining.md`  
**Roadmap:** Conflict UI (done) → **báo cáo tồn** → debt aging

## 1. Mục tiêu

Báo cáo **tồn hiện tại theo store**:

- List SKU / tên / đơn vị / qty / minQty
- **Giá trị tồn ước tính** `qty × costVnd` + **tổng giá trị store**
- Tìm kiếm; lọc dưới định mức; tùy chọn hiện qty = 0

**Không làm lần này:** CSV export, tổng hợp multi-store một bảng, sổ xuất nhập tồn mới (đã có tab Lịch sử tồn), debt aging, push notification low-stock.

## 2. Quyết định đã chốt

| Hạng mục | Quyết định |
|---|---|
| Phạm vi nội dung | B — list + giá trị ước tính + tổng store |
| Entry | C — Kho (primary) + link từ Báo cáo ngày |
| Nguồn dữ liệu | A — `GET /reports/stock-on-hand` + offline Drift |
| Lọc mặc định | A — ẩn qty=0; toggle Hiện hết; toggle Dưới định mức; search; chỉ SP active |
| `storeId` | **Bắt buộc** trên API; UI chọn store (owner) / store hiện tại (cashier) |
| Kiến trúc | Approach 1 — endpoint riêng + page Flutter; không gộp vào `/reports/day` |

## 3. API

`GET /reports/stock-on-hand?storeId=`

- Auth `JwtAuthGuard`; `assertStoreAccess` như day report
- `storeId` required → 400 nếu thiếu
- Query `ProductStoreStock` where `storeId` + `product.active = true`
- Join `Product`: sku, name, unit, costVnd

**Item:**

| Field | Ý nghĩa |
|---|---|
| `productId`, `sku`, `name`, `unit` | Catalog |
| `qty` | number (từ Decimal) |
| `minQty` | number |
| `costVnd` | int |
| `estimatedValueVnd` | `Math.round(qty * costVnd)` |
| `belowMin` | `qty < minQty` |

**Response:**

```json
{
  "storeId": "...",
  "items": [ /* sorted: belowMin DESC, then name ASC */ ],
  "totalEstimatedValueVnd": 0
}
```

`totalEstimatedValueVnd` = sum `estimatedValueVnd` trên **toàn bộ** items trả về (trước filter UI client). Server trả full list active+stock; filter qty=0 / belowMin / search làm trên client (hoặc query params tùy chọn Phase 1 — **chốt:** filter client để offline cùng semantics).

E2e: seed 2 SP tồn store; assert value math + belowMin; forbidden store.

## 4. Flutter

### 4.1 Repository

`StockOnHandRepository` (hoặc cạnh reports):

- Online: `GET /reports/stock-on-hand?storeId=`
- Offline network error: aggregate `productStocks` ⋈ `products` (active) cho `storeId`; cùng công thức value / belowMin / sort
- `isOffline` flag

### 4.2 UI — `StockOnHandPage`

- Header: tổng giá trị ước tính (format VND)
- Search field (tên / SKU)
- Switch **Dưới định mức**
- Switch **Hiện hết** (khi off: ẩn `qty == 0`)
- List: name, sku, qty/unit, min, giá trị; highlight dưới định mức
- Empty: “Không có tồn phù hợp bộ lọc”
- Banner offline nếu cần
- Owner: dropdown chọn store (danh sách từ storesLocal / quyền); cashier: lock store hiện tại

### 4.3 Entry

1. **Kho / InventoryHub:** nút hoặc tab **Tồn hiện tại** → `StockOnHandPage` (primary)
2. **DayReportPage:** TextButton / ListTile **Xem tồn hiện tại** → cùng page (store = store báo cáo / current)

## 5. Files gợi ý

| File | Vai trò |
|---|---|
| `apps/api/src/reports/reports.service.ts` | `stockOnHand` |
| `apps/api/src/reports/reports.controller.ts` | route |
| `apps/api/test/reports.e2e-spec.ts` | e2e |
| `apps/pos_app/lib/features/reports/stock_on_hand_repository.dart` | fetch + offline |
| `apps/pos_app/lib/features/reports/stock_on_hand_page.dart` | UI |
| `apps/pos_app/lib/features/inventory/inventory_hub_page.dart` | entry |
| `apps/pos_app/lib/features/reports/day_report_page.dart` | link |
| `apps/pos_app/test/stock_on_hand_repository_test.dart` | unit |

Không migration schema.

## 6. Tests

- API: value = round(qty×cost); belowMin; store access
- Flutter: offline aggregate + filter semantics (unit trên repository; filter UI optional widget later)

## 7. Rủi ro

| Rủi ro | Giảm nhẹ |
|---|---|
| costVnd = 0 → value 0 | Label “ước tính”; chấp nhận như top SKU |
| Offline lệch server (chưa sync) | Banner offline |
| List lớn | Search + ẩn qty=0 mặc định |

## 8. Done when

- [ ] `GET /reports/stock-on-hand` + e2e
- [ ] Page + offline + filters mặc định A
- [ ] Entry Kho + link DayReport
- [ ] Tick checklist stock-on-hand
- [ ] Không CSV / không aging

## 9. Next

**Debt aging / overdue views.**
