# Hoàn thiện go-live — Kế hoạch theo thứ tự ưu tiên

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement **một wave tại một thời điểm**. Steps dùng checkbox (`- [ ]`).
> Wave có feature code lớn (Wastage journal, Audit UI, …) → tách plan riêng trước khi code; wave này là **master index + chi tiết Wave 0–1**.

**Goal:** Đưa tap-hoa từ trạng thái “Phase 1–3 feature Done + hardening PASS trên nhánh” sang **sẵn sàng mở quán thật** (API prod, POS ký release, HĐĐT/gateway nếu cần, sổ không lỗ chứng từ vận hành chính).

**Architecture:** Không thêm epic feature lớn trong Wave 0–1. Ưu tiên: (1) đóng PR hardening vào `main`, (2) secrets + host + backup, (3) cấu hình HĐĐT/FCM/signing theo nhu cầu cửa hàng, (4) vá lỗ sổ đã deferred (xuất hủy / chuyển kho), (5) polish UX kế toán sau go-live.

**Tech Stack:** NestJS 10 + Prisma + PostgreSQL (`apps/api`); Flutter 3 + Drift (`apps/pos_app`); HĐĐT qua `EINVOICE_PROVIDER=http`; optional FCM.

**Trạng thái (cập nhật 2026-07-25):**

| Hạng mục | Trạng thái |
|----------|------------|
| Phase 1–3 + hardening PR #17 | **Done** trên `main` |
| Wave 0–1 (merge + ops in-repo) | **Done** on `main` @ `c718984` (synced `origin/main`) |
| Deploy VPS / secrets / backup thật | Chưa (operator) |
| Wave 2–5 | Chưa |
| **Kế hoạch còn lại** | `docs/superpowers/plans/2026-07-25-hoan-thien-con-lai.md` |
| Nộp CQT / SDK Viettel–MISA riêng | Ngoài scope (giữ YAGNI) |

## Global Constraints

- Không mở scope nộp CQT tự động; không viết SDK vendor HĐĐT riêng nếu HTTP gateway đủ.
- Không `npm audit fix --force` (phá exceljs) — chỉ theo dõi upstream.
- Mọi thay đổi sổ phải có e2e; Flutter UI plan phải `flutter analyze` sạch trên path đụng.
- Seed `0900000001` / `123456` **chỉ** cho dev/test — cấm dùng trên prod.
- `JWT_SECRET` prod phải random ≥ 32 bytes; `NODE_ENV=production`.
- Migrate prod chỉ `npx prisma migrate deploy` (không `migrate dev`).

---

## Bản đồ file / khu vực (theo wave)

| Wave | Khu vực chính | Files / docs neo |
|------|---------------|------------------|
| 0 | Merge + verify gate trên `main` | PR #17, `docs/superpowers/plans/2026-07-25-phase3-hardening.md` |
| 1 | Prod env, host, backup, HĐĐT, signing | `apps/api/.env.example`, `apps/api/src/auth/jwt.config.ts`, `apps/pos_app/android/app/build.gradle.kts`, README runbook |
| 2 | Smoke vận hành + FCM + PDF Unicode | `apps/pos_app/lib/firebase_options.dart`, `apps/api/src/reports/reports.service.ts` |
| 3 | Lỗ sổ deferred | `apps/api/src/ledger/*`, `apps/api/src/sync/stock-ops.service.ts` |
| 4 | Audit / mở khóa kỳ | `ledger.service.ts`, Flutter sổ, `AuditLog` |
| 5 | Polish design còn lại | cart line discount, share ảnh HĐ, cancel HĐĐT, PO NCC — **plan riêng từng mục** |

---

## Thứ tự ưu tiên (tóm tắt)

