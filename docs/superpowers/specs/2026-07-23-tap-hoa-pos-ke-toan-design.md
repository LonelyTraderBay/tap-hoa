# Thiết kế phần mềm POS + kế toán quán tạp hóa

**Ngày:** 2026-07-23  
**Dự án:** `tap-hoa`  
**Trạng thái:** Đã duyệt — triển khai Giai đoạn 1

## 1. Mục tiêu

Xây dựng phần mềm vận hành và kế toán cho **một chủ, nhiều điểm bán tạp hóa (2–3 quán/quầy)**:

- **Giai đoạn 1:** POS + kho + công nợ khách + thu chi cơ bản + báo cáo vận hành
- **Giai đoạn 2:** Kế toán sâu (sổ, giá vốn, NCC, quỹ) + hóa đơn điện tử

## 2. Quyết định đã chốt

| Hạng mục | Quyết định |
|---|---|
| Phạm vi | Làm theo 2 giai đoạn (C) |
| Client | Windows tại quầy **và** tablet đều bán được; app ĐT/tablet thêm kiểm kho + xem doanh thu |
| Quy mô | Nhiều điểm bán; báo cáo theo điểm và tổng hợp |
| Mạng | Offline-first: bán khi mất mạng, có mạng thì đồng bộ |
| Công nợ khách | Đầy đủ: còn nợ + lịch sử trả |
| Thuế / HĐĐT | Tích hợp NCC HĐĐT (Viettel, MISA, EasyInvoice…) ở giai đoạn 2 |
| Kiến trúc | **Hướng 1 — Local-first đa nền tảng** (một app, DB local, sync server trung tâm) |

## 3. Kiến trúc tổng thể

### 3.1 Mô hình

- **Client thống nhất** (Flutter) trên Windows + Android/iOS
- **SQLite local** trên mỗi máy: ghi chứng từ ngay, bán offline
- **Backend trung tâm:** đồng bộ đơn hàng, tồn kho, khách nợ, danh mục giữa các điểm
- Mỗi điểm bán có **tồn kho riêng**; chủ xem theo điểm hoặc tổng hợp

```text
[Máy Windows quầy A]     [Tablet quầy B]     [Điện thoại chủ]
   SQLite local  ◄──────── sync ────────►  Server + DB trung tâm
   bán offline                              (đơn, kho, nợ, user)
```

### 3.2 Vai trò người dùng

- **Chủ:** mọi điểm, báo cáo tổng, cấu hình, khóa sổ (GĐ2), HĐĐT
- **Quản lý điểm:** vận hành một/điểm được gán, kho, công nợ, báo cáo điểm
- **Thu ngân:** POS, mở/đóng ca, thu nợ cơ bản (theo phân quyền)

## 4. Giai đoạn 1 — POS + kho

### 4.1 Hệ thống & điểm bán

- Đăng nhập, phân quyền Chủ / Quản lý điểm / Thu ngân
- Quản lý 2–3 điểm bán; chọn điểm khi mở ca
- Mở/đóng ca: tiền đầu ca, cuối ca, chênh lệch
- Đồng bộ thủ công + tự động; UI trạng thái “chưa đồng bộ”

### 4.2 Danh mục hàng hóa

- Sản phẩm: mã, barcode, tên, đơn vị, nhóm, giá bán, giá nhập gần nhất
- Hàng cân (kg), hàng chiếc, combo/đóng gói
- Quy đổi đơn vị (thùng ↔ chai)
- Tồn tối thiểu theo từng điểm bán
- In/dán tem mã vạch (tùy chọn)

### 4.3 POS bán hàng (Windows + tablet)

- Quét mã / tìm nhanh / bán theo cân
- Giỏ hàng: sửa SL, giảm giá dòng/hóa đơn, hủy dòng
- Thanh toán: tiền mặt, chuyển khoản, kết hợp, **ghi nợ**
- In hóa đơn nhiệt / gửi ảnh hóa đơn
- Đổi trả trong ngày (có phân quyền)
- Offline đầy đủ; đồng bộ khi có mạng

### 4.4 Kho & nhập hàng

- Phiếu nhập từ NCC (có/không đơn đặt hàng)
- Chuyển kho giữa điểm bán
- Kiểm kê: lệch tăng/giảm + lý do
- Xuất hủy / hao hụt
- Xuất nhập tồn theo điểm

### 4.5 Công nợ khách

- Hồ sơ khách: tên, SĐT, hạn mức nợ (tùy chọn)
- Bán ghi nợ gắn khách + điểm bán
- Thu nợ toàn phần/một phần, nhiều lần
- Sổ nợ: số còn lại, lịch sử mua/trả, cảnh báo quá hạn
- Báo cáo công nợ theo điểm / tổng

### 4.6 Thu chi cơ bản

- Phiếu thu/chi (điện, thuê mặt bằng, ứng lương, chi khác)
- Gắn điểm bán + danh mục
- Đối chiếu với tiền ca và tồn quỹ tạm
- **Chưa** là sổ kế toán đầy đủ (để Giai đoạn 2)

### 4.7 Báo cáo Giai đoạn 1

- Doanh thu theo ngày/ca/điểm/tổng
- Top hàng bán chạy; lãi gộp **ước tính** (giá bán − giá nhập gần nhất)
- Tồn kho theo điểm, hàng sắp hết
- Công nợ phải thu
- Xem trên điện thoại khi đi chợ / ngoài quầy

### 4.8 App điện thoại (ngoài quầy)

