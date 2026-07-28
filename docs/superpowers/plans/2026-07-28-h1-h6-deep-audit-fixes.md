# Vá 6 gap phát hiện qua đối chiếu chi tiết với spec thiết kế riêng lẻ (H1-H6)

> **For agentic workers:** Subagent-Driven Development — **một Task = một subagent**, review giữa các task, không mở task tiếp theo khi task trước chưa PASS review.
> **Nguồn:** sau khi đóng đợt audit spec tổng §4-§6 (G1-G6, PR #28/#29), chạy thêm 8 subagent song song rà 33 file plan + 12 file ops + code TODO/dependency + đối chiếu chi tiết 12 file `docs/superpowers/specs/*-design.md` (spec riêng từng tính năng, chi tiết hơn bản spec tổng) với code thật trên `main` @ `efeece2`. Phát hiện 6 gap code thật (H1-H6), không phải toàn bộ mới — H1 vốn đã được ghi nhận là "còn nợ" từ P0.3 (đợt trước) nhưng chưa vá.
> **Branch:** `claude/fix-h1-h6-gaps`.

**Goal:** Vá 6 gap code thật (khác — không trùng — với G1-G6 đã đóng). 2 mục "Cao" ảnh hưởng trực tiếp tới độ chính xác đối chiếu tiền mặt và toàn vẹn dữ liệu kế toán; còn lại là sai số nhỏ/edge case/quả bom hẹn giờ tiềm ẩn.

**Đã đóng, không đưa vào plan này:** H5 (giá vốn `Product.costVnd` khi `vatEnabled=true`) — hỏi lại user, xác nhận **giữ nguyên hành vi hiện tại** (giá đã trừ VAT, khớp số dùng tính Nợ 632 trong sổ sách). Không cần sửa code.

**Architecture:** Không đổi monorepo. Offline-first giữ nguyên: chứng từ mới → Drift + outbox + sync DTO + e2e. Bút toán mới bám `LedgerService`/`journal-builders`.

**Tech Stack:** NestJS 10 + Prisma + PostgreSQL (`apps/api`); Flutter 3 + Drift (`apps/pos_app`).

## Global Constraints

- Thay đổi sổ/sync/kế toán → **bắt buộc e2e**; Flutter → `flutter analyze` sạch trên path đụng.
- Không mở YAGNI §7 (website, loyalty, HR, chuỗi > ~10 điểm, nộp CQT).
- Mọi task phải chạy được `npm run build` + `npm run test:unit` (API) trước khi review; e2e xác nhận qua container Postgres riêng (không đụng dev DB thật).
- Không `npm audit fix --force` (nợ dependency major-version ghi nhận riêng, không thuộc phạm vi đợt này).

---

## Trạng thái

| Task | Mô tả | Ưu tiên | Status |
|------|-------|---------|--------|
| **H1** | `loadShiftCashInputsWithClient` bỏ sót hoàn tiền mặt của trả hàng bán | Cao | **Done** — build/unit (79 test) + e2e (39 suite/141 test, 3 lần trên DB sạch) xanh |
| **H2** | Server không validate tổng refund split khớp `lines[].lineRefundVnd` khi trả hàng | Cao | Chưa |
| **H3** | Trial balance ("Tổng hợp") không lọc `store.active` như period reports — landmine tiềm ẩn | Trung bình | Chưa |
| **H4** | Giá vốn combo làm tròn từng thành phần rồi cộng, sai thứ tự so với spec | Thấp | Chưa |
| **H5** | ~~Giá vốn `costVnd` khi có VAT~~ | — | **Đã đóng — không phải gap, giữ nguyên (xem trên)** |
| **H6** | Thứ tự xử lý `/sync/push`: kho chạy trước bán hàng, ngược spec | Thấp | Chưa |

---

## H1 — `loadShiftCashInputsWithClient` bỏ sót hoàn tiền mặt trả hàng (Cao)

**Vấn đề:** `apps/api/src/shifts/shifts.service.ts` hàm `loadShiftCashInputsWithClient` (khoảng dòng 58-118) chỉ query `client.sale`/`client.debtLedgerEntry`/`client.cashVoucher` — hoàn toàn không truy vấn `saleReturn` (grep xác nhận 0 kết quả). Khi khách trả hàng và được hoàn tiền mặt trong ca, số tiền mặt "kỳ vọng" (`expectedCashVnd`) lúc đóng ca KHÔNG trừ đi khoản hoàn này → báo lệch âm giả (tiền mặt thực tế ít hơn kỳ vọng một cách giả tạo). Đã ghi nhận từ review P0.3 (`docs/superpowers/plans/2026-07-27-hoan-thien-100.md`, dòng ~64) nhưng cố tình tách task, chưa vá.

**DoD:**
- [x] `loadShiftCashInputsWithClient` (và `apps/api/src/cash/expected-cash.ts::computeShiftCashSnapshot` nếu logic tính toán nằm ở đó thay vì/thêm ở shifts.service.ts — đọc kỹ cả 2 file để xác định đúng chỗ cần sửa) cộng thêm hoàn tiền mặt (`cashRefundVnd`) từ `SaleReturn` thuộc đúng ca (theo `shiftId` nếu `SaleReturn` có field này, hoặc theo store+khung giờ ca nếu không).
- [x] Hoàn tiền chuyển khoản (`transferRefundVnd`) của trả hàng KHÔNG được tính vào tiền mặt (chỉ `cashRefundVnd` mới trừ vào kỳ vọng tiền mặt).
- [x] e2e: bán hàng tiền mặt → trả hàng hoàn tiền mặt một phần trong cùng ca → đóng ca → `expectedCashVnd` phải phản ánh đúng (đã trừ hoàn tiền), không còn lệch âm giả.
- [x] `npm run build` + `test:unit` + full `test:e2e` xanh.

### Ghi chú review H1

- **Chỗ sửa thật — cả 2 file, đúng như DoD dự đoán**: logic cộng dồn theo ca (query DB) nằm ở `apps/api/src/shifts/shifts.service.ts::loadShiftCashInputsWithClient` (dòng 58-127 sau khi sửa); công thức tính `expectedCashVnd` nằm ở `apps/api/src/cash/expected-cash.ts::computeShiftCashSnapshot` (dòng 26-47). Cả hai đều thiếu — đã sửa cả hai theo đúng hai vai trò riêng biệt: `shifts.service.ts` chỉ gom dữ liệu thô (`ShiftCashInputs`), `expected-cash.ts` chứa công thức thuần (không đụng DB, dễ unit-test độc lập).
- **Quy `SaleReturn` về đúng ca — KHÔNG cần join qua `Sale` gốc**: đọc `apps/api/prisma/schema.prisma` dòng 333-353 xác nhận `SaleReturn` có field `shiftId String?` **trực tiếp** (khác `SupplierPayment`, dòng 821-836, không có field này — đúng lý do P0.3 từng ghi "không quy được về ca"). Đọc thêm `apps/api/src/sync/sale-returns.service.ts` dòng 177 (`shiftId: dto.shiftId ?? null`) và `apps/pos_app/lib/features/pos/sale_return_service.dart` dòng 77-96 xác nhận client **bắt buộc** phải có ca đang mở (`_shiftRepository.requireOpenShift`) mới tạo được phiếu trả hàng, và luôn gửi `shiftId: shift.id` lên server — nên `shiftId` trên `SaleReturn` luôn được điền trong luồng thật, không cần fallback theo store+khung giờ. Migration `20260724160000_phase1_remaining_nine/migration.sql` dòng 63-78 xác nhận cột đã tồn tại thật trong DB (không chỉ khai báo trong schema.prisma). Fix: thêm `client.saleReturn.aggregate({ where: { shiftId }, _sum: { cashRefundVnd: true } })` ngay cạnh `salesAgg` (cùng dùng `aggregate`, nhất quán style với cách file này tính `saleCashTotal`/`saleTransferTotal`), gán vào field mới `saleReturnCashTotal` của `ShiftCashInputs`.
- **Công thức**: `expectedCashVnd = openingCash + saleCashTotal + debtPaymentCashTotal + voucherCashInTotal − voucherCashOutTotal − saleReturnCashTotal` (thêm đúng 1 số hạng trừ). Đối chiếu với `apps/api/src/reports/cash-fund.ts` (dòng 113-119, `computeCashFundTotals` cho endpoint `/reports/cash-fund` — đã tính đúng `saleReturnCashVnd` từ trước, xác nhận qua `cash-fund-consistency.e2e-spec.ts` đang PASS) — cùng dấu trừ, cùng chỉ lấy phần `cashRefundVnd`, khớp đúng cách hệ thống đã làm ở chỗ khác. `transferRefundVnd` của `SaleReturn` **không** được đưa vào `ShiftCashInputs` ở bất kỳ trường nào — đúng yêu cầu DoD #2.
- **Quyết định tự đưa ra — phạm vi KHÔNG đụng `transferInShiftVnd`**: `computeShiftCashSnapshot` còn trả `transferInShiftVnd` (= CK trong ca, hiển thị riêng cho cashier, không dùng để đối chiếu tiền mặt đếm tay). Về lý thuyết, hoàn tiền trả hàng qua chuyển khoản (`transferRefundVnd`) cũng làm giảm dòng tiền CK thực tế trong ca, và `cash-fund.ts::netTransferVnd` (dòng 120-126) đã trừ `saleReturnTransferVnd` cho mục đích đối chiếu sổ cái TK 112. Nhưng: (a) "Vấn đề" + DoD của H1 trong plan này chỉ nêu `expectedCashVnd`/`cashRefundVnd`, không nêu `transferInShiftVnd` là gap; (b) `transferInShiftVnd` không phải số liệu đối chiếu vật lý (không ai "đếm" tiền chuyển khoản như đếm tiền mặt trong ngăn kéo) nên rủi ro báo "lệch âm giả" như mô tả trong "Vấn đề" của H1 không áp dụng cho nó; (c) đối chiếu TK 112 thật đã có `/reports/cash-fund` + `/ledger/trial-balance` làm đúng việc đó ở tầng kỳ/sổ cái, độc lập với snapshot theo ca. Quyết định: **giữ nguyên** `transferInShiftVnd`, không trừ `transferRefundVnd`, để tránh mở rộng phạm vi ngoài DoD đã duyệt. Ghi chú lại đây làm nợ tiềm năng cho task khác nếu sau này xác nhận cashier thực sự cần đối chiếu CK theo ca.
- **Quyết định tự đưa ra — không đụng Flutter client**: `apps/pos_app/lib/features/cash/expected_cash.dart::computeBreakdown` là bản mirror Dart 1-1 của công thức cũ (thiếu đúng cùng một số hạng), dùng để hiển thị "Tiền mặt kỳ vọng" và tự điền gợi ý vào ô đếm tiền lúc đóng ca (`close_shift_page.dart`). Không sửa vì: (1) H1 trong plan này chỉ định danh `shifts.service.ts`/`expected-cash.ts` (backend); (2) server luôn là nguồn sự thật cuối — `CloseShiftDto`/`PushShiftCloseDto` không nhận `expectedCashVnd` từ client, `shifts.service.ts::close` luôn tự tính lại từ DB (xem dòng 203-204) nên số liệu **lưu vào DB và trả về client sau khi đóng ca luôn đúng** bất kể client hiển thị gì trước đó; (3) sửa Flutter đòi hỏi thêm truy vấn `saleReturnsLocal` theo ca ở tầng Drift + `flutter analyze`/`flutter test`, vượt phạm vi "chỉ đụng H1" đã được giao. Nợ UI thuần tuý (gợi ý đếm tiền trước khi xác nhận có thể lệch tạm thời so với số cuối cùng) — ghi nhận, không tự ý mở rộng sang H2-H6 hay pos_app.
- **Test**: (1) unit `apps/api/src/cash/expected-cash.spec.ts` — thêm field `saleReturnCashTotal` vào 2 test cũ (giá trị 0, không đổi hành vi) + 1 test mới `'H1: trừ hoàn tiền mặt trả hàng...'` tái hiện đúng phép trừ. (2) e2e `apps/api/test/shifts.e2e-spec.ts` (chọn thay vì `cash-fund-consistency.e2e-spec.ts` vì DoD cần assert trực tiếp response `POST /shifts/:id/close`, đúng việc file này đã làm cho 2 test khác) — thêm test mở ca (500.000) → bán tiền mặt 200.000 qua `/sync/push` → trả 1 đơn vị hoàn 30.000 tiền mặt + 20.000 chuyển khoản (cùng ca, cùng ngày ICT) → đóng ca, đếm đúng 670.000 (= 500.000+200.000−30.000) → assert `expectedCashVnd=670000`, `varianceVnd=0` (KHÔNG còn báo lệch âm giả 30.000 như trước khi vá), `transferInShiftVnd=0` (xác nhận hoàn CK không rò vào tiền mặt lẫn CK-trong-ca vì sale gốc không có phần CK). **Đã xác minh test thật sự bắt được lỗi**: tạm revert 1 dòng `- inputs.saleReturnCashTotal` trong `expected-cash.ts`, chạy riêng test H1 → fail đúng như dự đoán (`Expected: 670000, Received: 700000`), rồi khôi phục lại — chứng minh test không phải tautology.
- **Kết quả xác minh**: `npm run build` sạch; `npm run test:unit` 11 suite/79 test pass (baseline 78 + 1 test mới). `npm run test:e2e` (container `postgres:15` tạm, cổng host `55432` — ngoài dải cổng dev/Supabase bị chiếm, dùng `TAP_HOA_SKIP_LOCAL_IDENTITY=1` + `npx prisma migrate deploy` (28 migration) + `rtk proxy npx prisma db seed` vì hook `rtk` global của máy chặn nhầm resolve binary `prisma`) chạy **3 lần** trên DB tạo mới hoàn toàn mỗi lần (`DROP DATABASE`/`CREATE DATABASE` + migrate + seed lại), thứ tự file mỗi lần một khác (Jest không đảm bảo thứ tự ổn định) — cả 3 lần đều **39/39 suite, 141/141 test pass** (baseline 140 + 1 test mới). Container tạm đã `docker stop`/`docker rm` sau khi xong, không đụng container Supabase dev (`supabase_*_tap-hoa`, đang dừng sẵn) hay các container `omni-commerce` không liên quan.

---

## H2 — Server không validate tổng refund split khớp `lines[]` khi trả hàng (Cao)

**Vấn đề:** `apps/pos_app/lib/features/pos/sale_return_refund.dart` validate client-side: `cash + transfer + debtCredit == lineRefundTotal`. Nhưng `apps/api/src/sync/sale-returns.service.ts` (khoảng dòng 115-131) chỉ tự đối chiếu `cash + transfer + debtCredit === total` (nội bộ DTO), **không** đối chiếu `total`/split với tổng thực tế `dto.lines[].lineRefundVnd`. `PushSaleReturnDto` (`apps/api/src/sync/dto/push-sale.dto.ts`, khoảng dòng 128-136) chỉ là type thuần, không có class-validator. Payload lỗi (bug client) hoặc chỉnh tay qua raw-JSON editor của `OutboxEditSheet` có thể đẩy `totalRefundVnd`/split lệch hẳn với tổng dòng hàng thật mà server vẫn chấp nhận — bút toán sổ cái trả hàng khi đó sẽ sai số tiền.

**DoD:**
- [ ] `processFromSync` trong `sale-returns.service.ts` validate: tổng `dto.lines[].lineRefundVnd` phải khớp `dto.totalRefundVnd` (và qua đó khớp `cash+transfer+debtCredit`) — reject với reason rõ ràng (vd `refund_total_mismatch`) nếu lệch, không âm thầm chấp nhận.
- [ ] Xác nhận `outbox_reason_labels.dart` có nhãn tiếng Việt cho reason mới (theo đúng convention các reason khác).
- [ ] e2e: push trả hàng với `totalRefundVnd`/split KHÔNG khớp tổng `lines[]` → bị reject đúng reason; push khớp đúng → vẫn accept bình thường (không phá vỡ hành vi cũ).
- [ ] `npm run build` + `test:unit` + full `test:e2e` xanh.

---

## H3 — Trial balance "Tổng hợp" không lọc `store.active`, khác `period reports` (Trung bình)

**Vấn đề:** `LedgerService.trialBalance` (`apps/api/src/ledger/ledger.service.ts`, hàm `ledgerStoreFilter` khoảng dòng 966-980): owner xem "Tổng hợp" (không truyền `storeId`) → không lọc gì, gồm cả store `active=false` nếu tồn tại. `ReportsService.periodTrialBalance/periodPnl/vatSummary/export*` (`apps/api/src/reports/reports.service.ts`, `resolveStoreIds`/`resolvePeriodStoreFilter` khoảng dòng 146-162, 677-686): owner "Tổng hợp" → chỉ lấy store `active=true`. Hai API này cùng bị gọi từ CÙNG một màn `apps/pos_app/lib/features/ledger/ledger_page.dart` (tab "Cân đối phát sinh" gọi `/ledger/trial-balance`; tab báo cáo kỳ gọi `/reports/period/*`), dùng chung `storeId=null`. Hiện KHÔNG có endpoint nào set `Store.active=false` nên bug chưa tự lộ qua UI — nhưng là landmine sẽ nổ ngay khi tính năng "ngừng hoạt động điểm bán" xuất hiện, hoặc nếu ai đó set thẳng qua DB/seed.

**DoD:**
- [ ] Thống nhất 1 trong 2 cách: hoặc `ledgerStoreFilter` cũng loại `active=false` giống `resolveStoreIds`, hoặc `resolveStoreIds`/`resolvePeriodStoreFilter` bỏ điều kiện `active=true` để khớp `ledgerStoreFilter` — chọn theo đúng ý định nghiệp vụ thật (một điểm bán ngừng hoạt động thì sổ sách lịch sử của nó có nên tiếp tục xuất hiện trong "Tổng hợp" hay không — mặc định hợp lý nhất: CÓ, vì đó là dữ liệu lịch sử đã phát sinh thật, ngừng hoạt động chỉ nghĩa là không bán mới chứ không xoá lịch sử — nên khuyến nghị sửa `resolveStoreIds` bỏ lọc `active`, không sửa `ledgerStoreFilter`; nhưng tự xác nhận lại logic trước khi đổi, đừng chỉ tin bản DoD này).
- [ ] Test (unit hoặc e2e) dựng 1 store `active=false` có bút toán lịch sử, xác nhận `/ledger/trial-balance` và `/reports/period/pnl` (cả hai không truyền `storeId`) trả về **cùng nhất quán** việc có/không gồm store đó.
- [ ] `npm run build` + `test:unit` + full `test:e2e` xanh.

---

## H4 — Giá vốn combo làm tròn sai thứ tự so với spec (Thấp)

**Vấn đề:** Spec (`docs/superpowers/specs/2026-07-24-phase2-cogs-wac-design.md`) quy định giá vốn combo = `Σ (componentAvg * qtyBase)` rồi mới làm tròn 1 lần. Code hiện tại (`apps/api/src/sync/sync.service.ts:984`) làm tròn TỪNG thành phần rồi mới cộng dồn (`unitCostVnd += Math.round(avg * Number(c.qtyBase))`), gây lệch nhỏ có tính hệ thống (ví dụ 2 thành phần avgCost=1667đ, qtyBase=0.5: đúng spec = round(1667.0) = 1667đ, code hiện tại = round(833.5)+round(833.5) = 1668đ).

**DoD:**
- [ ] Sửa để cộng dồn giá trị chưa làm tròn của từng thành phần trước, chỉ làm tròn 1 lần ở kết quả cuối `unitCostVnd`.
- [ ] Unit test hoặc e2e tái hiện đúng case lệch nêu trên (2+ thành phần có `avgCost * qtyBase` lẻ, tổng làm tròn ra kết quả khác nếu làm tròn từng phần) — xác nhận kết quả mới khớp công thức spec.
- [ ] `npm run build` + `test:unit` + full `test:e2e` xanh.

---

## H6 — Thứ tự xử lý `/sync/push`: kho chạy trước bán hàng, ngược spec (Thấp)

**Vấn đề:** Spec (`docs/superpowers/specs/2026-07-24-inventory-stock-ops-design.md` §3.5) quy định thứ tự push: sau `sales`, trước `shiftCloses` (cùng nhóm cash/debt). Code thật (`apps/api/src/sync/sync.service.ts:246-262`): `pushInventory()` (dòng 246) chạy TRƯỚC `pushSales()` (dòng 248). Ảnh hưởng: nếu cùng 1 request `/sync/push` vừa có điều chỉnh kho (`stockTransferApprove`/`wastage`/...) vừa có `sale` đụng chung sản phẩm, kết quả `insufficient_stock` sẽ phụ thuộc thứ tự — ngược với thiết kế.

**DoD:**
- [ ] Đổi thứ tự gọi trong `/sync/push` handler: `pushSales()` chạy trước `pushInventory()`, giữ nguyên `pushCashVouchers`/`pushDebtPayments`/`pushInventory` cùng nhóm, `shiftCloses` xử lý sau cùng — khớp đúng §3.5.
- [ ] Rà lại KHÔNG có phụ thuộc ngầm nào dựa vào thứ tự cũ (đọc kỹ toàn bộ hàm xử lý push trước khi đổi — nếu có phụ thuộc thật sự hợp lý khiến đổi thứ tự gây hại nhiều hơn lợi, dừng lại và ghi rõ lý do trong ghi chú review thay vì đổi ẩu).
- [ ] e2e: 1 request `/sync/push` vừa có `wastage`/`stockTransferApprove` giảm tồn vừa có `sale` cùng sản phẩm trong cùng request → xác nhận hành vi khớp đúng thứ tự spec (sales trước).
- [ ] `npm run build` + `test:unit` + full `test:e2e` xanh.

---

## Cách chạy (SDD)

| Bước | Cách |
|------|------|
| Mỗi task | **1 subagent** — implement + test, không đụng file ngoài scope |
| Review | Orchestrator đọc diff + tự chạy lại build/test/e2e độc lập trước khi tick DoD |
| Commit | 1 commit/task, message tiếng Việt mô tả rõ, cập nhật bảng Trạng thái + tick DoD trong cùng commit |
| Thứ tự | H1 → H2 → H3 → H4 → H6 (ưu tiên Cao trước, còn lại theo mức ảnh hưởng) |
