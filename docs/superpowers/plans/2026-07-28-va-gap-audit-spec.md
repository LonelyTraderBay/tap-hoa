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
| **G2** | Rà soát + bổ sung toàn bộ action còn thiếu trong `defaultAuditActions` allowlist | Cao | Done (build xanh, unit 78/78 — 11 suite, e2e 39 suite/140 test pass; bổ sung 4 action: `debt_adjust`, `bank_recon_locked`, `ap_recon_locked`, `journal_post_failed`) |
| **G3** | Lối "Xem nhanh, không mở ca" cho app ngoài quầy (owner/store_manager) | Cao | Done (flutter analyze sạch; flutter test 172/172 pass — 40 file) |
| **G4** | Sửa `minQty` không sửa được sau khi tạo sản phẩm | Trung bình | Done (flutter analyze sạch — 0 issue toàn repo; flutter test 175/175 pass — 41 file, +3 so với baseline G3) |
| **G5** | Cảnh báo khi bán khiến tồn về âm (được cấu hình cho phép) | Trung bình | Done (flutter analyze sạch — 0 issue toàn repo; flutter test 177/177 pass — 42 file, +2 so với baseline G4) |
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
- [x] Grep toàn bộ `apps/api/src` tìm mọi lời gọi tạo `AuditLog` (`auditLog.create`), liệt kê đầy đủ action string thật đang tồn tại trong code.
- [x] Đối chiếu danh sách đó với `defaultAuditActions`, bổ sung **mọi** action còn thiếu (tối thiểu: `debt_adjust`; xác nhận lại `bank_recon_locked`, `ap_recon_locked`).
- [x] Test (unit hoặc e2e) xác nhận `GET /ledger/audit` không truyền `action` trả về đủ các action vừa bổ sung, không cần biết trước tên action.
- [x] `npm run build` + `test:unit` + full `test:e2e` xanh.

---

## G3 — Lối "Xem nhanh, không mở ca" cho app ngoài quầy (§4.7/§4.8, Cao)

**Vấn đề:** Tinh thần spec §4.8 là chủ quán xem nhanh doanh thu/tồn/công nợ khi "đi chợ, ngoài quầy" — nhưng luồng thật bắt buộc `login → chọn điểm → mở ca` mới vào được bất kỳ màn báo cáo nào (`pos_page.dart` là cửa duy nhất tới `DayReportPage`/`DebtCustomerListPage`/`stock check`). Nếu ca đã mở ở máy khác, `open_shift_page.dart:143-145` chặn cứng bằng text lỗi, không có lối thoát.

**Thiết kế đã chốt với user (2026-07-28):** thêm lựa chọn "Xem nhanh (không mở ca)" song song luồng mở ca hiện có, **chỉ cho owner/store_manager** (thu ngân vẫn bắt buộc mở ca vì việc chính là bán hàng tại quầy).

**DoD:**
- [x] Sau đăng nhập thành công, owner/store_manager thấy thêm lựa chọn "Xem nhanh (không mở ca)" cạnh luồng mở ca hiện tại; cashier không thấy lựa chọn này (giữ nguyên luôn phải mở ca).
- [x] Màn "Xem nhanh" (route/page mới, read-only) cho vào: báo cáo doanh thu nhanh, kiểm kho/quét mã xem tồn, danh sách công nợ — thu nợ tại chỗ từ màn này vẫn hoạt động bình thường (ghi outbox không cần ca đang mở).
- [x] owner ở màn "Xem nhanh" xem tổng hợp mọi điểm (khớp hành vi báo cáo hiện tại khi `storeId=null`); store_manager giới hạn đúng điểm được gán.
- [x] Có đường quay lại/điều hướng sang mở ca bán hàng bình thường bất cứ lúc nào từ màn "Xem nhanh".
- [x] Màn báo lỗi "Đã có ca đang mở tại cửa hàng này" (`open_shift_page.dart`) có thêm lối vào "Xem nhanh" thay vì chỉ chặn cứng.
- [x] `flutter test` phủ điều hướng mới (owner/store_manager thấy lựa chọn, cashier không thấy); `flutter analyze` sạch.

---

## G4 — Sửa `minQty` không sửa được sau khi tạo sản phẩm (§4.2, Trung bình)

**Vấn đề:** `apps/pos_app/lib/features/products/product_form_sheet.dart:509-529` chỉ hiện ô "Tồn tối thiểu" khi `widget.isCreate`; `apps/pos_app/lib/features/products/product_service.dart:144-162` (`update()`) chỉ gửi `minQty` khi `existingStock == null`. Backend (`apps/api/src/products/products.service.ts:296-324`) đã hỗ trợ cập nhật `minQty` cho tồn đã tồn tại — bug nằm hoàn toàn ở client.

**DoD:**
- [x] Ô "Tồn tối thiểu" hiện cả khi sửa sản phẩm đã tồn tại, load đúng giá trị hiện tại làm mặc định.
- [x] `product_service.dart::update()` luôn gửi `minQty` (kể cả khi `existingStock != null`) tới backend qua kênh phù hợp (`seedStock` hoặc field tương đương).
- [x] `flutter test` xác nhận round-trip: sửa `minQty` trên sản phẩm đã có tồn kho → đọc lại đúng giá trị mới.
- [x] `flutter analyze` sạch trên path đụng.

---

## G5 — Cảnh báo khi bán khiến tồn về âm (§6.2, Trung bình)

**Vấn đề:** `checkout_service.dart:107,331` cho phép bán khi `allowNegativeStock=true` (đúng spec "cho bán nếu cấu hình cho phép") nhưng đơn đi qua hoàn toàn im lặng — không có cảnh báo nào cho thu ngân, trong khi spec §6.2 yêu cầu "Cảnh báo" trong mọi trường hợp tồn về âm.

**DoD:**
- [x] Khi hoàn tất đơn khiến tồn kho của một dòng hàng về âm (và được cấu hình cho phép), hiển thị cảnh báo rõ ràng cho thu ngân ngay tại POS (banner/snackbar/dialog) — **không chặn giao dịch**, chỉ cảnh báo.
- [x] Cảnh báo nêu rõ sản phẩm nào và tồn còn lại (âm) để thu ngân biết cần báo chủ kiểm kê.
- [x] `flutter test` phủ: bán vượt tồn khi `allowNegativeStock=true` → cảnh báo xuất hiện đúng sản phẩm/số lượng; tồn đủ → không cảnh báo.
- [x] `flutter analyze` sạch trên path đụng.

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

---

### Ghi chú review G2

