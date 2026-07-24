# Thiết kế: Thu chi + đối chiếu tiền ca (Phase 1 remaining #2)

**Ngày:** 2026-07-24  
**Dự án:** `tap-hoa`  
**Trạng thái:** Đã duyệt  
**Spec gốc:** `docs/superpowers/specs/2026-07-23-tap-hoa-pos-ke-toan-design.md` (§4.6)  
**Checklist:** `docs/superpowers/plans/2026-07-23-phase1-remaining.md`

## 1. Mục tiêu

Hoàn thiện remaining #2 đầy đủ:

- **Phiếu thu/chi** có danh mục (seed cố định), kênh tiền mặt / chuyển khoản, offline-first qua outbox
- **Đối chiếu tiền ca** khi đóng ca: tiền mặt kỳ vọng vs đếm thực tế; chuyển khoản trong ca chỉ hiển thị
- **Sổ thu chi** gắn ca / điểm bán (list phiếu)

**Không làm lần này:** sửa/xóa phiếu đã ghi, CRUD danh mục trên app, chặn đóng ca khi lệch, quỹ ngân hàng / sổ kế toán GĐ2, ngưỡng lệch cấu hình.

## 2. Quyết định đã chốt

| Hạng mục | Quyết định |
|---|---|
| Phạm vi | A — đủ 3 hạng mục remaining #2 (phiếu + đối chiếu + sổ) |
| Kiến trúc | A — `CashVoucher` + `CashCategory` seed + outbox (không gom mọi dòng két vào một ledger) |
| Expected cash | C — hai dòng: tiền mặt kỳ vọng (đối chiếu) + CK trong ca (chỉ hiển thị) |
| Danh mục | A — seed cố định; Phase 1 không CRUD trên app |
| Đóng ca khi lệch | A — vẫn cho đóng; lưu `closingCash`, `expectedCash`, `variance`, ghi chú tùy chọn |
| Kênh phiếu | B — `cash` \| `transfer`; chỉ phiếu tiền mặt vào expected |
| UI điều hướng | Hybrid — tab Thu chi = sổ + tạo phiếu; Đóng ca từ POS/app bar |
| UI đóng ca | Có breakdown công thức (mở ca / bán TM / thu nợ TM / phiếu ±) |
| Offline | Có — ghi local + outbox; server nguồn đúng sau sync |
| Quyền Phase 1 | Mọi user thuộc store: tạo phiếu, xem sổ, đóng ca |

## 3. Dữ liệu & sync

### 3.1 Schema (PostgreSQL / Prisma)

**`CashCategory`** (seed):

| Cột | Ý nghĩa |
|---|---|
| `id` | UUID ổn định |
| `code` | Unique — vd. `electricity`, `rent`, `salary_advance`, `other_out`, `other_in` |
| `name` | Tên hiển thị |
| `direction` | `in` \| `out` |
| `sortOrder` | Int |

**`CashVoucher`:**

| Cột | Ý nghĩa |
|---|---|
| `id` | UUID client; khóa idempotent |
| `storeId` | Điểm bán |
| `shiftId` | Ca đang mở (bắt buộc) |
| `categoryId` | FK `CashCategory` |
| `direction` | `in` \| `out` — phải khớp category |
| `channel` | `cash` \| `transfer` |
| `amountVnd` | Luôn > 0 |
| `note` | Nullable |
| `recordedById` | User ghi |
| `clientCreatedAt` | Thời điểm máy client |
| `createdAt` / `updatedAt` | Server |

Index: `(storeId, clientCreatedAt)`, `(shiftId, clientCreatedAt)`.

**`Shift`** — thêm khi đóng:

- `expectedCashVnd Int?` — snapshot tiền mặt kỳ vọng lúc đóng
- `varianceVnd Int?` — `closingCash − expectedCashVnd`
- `transferInShiftVnd Int?` — snapshot CK trong ca (không đối chiếu đếm két)
- Đã có: `closingCash`, `note`

### 3.2 Local (Drift)

- Mirror `cash_categories`, `cash_vouchers`
- `shifts`: thêm các cột snapshot đóng ca
- Outbox type mới: `cash_voucher`
- Mở rộng payload `shift_close`: `closingCash`, `expectedCashVnd`, `varianceVnd`, `transferInShiftVnd`, `note`

### 3.3 Công thức đóng ca

```text
expectedCash =
  openingCash
  + Σ sale.cashAmount (shift)
  + Σ debt_payment.amountVnd WHERE paymentMethod = cash (shift)
  + Σ voucher.amountVnd WHERE direction = in  AND channel = cash (shift)
  − Σ voucher.amountVnd WHERE direction = out AND channel = cash (shift)

variance = closingCash − expectedCash

transferInShift =
  Σ sale.transferAmount (shift)
  + Σ debt_payment.amountVnd WHERE paymentMethod = transfer (shift)
  + Σ voucher.amountVnd WHERE direction = in  AND channel = transfer (shift)
  − Σ voucher.amountVnd WHERE direction = out AND channel = transfer (shift)
```

