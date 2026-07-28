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
| **H2** | Server không validate tổng refund split khớp `lines[].lineRefundVnd` khi trả hàng | Cao | **Done** — build/unit (79 test) + e2e (39 suite/143 test, 3 lần trên DB, 2 lần DB tạo mới hoàn toàn) xanh |
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
- [x] `processFromSync` trong `sale-returns.service.ts` validate: tổng `dto.lines[].lineRefundVnd` phải khớp `dto.totalRefundVnd` (và qua đó khớp `cash+transfer+debtCredit`) — reject với reason rõ ràng (vd `refund_total_mismatch`) nếu lệch, không âm thầm chấp nhận.
- [x] Xác nhận `outbox_reason_labels.dart` có nhãn tiếng Việt cho reason mới (theo đúng convention các reason khác).
- [x] e2e: push trả hàng với `totalRefundVnd`/split KHÔNG khớp tổng `lines[]` → bị reject đúng reason; push khớp đúng → vẫn accept bình thường (không phá vỡ hành vi cũ).
- [x] `npm run build` + `test:unit` + full `test:e2e` xanh.

### Ghi chú review H2

- **Vị trí validate mới**: `apps/api/src/sync/sale-returns.service.ts::processFromSync`, ngay sau khối check nội bộ `cash+transfer+debtCredit===total` hiện có (dòng 115-131 trước khi sửa, nay dòng 115-142) và trước check `debtCredit>0 && !sale.customerId` — tức trước phần build tax snapshot (dòng ~147+ sau khi sửa) và trước `$transaction` (dòng ~181+). Không có DB write nào xảy ra trước điểm reject này (câu lệnh DB duy nhất chạy trước đó là các `SELECT` load `sale`/`priorReturns`/kiểm tra dòng hàng — không phải write) — đúng yêu cầu "không ghi gì vào DB nếu reject".
- **Reason string đã chọn**: `refund_total_mismatch` — theo đúng gợi ý trong DoD, nhất quán với 2 convention song song đang có trong codebase: (1) suffix `_mismatch` đã dùng cho case tương tự trong `sync.service.ts` (`category_direction_mismatch`, dòng 538); (2) vocabulary "refund" đã dùng xuyên suốt tên field liên quan (`cashRefundVnd`/`transferRefundVnd`/`totalRefundVnd`/`lineRefundVnd`) và đã có tiền lệ ở phía client — `apps/pos_app/lib/features/pos/sale_return_refund.dart::validateSaleReturnRefundSplit` dùng đúng code `'refund_mismatch'` cho check gần giống (split vs lineRefundTotal, nhưng ở tầng UI trước khi submit). Cố ý chọn tên `refund_total_mismatch` khác với `refund_mismatch` của client để không đánh đồng 2 khái niệm gần nhưng không giống hệt nhau (server đối chiếu với `lines[]` đã lưu thật, không phải giá trị UI tính trước khi submit).
- **Cách check — so sánh tuyệt đối, gộp luôn kiểm tra kiểu dữ liệu**: `const lineRefundSum = dto.lines.reduce((sum, l) => sum + l.lineRefundVnd, 0); if (!Number.isSafeInteger(lineRefundSum) || lineRefundSum !== total) return reject`. `Number.isSafeInteger` trên tổng bắt luôn cả trường hợp `lineRefundVnd` bị thiếu/không phải number (NaN hoặc bị ép kiểu thành chuỗi do JSON chỉnh tay khiến `+` nối chuỗi thay vì cộng số) — không cần validate kiểu riêng từng dòng. Toàn bộ là số nguyên VNĐ nên so sánh tuyệt đối `!==`, không thêm buffer làm tròn — đúng lưu ý trong đề bài.
- **Xác nhận luồng client thật luôn tự nhất quán 3 chiều** (`total` = split = Σ `lines[]`): đọc `apps/pos_app/lib/features/pos/sale_return_sheet.dart` dòng 138-192 xác nhận biến `total` được tính từ Σ `discountedReturnLineRefundVnd(...)` theo từng dòng NGAY TRƯỚC KHI gọi `validateSaleReturnRefundSplit(lineRefundTotal: total, ...)` rồi mới gọi `service.createReturn(...)`; `sale_return_service.dart` dòng 82 + 101 xác nhận `totalRefundVnd` lưu xuống outbox = `cashRefundVnd+transferRefundVnd+debtCreditVnd` (đã qua validate ở trên nên = `total` = Σ `lines[]`). Nghĩa là validate mới KHÔNG có khả năng reject nhầm bất kỳ giao dịch nào phát sinh từ luồng UI chuẩn hiện có — chỉ chặn payload bị lỗi hoặc bị chỉnh tay qua `OutboxEditSheet` (raw JSON editor), đúng rủi ro nêu trong đề bài.
- **Không đụng `push-sale.dto.ts`**: DTO tiếp tục là type thuần, không thêm class-validator decorator — đúng phạm vi DoD (chỉ yêu cầu validate trong service, không yêu cầu đổi kiến trúc DTO/pipe).
- **Nhãn Flutter**: thêm 1 case trong `apps/pos_app/lib/features/sync/outbox_reason_labels.dart` (`'refund_total_mismatch' => 'Tổng tiền hoàn không khớp tổng các dòng hàng trả — kiểm tra lại số liệu'`), kèm comment giải thích lý do reason này chỉ phát sinh từ payload lỗi/chỉnh tay — theo đúng convention comment của các case đặc biệt khác trong file (vd `sync_retry_exhausted`). Các reason sale-return khác vốn đã KHÔNG có nhãn riêng từ trước (`sale_not_found`, `return_not_same_day`, `return_qty_exceeded`, `invalid_return`, `invalid_return_line`, `invalid_combo`, `stock_not_found` — tất cả rơi vào nhánh mặc định `_ => code`, hiển thị code thô) — không tự ý backfill nhãn cho các reason cũ đó vì ngoài phạm vi H2.
- **Test — chọn mở rộng `phase1-polish.e2e-spec.ts`** (không phải `ledger-returns-stocktake.e2e-spec.ts`, không tạo file mới): file này đã có sẵn 1 test reject sale-return trong cùng describe block (`'rejects sale_return when not same ICT day'`) và tạo `Sale` trực tiếp qua Prisma (không cần dựng lại toàn bộ luồng bán hàng qua `/sync/push`) — nhẹ và ít rủi ro nhiễu hơn `ledger-returns-stocktake.e2e-spec.ts`, vốn xoá toàn bộ journal `sourceType='sale_return'` ở đầu test chính của nó. Thêm 2 test mới ngay sau test reject có sẵn, cùng dùng 1 sale gốc mẫu (qty=2, unitPrice=10000):
  1. `'rejects sale_return when totalRefundVnd does not match sum of lines (H2)'` — push return với split TỰ NHẤT QUÁN nội bộ (`cash=15000=15000+0+0`, đủ qua check cũ) nhưng lệch tổng dòng hàng thật (`lineRefundVnd=10000` cho 1/2 đơn vị trả) — assert `rejectedSaleReturns` chứa đúng `reason: 'refund_total_mismatch'`, `acceptedSaleReturnIds` KHÔNG chứa id, và `prisma.saleReturn.findUnique(...)` trả về `null` (xác nhận không ghi gì vào DB).
  2. `'accepts sale_return when totalRefundVnd matches sum of lines (H2)'` — cùng cấu trúc nhưng số liệu khớp đúng (`lineRefundVnd=10000=totalRefundVnd`) — assert accept bình thường (`acceptedSaleReturnIds` chứa id) + `SaleReturn` được lưu đúng `totalRefundVnd`/`cashRefundVnd`.