**Phương pháp rà soát:** Grep `auditLog\.create\(` (không phân biệt `this.prisma.auditLog.create` hay `tx.auditLog.create` trong transaction — cùng field name `auditLog`) trên toàn bộ `apps/api/src` → đúng 10 call site trong 7 file, không có pattern ghi nào khác (đã kiểm thêm không có `auditLog.createMany`, không có raw SQL `$executeRaw`/`$queryRaw` nào đụng bảng `audit_log`). 2/10 call site không truyền `action` bằng string literal mà bằng biến — đã truy ngược lên mọi nơi gọi để lấy giá trị thật thay vì bỏ qua:
- `ledger.service.ts` (private helper `writeAudit`, dòng 52-69, tham số `action: string` — kiểu mở, không giới hạn) — truy ngược ra 4 lời gọi thật: `journal_blocked_period_lock` (dòng 107), `journal_post_failed` (dòng 151 — bên trong `safePost`, dòng 138-160, wrapper fail-soft được gọi từ 10 call site khác trong `suppliers.service.ts` (x2), `sync/sync.service.ts` (x3), `sync/sale-returns.service.ts` (x1), `sync/stock-ops.service.ts` (x4) mỗi khi một bút toán sổ cái post lỗi), `period_lock` (dòng 705), `period_unlock` (dòng 730).
- `einvoice.service.ts` (private helper `writeEinvoiceAudit`, dòng 43-73) — tham số `action` gõ kiểu union đóng `'einvoice_issue' | 'einvoice_cancel' | 'einvoice_adjust'` (dòng 46) nên compiler tự giới hạn đúng 3 giá trị; xác nhận cả 3 lời gọi thật (dòng 315, 431, 553) đều nằm trong 3 giá trị này — không có giá trị nào khác lọt qua type union.

**Danh sách đầy đủ 15 action string thật đang ghi `AuditLog`** (cột "Trước G2" = có mặt trong `defaultAuditActions` trước khi task này sửa hay không):

| # | Action | Evidence (file:line) | Trước G2 |
|---|--------|----------------------|----------|
| 1 | `period_lock` | `apps/api/src/ledger/ledger.service.ts:705` (qua `writeAudit`) | Có |
| 2 | `period_unlock` | `apps/api/src/ledger/ledger.service.ts:730` (qua `writeAudit`) | Có |
| 3 | `journal_blocked_period_lock` | `apps/api/src/ledger/ledger.service.ts:107` (qua `writeAudit`) | Có |
| 4 | `journal_post_failed` | `apps/api/src/ledger/ledger.service.ts:151` (qua `writeAudit`, gọi từ `safePost`, dòng 138-160) | **Thiếu** |
| 5 | `product_price_change` | `apps/api/src/products/products.service.ts:262` | Có |
| 6 | `user_create` | `apps/api/src/users/users.service.ts:123` | Có |
| 7 | `user_role_change` | `apps/api/src/users/users.service.ts:223` | Có |
| 8 | `user_password_reset` | `apps/api/src/users/users.service.ts:280` | Có |
| 9 | `einvoice_issue` | `apps/api/src/einvoice/einvoice.service.ts:61` (qua `writeEinvoiceAudit`, gọi tại dòng 315) | Có |
| 10 | `einvoice_cancel` | `apps/api/src/einvoice/einvoice.service.ts:61` (gọi tại dòng 431) | Có |
| 11 | `einvoice_adjust` | `apps/api/src/einvoice/einvoice.service.ts:61` (gọi tại dòng 553) | Có |
| 12 | `sale_return_create` | `apps/api/src/sync/sale-returns.service.ts:266` (thêm ở G1) | Có |
| 13 | `debt_adjust` | `apps/api/src/customers/customers.service.ts:155` | **Thiếu** |
| 14 | `bank_recon_locked` | `apps/api/src/reports/reports.service.ts:1779` (trong `lockBankRecon`) | **Thiếu** |
| 15 | `ap_recon_locked` | `apps/api/src/reports/reports.service.ts:2184` (trong `lockApRecon`) | **Thiếu** |

**4 action đã bổ sung vào `defaultAuditActions`** (`apps/api/src/ledger/ledger.service.ts:30-46`): `journal_post_failed`, `debt_adjust`, `bank_recon_locked`, `ap_recon_locked` — `journal_post_failed` chèn cạnh `journal_blocked_period_lock` (action liên quan gần nhất về mặt nghiệp vụ — cùng nhóm "sự kiện phát sinh khi post bút toán"); 3 action còn lại nối vào cuối mảng, sau `sale_return_create` (giữ đúng vị trí G1 để lại, không xáo trộn thứ tự cũ).

**Test:**
- `apps/api/src/ledger/ledger.service.spec.ts` (file mới) — 2 unit test, không dựng Nest DI container, khởi tạo thẳng `new LedgerService(fakePrisma)` (cùng pattern với `reports.service.spec.ts` đã có sẵn trong repo, ví dụ `new ReportsService(...)`). Test 1 gọi `listAudit(owner, {})` (không truyền `action`, y hệt cách `GET /ledger/audit` xử lý khi client — Flutter `ledger_page.dart` — không gửi query param `action`), bắt tham số thật truyền vào `prisma.auditLog.findMany` qua `jest.fn()`, khẳng định `where.action.in` chứa đủ toàn bộ 15 action ở bảng trên (`expect.arrayContaining`, không phụ thuộc thứ tự) và không có phần tử trùng lặp trong allowlist. Test 2 xác nhận khi caller truyền `action` tường minh thì dùng đúng giá trị đó (không rơi về allowlist) — giữ đúng hành vi cũ, tránh regression ngược.
- `apps/api/test/customers-debt-adjust.e2e-spec.ts` (mở rộng test có sẵn `'lets owner and manager post signed debt adjustments with ledger and audit'`) — sau khối assertion cũ (kiểm `prisma.auditLog.findMany` trực tiếp ở DB), thêm khối mới: gọi thật `GET /ledger/audit` **không truyền `action`** qua HTTP (token owner), lọc kết quả trả về theo `entityId = customerId`, khẳng định có đủ 2 bản ghi (tăng nợ + giảm nợ) và `detailJson` của bản ghi mới nhất khớp payload thật (`amountVnd`, `reason`, `balanceBeforeVnd`, `balanceAfterVnd`). Đây là bằng chứng qua HTTP thật cho action đã xác nhận chắc chắn tồn tại trong DB (`debt_adjust`) — đúng yêu cầu DoD. `bank_recon_locked`/`ap_recon_locked`/`journal_post_failed` được phủ qua unit test ở trên thay vì dựng e2e riêng (DoD G2 cho phép rõ cách này).

**Vì sao không viết e2e riêng cho `bank_recon_locked`/`ap_recon_locked`/`journal_post_failed`:** để gọi thành công `POST /reports/bank-recon/lock` hoặc `/ap-recon/lock` cần dựng đủ luồng import sao kê + khớp toàn bộ dòng + variance = 0 (xem `lockBankRecon`/`lockApRecon` trong `reports.service.ts`); để trigger `journal_post_failed` thật cần chủ động làm một bút toán post lỗi (qua `safePost`). Cả hai đều tốn setup không tương xứng với mục tiêu G2 (đảm bảo *allowlist* đầy đủ — không phải re-test nghiệp vụ đối soát/post bút toán, vốn đã có test riêng ở `bank-recon.e2e-spec.ts`/`ap-recon.e2e-spec.ts`/các e2e dùng `safePost`). Unit test kiểm tra trực tiếp mảng `defaultAuditActions` (qua hành vi `listAudit`) là đủ để khẳng định allowlist không bỏ sót — đúng phương án DoD đã cho phép.