- Local tính từ dữ liệu Drift của ca trước khi ghi đóng ca.
- Server tính lại từ dữ liệu đã apply khi nhận `shift_close` / close API; lưu snapshot trên `Shift`.
- Phần nợ trên hóa đơn (`debtAmount`) **không** vào expected hay CK.

### 3.4 Luồng nghiệp vụ

1. **Tạo phiếu:** bắt buộc ca mở → chọn category (đúng direction) → channel → amount → note tùy chọn → ghi local + outbox `cash_voucher` ngay.
2. **Push phiếu:** server upsert idempotent theo `id`; reject nếu không ca mở / category lệch direction / amount ≤ 0 / sai store.
3. **Đóng ca:** UI hiện breakdown + expected + CK + nhập `closingCash` + variance + note → local đóng ca + outbox `shift_close` (payload mở rộng). Cho đóng khi còn phiếu pending trong outbox (offline-first). Cả `POST /shifts/:id/close` và sync `shift_close` đều nhận `closingCash` + `note` (và có thể kèm snapshot client); **server luôn tính lại** `expectedCashVnd`, `varianceVnd`, `transferInShiftVnd` từ dữ liệu đã apply rồi lưu — không tin số client.
4. **Pull:** `cashCategories` (full / ít đổi) + `cashVouchers` theo store/cursor. Snapshot đóng ca nằm trên bản ghi `Shift` sau push close.

Server luôn là nguồn đúng sau sync; local có thể lệch tạm đến khi pull.

## 4. UI & luồng

### 4.1 Điều hướng (hybrid)

- **Tab Thu chi:** sổ phiếu (lọc ca đang mở / theo điểm) + nút tạo phiếu thu / chi.
- **Đóng ca:** từ POS / app bar (luồng cuối ca) — không đặt nút Đóng ca trong tab Thu chi làm lối chính.

### 4.2 Màn hình

1. **Sổ thu chi** — list phiếu: direction, category name, channel, amount, thời gian; empty state khi chưa có.
2. **Sheet tạo phiếu** — category (theo direction), channel TM/CK, amount, note → xác nhận.
3. **Đóng ca** — breakdown TM (mở ca, bán TM, thu nợ TM, phiếu thu−chi TM) → dòng **Tiền mặt kỳ vọng** → dòng **CK trong ca** → ô nhập tiền đếm → **Lệch** tự tính → ghi chú tùy chọn → Đóng ca (cho phép lệch ≠ 0).

### 4.3 Quyền

Phase 1: mọi user thuộc store được tạo phiếu, xem sổ, đóng ca của mình / theo rule shift hiện có (không thêm RBAC mới).

## 5. Biên & xung đột

| Tình huống | Xử lý |
|---|---|
| Không có ca mở khi tạo phiếu | Chặn local + server `shift_not_open` |
| Retry outbox phiếu | Idempotent theo `CashVoucher.id` |
| Category sai direction | Reject `category_direction_mismatch` |
| `amount ≤ 0` | Reject |
| Đóng ca còn outbox phiếu pending | Cho đóng; expected từ local đã ghi; server khớp sau apply |
| Đóng ca đã đóng / trùng | Giữ hành vi API hiện tại (reject) |
| Multi-device lệch expected | Server tính lại từ sales + debt payments + vouchers đã apply; lưu snapshot; client pull |
| Sửa / xóa phiếu đã ghi | Ngoài scope |
| Chặn đóng khi lệch | Ngoài scope |

## 6. Acceptance

1. Tạo phiếu thu/chi TM hoặc CK offline → sổ local; sau sync server khớp.
2. Đóng ca hiện breakdown; lưu `closingCash`, `expectedCashVnd`, `varianceVnd`, `transferInShiftVnd`, `note`.
3. Chỉ bán/thu nợ/phiếu **tiền mặt** vào expected; CK chỉ vào dòng CK trong ca.
4. e2e API: voucher idempotent; reject không ca / category lệch; close shift snapshot đúng công thức.
5. Flutter: unit test công thức expected + service tạo phiếu / đóng ca (outbox).

## 7. Thứ tự triển khai gợi ý (sau khi duyệt → plan)

1. Migration Prisma + seed `CashCategory` + Drift (`CashVoucher`, cột Shift)
2. Server: push/pull `cash_voucher`; mở rộng close shift / `shift_close` + tính expected
3. Client: sổ thu chi + sheet tạo phiếu + outbox
4. Client: UI đóng ca (breakdown + variance)
5. Tests e2e + unit

## 8. Liên quan tiếp theo

Sau #2: **#3 Chuyển kho / kiểm kê / phiếu nhập NCC**, rồi catalog CRUD / in nhiệt — mỗi cái một vòng spec → plan → code riêng.
