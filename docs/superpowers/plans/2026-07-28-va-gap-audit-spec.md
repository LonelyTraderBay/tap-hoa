# Vá gap audit spec §4–§6 (đợt 2) — 6 mục phát hiện qua đối chiếu code thật

> **For agentic workers:** Subagent-Driven Development — **một Task = một subagent**, review giữa các task, không mở task tiếp theo khi task trước chưa PASS review.
> **Nguồn:** đối chiếu code thật (không dựa vào docs/plan cũ) với `docs/superpowers/specs/2026-07-23-tap-hoa-pos-ke-toan-design.md` §4–§6, chạy 8 subagent song song 2026-07-28 trên `main` @ `a5e82fd` (sau khi PR #27 "hoàn thiện 100% đợt 1" đã merge).
> **Branch:** `claude/spec-gap-audit-fixes`.

**Goal:** Vá 6 gap thật phát hiện qua audit toàn diện — 3 mục "Nghiêm trọng" (compliance/audit trail + UX chặn đúng tinh thần spec), 3 mục "Nên sửa" (bug rõ + thiếu cảnh báo + thiếu phân quyền thao tác).

**Không nằm trong phạm vi đợt này** (ghi nhận nhưng chưa đủ rõ ý định để coi là gap): backup/restore phía server (chỉ có client), "gửi ảnh hóa đơn" gửi PDF thay vì ảnh raster.

**Architecture:** Không đổi monorepo. Offline-first giữ nguyên: chứng từ mới → Drift + outbox + sync DTO + e2e. Bút toán/audit mới bám `LedgerService` / `journal-builders` + `defaultAuditActions` allowlist.

**Tech Stack:** NestJS 10 + Prisma + PostgreSQL (`apps/api`); Flutter 3 + Drift (`apps/pos_app`).

## Global Constraints

- Thay đổi sổ/sync/audit → **bắt buộc e2e**; Flutter → `flutter analyze` sạch trên path đụng.
- Không mở YAGNI §7 (website, loyalty, HR, chuỗi > ~10 điểm, nộp CQT).
- Mọi task phải chạy được `npm run build` + `npm run test:unit` (API) trước khi review; e2e xác nhận qua container Postgres riêng (không đụng dev DB thật), theo đúng phương pháp đã dùng suốt đợt 1.
- Seed `0900000001` / `123456` chỉ dev/test.
- Không `npm audit fix --force`.

---

## Trạng thái

| Task | Mô tả | Ưu tiên | Status |
|------|-------|---------|--------|
| **G1** | Ghi AuditLog cho trả hàng/hủy đơn | Cao | Done (build xanh, unit 76/76, e2e 39 suite/140 test pass) |
| **G2** | Rà soát + bổ sung toàn bộ action còn thiếu trong `defaultAuditActions` allowlist | Cao | Chưa |
| **G3** | Lối "Xem nhanh, không mở ca" cho app ngoài quầy (owner/store_manager) | Cao | Chưa |
| **G4** | Sửa `minQty` không sửa được sau khi tạo sản phẩm | Trung bình | Chưa |
| **G5** | Cảnh báo khi bán khiến tồn về âm (được cấu hình cho phép) | Trung bình | Chưa |
| **G6** | Đánh dấu `dead_letter` = "cần chủ xử lý" + khoá thao tác cho cashier | Trung bình | Chưa |

---

## G1 — Ghi AuditLog cho trả hàng/hủy đơn (§5.7, Cao)

**Vấn đề:** `apps/api/src/sync/sale-returns.service.ts::processFromSync` (dòng 39-275) tạo `SaleReturn` + `StockMovement` + bút toán sổ cái (`postFromSaleReturn`) nhưng **không hề gọi `tx.auditLog.create`**. Đây đúng là nghiệp vụ "xóa/hủy đơn" mà spec §5.7 yêu cầu phải có nhật ký — hiện không có dấu vết nào trong `AuditLog`.

**DoD:**
- [x] `processFromSync` ghi 1 `AuditLog` khi tạo `SaleReturn` thành công, action đặt tên nhất quán với các action hiện có (vd `sale_return_create`), payload đủ để truy vết: `saleId`, `storeId`, actor (`userId`), số tiền hoàn, lý do (nếu client có gửi).
- [x] Action mới được thêm vào `defaultAuditActions` (`ledger.service.ts`) **ngay trong task này** — không để lặp lại đúng lỗi của G2.
- [x] `sale-returns.e2e-spec.ts` (hoặc file e2e liên quan) có test: trả hàng xong → `GET /ledger/audit` (không truyền `action`) trả về đúng bản ghi, đủ field.
- [x] `npm run build` + `test:unit` + full `test:e2e` xanh (container Postgres riêng).

---

## G2 — Rà soát + bổ sung `defaultAuditActions` allowlist (§5.7, Cao)

**Vấn đề:** `debt_adjust` được ghi thật vào `AuditLog` (`apps/api/src/customers/customers.service.ts:151-167`) nhưng `defaultAuditActions` (`apps/api/src/ledger/ledger.service.ts:30-41`) — allowlist dùng làm bộ lọc mặc định cho `GET /ledger/audit` khi client không truyền `action` — **thiếu `'debt_adjust'`**, nên màn "Sổ · Nhật ký" trên Flutter (`ledger_page.dart`, gọi `listAudit` không truyền `action`) không bao giờ hiện log này dù nó tồn tại trong DB. Cùng lỗi khả năng cao còn ở `bank_recon_locked`/`ap_recon_locked` (phát hiện qua audit nhưng chưa xác nhận kỹ) và có thể còn action khác chưa rà hết.

**DoD:**
- [ ] Grep toàn bộ `apps/api/src` tìm mọi lời gọi tạo `AuditLog` (`auditLog.create`), liệt kê đầy đủ action string thật đang tồn tại trong code.
- [ ] Đối chiếu danh sách đó với `defaultAuditActions`, bổ sung **mọi** action còn thiếu (tối thiểu: `debt_adjust`; xác nhận lại `bank_recon_locked`, `ap_recon_locked`).
- [ ] Test (unit hoặc e2e) xác nhận `GET /ledger/audit` không truyền `action` trả về đủ các action vừa bổ sung, không cần biết trước tên action.
- [ ] `npm run build` + `test:unit` + full `test:e2e` xanh.

---

## G3 — Lối "Xem nhanh, không mở ca" cho app ngoài quầy (§4.7/§4.8, Cao)

**Vấn đề:** Tinh thần spec §4.8 là chủ quán xem nhanh doanh thu/tồn/công nợ khi "đi chợ, ngoài quầy" — nhưng luồng thật bắt buộc `login → chọn điểm → mở ca` mới vào được bất kỳ màn báo cáo nào (`pos_page.dart` là cửa duy nhất tới `DayReportPage`/`DebtCustomerListPage`/`stock check`). Nếu ca đã mở ở máy khác, `open_shift_page.dart:143-145` chặn cứng bằng text lỗi, không có lối thoát.

**Thiết kế đã chốt với user (2026-07-28):** thêm lựa chọn "Xem nhanh (không mở ca)" song song luồng mở ca hiện có, **chỉ cho owner/store_manager** (thu ngân vẫn bắt buộc mở ca vì việc chính là bán hàng tại quầy).

**DoD:**
- [ ] Sau đăng nhập thành công, owner/store_manager thấy thêm lựa chọn "Xem nhanh (không mở ca)" cạnh luồng mở ca hiện tại; cashier không thấy lựa chọn này (giữ nguyên luôn phải mở ca).
- [ ] Màn "Xem nhanh" (route/page mới, read-only) cho vào: báo cáo doanh thu nhanh, kiểm kho/quét mã xem tồn, danh sách công nợ — thu nợ tại chỗ từ màn này vẫn hoạt động bình thường (ghi outbox không cần ca đang mở).
- [ ] owner ở màn "Xem nhanh" xem tổng hợp mọi điểm (khớp hành vi báo cáo hiện tại khi `storeId=null`); store_manager giới hạn đúng điểm được gán.
- [ ] Có đường quay lại/điều hướng sang mở ca bán hàng bình thường bất cứ lúc nào từ màn "Xem nhanh".
- [ ] Màn báo lỗi "Đã có ca đang mở tại cửa hàng này" (`open_shift_page.dart`) có thêm lối vào "Xem nhanh" thay vì chỉ chặn cứng.
- [ ] `flutter test` phủ điều hướng mới (owner/store_manager thấy lựa chọn, cashier không thấy); `flutter analyze` sạch.

---

## G4 — Sửa `minQty` không sửa được sau khi tạo sản phẩm (§4.2, Trung bình)

**Vấn đề:** `apps/pos_app/lib/features/products/product_form_sheet.dart:509-529` chỉ hiện ô "Tồn tối thiểu" khi `widget.isCreate`; `apps/pos_app/lib/features/products/product_service.dart:144-162` (`update()`) chỉ gửi `minQty` khi `existingStock == null`. Backend (`apps/api/src/products/products.service.ts:296-324`) đã hỗ trợ cập nhật `minQty` cho tồn đã tồn tại — bug nằm hoàn toàn ở client.

**DoD:**
- [ ] Ô "Tồn tối thiểu" hiện cả khi sửa sản phẩm đã tồn tại, load đúng giá trị hiện tại làm mặc định.
- [ ] `product_service.dart::update()` luôn gửi `minQty` (kể cả khi `existingStock != null`) tới backend qua kênh phù hợp (`seedStock` hoặc field tương đương).
- [ ] `flutter test` xác nhận round-trip: sửa `minQty` trên sản phẩm đã có tồn kho → đọc lại đúng giá trị mới.
- [ ] `flutter analyze` sạch trên path đụng.

---

## G5 — Cảnh báo khi bán khiến tồn về âm (§6.2, Trung bình)

**Vấn đề:** `checkout_service.dart:107,331` cho phép bán khi `allowNegativeStock=true` (đúng spec "cho bán nếu cấu hình cho phép") nhưng đơn đi qua hoàn toàn im lặng — không có cảnh báo nào cho thu ngân, trong khi spec §6.2 yêu cầu "Cảnh báo" trong mọi trường hợp tồn về âm.

**DoD:**
- [ ] Khi hoàn tất đơn khiến tồn kho của một dòng hàng về âm (và được cấu hình cho phép), hiển thị cảnh báo rõ ràng cho thu ngân ngay tại POS (banner/snackbar/dialog) — **không chặn giao dịch**, chỉ cảnh báo.
- [ ] Cảnh báo nêu rõ sản phẩm nào và tồn còn lại (âm) để thu ngân biết cần báo chủ kiểm kê.
- [ ] `flutter test` phủ: bán vượt tồn khi `allowNegativeStock=true` → cảnh báo xuất hiện đúng sản phẩm/số lượng; tồn đủ → không cảnh báo.
- [ ] `flutter analyze` sạch trên path đụng.

---

## G6 — Đánh dấu `dead_letter` = "cần chủ xử lý" + khoá thao tác cho cashier (§6.3, Trung bình)

**Vấn đề:** `outbox_conflicts_page.dart:150-163` chỉ phân loại `error` vs `dead_letter`, không role-gate — cashier tự thử lại/bỏ qua được mọi conflict kể cả `dead_letter` (đã hết retry hạ tầng). Spec §6.3 yêu cầu xung đột nghiêm trọng phải "giữ local, đánh dấu cần chủ xử lý".

**Thiết kế đã chốt với user (2026-07-28):** không thêm trạng thái DB mới — coi `dead_letter` hiện có đúng là "nghiêm trọng" theo spec.

**DoD:**
- [ ] Dòng `dead_letter` trong `outbox_conflicts_page.dart` có nhãn/badge rõ ràng "Cần chủ xử lý".
- [ ] Nút Thử lại / Bỏ qua trên dòng `dead_letter` bị ẩn hoặc khoá (disabled) khi role hiện tại là cashier; chỉ owner/store_manager thao tác được.
- [ ] Dòng `error` (chưa tới `dead_letter`, còn tự retry) giữ nguyên hành vi cũ cho mọi role.
- [ ] `flutter test` phủ: cashier thấy nhãn nhưng nút bị khoá trên `dead_letter`; owner/store_manager thao tác bình thường; `error` không đổi hành vi.
- [ ] `flutter analyze` sạch trên path đụng.

---

## Cách chạy (SDD)

| Bước | Cách |
|------|------|
| Mỗi task | **1 subagent** — implement + test, không đụng file ngoài scope |
| Review | Orchestrator đọc diff + tự chạy lại build/test/e2e độc lập trước khi tick DoD |
| Commit | 1 commit/task, message tiếng Việt mô tả rõ, cập nhật bảng Trạng thái + tick DoD trong cùng commit |
| Thứ tự | G1 → G2 → G3 → G4 → G5 → G6 (nghiêm trọng trước, còn lại theo thứ tự phát hiện) |

---

### Ghi chú review G1

**Action string đã chọn:** `sale_return_create` — theo đúng gợi ý trong DoD, giữ style `<entity>_<verb>` nhất quán với các action hiện có (`product_price_change`, `debt_adjust`, `einvoice_issue/cancel/adjust`, `user_create`). `entityType` dùng `'sale_return'`, `entityId` = `SaleReturn.id` — khớp với convention đã có sẵn của `journal_blocked_period_lock` khi nguồn là sale_return (xem `postEntry` trong `ledger.service.ts`, dùng `auditSourceType ?? sourceType`).

**Evidence (file:line):**
- Ghi `AuditLog` trong cùng transaction tạo `SaleReturn`: `apps/api/src/sync/sale-returns.service.ts:260-279` (`tx.auditLog.create` ngay sau khối cập nhật công nợ, vẫn trong `this.prisma.$transaction(...)` bắt đầu ở dòng 171 — đảm bảo không có bản ghi `SaleReturn` nào thiếu audit tương ứng, kể cả khi rollback). Payload `detailJson` gồm `saleId` (= `dto.originalSaleId`), `storeId`, `totalVnd`, `cashRefundVnd`, `transferRefundVnd`, `debtCreditVnd`, `reason` (= `dto.note ?? null`); actor nằm ở field top-level `actorUserId` (theo đúng convention của `customers.service.ts`/`products.service.ts`, không lặp lại trong `detailJson`).
- Bổ sung allowlist: `apps/api/src/ledger/ledger.service.ts:41` — thêm `'sale_return_create'` vào `defaultAuditActions` (mảng dòng 30-42), để `GET /ledger/audit` không truyền `action` vẫn trả về log này (tránh lặp lại lỗi G2 mô tả với `debt_adjust`).
- Test e2e: mở rộng test có sẵn `apps/api/test/ledger-returns-stocktake.e2e-spec.ts` (`it('sale return posts reverse revenue/COGS; idempotent', ...)`, dòng 46) thay vì tạo file `sale-returns.e2e-spec.ts` mới, vì file này đã dựng sẵn đúng luồng sale → sale_return qua `/sync/push` và đã có `token`/`userId`/`storeId`/`returnId` trong scope. Assertions mới ở dòng 181-210: kiểm tra đúng 1 bản ghi `AuditLog` cho `returnId` (không bị ghi trùng khi `pushReturn()` gọi lại lần 2 — do khối `existing` check nằm ngoài transaction nên lần retry không chạm lại `tx.auditLog.create`), gọi thật `GET /ledger/audit` **không truyền `action`** rồi tìm bản ghi theo `action`+`entityId`, `toMatchObject` actor/entityType/entityId, và `JSON.parse(detailJson)` khớp đủ field kể cả `reason` (đã thêm `note: 'Khach doi y, tra lai hang'` vào payload push để bài test phủ luôn nhánh "lý do có gửi kèm").

**Kết quả xác nhận:** `npm run build` xanh; `npm run test:unit` 76/76 pass (10 suite); `npm run test:e2e` (container Postgres 15 tạm, cổng 55977, đã `docker stop`/`rm` sau khi xong) 140/140 test pass, 39/39 suite pass — bao gồm `ledger-returns-stocktake.e2e-spec.ts` với assertion audit mới.

**Quyết định tự đưa ra khi implement:**
- Đặt lệnh `tx.auditLog.create` ở cuối khối transaction (sau nhánh cập nhật công nợ `debtCredit`) thay vì ngay sau `tx.saleReturn.create` — theo đúng vị trí tương tự các chỗ khác trong repo (`users.service.ts`, `customers.service.ts` đều ghi audit là thao tác cuối cùng trong transaction trước khi trả về), và vì payload audit không phụ thuộc dữ liệu tạo ra ở các bước sau nó nên vị trí không ảnh hưởng tính đúng đắn — chỉ ảnh hưởng thứ tự đọc code.
- Không thêm field mới vào `PushSaleReturnDto` — trường `note` sẵn có (dùng làm "lý do trả hàng" hiển thị trên `SaleReturn.note`) được tái dùng làm "lý do" trong audit payload, tránh nhân đôi khái niệm phía client.
- Không sửa `postFromSaleReturn`/`safePost` (bút toán sổ cái) — audit trail cho hành vi "tạo trả hàng" là độc lập với việc bút toán có post thành công hay không (bút toán dùng `safePost` fail-soft, có audit `journal_post_failed` riêng nếu lỗi); ghi trong transaction tạo `SaleReturn` là đúng phạm vi "xóa đơn" mà spec §5.7 yêu cầu, không mở rộng sang phạm vi kế toán của G2+.