**Kết quả xác nhận:** `npm run build` xanh; `npm run test:unit` 78/78 pass (11 suite — tăng từ 76/76 · 10 suite baseline G1 nhờ 2 test mới trong `ledger.service.spec.ts`); `npm run test:e2e` (container Postgres 15 tạm, tên `tap-hoa-g2-e2e`, cổng host 55980, biến `TAP_HOA_SKIP_LOCAL_IDENTITY=1`, đã `docker stop`/`docker rm` sau khi xong — không đụng DB dev thật ở cổng 54422) 140/140 test pass, 39/39 suite pass — số suite/test HTTP giữ nguyên so với G1 vì chỉ mở rộng assertion trong `it()` có sẵn của `customers-debt-adjust.e2e-spec.ts`, không thêm `it()` mới ở lớp e2e.

**Quyết định tự đưa ra khi implement:**
- Bổ sung cả `journal_post_failed` dù đề bài task chỉ nêu tên `debt_adjust`/`bank_recon_locked`/`ap_recon_locked` — phát hiện qua bước "truy ngược biến" bắt buộc trong DoD (đọc `writeAudit` rồi rà từng lời gọi thay vì dừng ở chỗ định nghĩa). Đây là action thật, ghi bởi `safePost` — wrapper dùng ở 10 call site rải khắp `suppliers`/`sync`/`stock-ops` services mỗi khi một bút toán sổ cái post lỗi (fail-soft, không throw ra ngoài) — đúng tinh thần DoD "bổ sung MỌI action còn thiếu, không chỉ liệt kê tối thiểu trong đề bài". Bỏ sót action này sẽ khiến chủ quán không bao giờ thấy được các lần bút toán lỗi thầm lặng trong màn "Sổ · Nhật ký", dù đây chính xác là loại sự kiện "cần chủ biết" mà spec §5.7 hướng tới.
- Không viết e2e đầy đủ cho `bank_recon_locked`/`ap_recon_locked`/`journal_post_failed` (lý do chi tiết ở mục trên) — chọn unit test kiểm tra allowlist trực tiếp, đúng phương án DoD đã cho phép rõ ràng ("có thể assert bằng cách kiểm tra trực tiếp mảng `defaultAuditActions`").
- Không sắp xếp lại toàn bộ mảng `defaultAuditActions` theo alphabet hay theo nhóm nghiệp vụ — chỉ chèn 4 action mới (1 cạnh action liên quan gần nhất, 3 còn lại nối cuối mảng), giữ diff nhỏ, dễ review, và giữ nguyên vị trí G1 để lại thay vì xáo trộn không cần thiết.

---

### Ghi chú review G3

**Thiết kế điều hướng đã chọn:** 2 page/route mới, thuần Flutter client, không đụng `apps/api`:

- `QuickViewHubPage` (`apps/pos_app/lib/features/quick_view/quick_view_hub_page.dart`) — hub "Xem nhanh", điều hướng thuần (không tự đọc/ghi Drift/outbox gì trực tiếp — đúng nghĩa "read-only" của DoD): 3 ô vào báo cáo doanh thu nhanh (`DayReportPage`), kiểm kho/quét mã xem tồn (`InventoryHubPage` — tái dùng nguyên trang, gồm cả `_scanCheckStock`), công nợ khách hàng (`DebtCustomerListPage`), cộng 1 nút "Mở ca bán hàng" luôn hiển thị (không phụ thuộc trạng thái tải) để thoát sang luồng mở ca bất cứ lúc nào.
- `EntryChoicePage` (`apps/pos_app/lib/features/auth/entry_choice_page.dart`) — màn chọn sau đăng nhập cho owner/store_manager, 2 nút "Mở ca bán hàng" (→ `OpenShiftPage`, luồng cũ nguyên vẹn) và "Xem nhanh (không mở ca)" (→ `QuickViewHubPage`).
- Helper role-gate `bool quickViewAllowedForRole(String role) => role == 'owner' || role == 'store_manager';` đặt tại `quick_view_hub_page.dart:30-31` (cùng file với trang nó gác cổng) — dùng lại ở cả `login_page.dart:97` (chọn `EntryChoicePage` hay `OpenShiftPage` sau login) lẫn `open_shift_page.dart:251-252` (chỉ hiện nút "Xem nhanh" trên màn lỗi "đã có ca mở ở máy khác" nếu role cho phép). Tách hàm thuần (không phụ thuộc `BuildContext`/widget state) để unit-test độc lập, không cần dựng widget tree.
- Routing: dùng `Navigator.push`/`pushReplacement` + `MaterialPageRoute` y hệt convention hiện có trong toàn bộ `apps/pos_app` (app này không dùng named routes/router package nào) — `EntryChoicePage`/`QuickViewHubPage` đều nhận đúng bộ tham số DI (`repository`, `dayReportRepository`, `stockOnHandRepository`, `productRepository`, `productService`, `customerRepository`, `debtPaymentService`, `cashVoucherService`, `database`, `pullCatalog`, `checkoutService`, `outboxWorker`, `syncSchedulerKey`) giống hệt `OpenShiftPage`/`CloseShiftPage` đã có, nên `login_page.dart`/`main.dart` không cần thêm dependency mới nào.

**Xử lý `storeId` cho owner (xem tổng hợp mọi điểm) vs store_manager (giới hạn điểm được gán):** không tự viết lại logic — 3 trang đích đã tự xử lý đúng khi được tái sử dụng nguyên trạng:
- `DayReportPage` tự quy `storeId` về `null` khi `role == 'owner'` ngay trong `_loadReport()` (`apps/pos_app/lib/features/reports/day_report_page.dart:60`: `final storeId = widget.role == 'owner' ? null : widget.storeId;`) — bất kể `QuickViewHubPage` truyền `storeId` cụ thể nào vào, owner vẫn luôn thấy báo cáo tổng hợp mọi điểm; store_manager thấy đúng 1 điểm được truyền vào.
- `DebtCustomerListPage._canLoadAggregate` (`apps/pos_app/lib/features/customers/debt_customer_list_page.dart:34-36`) bật khối "Tổng công nợ" (gọi `GET /reports/debt-aging`, không tham số `storeId` — do đó đã tự scope theo JWT ở server) khi `role` là `owner`/`store_manager`, độc lập với `storeId` truyền vào — `storeId` chỉ ảnh hưởng phần "Danh sách cục bộ"/nút "Ngưỡng quá hạn".
- `InventoryHubPage` (kiểm kho) không có khái niệm "tổng hợp" — luôn cần đúng 1 `storeId`. Vì vậy `QuickViewHubPage` tự dựng 1 dropdown chọn điểm (nhãn "Điểm kiểm kho" cho owner, "Cửa hàng" cho store_manager), nạp qua `widget.shiftRepository.fetchStores()` — **tái dùng đúng API `GET /stores` đã role-scope sẵn ở server** (`apps/api/src/stores/stores.service.ts:35-44` — `findForUser`: owner nhận toàn bộ store `active`, role khác chỉ nhận đúng `storeIds` được gán), y hệt cách `OpenShiftPage._loadStores()` đã dùng — không viết thêm logic lọc theo role phía client.