- **Xác minh test không phải tautology — bị chặn bởi auto-mode classifier, thay bằng suy luận tĩnh**: thử lặp lại đúng kỹ thuật ghi nhận ở H1 (tạm vô hiệu hoá check mới bằng `if (false && ...)`, chạy riêng file test để xác nhận test (a) fail đúng như dự đoán) nhưng cả 2 lần thử (có và không qua `rtk proxy`) đều bị **Claude Code auto-mode classifier chặn** lệnh chạy test ("Blocked by classifier") vì đang chạy test trên code đã bị sửa để tắt validate — không cố lách qua theo đúng nguyên tắc an toàn của tool, khôi phục lại đúng nguyên trạng đoạn code ngay sau đó (`git diff` xác nhận diff sạch, đúng 11 dòng thêm, không sót, không thừa). Thay vào đó xác minh bằng suy luận tĩnh: với code CŨ (chưa có check H2), DTO của test (a) có `cash+transfer+debtCredit=15000=total=15000` nên qua lọt check cũ, `debtCredit=0` nên qua luôn check khách hàng — sẽ rơi thẳng vào `$transaction` và được **accept**, nghĩa là trên code cũ `res.body.acceptedSaleReturnIds` sẽ chứa id thay vì `rejectedSaleReturns` chứa nó, khiến assertion `expect(res.body.rejectedSaleReturns).toEqual(expect.arrayContaining([...]))` chắc chắn FAIL — chứng minh test (a) thực sự bắt được đúng lỗi H2 mô tả, không phải tautology.
- **Kết quả xác minh**: `npm run build` sạch. `npm run test:unit` 11 suite/79 test pass (không đổi so với baseline sau H1 — H2 không thêm unit test vì toàn bộ logic mới phụ thuộc DTO đi qua `/sync/push` + DB thật, hợp lý hơn để ở e2e). `npm run test:e2e` (container `postgres:15` tạm, cổng host `55432` — ngoài dải cổng dev/Supabase đang chiếm, dùng `TAP_HOA_SKIP_LOCAL_IDENTITY=1` + `npx prisma migrate deploy` (28 migration, xác nhận qua `SELECT count(*) FROM _prisma_migrations` vì log CLI báo nhầm "2 migration(s) deployed" — đã đối chiếu trực tiếp DB, không tin theo text log) + `rtk proxy npx prisma db seed` vì hook `rtk` global chặn nhầm resolve binary `prisma`) chạy tổng **3 lần** — 2 lần trên container Postgres tạo mới hoàn toàn (`docker run` mới + migrate + seed lại từ đầu), 1 lần lặp lại giữa chừng trên cùng DB (ngay sau khi khôi phục code từ thử nghiệm tautology ở trên) — cả 3 lần đều **39/39 suite, 143/143 test pass** (baseline 141 + 2 test mới), thứ tự chạy file mỗi lần một khác (Jest `--runInBand` không đảm bảo thứ tự ổn định giữa các lần, ví dụ lần đầu `users→shifts→cash-fund-consistency→...`, lần cuối `users→sync-push→customers-debt→...`). Riêng `phase1-polish.e2e-spec.ts` xác nhận thêm qua chạy verbose độc lập: 5/5 test pass, đúng tên 2 test H2 mới. Cả 2 container tạm (`tap-hoa-h2-e2e-pg`, `tap-hoa-h2-e2e-pg2`) đã `docker stop`/`docker rm` sau khi xong, không đụng container Supabase dev (`supabase_*_omni-commerce`/`supabase_*_tap-hoa`) hay các container không liên quan khác.
- **`flutter analyze`**: sạch ("No issues found!", ~75s). `flutter pub get` (chạy ngầm bên trong `analyze`) làm đổi 3 file `apps/pos_app/windows/flutter/generated_plugin_registrant.cc/.h` + `generated_plugins.cmake`, nhưng `git diff` xác nhận rỗng thực chất (chỉ khác byte CRLF/LF do `.gitattributes` normalize, không có nội dung thật thay đổi) — đã `git restore` cả 3 file trước khi commit, đúng lưu ý trong đề bài.

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