```text
Wave 0  Merge hardening → main          [P0 — chặn mọi thứ khác]
Wave 1  Go-live infra + secrets         [P0]
Wave 2  Smoke 2 máy + FCM/PDF           [P1]
Wave 3  Journal xuất hủy (+ optional CK)[P1 kế toán]
Wave 4  Period unlock + audit UI        [P1–P2]
Wave 5  Polish / Phase 4 nhẹ            [P2 — sau ổn định quán]
```

---

## Wave 0 — Merge closeout vào `main` (P0)

**DoD:** `main` chứa hardening; CI/local gate A0 xanh trên `main`; PR #17 merged hoặc tương đương.

### Task 0.1: Review + merge PR #17

**Files:**
- Review: `docs/superpowers/plans/2026-07-25-phase3-hardening.md`
- Branch: `hardening/phase3-closeout` → `main`

- [ ] **Step 1: Xác nhận diff so với `main`**

```powershell
cd c:\Users\C-PC\Documents\Projects\tap-hoa
git fetch origin
git log origin/main..origin/hardening/phase3-closeout --oneline
```

Expected: các commit hardening (`a24d0e7` … `40eeae7` hoặc tương đương).

- [ ] **Step 2: Chạy lại gate A0 trên nhánh hardening**

```powershell
cd apps\api
npx prisma migrate deploy
npm run build
npm run test:e2e
npx jest --config ./jest-unit.json --runInBand
cd ..\pos_app
flutter analyze
flutter test
```

Expected: e2e **26 suites / 77 tests**; unit journal-builders xanh; Flutter analyze sạch; flutter test ~95 PASS.

- [ ] **Step 3: Merge PR #17**

```powershell
gh pr merge 17 --merge
git checkout main
git pull origin main
```

Expected: `main` chứa migrate `20260725160000_phase3_hardening` (+ follow-ups tax snapshot nếu có).

- [ ] **Step 4: Commit docs nếu cần tick “merged to main”**

Cập nhật dòng trạng thái trong `2026-07-25-phase3-roadmap.md` / hardening plan nếu vẫn ghi “on branch only”. Commit message: `docs: note Phase 3 hardening merged to main`.

---

## Wave 1 — Go-live production (P0)

**DoD:** API chạy production với secret thật; Postgres có backup; POS Windows/Android dùng được với `API_URL` prod; HĐĐT cấu hình nếu cửa hàng cần xuất HĐ ngày 1.

### Task 1.1: Secrets & tài khoản prod

**Files:**
- Modify ops (không commit secret): host env / secret manager
- Reference: `apps/api/.env.example`, `apps/api/src/auth/jwt.config.ts`

- [ ] **Step 1: Sinh JWT secret**

```powershell
# PowerShell
[Convert]::ToBase64String((1..48 | ForEach-Object { Get-Random -Maximum 256 }) -as [byte[]])
```

Đặt `JWT_SECRET=<giá trị>` trên host; **không** commit vào git.

- [ ] **Step 2: Tạo user owner thật (không dùng seed)**

Sau migrate trên DB prod: tạo user qua seed tạm hoặc SQL/Prisma script một lần, rồi **xóa/đổi** mật khẩu seed nếu seed từng chạy. Đảm bảo không còn `123456` trên prod.

- [ ] **Step 3: Checklist env prod tối thiểu**

```env
NODE_ENV=production
DATABASE_URL=postgresql://...
JWT_SECRET=<random>
PORT=3000
# Nếu xuất HĐĐT thật ngày 1:
EINVOICE_PROVIDER=http
EINVOICE_HTTP_URL=https://...
EINVOICE_HTTP_API_KEY=...
EINVOICE_HTTP_TIMEOUT_MS=15000
# Optional FCM:
# FIREBASE_SERVICE_ACCOUNT=/absolute/path/sa.json
```

Verify: `GET /health` → `{ "ok": true }`; login owner thật thành công; login seed fail hoặc đã bị disable.

### Task 1.2: Host API + migrate + backup Postgres

