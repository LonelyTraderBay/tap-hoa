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
| **I2** | `firebase-admin` 13→14 | Thấp | Chưa |
| **I3** | `jest` + `@types/jest` 29→30 | Thấp-Trung bình | Chưa |
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
- [ ] `npm install firebase-admin@latest`.
- [ ] Kiểm tra `apps/api/src` có nơi nào import API của `firebase-admin` mà 14.x đổi breaking (đọc changelog chính thức) — sửa nếu có.
- [ ] `npm run build` + `test:unit` + full `test:e2e` xanh.
- [ ] Cập nhật bảng Trạng thái + tick DoD.

## I3 — `jest`/`@types/jest` 29→30 (Thấp-Trung bình)

**DoD:**
- [ ] `npm install jest@latest @types/jest@latest ts-jest@latest` (nếu `ts-jest` cũng cần khớp version) — kiểm tra `jest-unit.json`/`test/jest-e2e.json` config còn tương thích cú pháp Jest 30 (một số option đổi tên/bỏ giữa 29→30).
- [ ] `npm run build` + `test:unit` + full `test:e2e` xanh — đây chính là công cụ dùng để verify các task khác, nên phải đặc biệt chắc chắn nó tự chạy đúng trước.
- [ ] Cập nhật bảng Trạng thái + tick DoD.

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
