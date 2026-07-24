# Phase 2 Epic 1 — Giá vốn bình quân gia quyền (WAC)

**Ngày:** 2026-07-24  
**Trạng thái:** Approved for implement  
**Parent:** `2026-07-23-tap-hoa-pos-ke-toan-design.md` §5.2, §5.8 #1

## Quyết định

- Phương pháp: **bình quân gia quyền (WAC)** per `(storeId, productId)` — không FIFO trong Epic 1.
- `Product.costVnd` giữ làm catalog/default seed; **không** còn nguồn lãi chính.
- Snapshot `SaleLine.unitCostVnd` tại lúc bán (COGS lịch sử ổn định).

## Schema

- `ProductStoreStock.avgCostVnd Int @default(0)`
- `SaleLine.unitCostVnd Int?` (null = sale cũ trước migration)

## Công thức

```
newAvg = round((oldQty * oldAvg + receiptQty * unitCost) / (oldQty + receiptQty))
```

- `oldQty <= 0` → `newAvg = unitCost`
- Purchase không có `unitCostVnd` → không đổi `avgCostVnd`
- Vẫn ghi `Product.costVnd = unitCost` (last purchase hint)

## Sale

- Line thường: `unitCostVnd = stock.avgCostVnd || product.costVnd`
- Combo: `unitCostVnd = Σ (componentAvg * qtyBase)` với avg component theo store

## Báo cáo

- `topSkus.estimatedGrossVnd`: ưu tiên `Σ (lineTotal - qty * line.unitCostVnd)`; fallback avg/catalog
- `stockOnHand.estimatedValueVnd`: `qty * (avgCostVnd || product.costVnd)`

## Ngoài scope Epic 1

- FIFO layers, sổ kế toán, AP NCC, HĐĐT
- Đổi phương pháp runtime