**Debt payment không có ca đang mở — quyết định + bằng chứng (theo đúng yêu cầu review):** `record_debt_payment_sheet.dart` → `DebtPaymentService.recordPayment()` (trước G3) gọi `_shiftRepository.requireOpenShift(...)`, ném `NoOpenShiftException` nếu chưa mở ca → thu nợ từ "Xem nhanh" sẽ luôn báo "Thu nợ thất bại". Đã xác minh **kiến trúc sẵn sàng cho `shiftId` rỗng ở cả hai đầu** trước khi chọn phương án, nên **chọn cho phép thu nợ với `shiftId=null`** thay vì ẩn nút:
- Local schema đã nullable từ trước, không cần migration: `apps/pos_app/lib/data/local/tables.dart:178` — `TextColumn get shiftId => text().nullable()();` trong `DebtLedgerLocal`.
- Server Prisma schema cũng đã nullable từ trước: `apps/api/prisma/schema.prisma:273` — `shiftId String?` trong `model DebtLedgerEntry`.
- Server xử lý sync (`apps/api/src/sync/sync.service.ts::processDebtPayment`, dòng 614-699) **không** bắt buộc `shiftId` trong khối validate (dòng 618-629, không có check `!payment.shiftId` — khác hẳn `processCashVoucher` dòng 500-509 vẫn bắt buộc `!voucher.shiftId` và còn xác nhận ca đang mở ở dòng 546) và đã tự `shiftId: payment.shiftId ?? null` từ dòng 666 — tức nhánh "không có ca" đã được server hỗ trợ đầy đủ từ trước G3, chỉ chưa ai gọi tới qua client.
- Thay đổi client duy nhất: `apps/pos_app/lib/features/customers/debt_payment_service.dart:45-48` đổi `_shiftRepository.requireOpenShift(...)` (ném exception) → `_shiftRepository.findOpenShift(...)` (trả `null`), rồi dùng `shift?.id` ở cả bản ghi `DebtLedgerLocal` (dòng 76) lẫn payload outbox (dòng 95). Khi có ca đang mở, hành vi giữ nguyên 100% (`shift.id` như cũ) — 2 test cũ trong `debt_payment_test.dart` (đều gọi `openShift()` trước `recordPayment()`) pass không đổi, xác nhận không có regression.
- Test mới xác nhận nhánh không có ca: `apps/pos_app/test/debt_payment_test.dart` — `'recordPayment succeeds without an open shift and stores a null shiftId'` (không gọi `openShift()`), kiểm `ledger.shiftId == null` và outbox `payloadJson` chứa `"shiftId":null`.

**Test mới (đủ cả 2 hướng DoD cho phép — unit cho helper + widget test cho luồng thật):**
- `apps/pos_app/test/quick_view_hub_page_test.dart` (mới) — unit test `quickViewAllowedForRole` (owner/store_manager true, cashier false); widget test `QuickViewHubPage`: owner thấy đủ 3 ô + ghi chú "tổng hợp tất cả điểm", store_manager không thấy ghi chú đó; nút "Mở ca bán hàng" luôn có mặt kể cả khi danh sách cửa hàng còn đang tải (`Completer` chưa complete); tap "Mở ca bán hàng" → `OpenShiftPage`; tap "Kiểm kho / quét mã xem tồn" → `InventoryHubPage`; tap "Công nợ khách hàng" → `DebtCustomerListPage` (2 trang sau dùng `AppDatabase` in-memory thật thay vì mock để tránh phải giả lập Drift stream).
- `apps/pos_app/test/open_shift_page_test.dart` (mới) — owner gặp lỗi "đã có ca đang mở tại cửa hàng này" thấy thêm nút "Xem nhanh (không mở ca)", tap vào tới đúng `QuickViewHubPage`; cashier gặp lỗi y hệt nhưng **không** thấy nút này (hành vi chặn cứng giữ nguyên).
- `apps/pos_app/test/widget_test.dart` — sửa test cũ `'navigates to open shift after login'` (role owner đi thẳng `OpenShiftPage` trước G3, nay phải qua `EntryChoicePage` trước — đổi tên thành `'owner sees the entry choice screen after login, then reaches open shift'`, thêm bước tap "Mở ca bán hàng"); thêm 3 test mới: owner tới đúng `QuickViewHubPage` khi chọn "Xem nhanh", store_manager cũng thấy màn chọn, cashier đi thẳng `OpenShiftPage` như cũ (không có "Xem nhanh (không mở ca)" ở đâu cả).
- `apps/pos_app/test/debt_payment_test.dart` — thêm test không-có-ca-mở như mô tả ở trên.

**Kết quả xác nhận:** `flutter analyze` — "No issues found!" (0 issue, kể cả trên toàn repo `pos_app`, không riêng path đụng). `flutter test` — 172/172 test pass, 0 failed (đếm độc lập bằng `grep -c '^\s*(test|testWidgets)\('` trên toàn bộ `test/*.dart` cũng ra đúng 172, khớp dòng tổng kết `+172: All tests passed!` — xác nhận không có test nào bị bỏ sót/không chạy). File Windows generated (`generated_plugin_registrant.cc/.h`, `generated_plugins.cmake`) bị `flutter test`/`flutter analyze` đụng vào nhưng `git diff --ignore-all-space` rỗng (đúng quirk môi trường đã ghi trong plan) — đã `git restore` trước khi commit.