**Files:**
- Create (khuyến nghị): `apps/api/Dockerfile` + (optional) `docker-compose.prod.yml` **hoặc** runbook VPS thuần Node
- Modify: `README.md` section “Phase 3 runbook” → bổ sung prod

- [ ] **Step 1: Chọn host** (một trong: VPS Node + systemd, Docker trên VPS, PaaS). Chưa có Dockerfile trong repo — nếu chọn Docker, thêm file tối giản:

```dockerfile
# apps/api/Dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npx prisma generate && npm run build

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package*.json ./
COPY --from=build /app/prisma ./prisma
EXPOSE 3000
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/main.js"]
```

- [ ] **Step 2: Deploy lần đầu**

```powershell
# trên máy CI/local đã trỏ DATABASE_URL prod
cd apps\api
npx prisma migrate deploy
npm run build
# start theo host (node dist/main.js | docker | pm2)
```

- [ ] **Step 3: Backup tự động**

Thiết lập cron/Task Scheduler **hàng ngày** trước giờ mở quán:

```bash
pg_dump "$DATABASE_URL" -Fc -f "backup-$(date +%Y%m%d).dump"
```

Giữ ≥ 7 bản; thử restore 1 lần trên DB staging. Ghi path backup vào runbook nội bộ (không bắt buộc commit).

- [ ] **Step 4: Rollback drill (15 phút)**

1. Snapshot DB trước migrate.
2. Giả lập lỗi → restore snapshot.
3. Xác nhận app version pin về commit pre-hardening nếu cần.
Không dùng `migrate resolve` tùy tiện trên prod (đã ghi trong README).

### Task 1.3: Cấu hình HĐĐT HTTP (chỉ nếu cần HĐ hợp lệ ngày 1)

**Files:**
- Spec: `docs/superpowers/specs/2026-07-25-phase3-einvoice-http-design.md`
- Code: `apps/api/src/einvoice/*`

- [ ] **Step 1: Trỏ gateway** — set env như Task 1.1; restart API.
- [ ] **Step 2: Xuất 1 HĐ thử** từ đơn đã sync (Flutter **Xuất HĐĐT**); xác nhận provider trả status trong allowlist; lần 2 cùng sale → idempotent (không double-issue).
- [ ] **Step 3: Nếu chưa có gateway** — giữ `EINVOICE_PROVIDER=stub` và **không** xuất HĐ cho khách/CQT; đánh dấu cửa hàng “chưa HĐĐT thật”.

### Task 1.4: Android release signing (nếu dùng tablet/ĐT)

**Files:**
- Modify: `apps/pos_app/android/app/build.gradle.kts` (bỏ `signingConfig = debug` trên release)
- Create local (không commit keystore): `key.properties` + `.gitignore` đã ignore

- [ ] **Step 1: Tạo keystore**

```powershell
keytool -genkey -v -keystore tap-hoa-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias taphoa
```

- [ ] **Step 2: Wire signing** theo Flutter docs (`key.properties` → `signingConfigs.release`).
- [ ] **Step 3: Build**

```powershell
cd apps\pos_app
flutter build apk --release --dart-define=API_URL=https://api.example.com
# hoặc appbundle
```

Expected: APK/AAB ký release; cài máy thật login được.

### Task 1.5: POS Windows prod pointer

- [ ] Build/run Windows với `--dart-define=API_URL=https://…`
- [ ] Smoke: login → chọn CH → mở ca → bán 1 đơn TM → đồng bộ → báo cáo ngày thấy doanh thu.

---

## Wave 2 — Vận hành ổn định ngày 1–3 (P1)

**DoD:** Hai thiết bị offline→online không lệch ca/đơn; FCM optional hoạt động hoặc documented skip; PDF kỳ hiện đúng tiếng Việt trên host prod.

### Task 2.1: Smoke multi-device (bắt buộc)

Checklist thủ công (ghi kết quả vào note nội bộ hoặc comment PR):

