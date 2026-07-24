# Thiết kế: Nhóm hàng (Product groups)

**Ngày:** 2026-07-24  
**Dự án:** `tap-hoa`  
**Trạng thái:** Đã duyệt (implement)  
**Checklist:** Phase 1 remaining — Product groups / categories

## Mục tiêu

- CRUD nhóm hàng (`ProductGroup`)
- Gán `groupId` (nullable) cho sản phẩm
- Lọc theo nhóm trên POS và danh mục

## Schema

- `ProductGroup { id, name, sortOrder, active, updatedAt, createdAt }`
- `Product.groupId String?` FK → ProductGroup

## Sync

- Pull: `productGroups[]` (updatedSince)
- Push: `productGroupUpserts[]` + `product_upsert.groupId`

## UI

- Form SP: dropdown nhóm
- Danh mục + POS: chip lọc (Tất cả + từng nhóm active)

## Ngoài scope

- Quy đổi ĐV, combo (workstream sau)