**Quyết định tự đưa ra khi implement:**
- **Debt payment `shiftId=null`** (đã trình bày chi tiết ở trên) — chọn phương án "cho phép" thay vì "ẩn nút", vì xác minh được kiến trúc (local schema + Prisma schema + server sync handler) đã hỗ trợ sẵn `shiftId` rỗng cho riêng entity `debt_payment` (khác với `cash_voucher`, entity đó server vẫn bắt buộc ca đang mở — **cố ý không đụng `cash_voucher`/`CashVoucherService` trong task này**, vì DoD G3 chỉ yêu cầu "thu nợ tại chỗ", không yêu cầu "thu chi tại chỗ"; mở rộng thêm sẽ vượt phạm vi G3 và đụng vào một entity mà server chưa sẵn sàng nhận `shiftId=null`).
- **Tái dùng nguyên `InventoryHubPage`** (gồm cả các thao tác ghi: Nhập NCC, Tạo PO, Xuất hủy, Kiểm kê, Chuyển kho) thay vì tách riêng 1 trang "chỉ xem tồn" — vì (a) DoD chỉ định "read-only" cho chính `QuickViewHubPage` (trang điều hướng), không bắt các trang đích phải read-only (chính DoD cũng yêu cầu thu nợ — 1 thao tác ghi — phải hoạt động), (b) `InventoryService` (đã đọc kỹ toàn bộ `inventory_service.dart`) không có bất kỳ phụ thuộc `shiftId`/ca đang mở nào ở tất cả các hàm ghi (`recordPurchase`, `recordWastage`, `recordStocktake`, `createTransfer`, `approve/rejectTransfer`, `receiveTransfer` — chỉ dùng `_session()` đọc `currentStoreId`/`currentUser` từ meta, không đọc `shiftsLocal`), nên không có rủi ro "landmine" giống debt payment; (c) task yêu cầu rõ tái dùng "trang kiểm tồn trong `inventory_hub_page.dart`" — file này không tách sẵn 1 trang con "chỉ xem", tách ra sẽ là viết lại logic UI không cần thiết.
- **Không truyền `database`/`shiftRepository` vào `DayReportPage`** từ `QuickViewHubPage` (2 tham số optional, để `null`) — 2 tham số này chỉ dùng để bật nút "Đổi trả trong ngày" (`_openReturn`, gọi `SaleReturnService`). Đổi trả không nằm trong danh sách DoD G3 ("báo cáo doanh thu nhanh, kiểm kho/quét mã xem tồn, danh sách công nợ") và chưa xác minh `SaleReturnService`/`postFromSaleReturn` có phụ thuộc ca đang mở hay không (ngoài phạm vi audit của task này) — an toàn hơn là giữ ẩn, đúng cơ chế "tắt tính năng phụ" mà `DayReportPage` đã tự thiết kế sẵn qua 2 param nullable này (`widget.database != null && widget.shiftRepository != null` ở dòng 417 của `day_report_page.dart`).
- **Store picker luôn hiện cho cả owner lẫn store_manager** (kể cả khi chỉ có 1 cửa hàng) thay vì ẩn khi danh sách có ≤ 1 phần tử — giữ code đơn giản, đúng y hệt cách `OpenShiftPage` đang làm (`_stores`/`_selectedStore`, luôn render `DropdownButtonFormField`), tránh thêm 1 nhánh UI chỉ để tiết kiệm 1 dòng dropdown khi store_manager thường chỉ có đúng 1 điểm.
- **Vị trí nút "Mở ca bán hàng" trong `QuickViewHubPage`** đặt ngoài vùng `_isLoading` (không nằm trong `Expanded` phía dưới) để đảm bảo luôn bấm được ngay cả khi `fetchStores()` chưa trả lời (mất mạng/chậm) — tránh tình huống "kẹt" y hệt lỗi gốc mà G3 phải sửa (`open_shift_page.dart` cũ không có lối thoát khi lỗi).
- **Không sửa `main.dart`** — `LoginPage` giữ nguyên chữ ký constructor, không thêm dependency mới nào (mọi thứ `EntryChoicePage`/`QuickViewHubPage` cần đều đã có sẵn trong bộ tham số `LoginPage` nhận từ `main.dart`).

---

### Ghi chú review G4

**Xác nhận lại mô tả bug so với code thật:** đúng như audit mô tả — `ProductEditData` (`apps/pos_app/lib/features/products/product_repository.dart:37-74`) đã có sẵn field `minQty` và `getForEdit()` (dòng 161-207) đã đọc đúng `stock?.minQty ?? '0'` theo đúng `storeId` — nhưng `_ProductFormSheetState._loadExisting()` chưa từng gán giá trị đó vào `_minQtyController`, và ô nhập nằm trong khối `if (widget.isCreate)` nên không hiện khi sửa. Phát hiện thêm 1 chi tiết sâu hơn mô tả gốc: nhánh `else` (sửa) của `_save()` gọi `widget.productService.update(...)` **hoàn toàn không truyền `minQty`** (không phải truyền `'0'` — tham số bị bỏ qua luôn), nên dù `update()` có sửa được cũng luôn nhận default `'0'` — cộng với bug ở `product_service.dart::update()` (chỉ set `seedStock` khi `existingStock == null`) tạo thành 2 lớp bug cộng dồn, không chỉ 1.

**Sửa `product_form_sheet.dart`:**
- `_loadExisting()` — thêm `_minQtyController.text = data.minQty;` (dòng 108), nạp đúng minQty hiện tại của `widget.storeId` (form này không có khái niệm chọn điểm bán — `storeId` cố định theo tham số constructor, truyền từ `product_list_page.dart`, nơi duy nhất gọi `ProductFormSheet.show`).
- Tách khối `if (widget.isCreate) [...]` ở `build()` (dòng 513-534): ô "Tồn ban đầu" vẫn chỉ hiện lúc tạo mới (sửa tồn ban đầu không có ý nghĩa — tồn thực tế phải đi qua nghiệp vụ kho, không qua form sản phẩm), ô "Tồn tối thiểu" chuyển ra ngoài, luôn hiện ở cả 2 chế độ.
- Validate `_save()` (dòng 184-191): tách check `initialQty.isEmpty` (chỉ bắt buộc lúc tạo) khỏi check `minQty.isEmpty` (bắt buộc ở cả 2 chế độ, vì ô giờ luôn hiện) — quyết định tự đưa ra: chặn rỗng ở client vì gửi `seedStock.minQty` rỗng lên backend sẽ khiến `parseNonNegativeQty('')` throw, `upsertFromSync` reject nguyên bản ghi (`invalid_product`) — không chỉ minQty thất bại mà toàn bộ sửa tên/giá cũng mất theo (xem `apps/api/src/products/products.service.ts:147-158`).
- Nhánh `else` (sửa) của `_save()` (dòng 248): thêm `minQty: minQty,` vào lời gọi `widget.productService.update(...)` — đây chính là chỗ tham số bị bỏ sót hoàn toàn trước đây.