- [ ] Máy A offline: mở ca → bán nợ + bán TM → bật mạng → **Đồng bộ** (outbox `shift_open` trước `sale`).
- [ ] Máy B pull: tồn giảm đúng; báo cáo ngày khớp.
- [ ] Đóng ca A: expected cash vs đếm thực tế; lệch có ghi chú vẫn đóng được.
- [ ] Owner: sổ kỳ / VAT (nếu bật) / Excel hoặc PDF export thử 1 lần.

### Task 2.2: FCM (optional)

**Files:**
- `apps/pos_app/lib/firebase_options.dart` (hiện placeholder `REPLACE_ME`)
- API: `FIREBASE_SERVICE_ACCOUNT`

- [ ] `flutterfire configure` → ghi đè options thật.
- [ ] Đặt SA JSON trên API; gửi thử low-stock alert.
- [ ] Nếu skip: ghi rõ “FCM off” trong runbook quán — app vẫn chạy.

### Task 2.3: Font Unicode PDF kỳ trên API

**Files:**
- Modify: `apps/api/src/reports/reports.service.ts` (~621–628)
- Optional asset: `apps/api/assets/fonts/NotoSans-Regular.ttf` (embed trong image/deploy)

- [ ] **Step 1:** Bundle TTF có dấu Việt vào repo hoặc image (không phụ thuộc `C:\Windows\Fonts\arial.ttf`).
- [ ] **Step 2:** `doc.font(path.join(__dirname, '../../assets/fonts/NotoSans-Regular.ttf'))` với fallback Helvetica chỉ khi thiếu file.
- [ ] **Step 3:** e2e hoặc smoke `GET /reports/period/export.pdf` — mở PDF thấy “Báo cáo kỳ” không lỗi font.
- [ ] Commit: `fix: embed Unicode font for period PDF export`.

---

## Wave 3 — Vá lỗ sổ kế toán deferred (P1)

> **Trước khi code:** viết plan chi tiết riêng `docs/superpowers/plans/YYYY-MM-DD-wastage-transfer-journals.md` (TDD e2e). Dưới đây chỉ khóa scope + thứ tự.

**DoD:** Xuất hủy/hao hụt sinh journal đúng CoA; (optional) chuyển kho không làm lệch tồn kế toán; e2e mới PASS; period lock vẫn chặn post.

### Task 3.1: Journal xuất hủy / wastage (bắt buộc trước Task 3.2)

**Hooks hiện có để bắt chước:**
- `LedgerService.postFromStocktake` — `apps/api/src/ledger/ledger.service.ts`
- Sync hook stocktake trong `apps/api/src/sync/stock-ops.service.ts`

- [ ] Spec nhanh: Dr giá vốn / Cr tồn (hoặc theo CoA hiện dùng cho stocktake giảm) khi wastage sync thành công; fail-soft như stocktake; tôn trọng period lock.
- [ ] Unit: builder + e2e `wastage-journal.e2e-spec.ts`.
- [ ] Hook sau persist wastage trong `stock-ops.service.ts`.

### Task 3.2: Journal chuyển kho (optional nếu hay chuyển điểm)

- [ ] Hai store: giảm tồn nguồn + tăng đích; journal/transfer accounts theo quyết định kế toán (ghi rõ trong plan con — tránh double COGS).
- [ ] e2e multi-store.

### Task 3.3: Cập nhật deferred list

- [ ] Sửa `docs/superpowers/plans/2026-07-25-phase2-hardening.md` mục Deferred — tick wastage/transfer khi xong.
- [ ] CHANGELOG Unreleased.

---

## Wave 4 — Period unlock + audit UI (P1–P2)

> Plan con riêng trước khi implement.

**DoD:** Owner mở khóa kỳ có `AuditLog`; Flutter xem được nhật ký khóa/mở; manager/cashier không mở khóa.

### Task 4.1: API unlock