- Doanh thu nhanh (ngày / điểm / tổng)
- Kiểm kho / quét mã xem tồn
- Thu nợ tại chỗ (mạng hoặc xếp hàng đồng bộ)
- Thông báo tùy chọn: sắp hết hàng, nợ lớn

## 5. Giai đoạn 2 — Kế toán sâu + HĐĐT

Giai đoạn 2 **sinh bút toán từ chứng từ Giai đoạn 1**, không nhập lại tay.

### 5.1 Sổ kế toán

- Hệ thống tài khoản gọn cho hộ KD / DN nhỏ
- Tự sinh bút toán từ bán hàng, giá vốn, tiền mặt, công nợ…
- Sổ nhật ký, sổ cái, cân đối phát sinh
- Khóa sổ theo kỳ (tháng); sửa sau khóa cần quyền + audit

### 5.2 Giá vốn & lãi thật

- Chọn **một** phương pháp khi triển khai: bình quân gia quyền **hoặc** FIFO
- Giá vốn theo lần bán / phiếu xuất
- Lãi gộp / lãi ròng theo điểm và tổng (đáng tin hơn GĐ1)

### 5.3 Công nợ nhà cung cấp

- Hồ sơ NCC, phải trả
- Nhập hàng → tăng nợ; chi trả / trả hàng → giảm nợ
- Đối chiếu sao kê theo kỳ

### 5.4 Quỹ & ngân hàng

- Sổ quỹ tiền mặt theo điểm / tổng
- Tài khoản ngân hàng; đối chiếu chuyển khoản POS
- Phiếu chi / báo có mức đơn giản

### 5.5 Hóa đơn điện tử

- Adapter tích hợp Viettel / MISA / EasyInvoice… (đổi NCC không đụng lõi)
- Lập HĐ từ đơn bán (lẻ hoặc gộp theo khách)
- Trạng thái: chờ ký, đã cấp mã, hủy/điều chỉnh
- Lưu MST khách, mẫu số, ký hiệu; XML/PDF khi cần
- Chỉ xuất HĐ khi **có mạng** và đơn **đã sync thành công**

### 5.6 Báo cáo tài chính & thuế (vừa đủ)

- Cân đối phát sinh, KQKD theo kỳ
- Tổng hợp doanh thu / VAT đầu ra–đầu vào (nếu GTGT)
- Export Excel/PDF cho kế toán thuê
- **Ngoài scope:** kê khai thuế tự động lên cơ quan thuế

### 5.7 Kiểm soát & audit

- Nhật ký: sửa giá, xóa đơn, điều chỉnh nợ, mở khóa sổ
- Tách quyền: bán hàng ≠ kế toán ≠ xuất HĐĐT

### 5.8 Thứ tự triển khai Giai đoạn 2

1. Giá vốn
2. Sổ tự động từ chứng từ
3. Công nợ NCC + quỹ
4. HĐĐT
5. Báo cáo kỳ

## 6. Đồng bộ offline & xử lý lỗi

### 6.1 Luồng

1. Đăng nhập → chọn điểm bán → mở ca
2. Mọi chứng từ ghi **SQLite local** ngay
3. Có mạng → đẩy hàng đợi sync → kéo thay đổi điểm khác
4. Đóng ca → đối chiếu tiền mặt local; online thì server xác nhận tổng ca

### 6.2 Quy tắc xung đột

| Tình huống | Xử lý |
|---|---|
| Hai máy bán cùng SP khi offline | Giữ cả hai đơn; tồn server = tồn − tổng SL theo thời gian |
| Tồn về âm | Cảnh báo; cho bán nếu cấu hình cho phép; báo cáo lệch để kiểm kê |
| Sửa đơn đã sync | Tạo chứng từ điều chỉnh (không xóa im lặng) |
| Thu nợ trùng (2 máy) | Server từ chối lần sau nếu hết nợ; máy hoàn tác local |
| Xuất HĐĐT | Chỉ khi đơn đã sync thành công |

### 6.3 Phục hồi

- Hàng đợi sync: chờ / lỗi / xong — xem được trên UI
- Lỗi mạng: không chặn bán
- Xung đột nghiêm trọng: giữ local, đánh dấu “cần chủ xử lý”
- Sao lưu local định kỳ; khôi phục từ backup máy + server

### 6.4 Kiểm thử tối thiểu (xong Giai đoạn 1)

- Bán offline → online → đủ đơn trên điểm khác & báo cáo tổng
- Hai điểm bán cùng lúc cùng mặt hàng
- Ghi nợ + thu nợ một phần trên máy khác
- Mất mạng giữa chừng khi đang sync

## 7. Phạm vi loại trừ (YAGNI)

- Đặt hàng online / website bán lẻ
- Chương trình loyalty phức tạp (điểm thưởng nhiều tầng)
- Quản lý nhân sự / chấm công đầy đủ
- Kê khai thuế tự động lên CQT
- Chuỗi > ~10 điểm (thiết kế hiện tại tối ưu 2–3 điểm; mở rộng sau nếu cần)

## 8. Tiêu chí thành công

**Giai đoạn 1:** Quầy bán ổn khi mất mạng; tồn và doanh thu đúng theo điểm + tổng; sổ nợ khách dùng được hàng ngày.  
**Giai đoạn 2:** Lãi theo giá vốn tin cậy; xuất được HĐĐT từ đơn đã sync; khóa sổ tháng có audit.

## 9. Bước tiếp theo

Implementation plan Giai đoạn 1 MVP: `docs/superpowers/plans/2026-07-23-phase1-foundation-pos.md`