**Sửa `product_service.dart::update()`** (dòng 144-179):
- Giữ nguyên nhánh `existingStock == null` (tạo mới dòng tồn kho — không đổi hành vi). Thêm nhánh `else` (dòng 167-179): `UPDATE productStocks SET minQty = ... WHERE productId = ... AND storeId = ...` trên Drift local trước (để app đọc lại ngay lập tức không cần chờ round-trip server), sau đó luôn gán `seedStock = {'qty': existingStock.qty, 'minQty': minQty}` (không còn nhánh nào để `seedStock` là `null`) — dùng **`existingStock.qty` hiện tại** làm `qty` gửi kèm, không phải `initialQty` (vốn luôn là `'0'` mặc định vì form sửa không có ô nhập tồn ban đầu) để tránh gửi nhầm tồn về 0.
- Điều này an toàn vì đã đọc kỹ `apps/api/src/products/products.service.ts::upsertFromSync` (dòng 296-325): điều kiện vào khối này là `dto.seedStock != null && seedQty != null` (**bắt buộc phải có `qty` hợp lệ dù chỉ muốn sửa `minQty`** — đây là lý do không thể chỉ gửi `{minQty: ...}` mà thiếu `qty`), nhưng khi `existing` (dòng tồn) đã có sẵn, nhánh cập nhật (dòng 314-324) **chỉ `update({ data: { minQty: seedMinQty } })`** — hoàn toàn không đụng `qty` — nên giá trị `qty` gửi kèm trong `seedStock` lúc này chỉ để thoả điều kiện validate của backend, không có tác dụng ghi đè tồn thực tế.
- Đổi luôn `_enqueueOutbox({ required Map<String, String>? seedStock, ... })` → non-nullable (`required Map<String, String> seedStock`) vì sau fix, **cả `create()` lẫn `update()` đều luôn truyền một map cụ thể**, không còn caller nào truyền `null` — bỏ nhánh `if (seedStock != null) payload['seedStock'] = ...` (dead code sau fix), gán thẳng `payload['seedStock'] = seedStock`. Đây là dọn dẹp nhỏ đi kèm, không đổi hành vi ở 2 caller hiện có.

**Payload gửi backend không đổi field/format:** vẫn đúng `PushProductSeedStockDto = { qty: string; minQty?: string }` dưới key `seedStock` (`apps/api/src/sync/dto/push-sale.dto.ts:83-86,103`) — xác nhận qua `apps/pos_app/lib/data/sync/outbox_worker.dart:322,336` (`jsonDecode(entry.payloadJson)` rồi forward nguyên map `payload` vào mảng `productUpserts` gửi lên `/sync/push`, không có bước ánh xạ tên field trung gian nào) nên key `'seedStock'`/`'qty'`/`'minQty'` trong `product_service.dart` phải khớp chính xác chữ ký DTO phía server — đã đối chiếu khớp.

**Test mới/sửa:**
- `apps/pos_app/test/product_service_test.dart` — sửa lại test cũ `'update changes fields and omits seedStock when stock exists'` (assertion `payload.containsKey('seedStock'), isFalse` **chính là bug đã được mã hoá thành test** — nếu giữ nguyên sẽ tự mâu thuẫn với fix) thành `'update on a product that already has stock still sends seedStock (current qty + new minQty) — regression cho bug G4'`: tạo sản phẩm có `initialQty:'3', minQty:'2'`, gọi `update(..., minQty:'9')`, xác nhận cả local Drift (`productStocks.minQty=='9'`, `qty` giữ nguyên `'3'`) lẫn outbox payload (`seedStock.qty=='3'`, `seedStock.minQty=='9'`) đúng như thiết kế. Thêm test round-trip đúng theo DoD: `'round-trip: sửa minQty trên sản phẩm ĐÃ CÓ tồn kho rồi đọc lại qua ProductRepository.getForEdit ra đúng giá trị mới'` — tạo sản phẩm (`minQty:'1'`), đọc qua `getForEdit` xác nhận `'1'`, gọi `update(minQty:'7')`, đọc lại qua `getForEdit` xác nhận `'7'` và `qty` không đổi (`'10'`).
- `apps/pos_app/test/product_form_sheet_test.dart` (file mới — chưa từng có test riêng cho `ProductFormSheet`, không có convention sẵn để theo nên dùng đúng pattern `Builder` + `ElevatedButton` mở sheet qua `.show(...)` giống `sale_return_refund_test.dart:153-169`, và `AppDatabase` in-memory thật + `ProductRepository`/`ProductService` thật thay vì mock, giống lý do G3 đã chọn cho `quick_view_hub_page_test.dart`) — 2 test: (1) sửa sản phẩm đã tồn tại vẫn hiện ô "Tồn tối thiểu" nạp sẵn `'4'`, không hiện ô "Tồn ban đầu"; (2) đổi ô thành `'9'`, tap "Lưu" (phải `tester.ensureVisible` trước vì sheet dài hơn viewport test mặc định 800×600 nên nút nằm off-screen), sheet đóng lại, đọc lại qua `getForEdit` ra đúng `'9'` và `qty` không đổi (`'20'`) — đây là bài test đi qua đúng luồng UI thật (không gọi thẳng service) nên phủ được cả phần sửa trong `product_form_sheet.dart` mà test service-level không chạm tới.
- Gặp 1 lỗi biên dịch khi viết test: `package:drift/drift.dart` (cần cho `.equals()` khi build `where`) và `package:flutter_test/flutter_test.dart` cùng export 1 symbol top-level tên `isNotNull` (`ambiguous_import`) trong `product_service_test.dart` — sửa bằng cách dùng `isA<ProductEditData>()` thay cho `isNotNull` (không đụng tới import dùng chung của file).

**Kết quả xác nhận:**
- `flutter analyze` — "No issues found!" trên cả 4 file đụng trực tiếp lẫn toàn bộ repo `pos_app`.
- `flutter test` (toàn bộ, không riêng file mới) — `+175: All tests passed!`, 0 failed. Đếm độc lập bằng `rg '^\s*(test|testWidgets)\(' apps/pos_app/test -c` cũng ra đúng **175 test / 41 file** (baseline G3 là 172/40 file — tăng đúng 3 test mới: 1 test sửa lại + 1 test round-trip trong `product_service_test.dart`, 2 test trong `product_form_sheet_test.dart` mới — tổng +3 khớp).
- File Windows generated (`generated_plugin_registrant.cc/.h`, `generated_plugins.cmake`) bị `flutter test`/`flutter analyze` đụng vào (đúng quirk môi trường đã ghi trong plan) nhưng `git diff --ignore-all-space` rỗng — đã `git restore` cả 3 file trước khi commit.

