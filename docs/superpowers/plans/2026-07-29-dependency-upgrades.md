# Nâng cấp dependency có lỗ hổng bảo mật (I1-I8)

> **For agentic workers:** Subagent-Driven Development — **một Task = một subagent**, review giữa các task, không mở task tiếp theo khi task trước chưa PASS review.
> **Nguồn:** `npm audit` trên `apps/api` (2026-07-28, xác nhận lại 2026-07-29): 58 lỗ hổng toàn cây (3 low/20 moderate/34 high/1 critical), lọc production (`--omit=dev`) còn 27 (14 moderate/12 high/1 critical) — chủ yếu qua `@nestjs/*`, `exceljs`, `firebase-admin`. Không có bản vá lẻ, phải nâng major. **Không dùng `npm audit fix --force`** (theo đúng Global Constraint đã áp dụng suốt các đợt G/H trước — force fix chọn version tự động, không kiểm soát được, không phù hợp khi cần verify từng bước).
> **Branch:** `chore/dependency-upgrades`.

**Goal:** Nâng từng dependency lên major mới nhất, **thấp rủi ro trước, cao rủi ro sau** — mỗi bước tự đứng độc lập, build+test+e2e xanh trước khi qua bước tiếp theo. Nếu 1 bước phát hiện rủi ro/breaking change vượt phạm vi hợp lý, dừng lại, ghi rõ lý do, không ép chạy.

**Không thuộc phạm vi:** golang webpack/teeny-request/@google-cloud/storage transitive qua `firebase-admin` — nâng `firebase-admin` (I2) tới bản mới nhất hiện có, phần dư nếu còn tồn tại là do lỗ hổng upstream chưa có bản vá, ghi nhận lại chứ không tự chế fix riêng.

**Architecture:** Không đổi monorepo, không đổi logic nghiệp vụ — đây thuần là nâng version + sửa breaking-change API nếu phát sinh khi build/test đỏ.

**Tech Stack hiện tại → mục tiêu** (xác nhận qua `npm outdated`, `npm view <pkg>@<major> peerDependencies/engines` — 2026-07-29):

| Package | Hiện tại | Mục tiêu | Rủi ro |
|---|---|---|---|
| `bcrypt` + `@types/bcrypt` | 5.1.1 / 5.0.2 | 6.x | Thấp |
| `@types/supertest` | 6.0.3 | 7.x | Thấp (chỉ dev/test) |
| `firebase-admin` | 13.10.0 | 14.x | Thấp (FCM chưa cấu hình thật, đường code ít dùng) |
| `jest` + `@types/jest` | 29.7.0 / 29.5.14 | 30.x | Thấp-Trung bình |
| `class-validator` | 0.14.4 | 0.15.x | Trung bình (dùng khắp DTO) |
| `@types/express` | 4.17.25 | 5.x | Trung bình (cần xác nhận express runtime thật có bị ảnh hưởng qua NestJS không) |
| `typescript` + `@types/node` | 5.9.3 / 22.20.1 | 7.x / 26.x | **Cao** |
| `@nestjs/*` (common/core/cli/jwt/platform-express/testing) | 10.x | 11.x | **Cao** — peer dep đòi `@nestjs/common@^11`, `@nestjs/platform-express@^11` khớp nhau; node >=20 (Dockerfile `node:20-alpine` đã đủ) |
| `@prisma/client` + `prisma` | 6.19.3 | 7.x | **Cao** — cần node `^20.19 \|\| ^22.12 \|\| >=24.0`, phải xác nhận patch version thật của `node:20-alpine` đủ `20.19+` |

## Global Constraints

- **Không `npm audit fix --force`** dưới mọi hình thức.
- Mỗi task: `npm run build` + `npm run test:unit` + full `npm run test:e2e` (container Postgres riêng) đều phải xanh trước khi coi là xong.
- Nếu 1 package cần sửa code (không chỉ bump version trong `package.json`), sửa tối thiểu — chỉ đủ để build/test xanh lại, không nhân tiện refactor thêm.
- Nếu phát hiện breaking change quá lớn/rủi ro cao hơn lợi ích rõ ràng, dừng — ghi "Ghi chú review" giải thích, để nguyên version cũ, coi đó là kết luận hợp lệ (giống cách H6 đã làm với thứ tự sync).
- Không đụng `apps/pos_app` (Flutter) — ngoài phạm vi đợt này.

---

## Trạng thái

