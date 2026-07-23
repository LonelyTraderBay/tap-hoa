# Thiết kế: Thu nợ + hạn mức tín dụng (Phase 1 remaining #1)

**Ngày:** 2026-07-24  
**Dự án:** `tap-hoa`  
**Trạng thái:** Đã duyệt  
**Spec gốc:** `docs/superpowers/specs/2026-07-23-tap-hoa-pos-ke-toan-design.md` (§4.5)  
**Checklist:** `docs/superpowers/plans/2026-07-23-phase1-remaining.md`

## 1. Mục tiêu

Hoàn thiện stub công nợ MVP:

- Ghi **thu nợ** (toàn phần / một phần), offline-first qua outbox
- **Lịch sử** mua nợ / trả nợ trên sổ giao dịch
- **Hạn mức tín dụng** chặn bán nợ vượt hạn (local + server)

**Không làm lần này:** aging / quá hạn, điều chỉnh nợ thủ công, xóa/sửa phiếu thu đã ghi, báo cáo công nợ tổng hợp mới, CRUD khách đầy đủ ngoài hạn mức, in biên lai thu nợ.

## 2. Quyết định đã chốt

| Hạng mục | Quyết định |
|---|---|
| Phạm vi | B — thu nợ + lịch sử + hạn mức; aging để sau |
| Kiến trúc | A — sổ `DebtLedger` + outbox (không chỉ cập nhật số dư) |
| Offline | Có — ghi local + outbox; server là nguồn đúng sau sync |
| Hạn mức | `creditLimitVnd Int?` trên `Customer`; `null` = không hạn |
| Thu nợ | Tiền mặt hoặc chuyển khoản; không vượt số dư |
| Quyền Phase 1 | Mọi user thuộc store: xem lịch sử, thu nợ, sửa hạn mức |

## 3. Dữ liệu & sync

### 3.1 Schema (PostgreSQL / Prisma)

**`Customer`** — thêm:

- `creditLimitVnd Int?` — `null` = không áp hạn mức

**`DebtLedgerEntry`** (mới):

| Cột | Ý nghĩa |
|---|---|
| `id` | UUID client hoặc server; khóa idempotent |
| `storeId` | Điểm bán |
| `customerId` | Khách |
| `type` | `sale_debt` \| `payment` |
| `amountVnd` | Luôn > 0 |
| `balanceAfterVnd` | Số dư sau bút toán (snapshot) |
| `saleId` | Nullable — gắn sale khi `sale_debt` |
| `shiftId` | Nullable — ca đang mở khi thu / bán |
| `recordedById` | User ghi |
| `paymentMethod` | Nullable — `cash` \| `transfer` chỉ khi `payment` |
| `note` | Nullable |
| `clientCreatedAt` | Thời điểm máy client |
| `createdAt` / `updatedAt` | Server |

Index: `(storeId, clientCreatedAt)`, `(customerId, clientCreatedAt)`.

### 3.2 Local (Drift)

- Mirror `customers` thêm `creditLimitVnd`
- Bảng `debt_ledger_local` tương đương
- Outbox type mới: `debt_payment`

### 3.3 Luồng nghiệp vụ

1. **Bán nợ** (đã có): tăng `balanceVnd`; khi apply sale (local checkout + server push) **đồng thời** ghi entry `sale_debt` vào ledger. Mỗi sale nợ có đúng một `sale_debt`; `saleId` unique khi `type = sale_debt` (idempotent nếu push/retry).
2. **Thu nợ**: local giảm `balanceVnd` + ghi `payment` + enqueue outbox → server apply idempotent theo `id`, giảm balance, ghi ledger. Reject nếu `amount > balance` hoặc sai store.
3. **Pull**: clients kéo `customers` (`balanceVnd`, `creditLimitVnd`, …) và `debt_ledger` theo store/cursor (cùng pattern pull stock).
4. **Sửa hạn mức**: cập nhật local ngay; đẩy qua outbox `customer_upsert` (cùng payload upsert khách đã có, thêm `creditLimitVnd`). Server upsert field; pull sau đó là nguồn đúng.

Server luôn là nguồn đúng sau sync; local có thể lệch tạm đến khi pull.

## 4. UI & hạn mức checkout

### 4.1 Màn hình

1. **Khách nợ** — mở rộng list hiện có: tap → **Chi tiết** (số dư, hạn mức, lịch sử ledger local).
2. **Thu nợ** — từ chi tiết: số tiền (mặc định = còn nợ), `tiền mặt` / `chuyển khoản`, ghi chú tùy chọn → xác nhận → ghi local ngay.
3. **Sửa hạn mức** — trên chi tiết; local + outbox `customer_upsert` (xem §3.3).
4. **Payment sheet** — khi `nợ > 0` và đã chọn khách: nếu vượt hạn → chặn Confirm + thông báo (số dư, hạn, còn được nợ).

### 4.2 Công thức hạn mức

```text
creditLimitVnd != null AND (balanceVnd + debtAmount > creditLimitVnd)
  → reject
```

- Local: chặn trước khi ghi sale (tránh outbox thừa).
- Server: khi push sale nợ, reject `credit_limit_exceeded` (race multi-device).
- Thu nợ **không** dùng hạn mức; chỉ không cho thu > số dư (local + server `payment_exceeds_balance`).

## 5. Biên & xung đột

| Tình huống | Xử lý |
|---|---|
| Retry outbox thu nợ | Idempotent theo `DebtLedgerEntry.id` — không trừ đôi |
| `amount > balance` trên server | Reject `payment_exceeds_balance`; giữ failed outbox như sale reject |
| Multi-device lệch số dư | Pull customers + ledger sau sync |
| Bán nợ offline vượt hạn (balance cũ) | Server reject `credit_limit_exceeded`; sale không apply |
| Sửa / xóa phiếu thu đã ghi | Ngoài scope Phase 1 |
| Thu âm / hoàn tác | Ngoài scope |

## 6. Acceptance

1. Thu nợ một phần/toàn phần offline → số dư local giảm; sau sync server khớp; lịch sử có dòng `payment`.
2. Bán nợ tạo dòng `sale_debt` trên ledger (local khi checkout; server khi push).
3. Khách có `creditLimitVnd`: checkout nợ vượt hạn bị chặn; `null` vẫn bán nợ bình thường.
4. e2e API: payment idempotent; reject vượt số dư; reject sale vượt hạn mức.
5. Flutter test: credit check + thu nợ cập nhật balance/outbox.

## 7. Thứ tự triển khai gợi ý (sau khi duyệt → plan)

1. Migration Prisma + Drift (`creditLimitVnd`, `DebtLedgerEntry`)
2. Server: ghi `sale_debt` khi push sale; push/pull `debt_payment` + credit check
3. Client: thu nợ + chi tiết + lịch sử
4. Client: credit limit trên payment sheet + checkout
5. Tests e2e + unit/widget

## 8. Liên quan tiếp theo

Sau #1: **#2 Thu chi + đối chiếu tiền ca**, rồi **#3 Kho vận hành** — mỗi cái một vòng spec → plan → code riêng.