**Quyết định tự đưa ra khi implement:**
- **Gửi `existingStock.qty` (tồn hiện tại) thay vì `'0'`/`initialQty` trong `seedStock.qty` khi sửa tồn đã có** — bắt buộc về mặt kỹ thuật (backend yêu cầu `seedQty != null` mới vào được nhánh xử lý `seedStock`, kể cả khi mục đích chỉ là sửa `minQty`), và chọn giá trị tồn **thật** thay vì `'0'` để nếu tương lai có ai sửa lại điều kiện backend (vd bỏ yêu cầu `seedQty`), hành vi vẫn an toàn — không có giá trị rác nào được gửi đi dù hiện tại backend không dùng tới nó ở nhánh update.
- **Không thêm dropdown/khái niệm "chọn điểm bán" vào `ProductFormSheet`** — đã đọc kỹ và xác nhận `storeId` là tham số cố định truyền từ nơi gọi duy nhất (`product_list_page.dart`), form không có UI chọn điểm bán nào, nên câu "load đúng giá trị minQty hiện tại của điểm bán đang chọn" trong yêu cầu áp dụng đúng nghĩa "điểm bán đang được xem" (`widget.storeId`), không cần thêm state mới.
- **Không thêm parse/validate số cho `minQty`** (vd không âm, đúng định dạng số) — giữ đúng mức độ rigor hiện có của form (bug gốc chỉ về việc hiện ô + gửi dữ liệu, không phải về validate định dạng; `initialQty` cạnh đó cũng chưa từng được parse-validate trong `_save()` từ trước) — tránh mở rộng phạm vi ngoài G4. Chỉ thêm đúng 1 lớp validate mới (không rỗng) vì đây là điều kiện bắt buộc để tránh backend reject nguyên bản ghi, không phải một cải tiến UX ngoài phạm vi.
- **Đổi `_enqueueOutbox`'s `seedStock` sang non-nullable** — dọn dẹp đi kèm hợp lý vì cả 2 caller (`create`, `update`) sau fix đều luôn truyền map cụ thể; cân nhắc rồi quyết định giữ thay đổi này (thay vì giữ nullable cho "an toàn") vì kiểu non-nullable diễn đạt đúng invariant mới của code, và `flutter analyze` xác nhận không có caller nào khác bị ảnh hưởng (`_enqueueOutbox` là hàm private, chỉ 2 call site).

---

### Ghi chú review G5

**Cơ chế cảnh báo đã chọn:** `CheckoutService.complete()` (service thuần, không có `BuildContext`, không tự hiện UI được) đổi kiểu trả về từ `Future<String>` sang `Future<CheckoutResult>` — gói `saleId` cũ + `negativeStockWarnings: List<NegativeStockWarning>` (rỗng ở đường đi bình thường, chỉ có phần tử khi `allowNegativeStock=true` VÀ tồn SAU bán thực sự < 0). Lớp UI phía trên — cụ thể là `PaymentSheet._complete()` (không đụng `pos_page.dart`) — đọc `result.negativeStockWarnings` SAU KHI `complete()` đã resolve (đơn đã ghi Drift + outbox xong, giao dịch không còn có thể bị chặn nữa nên không có rủi ro "cảnh báo làm hỏng giao dịch") và hiển thị 1 `SnackBar` màu đỏ (`Colors.red.shade700`, `duration: 8s`) liệt kê từng sản phẩm + tồn còn lại, rồi mới `Navigator.pop()` như luồng thành công bình thường — không có `AlertDialog` xác nhận nào chắn đường.

**Vì sao chọn SnackBar (không phải banner/dialog mới):** `payment_sheet.dart` đã có sẵn đúng 1 precedent y hệt về hình dạng — khối `catch` quanh `promptAndPrintReceipt` (dòng 179-185) hiện `SnackBar` "Tạo hóa đơn thất bại" SAU khi đơn đã hoàn tất, ngay trước `Navigator.pop()`. Tái dùng đúng pattern này giữ "nhất quán phong cách" (yêu cầu trong DoD) thay vì đưa vào 1 loại UI mới (`MaterialBanner` — đã grep xác nhận không dùng ở đâu trong `apps/pos_app`, trong khi `SnackBar` xuất hiện ở 23 file). Có tô màu đỏ + kéo dài `duration` lên 8s (mặc định Flutter là 4s, không file nào khác trong repo tự set `duration`) để đủ thời gian đọc danh sách nhiều dòng sản phẩm, phân biệt trực quan với các SnackBar thông tin thường (không màu) trong cùng file.

**Evidence (file:line):**
- `apps/pos_app/lib/features/pos/checkout_service.dart:67-79` — class `NegativeStockWarning` (`productId`, `productName`, `remainingQtyLabel` — String đã format sẵn qua `_formatQty` có sẵn của file, luôn âm).
- `apps/pos_app/lib/features/pos/checkout_service.dart:81-94` — class `CheckoutResult` (`saleId` + `negativeStockWarnings`).
- `apps/pos_app/lib/features/pos/checkout_service.dart:105` — `complete()` đổi chữ ký `Future<String>` → `Future<CheckoutResult>`.
- `apps/pos_app/lib/features/pos/checkout_service.dart:135` — khai báo `final warnings = <NegativeStockWarning>[];` trước khối `_db.transaction`, thu thập trong lúc lặp qua từng dòng hàng (dòng 239-251 cho thành phần combo, dòng 254-266 cho dòng hàng thường).
- `apps/pos_app/lib/features/pos/checkout_service.dart:347` — `return CheckoutResult(saleId: saleId, negativeStockWarnings: warnings);`.
- `apps/pos_app/lib/features/pos/checkout_service.dart:354-417` — `_decrementStock` đổi trả về `Future<NegativeStockWarning?>`: giữ nguyên 100% logic trừ tồn + ghi `stockMovementsLocal` hiện có; chỉ thêm khối mới ở cuối (dòng 406-416) — khi `newQty < Decimal.zero` (chỉ có thể xảy ra lúc `allowNegative=true`, vì nhánh `!allowNegative` đã throw `InsufficientStockException` ở dòng 375-377 từ trước, giữ nguyên không đổi) mới truy vấn thêm `_db.products` để lấy `productName` — không tốn thêm query trên đường đi bình thường, chỉ query khi thực sự cần dựng cảnh báo.
- `apps/pos_app/lib/features/pos/payment_sheet.dart:139,144` — `final result = await widget.checkoutService.complete(...); final saleId = result.saleId;`.
- `apps/pos_app/lib/features/pos/payment_sheet.dart:186-195` — sau khối `try/catch` in hóa đơn (không đổi), kiểm `result.negativeStockWarnings.isNotEmpty` rồi `ScaffoldMessenger.of(context).showSnackBar(...)` **trước** `Navigator.of(context).pop()` — comment tại chỗ giải thích rõ đây là cảnh báo thêm, không phải dialog chặn luồng.
- `apps/pos_app/lib/features/pos/payment_sheet.dart:224-235` — `_negativeStockSnackBar()`: nội dung `'Cảnh báo: tồn kho đã về âm, báo chủ kiểm kê\n<Tên SP>: còn <qty âm>'` (mỗi sản phẩm 1 dòng nếu nhiều dòng hàng cùng về âm trong cùng đơn).

**Test:**
- `apps/pos_app/test/checkout_service_test.dart` — mở rộng 2 test hiện có thay vì thêm `test()` mới (đúng test đã có sẵn cho 2 kịch bản tồn đủ/tồn âm của checkout):
  - `'checkout writes sale and decrements stock'` (tồn đủ, 10 → 8): thêm `expect(result.negativeStockWarnings, isEmpty)` — kịch bản (b) của DoD ở tầng service.
  - `'checkout allows negative stock when store setting enabled'` (tồn 1 → -1, `allowNegativeStock=true`): thêm assertion `result.negativeStockWarnings` có đúng 1 phần tử, `productId='p1'`, `productName='Sting'`, `remainingQtyLabel='-1'` — kịch bản (a) ở tầng service.
  - `apps/pos_app/test/debt_checkout_test.dart` — cập nhật 1 call site lấy `saleId` qua `result.saleId` (đổi kiểu trả về của `complete()`, không đổi hành vi/assertion của test).