| Task | Mô tả | Rủi ro | Status |
|------|-------|--------|--------|
| **I1** | `bcrypt` + `@types/bcrypt` 5→6, `@types/supertest` 6→7 | Thấp | **Done** — bcrypt 5.1.1→6.0.0, @types/bcrypt 5.0.2→6.0.0, @types/supertest 6.0.2→7.2.1; không sửa code (build sạch ngay); build sạch + unit (12 suite/84 test) + e2e (39 suite/146 test, 1 lần trên Postgres 15 tạm cổng 55432) xanh |
| **I2** | `firebase-admin` 13→14 | Thấp | **Done** — firebase-admin 13.10.0→14.2.0; CÓ sửa code (`src/devices/devices.service.ts`: legacy namespace API `admin.apps`/`admin.credential.cert`/`admin.messaging()` bị gỡ bỏ hoàn toàn ở v14, chuyển sang modular `firebase-admin/app` + `firebase-admin/messaging`); build sạch + unit (12 suite/84 test) + e2e (39 suite/146 test, container Postgres 15 tạm cổng 55433) xanh |
| **I3** | `jest` + `@types/jest` 29→30 | Thấp-Trung bình | **Done** — jest 29.7.0→30.4.2, @types/jest 29.5.14→30.0.0; `ts-jest` giữ nguyên `^29.2.5` (không có major 30.x, bản `latest` 29.4.12 đã hỗ trợ peer `jest@^30`, đã resolve sẵn); không sửa config/code (2 file jest config + toàn bộ test giữ nguyên nội dung); build sạch + unit (12 suite/84 test) + e2e (39 suite/146 test, chạy 3 lần trên 2 container Postgres 15 tạm cổng 55434, không lần nào gặp flaky) xanh |
| **I4** | `class-validator` 0.14→0.15 | Trung bình | Chưa |
| **I5** | `@types/express` 4→5 | Trung bình | Chưa |
| **I6** | `typescript` + `@types/node` lên bản mới nhất tương thích | Cao | Chưa |
| **I7** | `@nestjs/*` 10→11 | Cao | Chưa |
| **I8** | `@prisma/client` + `prisma` 6→7 | Cao | Chưa |

---

## I1 — `bcrypt`/`@types/bcrypt`/`@types/supertest` (Thấp)

**DoD:**
- [x] `npm install bcrypt@latest @types/bcrypt@latest @types/supertest@latest` (trong `apps/api`).
- [x] Đọc CHANGELOG/breaking-change note của `bcrypt` 6.x (native binding version, Node ABI) — xác nhận bản mới vẫn build được trên môi trường hiện tại (`node:20-alpine` cho Docker, Windows cho dev).
- [x] `npm run build` + `test:unit` + full `test:e2e` xanh (đặc biệt test liên quan login/password: `auth.e2e-spec.ts`, `users.e2e-spec.ts`).
- [x] Cập nhật bảng Trạng thái + tick DoD.

### Ghi chú review I1