- [ ] `POST /ledger/period-locks/:periodYm/unlock` (hoặc DELETE có body lý do) — chỉ `owner`.
- [ ] Ghi `AuditLog` (đã có model trong Prisma).
- [ ] e2e: lock → post bị chặn → unlock → post lại được.

### Task 4.2: Flutter audit / unlock

- [ ] Màn hoặc section trên **Sổ kế toán**: danh sách lock + nút mở khóa + list audit gần đây.
- [ ] `flutter analyze` sạch.

---

## Wave 5 — Polish sau ổn định quán (P2)

Làm **từng mục một plan**; không nhồi chung sprint go-live.

| # | Mục | Nguồn design | Ghi chú |
|---|-----|--------------|---------|
| 5.1 | Giảm giá theo dòng giỏ | Spec §4.3 | Hiện chỉ `discountVnd` hóa đơn — `apps/pos_app/lib/features/pos/cart.dart` |
| 5.2 | Gửi ảnh hóa đơn | Spec §4.3 / thermal deferred | Share PDF/ảnh sau bán |
| 5.3 | Hủy / điều chỉnh HĐĐT | Spec §5.5 | Enum `cancelled` có sẵn; thiếu flow |
| 5.4 | Đơn đặt hàng NCC (PO) | Spec §4.4 | YAGNI trừ khi NCC bắt buộc PO |
| 5.5 | Sao lưu SQLite local định kỳ | Spec §6.3 | Export DB file + nhắc user |
| 5.6 | Theo dõi `npm audit` upstream | Hardening security | exceljs / firebase-admin |
| 5.7 | SDK Viettel/MISA | Hardening ngoài scope | Chỉ khi HTTP gateway không đủ compliance |

**Ngoài scope cố định (không đưa vào hoàn thiện go-live):** nộp CQT; website bán lẻ; loyalty; HR; chuỗi > ~10 điểm.

---

## Tiêu chí “xong hoàn thiện tối thiểu” (MVP go-live)

Coi là **đủ mở quán** khi:

1. [ ] PR #17 đã merge; prod đã `migrate deploy`.
2. [ ] JWT + user thật; không còn seed password trên prod.
3. [ ] Backup Postgres chạy ≥ 1 lần restore thử.
4. [ ] POS Windows (và Android nếu dùng) trỏ API prod; bán + sync + đóng ca OK trên 2 máy.
5. [ ] HĐĐT: hoặc gateway thật đã xuất 1 HĐ thử, hoặc cửa hàng chấp nhận stub/off.
6. [ ] (Khuyến nghị trước tháng kế toán đầu) Wave 3 wastage journal xong nếu quán dùng xuất hủy thường xuyên.

---

## Cách chạy kế hoạch này

| Cách | Khi nào |
|------|---------|
| **Subagent-Driven** | Wave 0–1 (ops + merge) và mỗi plan con Wave 3–5 |
| **Inline Execution** | Smoke Wave 2, chỉnh font PDF, docs tick |
| **Dừng sau Wave 1+2** | Nếu chỉ cần mở quán; Wave 3–5 xếp lịch tuần sau |

**Không** bắt đầu Wave 5 khi Wave 0 chưa merge hoặc Wave 1 chưa có backup.

---

## Self-review (coverage)

| Nhu cầu go-live / gap đã khảo sát | Wave |
|-----------------------------------|------|
| Merge hardening | 0 |
| Secrets, host, backup, HĐĐT env, Android signing | 1 |
| Smoke 2 máy, FCM, PDF Unicode | 2 |
| Wastage/transfer journals (deferred P2) | 3 |
| Period unlock + audit UI | 4 |
| Line discount, share receipt, cancel HĐĐT, PO, local backup, audit deps | 5 |
| Nộp CQT / SDK vendor / Phase 4 lớn | Ngoài scope |

Không còn placeholder TBD trong các step Wave 0–2; Wave 3–5 cố ý yêu cầu plan con trước khi code.
