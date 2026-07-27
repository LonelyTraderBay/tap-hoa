# Ghi chú phát hành — Giai đoạn 1 (POS + kho)

**Dự án:** tap-hoa  
**Ngày:** 2026-07-23  
**Nhánh:** `feat/phase1-pos-mvp`  
**Commit gốc kỹ thuật:** `2807b2c`

## Mục tiêu đã giao

Xây dựng MVP **offline-first** cho quán tạp hóa nhiều điểm bán (2–3 cửa hàng):

- Bán hàng trên Windows và tablet/điện thoại (Flutter)
- Đồng bộ đơn hàng / tồn kho khi có mạng
- Công nợ khách cơ bản
- Báo cáo doanh thu theo ngày (múi giờ ICT)
- API trung tâm NestJS + PostgreSQL

## Phạm vi đã hoàn thành

### Hệ thống & điểm bán
- Đăng nhập JWT, phân quyền `owner` / `store_manager` / `cashier`
- Nhiều điểm bán; mở/đóng ca thu ngân
- Đồng bộ hàng đợi (outbox) + banner trạng thái sync

### Danh mục & kho tại quầy
- Kéo danh mục / tồn về máy local (Drift/SQLite)
- Trừ tồn khi bán; cho phép tồn âm theo chính sách offline
- Đồng bộ tồn giữa các thiết bị sau khi đẩy đơn
- Tạo/sửa sản phẩm offline (owner / store_manager); đẩy `product_upsert` qua outbox
- Seed tồn ban đầu chỉ cho cửa hàng hiện tại; cập nhật không ghi đè số lượng tồn
- In tem mã vạch (PDF) qua hộp thoại in hệ điều hành

### POS offline
- Giỏ hàng (hàng cân, giảm giá hóa đơn, làm tròn VND half-up)
- Thanh toán tiền mặt / chuyển khoản / ghi nợ
- Không chặn bán khi mất mạng

### Công nợ khách (stub Giai đoạn 1)
- Tạo/chọn khách khi ghi nợ
- Đồng bộ tăng `balanceVnd` kèm upsert khách offline
- Danh sách khách còn nợ
- Thu nợ offline (một phần/toàn phần) + sổ công nợ; hạn mức tín dụng khi bán nợ

### Thu chi quỹ & đóng ca
- Phiếu thu/chi offline theo danh mục seed (không CRUD danh mục)
- Sổ thu chi theo ca/cửa hàng; đồng bộ qua outbox
- Đóng ca đối chiếu tiền mặt kỳ vọng vs thực tế; hiển thị tách tiền mặt / chuyển khoản
- Cho phép đóng ca khi lệch quỹ (ghi chú); server tính lại expected cash

### Báo cáo
- Doanh thu theo ngày, theo cửa hàng và tổng (chủ)
- Mốc ngày theo **Asia/Ho_Chi_Minh (ICT)**
- Fallback offline khi mất mạng (chỉ lỗi kết nối)

### Tài liệu
- Spec thiết kế, plan triển khai, runbook README
- Checklist nghiệm thu MVP
- Danh mục hạng mục Giai đoạn 1 còn lại

## Cố ý chưa làm (plan sau)

Xem `docs/superpowers/plans/2026-07-23-phase1-remaining.md` (Phase 1 polish đã tick).

**Giai đoạn 2 (2026-07-25):** Done + closeout PASS — sổ kế toán, WAC, AP/NCC, HĐĐT stub, báo cáo kỳ, Flutter surfaces, bút toán trả hàng/kiểm kê.  
Gate: `docs/superpowers/plans/2026-07-25-phase2-hardening.md`.

**Phase 3 (outline):** VAT/GTGT CoA thật; provider HĐĐT thật; Excel/PDF; trả hàng NCC; đối chiếu CK đầy đủ.
## Cách chạy nhanh

Local DB = **Supabase only** (`project_id=tap-hoa`, DB `tap_hoa` cổng **54422**, API **3040**). Chi tiết: `docs/ops/local-dev.md`.

1. Repo root: `.\scripts\dev-up.ps1` → `.\scripts\dev-setup.ps1` → `.\scripts\start-api.ps1`
2. `apps/pos_app`: `flutter run -d windows --dart-define=API_URL=http://127.0.0.1:3040`
3. Đăng nhập seed: `0900000001` / `123456`
4. Studio: http://127.0.0.1:54423

## Kiểm thử đã ghi nhận

- API e2e: bộ suite Phase 1 (auth, ca, sync, báo cáo, công nợ) — **PASS**
- Flutter: `flutter analyze` sạch; `flutter test` trên Windows đôi khi kẹt `sqlite3.dll` (hạ tầng native-assets)

## Rủi ro còn lại (đã giảm sau review)

- Nên chạy lại `flutter test` trên máy sạch trước khi triển khai thực tế
- `JWT_SECRET` bắt buộc cấu hình đúng môi trường (không dùng secret mặc định ngoài dev/test)
- Outbox `shift_open` phải đẩy trước `sale` (đã sửa) — cần smoke-test offline → online đầy đủ trên 2 máy