- **Version thật trước→sau** (đối chiếu `git diff apps/api/package.json`, không phải số trong bảng Tech Stack ở đầu file — bảng đó ghi `@types/supertest` hiện tại là `6.0.3` nhưng `package.json` thật đang pin `^6.0.2`, lệch nhẹ so với thực tế lúc viết plan, không ảnh hưởng kết quả): `bcrypt` `^5.1.1`→`^6.0.0`, `@types/bcrypt` `^5.0.2`→`^6.0.0`, `@types/supertest` `^6.0.2`→`^7.2.1`. `supertest` runtime (không đổi, ngoài phạm vi I1) đã là `^7.0.0` từ trước — nghĩa là `@types/supertest@6` từng lệch pha với runtime `7.x`, bump lần này thực ra là sửa một type mismatch tồn đọng, không phải rủi ro mới.
- **Nghiên cứu breaking change `bcrypt` 6.x trước khi cài** (`npm view bcrypt engines` + đọc `CHANGELOG.md`/release notes chính thức trên GitHub `kelektiv/node.bcrypt.js`, không đoán): thay đổi lớn nhất là bỏ `node-pre-gyp` (tải prebuilt binary qua mạng lúc `npm install`), chuyển sang `prebuildify` (đóng gói sẵn prebuilt binary NGAY TRONG tarball npm, dùng `node-gyp-build` để chọn đúng binary lúc `require()`, không cần mạng lúc cài). Node engines đổi từ không giới hạn rõ ràng sang `>= 18` (`npm view bcrypt engines` xác nhận), CHANGELOG ghi rõ "Drop support for NodeJS <= 16" — cả hai đều nằm dưới Node 20 (base image `apps/api/Dockerfile` dùng `node:20-alpine`), không có yêu cầu Node cao hơn 20. Binary vẫn build trên N-API (`prebuildify --napi`, xác nhận qua `scripts.build` trong `package.json` của package đã cài) — ABI ổn định qua các bản Node major, giảm rủi ro "vỡ" khi Node runtime đổi version trong tương lai so với kiểu binding cũ dựa thẳng vào `NODE_MODULE_VERSION`.
- **Xác nhận thật (không chỉ đọc doc) rằng native binding chạy được trên cả 2 môi trường mục tiêu** — đọc trực tiếp nội dung package vừa cài, KHÔNG build Docker image thật (đúng phạm vi DoD, không yêu cầu build image trong task này): `node_modules/bcrypt/prebuilds/` chứa sẵn 7 target (`darwin-arm64`, `darwin-x64`, `linux-arm`, `linux-arm64`, `linux-x64`, `win32-arm64`, `win32-x64`), riêng `linux-x64` có CẢ HAI biến thể libc — `bcrypt.glibc.node` VÀ `bcrypt.musl.node` — tức Alpine (`node:20-alpine` dùng musl, không phải glibc) có sẵn prebuilt binary đóng gói sẵn, không cần toolchain biên dịch (`Dockerfile` hiện chỉ `apk add openssl`, không có `python3`/`make`/`g++`) như lo ngại ban đầu trong đề bài. Trên Windows dev: chạy trực tiếp `node -e "require('bcrypt').hashSync(...)"`/`compareSync(...)` ngay sau khi cài (dùng `win32-x64/bcrypt.node` có sẵn) → **thành công**, không cần biên dịch gì thêm.
- **Một quan sát về môi trường, không phải bug của I1**: `npm install` in ra cảnh báo `npm warn allow-scripts` — một cơ chế chặn install-script (đến từ tooling toàn cục trên máy, không phải config trong repo — đã kiểm tra không có `allowScripts`/`.npmrc` nào trong repo) — khiến install-script `node-gyp-build` của `bcrypt@6.0.0` KHÔNG chạy tự động lúc `npm install`. Đã xác minh đây không phải vấn đề thật: `require('bcrypt')` gọi `node-gyp-build` lúc RUNTIME (không phải chỉ lúc install) để tự tìm đúng prebuild trong `prebuilds/`, nên hoạt động bình thường dù install-script bị chặn (đã test `hashSync`/`compareSync` thành công ở trên, và toàn bộ e2e dùng `bcrypt.hash`/`bcrypt.compare` qua `AuthService`/`UsersService`/`prisma/seed.ts` cũng pass). Không sửa gì — ngoài phạm vi I1 (là hành vi máy cục bộ, không phải của package hay của repo).
- **Không cần sửa code**: `npm run build` sạch ngay sau khi cài, không có lỗi type nào phát sinh dù `@types/bcrypt`/`@types/supertest` nâng major — 2 điểm gọi API `bcrypt.hash(...)`/`bcrypt.compare(...)` trong `apps/api/src/auth/auth.service.ts` và `apps/api/src/users/users.service.ts` dùng đúng chữ ký promise-based không đổi giữa 5.x/6.x. `git diff` xác nhận chỉ có `apps/api/package.json` + `apps/api/package-lock.json` thay đổi, không đụng file `src/`.
- **Xác minh migration áp dụng đúng, không tin theo text log CLI** (đúng phát hiện đã ghi nhận từ đợt H2-H7 — `rtk` hook rewrite output CLI đôi khi rút gọn gây hiểu nhầm): `npx prisma migrate deploy` trên container tạm in ra `"2 migration(s) deployed"` — con số này KHÔNG khớp với 28 file migration thật có trong `apps/api/prisma/migrations/`. Đối chiếu trực tiếp bằng SQL (`SELECT count(*) FROM _prisma_migrations` → **28**, `SELECT count(*) FROM information_schema.tables WHERE table_schema='public'` → **47 bảng**) xác nhận migrate deploy áp dụng đúng, đủ 28/28 — text log CLI bị `rtk` rút gọn gây hiểu lầm, không phải migrate thật sự thiếu.
- **`npx prisma db seed` bị hook `rtk` chặn nhầm** (`rtk: Failed to resolve 'prisma' via PATH... [rtk: program not found]`, exit 127) — dùng `rtk proxy npx prisma db seed` theo đúng hướng dẫn trong đề bài, chạy thành công (seed owner `0900000001` + 2 store + cash categories + accounts).
- **Kết quả xác minh**: `npm run build` sạch. `npm run test:unit` — **12 suite/84 test pass**. `npm run test:e2e` (container `postgres:15` tạm tên `tap-hoa-i1-e2e-pg`, cổng host `55432` — xác nhận trống trước khi dùng qua `docker ps` (không trùng cổng dev `54420-54429`/`3040` hay các container khác đang chạy), `TAP_HOA_SKIP_LOCAL_IDENTITY=1` + `DATABASE_URL` trỏ container tạm) — **39/39 suite, 146/146 test pass**, gồm cả `auth.e2e-spec.ts` và `users.e2e-spec.ts` (test login/đổi mật khẩu dùng `bcrypt.compare`/`bcrypt.hash` thật qua HTTP). Đã `docker stop`/`docker rm` container tạm ngay sau khi xong, không đụng container dev/Supabase/prod đang chạy trên máy.
- **Rủi ro thật sự**: không có. Đây là bump major đúng nghĩa "chỉ đổi hạ tầng build/phân phối binary", không đổi API JS, không đổi hành vi hash/compare, không cần sửa code, không phát hiện rủi ro nào vượt phạm vi hợp lý.

## I2 — `firebase-admin` 13→14 (Thấp)

**DoD:**
- [x] `npm install firebase-admin@latest`.
- [x] Kiểm tra `apps/api/src` có nơi nào import API của `firebase-admin` mà 14.x đổi breaking (đọc changelog chính thức) — sửa nếu có.
- [x] `npm run build` + `test:unit` + full `test:e2e` xanh.
- [x] Cập nhật bảng Trạng thái + tick DoD.

### Ghi chú review I2