- `apps/pos_app/test/payment_sheet_test.dart` (file mới) — 2 `testWidgets` lái **đúng luồng UI thật** (`PaymentSheet.show(...)` → tap "Hoàn tất" → dialog "Hóa đơn" → "Bỏ qua" → kiểm SnackBar), không gọi thẳng `CheckoutService`, đúng yêu cầu DoD "cảnh báo xuất hiện" (hiện tượng UI quan sát được, không chỉ dữ liệu service):
  - Kịch bản (a): tồn 1, bán 2, `allowNegativeStock=true` → sau khi sheet đóng (`find.text('Thanh toán')` findsNothing — xác nhận giao dịch KHÔNG bị chặn), tìm thấy `'Sting: còn -1'` và `'Cảnh báo: tồn kho đã về âm'`.
  - Kịch bản (b): tồn 10, bán 2 (vẫn giữ `allowNegativeStock=true`, để tách biệt đúng biến đang test là "có về âm hay không" chứ không phải cờ cấu hình) → sheet đóng bình thường, `'Cảnh báo: tồn kho đã về âm'` findsNothing.
  - 2 vướng mắc kỹ thuật gặp phải khi viết test (không phải bug ở code sản phẩm, đã xác nhận qua debug print tạm thời rồi gỡ) — ghi lại vì không hiển nhiên với ai đọc lại sau này:
    1. `pumpAndSettle()` treo tới hết timeout ("pumpAndSettle timed out") nếu gọi ngay sau khi tap "Hoàn tất": nút này hiện `CircularProgressIndicator` (animation vô hạn) trong lúc `_complete()` đang `await` dialog "Hóa đơn" (chờ người dùng thật, không tự resolve) — 2 điều kiện cộng lại khiến `hasScheduledFrame` không bao giờ về `false`. Khắc phục bằng `pump()` có giới hạn (`tapCompleteAndReachReceiptDialog`, dòng 144-149 của file test) thay cho `pumpAndSettle()` ở đúng bước này; sau khi dialog bị tắt (sheet sắp bị pop, spinner biến mất theo) mới quay lại dùng `pumpAndSettle()` an toàn.
    2. `ScaffoldMessenger.showSnackBar` throw assertion `_scaffolds.isNotEmpty` nếu cây widget test không có `Scaffold` con nào — khác với ứng dụng thật (`pos_page.dart` luôn có `Scaffold` bao ngoài chỗ gọi `PaymentSheet.show`). Khắc phục bằng cách bọc `Scaffold` quanh `Builder` trong harness test (`openPaymentSheet`, dòng 114-136 của file test), khớp đúng cây widget thật thay vì né bằng cách khác (vd gọi thẳng `showSnackBar` ngoài context thật).

**Kết quả xác nhận:**
- `flutter analyze` — "No issues found!" trên toàn bộ repo `pos_app` (không riêng path đụng).
- `flutter test` (toàn bộ) — `+177: All tests passed!`, 0 failed. Đếm độc lập bằng `rg '^\s*(test|testWidgets)\(' apps/pos_app/test -c` ra đúng **177 test / 42 file** (baseline G4 là 175/41 file — tăng đúng 2, khớp 2 `testWidgets` mới trong `payment_sheet_test.dart`; không có `test()`/`testWidgets()` mới ở 2 file mở rộng vì chỉ thêm `expect` vào thân test có sẵn, không thêm khối test mới).
- File Windows generated (`generated_plugin_registrant.cc/.h`, `generated_plugins.cmake`) bị đụng bởi `flutter test`/`flutter analyze` (đúng quirk môi trường đã ghi trong plan) nhưng `git diff --ignore-all-space` rỗng — đã `git restore` cả 3 file trước khi commit.

**Quyết định tự đưa ra khi implement:**
- **Đổi kiểu trả về của `complete()` thay vì dùng callback/exception để truyền cảnh báo** — cân nhắc 2 phương án khác trước khi chọn: (a) throw 1 exception "soft" mang theo warnings — loại ngay vì cảnh báo không phải lỗi, throw sẽ nhảy vào nhánh `catch` sai ngữ nghĩa trong khi đơn đã thành công thật sự; (b) thêm callback `onNegativeStock(List<...>)` vào `complete()` — loại vì thêm 1 tham số phụ vào chữ ký service chỉ để phục vụ đúng 1 UI. Trả trong `CheckoutResult` (cùng pattern với `ReceiptPdfShareResult` đã có sẵn trong `receipt_print.dart`) là cách "thuần" hơn, giữ `checkout_service.dart` không có `BuildContext`/phụ thuộc UI, và cho phép caller tương lai (nếu có luồng checkout khác ngoài `PaymentSheet`) tự quyết định cách hiển thị.
- **Không sửa `pos_page.dart`** — cảnh báo được implement gọn trong `payment_sheet.dart` (nơi duy nhất gọi `checkoutService.complete()` — đã grep xác nhận toàn bộ `apps/pos_app/lib`), dùng lại đúng `ScaffoldMessenger` pattern đã có sẵn tại chỗ (khối bắt lỗi in hóa đơn ngay phía trên). Không cần đổi chữ ký `onCompleted` (`VoidCallback`) hay đụng `_message` state của `PosPage` — giữ đúng phạm vi G5, giảm diện tích diff.
- **SnackBar hiện TRƯỚC `Navigator.pop()`, không phải sau** — dựa đúng theo thứ tự đã có sẵn của khối "Tạo hóa đơn thất bại" (show rồi mới pop); xác nhận qua test rằng `ScaffoldMessenger` được đăng ký ở `Scaffold` của trang bên dưới (không phải của sheet đang đóng) nên SnackBar sống sót qua việc pop, không bị mất theo animation đóng sheet.
- **Không dedupe cảnh báo khi 1 sản phẩm xuất hiện nhiều lần** (vd vừa là dòng bán thường vừa là thành phần combo trong cùng đơn) — DoD không yêu cầu, và thông tin lặp vẫn đúng (phản ánh đúng tiến trình trừ tồn qua từng lần `_decrementStock`), không sai lệch — thêm dedupe sẽ là over-engineering ngoài 2 kịch bản DoD yêu cầu.
- **Ngưỡng cảnh báo là `< 0` tuyệt đối, không có buffer/ngưỡng gần hết** — đúng yêu cầu "chỉ cảnh báo khi tồn SAU bán thực sự ÂM (< 0)"; tồn về đúng 0 KHÔNG kích hoạt cảnh báo (điều kiện `newQty < Decimal.zero` loại trừ đúng trường hợp bằng 0) — phân biệt rõ với "hàng sắp hết" (báo cáo tồn kho, ngoài phạm vi G5).