- **Version thật trước→sau**: `firebase-admin` `^13.10.0` → `^14.2.0` (bản mới nhất hiện có lúc thực hiện, 2026-07-29, xác nhận qua `npm view firebase-admin version`).
- **Nơi dùng thật trong `apps/api/src`** (grep `firebase-admin` toàn bộ `apps/api`, chỉ khớp `package.json`/`package-lock.json`/1 file source): đúng như đề bài mô tả — chỉ `src/devices/devices.service.ts`, dùng `require('firebase-admin')` (dynamic require, không static import, có try/catch bao ngoài) để lấy `admin.apps` / `admin.initializeApp` / `admin.credential.cert` / `admin.messaging()` phục vụ gửi FCM multicast (`sendEachForMulticast`) trong `notifyUser()`. Không có file `*.spec.ts`/`*.e2e-spec.ts` nào mock hay gọi trực tiếp firebase-admin/messaging.
- **Nghiên cứu breaking change 13→14 qua nguồn chính thức** (`gh api`/`gh pr view` trên `firebase/firebase-admin-node`, không đoán): release `v14.0.0` liệt kê breaking changes gồm "Remove Deprecated Legacy Namespace Support" (#3164), "Drop legacy messaging types" (#3157), "Drop support for Node.js 18 and 20" (#3138), "Remove deprecated Instance ID service" (#3166). Đọc trực tiếp nội dung PR #3164: root `firebase-admin` (`src/index.ts`) bị viết lại để **chỉ** export API modular App-related (`initializeApp`, `getApp`, `getApps`, `deleteApp`, `cert`, `applicationDefault`, `refreshToken`, `SDK_VERSION`...) — namespace object cũ (`admin.apps`, `admin.credential.cert`, `admin.messaging()`) bị xoá hoàn toàn, đúng 3 API mà `devices.service.ts` đang dùng. Đọc PR #3157: chỉ bỏ 4 type cũ (`DataMessagePayload`/`MessagingOptions`/`MessagingPayload`/`NotificationMessagePayload`) — không ảnh hưởng vì code tự định nghĩa type `AdminMessaging` riêng, không import type từ package. Đối chiếu lại bằng cách đọc trực tiếp `node_modules/firebase-admin/lib/index.d.ts` + `package.json#exports` sau khi cài — khớp đúng mô tả trong PR: phải `require('firebase-admin/app')` và `require('firebase-admin/messaging')` (2 subpath riêng) mới có `getApps`/`initializeApp`/`cert` và `getMessaging()`; `sendEachForMulticast(message, dryRun?)` và `BatchResponse.successCount` (kiểu trả về) không đổi.
- **Có sửa code, tối thiểu**: `src/devices/devices.service.ts`, method `getMessaging()` — đổi 1 lần `require('firebase-admin')` (namespace API) thành 2 require riêng theo đúng modular entrypoint v14 bắt buộc: `require('firebase-admin/app')` (lấy `getApps`/`initializeApp`/`cert`) và `require('firebase-admin/messaging')` (lấy `getMessaging`). Giữ nguyên 100% cấu trúc defensive try/catch + kiểu dữ liệu tối giản tự định nghĩa như bản gốc, không refactor gì thêm ngoài phần bắt buộc để khớp API mới. Lưu ý: `npm run build` KHÔNG tự phát hiện lỗi này (vì `require()` động, TypeScript chỉ check theo type tự khai báo, không check theo type thật của package) — nên đã tự viết smoke-test runtime thật (không chỉ tin doc): tạo RSA key tạm bằng `openssl genrsa`, gọi thật `cert(fakeServiceAccount)` → `initializeApp({credential})` → `getMessaging()` → xác nhận `getApps().length` tăng đúng từ 0→1 và `messaging.sendEachForMulticast` là function — chạy thành công với code MỚI, xoá file tạm ngay sau đó (`_smoke_test_tmp.js`, `_smoke_test_key_tmp.pem`, không lọt vào git).
- **Rủi ro phát hiện thêm, báo cáo lại thay vì tự bỏ qua**: `firebase-admin@14.x` đổi `engines.node` từ `>=18` (bản 13.x) sang `>=22` — đây là thay đổi CHỦ ĐÍCH, xác nhận qua đúng dòng trong release note "Drop support for Node.js 18 and 20 (v14)" (#3138), không phải suy đoán. `apps/api/Dockerfile` (cả build stage lẫn runtime stage) đang dùng `node:20-alpine` — THẤP hơn yêu cầu mới này. Repo không có `.npmrc` với `engine-strict=true`, nên `npm ci`/`npm install` trên Node 20 trong Docker build chỉ in cảnh báo EBADENGINE chứ không fail — build Docker hiện tại không bị chặn ngay. Vì FCM chưa cấu hình thật ở bất kỳ đâu (kể cả biến môi trường trong Dockerfile/compose), `require('firebase-admin/...')` không được gọi thật lúc runtime hiện tại nên không có tác động ngay lập tức. Nhưng đây là rủi ro tiềm ẩn có thật: nếu sau này ai đó cấu hình `FIREBASE_SERVICE_ACCOUNT` thật trên image `node:20-alpine` hiện tại, hành vi của `firebase-admin@14.x` trên Node 20 không được đội firebase-admin hỗ trợ/kiểm thử chính thức (nhiều khả năng vẫn chạy được vì Node 20/22 phần lớn tương thích, nhưng không có cam kết upstream). Phát hiện này CHƯA từng được liệt kê trong bảng Tech Stack/rủi ro ở đầu file — nằm ngoài phạm vi sửa của I2 (không đụng Dockerfile), cần cân nhắc bump base image Node lên >=22 ở một task riêng (có thể tự nhiên trùng với yêu cầu Node của I6/I7/I8) trước khi thật sự bật FCM trong production.
- **Side-issue phát hiện khi chạy e2e, KHÔNG thuộc phạm vi I2 (test flakiness phụ thuộc thứ tự chạy, không liên quan firebase-admin)**: `test/vat-summary.e2e-spec.ts` (dòng ~51-61) dọn dữ liệu store trước mỗi test bằng cách xoá `purchaseReceipt`/`saleLine`/`sale` nhưng THIẾU bước xoá `saleReturn` trước — nếu một suite khác đã chạy trước đó và để lại `SaleReturn` tham chiếu tới `Sale` cùng store `CH1` (nhiều suite khác có tạo sale-return, chưa dò ra suite cụ thể vì ngoài phạm vi), `prisma.sale.deleteMany()` sẽ throw `Foreign key constraint violated: SaleReturn_originalSaleId_fkey`. Gặp lỗi này ở lần chạy `test:e2e` đầu tiên (Jest default sequencer xếp `vat-summary` chạy thứ 23/39 do dùng cache thời gian chạy trước đó — không cố định thứ tự giữa các lần chạy). Đã XÁC MINH RÕ ĐÂY LÀ LỖI TIỀN TỒN TẠI, không liên quan tới bump `firebase-admin`: dừng lại, `git stash` code I2, `npm install` để phục hồi hẳn `firebase-admin@13.10.0` (baseline gốc), rebuild, reset DB sạch (drop/create lại database), chạy lại `test:e2e` — lần này `vat-summary` chạy thứ 1/39 (thứ tự đổi do cache Jest, không phải do code) → **PASS**, toàn bộ 39/39 suite 146/146 test xanh trên baseline cũ. Sau đó `git stash pop` phục hồi code I2, `npm install` lại để có `firebase-admin@14.2.0`, rebuild, reset DB sạch, chạy `test:e2e` lần cuối trên đúng code I2 thật → `vat-summary` lại chạy thứ 1/39 → **PASS**, 39/39 suite, 146/146 test xanh. Kết luận: lỗi phụ thuộc hoàn toàn vào THỨ TỰ chạy file test (dữ liệu `SaleReturn` sót từ suite chạy trước), hoàn toàn không liên quan `firebase-admin` — code `require('firebase-admin/...')` chưa từng được gọi thật trong suốt tất cả các lần chạy (`FIREBASE_SERVICE_ACCOUNT` luôn không set trong môi trường test). Không sửa `vat-summary.e2e-spec.ts` (ngoài phạm vi I2) — ghi nhận lại để I3-I8 (cũng chạy full e2e nhiều lần) không nhầm tưởng đây là regression do dependency bump của mình nếu gặp lại; gợi ý cho một task dọn dẹp test riêng sau này: thêm `await prisma.saleReturn.deleteMany({ where: { sale: { storeId } } })` trước dòng xoá `sale` trong file này.
- **Kết quả xác minh cuối cùng** (trên đúng code I2, sau khi đã hiểu rõ nguyên nhân flake ở trên): `npm run build` sạch (2 lần, trước và sau vòng đối chiếu baseline). `npm run test:unit` — **12 suite/84 test pass** (2 lần). `npm run test:e2e` (container `postgres:15` tạm tên `tap-hoa-i2-e2e-pg`, cổng host `55433` — xác nhận trống trước khi dùng qua `Get-NetTCPConnection` + `docker ps`, không trùng cổng dev/Supabase/prod đang chạy trên máy) — kết quả cuối **39/39 suite, 146/146 test pass**. Xác minh migrate deploy đúng bằng SQL trực tiếp (không tin số dòng log CLI bị `rtk` rút gọn, đúng pattern đã rút ra từ I1): `SELECT count(*) FROM _prisma_migrations` → **28**, khớp đúng 28 file migration trên đĩa; `information_schema.tables` → **47 bảng**. `npx prisma db seed` bị hook `rtk` chặn nhầm y như I1 đã ghi nhận (`rtk: program not found`, exit 127) — dùng `rtk proxy npx prisma db seed` chạy thành công. Đã `docker stop`/`docker rm` container tạm ngay sau khi xong; xác nhận các container khác (`tap-hoa-prod-api`, `tap-hoa-prod-db`, `supabase_*_omni-commerce`) không bị đụng tới.
- **`npm audit --omit=dev` sau khi nâng**: 24 lỗ hổng (12 moderate/12 high), giảm so với baseline đầu file (27: 14 moderate/12 high/1 critical) — hết critical. Phần còn lại đi qua `firebase-admin` → `@google-cloud/storage` → `teeny-request` → `uuid` (moderate, GHSA-w5hq-g745-h8pq) vẫn tồn tại ở `firebase-admin@14.2.0` (bản mới nhất hiện có) — đúng như đã loại trừ ở đầu file ("Không thuộc phạm vi... phần dư nếu còn tồn tại là do lỗ hổng upstream chưa có bản vá, ghi nhận lại chứ không tự chế fix riêng"), không có bản vá lẻ nào khác để làm thêm trong I2.

## I3 — `jest`/`@types/jest` 29→30 (Thấp-Trung bình)

**DoD:**
- [x] `npm install jest@latest @types/jest@latest ts-jest@latest` (nếu `ts-jest` cũng cần khớp version) — kiểm tra `jest-unit.json`/`test/jest-e2e.json` config còn tương thích cú pháp Jest 30 (một số option đổi tên/bỏ giữa 29→30).
- [x] `npm run build` + `test:unit` + full `test:e2e` xanh — đây chính là công cụ dùng để verify các task khác, nên phải đặc biệt chắc chắn nó tự chạy đúng trước.
- [x] Cập nhật bảng Trạng thái + tick DoD.

### Ghi chú review I3

- **Version thật trước→sau**: `jest` `^29.7.0`→`^30.4.2`, `@types/jest` `^29.5.14`→`^30.0.0`. `ts-jest` **giữ nguyên** `^29.2.5` trong `package.json` — xác nhận qua `npm view ts-jest dist-tags`: package này chưa từng phát hành major 30.x, bản `latest` hiện tại vẫn là `29.4.12` nhưng đã tự thêm peerDependency `"jest": "^29.0.0 || ^30.0.0"` từ trong dòng 29.x, và bản đang cài (`npm ls ts-jest` xác nhận `29.4.12`) đã resolve đúng theo range `^29.2.5` hiện có, không cần đổi gì trong `package.json`. `npm install` không báo `ERESOLVE`/peer conflict nào.
- **Nghiên cứu breaking change 29→30 qua nguồn chính thức** (`gh api repos/jestjs/jest/releases/tags/v30.0.0` + WebFetch migration guide `jestjs.io/docs/upgrading-to-jest30`, không đoán): breaking change thật gồm — đổi CLI flag `--testPathPattern`→`--testPathPatterns`, xoá lệnh `jest --init`, đổi default `moduleFileExtensions`/`testMatch`/`testRegex` (thêm `mjs`/`cjs`/`mts`/`cts`), xoá hẳn 10 alias matcher (`toBeCalled`, `toBeCalledWith`, `toThrowError`...), đổi format snapshot (`Error.cause`, `ArrayBuffer`/`DataView`, non-enumerable properties bị loại khỏi object matching), Node tối thiểu `^18.14.0 || ^20.0.0 || ^22.0.0 || >=24.0.0` (bỏ Node 14/16/19/21/23), TypeScript tối thiểu 5.4. Đối chiếu với dự án: `apps/api/jest-unit.json` và `apps/api/test/jest-e2e.json` chỉ dùng `moduleFileExtensions`/`rootDir`/`testEnvironment`/`testRegex`/`transform`/`setupFiles` — không option nào trong số này bị đổi tên/bỏ, và vì `moduleFileExtensions`/`testRegex` được khai báo tường minh (không dùng default) nên thay đổi default value không ảnh hưởng. Đã grep toàn bộ `apps/api` xác nhận **không dùng** alias matcher nào bị xoá, không dùng `testPathPattern`/`--init`/`SpyInstance`/`MockFunctionMetadata`/`genMockFromModule`, không có file `.snap` nào (`toMatchSnapshot`/`toMatchInlineSnapshot` không xuất hiện) nên thay đổi snapshot format không có gì để vỡ. Node: máy dev `v24.18.0` (khớp `>=24.0.0`), `node:20-alpine` trong `Dockerfile` (khớp `^20.0.0`, range này chấp nhận mọi patch/minor 20.x nên không cần xác nhận patch version cụ thể). TypeScript hiện tại `^5.7.2` > 5.4, không cần đổi.
- **Không cần sửa config lẫn code**: `git diff` xác nhận chỉ `apps/api/package.json` + `apps/api/package-lock.json` thay đổi — 2 file jest config và toàn bộ `src/`/`test/` giữ nguyên 100%, không option nào phải đổi tên, không test nào phải sửa cú pháp.
- **Phát hiện phụ đáng ghi nhận (không phải rủi ro, là cải thiện)**: đối chiếu `npm audit` (đầy đủ, gồm devDependencies) trước/sau bằng cách tạm `git checkout` về `jest@29.7.0` + `npm ci` + `npm audit`, rồi khôi phục lại `jest@30.4.2` + `npm ci` + `npm audit`, diff chính xác danh sách gói bị flag: **55→54 lỗ hổng (34 high→33 high, moderate/low không đổi)**, chênh lệch duy nhất là gói `create-jest` (phụ thuộc của lệnh `jest --init`) biến mất hoàn toàn khỏi cây phụ thuộc — đúng như dự đoán từ release note ("Remove deprecated `--init` argument"), Jest 30 không còn kéo `create-jest` về nữa nên tự động dọn theo 1 lỗ hổng high. Không có lỗ hổng mới nào phát sinh từ bump này (verify bằng `comm -13` giữa 2 danh sách gói đã sort — rỗng). `npm audit --omit=dev` không đổi (vẫn 24: 12 moderate/12 high, giống số cuối I2) vì `jest` chỉ là devDependency, không nằm trong cây production.
- **Rủi ro đã kiểm tra kỹ và loại trừ, không phải của I3**: audit đầy đủ vẫn còn hiển thị advisory `GHSA-mh99-v99m-4gvg` ("brace-expansion: DoS via unbounded expansion length") ở CẢ baseline lẫn sau khi nâng — tra `gh api advisories/GHSA-mh99-v99m-4gvg` xác nhận bản vá đầu tiên là `5.0.8`, nhưng **toàn bộ** cây phụ thuộc hiện tại (kể cả `@nestjs/cli`→`glob@10.4.5`, `exceljs`→`archiver`→`glob@7.2.3`, và `jest`→`glob@10.5.0` — cả 3 nguồn độc lập) đều kéo theo `minimatch`/`brace-expansion` phiên bản thấp hơn nhiều so với `5.0.8` vì chưa có gói nào trong hệ sinh thái (kể cả bản `glob@10.5.0` mới nhất mà Jest 30 tự dùng) publish bản phụ thuộc `brace-expansion@^5` — không có bản vá lẻ khả thi, giống hệt tình huống `firebase-admin`→`uuid` đã ghi nhận ở I2, ngoài phạm vi sửa của I3 (đổi được thì phải đổi cả `@nestjs/cli` lẫn `exceljs`, không riêng jest). Tương tự advisory `GHSA-5j98-mcp5-4vw2` (glob CLI command injection, range `>=10.2.0 <10.5.0`): bản `glob@10.5.0` mà Jest 30 dùng nằm NGOÀI range này (đã vá), advisory này chỉ còn xuất hiện trong audit vì `@nestjs/cli` kéo riêng `glob@10.4.5` (nằm trong range, dính lỗi) — không liên quan jest, thuộc phạm vi I7 (nâng `@nestjs/cli`) nếu muốn giải quyết.
- **Sự cố phát sinh trong quá trình xác minh audit, đã tự phát hiện và khắc phục, không lọt vào commit**: khi tạm `git checkout`/`npm ci` qua lại để so sánh audit trước/sau, `npm ci` làm mất Prisma Client đã generate (do `@prisma/client` có `postinstall` script bị chặn bởi cơ chế `allow-scripts` của máy — không phải config repo, giống quan sát đã ghi nhận ở I1) → `npm run build` báo hơn 200 lỗi type (`Module '"@prisma/client"' has no exported member 'Role'`...) — đã xác minh ngay đây KHÔNG PHẢI do Jest 30 mà do thiếu bước `npx prisma generate` sau `npm ci`; chạy lại `npx prisma generate` xong build sạch lại ngay, unit test lại xanh 12/84. Không có gì trong sự cố này lọt vào git diff (chỉ ảnh hưởng `node_modules` cục bộ).
- **Kết quả xác minh cuối cùng**: `npm run build` sạch. `npm run test:unit` — **12 suite/84 test pass**. `npm run test:e2e` chạy **3 lần độc lập** trên 2 container `postgres:15` tạm (`tap-hoa-i3-e2e-pg` rồi `tap-hoa-i3-e2e-pg-final`, cùng cổng host `55434` — xác nhận trống qua `docker ps`/`Get-NetTCPConnection` trước khi dùng, không trùng cổng dev/Supabase/prod đang chạy), `TAP_HOA_SKIP_LOCAL_IDENTITY=1` + `DATABASE_URL` trỏ container tạm, DB reset sạch (drop/create hoặc container mới) giữa mỗi lần — cả 3 lần đều **39/39 suite, 146/146 test pass**, không lần nào gặp lại flaky `vat-summary.e2e-spec.ts` đã ghi nhận ở I2 (nên không cần áp dụng nhánh xử lý flaky trong đề bài). Xác minh migrate deploy đúng bằng SQL trực tiếp mỗi lần (không tin số dòng log CLI bị `rtk` rút gọn thành "2 migration(s) deployed"): `SELECT count(*) FROM _prisma_migrations` → **28**, khớp đúng 28 file trên đĩa. `npx prisma db seed` bị `rtk` chặn nhầm y hệt I1/I2 (`rtk: program not found`, exit 127) — dùng `rtk proxy npx prisma db seed` chạy thành công cả 2 lần seed thật. Đã `docker stop`/`docker rm` cả 2 container tạm ngay sau khi xong; xác nhận `docker ps -a` cuối cùng chỉ còn đúng các container prod/Supabase đã chạy từ trước, không đụng gì tới chúng.
- **Rủi ro thật sự**: không có. Bump major `jest` 29→30 không đụng tới bất kỳ option nào dự án đang dùng trong 2 file jest config, không cần sửa test nào, và còn tự dọn thêm 1 lỗ hổng high-severity (`create-jest`) nhờ Jest 30 bỏ lệnh `--init`. Công cụ test (`npm run test:unit`/`npm run test:e2e`) đã xác nhận chạy đúng, ổn định qua 3 lần e2e liên tiếp — đủ tin cậy làm công cụ verify cho I4-I8 tiếp theo.

## I4 — `class-validator` 0.14→0.15 (Trung bình)

**DoD:**
- [ ] `npm install class-validator@latest`.
- [ ] Đọc breaking-change note 0.15 — dự án dùng validator ở đâu (DTO nào có decorator thật, phân biệt với các DTO kiểu `type` thuần không dùng class-validator như đã thấy ở nhiều chỗ trong `apps/api/src/sync/dto`).
- [ ] `npm run build` + `test:unit` + full `test:e2e` xanh — chú ý các test liên quan validate input (400 Bad Request cases).
- [ ] Cập nhật bảng Trạng thái + tick DoD.

## I5 — `@types/express` 4→5 (Trung bình)

**DoD:**
- [ ] Xác nhận trước: `express` runtime thật có được cài trực tiếp trong `package.json` hay chỉ đến qua `@nestjs/platform-express` (NestJS 10 bundle Express 4 nội bộ) — nếu chỉ nâng `@types/express` lên 5 mà runtime vẫn là Express 4 thật, có thể type không khớp runtime, cần cân nhắc hoãn tới sau khi NestJS 11 (I7, tự mang theo Express tương thích) thay vì làm riêng lẻ trước.
- [ ] Nếu xác nhận an toàn: `npm install @types/express@latest`, sửa lỗi type nếu build đỏ.
- [ ] Nếu xác nhận rủi ro (type/runtime lệch pha) cao hơn lợi ích trước khi I7 xong: dừng, ghi rõ lý do, để version cũ, coi là kết luận hợp lệ — làm lại sau I7 nếu còn cần.
- [ ] `npm run build` + `test:unit` + full `test:e2e` xanh (nếu tiến hành nâng cấp).
- [ ] Cập nhật bảng Trạng thái + tick DoD.

## I6 — `typescript`/`@types/node` (Cao)

**DoD:**
- [ ] Xác nhận version TypeScript mới nhất **tương thích với @nestjs/core@11** (I7 sắp làm ngay sau) trước khi chọn target — đọc `npm view @nestjs/core@11 peerDependencies`/`devDependencies` liên quan `typescript`, đừng nâng TS lên bản NestJS 11 chưa hỗ trợ.
- [ ] `npm install typescript@<bản đã xác nhận tương thích> @types/node@<bản khớp Node runtime thật đang dùng — kiểm tra `node -v` cả trên máy dev lẫn base image `node:20-alpine` trong Dockerfile, đừng nâng @types/node vượt quá version Node thật>`.
- [ ] `npm run build` — TypeScript major bump thường lộ ra lỗi type mới bị chặt hơn; sửa tối thiểu để build sạch, không refactor thêm.
- [ ] `npm run test:unit` + full `test:e2e` xanh.
- [ ] Cập nhật bảng Trạng thái + tick DoD.

## I7 — `@nestjs/*` 10→11 (Cao)

**DoD:**
- [ ] Đọc migration guide chính thức NestJS 10→11 (breaking changes: Express version bump nội bộ, thay đổi decorator/DI nếu có, thay đổi `@nestjs/testing` API nếu có).
- [ ] `npm install @nestjs/common@11 @nestjs/core@11 @nestjs/platform-express@11 @nestjs/jwt@11 @nestjs/testing@11 @nestjs/cli@11` (đồng bộ tất cả cùng lúc theo đúng peer dependency, không nâng lẻ tẻ).
- [ ] Sửa mọi lỗi build phát sinh (breaking API) — tối thiểu, không refactor thêm ngoài phạm vi bắt buộc để build xanh.
- [ ] `npm run build` + `test:unit` + full `test:e2e` xanh — đây là thay đổi core framework, rủi ro regression cao nhất đợt này, chạy full e2e nhiều lần trên DB sạch khác nhau như các task H trước.
- [ ] Cập nhật bảng Trạng thái + tick DoD.

## I8 — `@prisma/client`/`prisma` 6→7 (Cao)

**DoD:**
- [ ] Đọc migration guide chính thức Prisma 6→7 (breaking changes: schema syntax, client API, generator config).
- [ ] Xác nhận patch version thật của `node:20-alpine` trong `apps/api/Dockerfile` đủ `>=20.19` (yêu cầu engine Prisma 7) — nếu base image pin ở patch cũ hơn, cần bump tag trước.
- [ ] `npm install prisma@latest @prisma/client@latest`, chạy `npx prisma generate` lại, sửa lỗi phát sinh (tối thiểu).
- [ ] `npm run build` + `test:unit` + full `test:e2e` xanh (bao gồm chạy `npx prisma migrate deploy` thật trên container Postgres tạm — xác nhận toàn bộ 28 migration cũ vẫn áp dụng đúng dưới Prisma 7).
- [ ] Cập nhật bảng Trạng thái + tick DoD.

---

## Cách chạy (SDD)

| Bước | Cách |
|------|------|
| Mỗi task | **1 subagent** — implement + test, không đụng file ngoài scope |
| Review | Orchestrator đọc diff + tự chạy lại build/test/e2e độc lập trước khi tick DoD |
| Commit | 1 commit/task, message tiếng Việt mô tả rõ, cập nhật bảng Trạng thái + tick DoD trong cùng commit |
| Thứ tự | I1 → I2 → I3 → I4 → I5 → I6 → I7 → I8 (rủi ro thấp trước, cao sau) |
