# Hoàn thiện vận hành & đóng vòng còn lại — Kế hoạch theo thứ tự ưu tiên

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) hoặc `superpowers:executing-plans`. Một Wave / Task tại một thời điểm. Epic code lớn → plan con TDD trước khi implement.  
> **Bối cảnh:** Feature design §4/§5 + Phase 1–3 đã merge (`main` @ `ab65fcc`, PR [#18](https://github.com/LonelyTraderBay/tap-hoa/pull/18)). Kế hoạch này chỉ phần **còn lại để mở quán thật + đóng gap tùy chọn**.

**Goal:** Từ “code đủ trên `main`” → **API/POS prod ổn định**, rồi (tuỳ nhu cầu) đối chiếu NCC, camera barcode, tách quyền KT/HĐĐT.

**Architecture:** Không đổi kiến trúc monorepo. Ưu tiên operator runbook trước; code tiếp theo chỉ khi operator hoặc kế toán yêu cầu.

**Tech Stack:** NestJS + Prisma + PostgreSQL; Flutter POS; Docker/`docs/ops/*`; HĐĐT stub|http; FCM optional.

## Global Constraints

- Không nộp CQT; không SDK Viettel/MISA nếu HTTP gateway đủ.
- Không `npm audit fix --force` — theo `docs/ops/npm-audit.md`.
- Prod: `JWT_SECRET` ≥ 32 bytes; `NODE_ENV=production`; chỉ `prisma migrate deploy`.
- Seed `0900000001` / `123456` chỉ dev/test.
- Thay đổi sổ/sync → e2e; Flutter → `flutter analyze` sạch trên path đụng.
- Không mở YAGNI: website, loyalty, HR, chuỗi > ~10 điểm.

---

## Trạng thái hiện tại (2026-07-26)

| Hạng mục | Status |
|----------|--------|
| Phase 1–3 + hardening | Done trên `main` |
| Gap design §4/§5 (PR #18) | **Merged** |
| **Wave A in-repo** (checklist + ops docs handoff) | **Done** (`be892e1`) |
| **Wave B in-repo** (CI, CHANGELOG, README, tag docs) | **Done** (`61e607c`) |
| **Wave C in-repo** (AP statement recon) | **Done** (`1a175d3`) |
| **Wave D in-repo** (camera barcode mobile) | **Done** (`2e98b23`) |
| **Wave E in-repo** (`canLedger` / `canEinvoice`; toolbar fix `21f38ac`) | **Done** |
| **Wave F in-repo** (manager ledger, PO multi-line, debt adjust, batch HĐĐT idempotent, npm-audit) | **Done** (`a482b8d`) |
| **Deploy VPS + owner + backup + smoke 2 máy** | **Chưa** (operator — Wave A live) |
| **100% plan in-repo** | **Done** — còn Wave A live trên VPS |

---

## Thứ tự ưu tiên

```text
Wave A  Go-live prod thật (operator)           [P0 — chặn mở quán]  in-repo Done; VPS live còn operator
Wave B  CI + release hygiene trên main         [P0 khuyến nghị]      Done in-repo
Wave C  Đối chiếu sao kê NCC (AP recon)        [P1 kế toán]          Done in-repo
Wave D  Camera barcode (mobile)                [P2]                  Done in-repo
Wave E  Tách quyền kế toán ≠ HĐĐT              [P2]                  Done in-repo (+ toolbar fix 21f38ac)
Wave F  Hardening UX/ops nhỏ                   [P3]                  Done in-repo
```

**Đủ mở quán:** xong **Wave A** (khuyến nghị thêm Wave B).  
Waves C–F không chặn ngày mở quán.

---

## Bản đồ file / khu vực

| Wave | Khu vực | Neo |
|------|---------|-----|
| A | Ops | `docs/ops/go-live-checklist.md`, `production-secrets.md`, `production-deploy.md`, `smoke-multi-device.md`, `windows-prod.md`, `android-release.md`, `einvoice-http.md`, `fcm.md` |
| B | CI/docs | `.github/workflows/*` (tạo mới), README |
| C | AP recon | `apps/api/src/suppliers/*` hoặc `reports/*`, Flutter NCC |
| D | Scanner | `pos_page.dart`, `mobile_scanner` |
| E | Roles | Prisma `Role` / permissions, guards Nest + Flutter nav |
| F | Polish | manager ledger entry, PO multi-line UI, v.v. |

---

## Wave A — Go-live prod thật (P0)

> **In-repo:** Done (checklist + ops docs @ `be892e1`). **Operator còn lại:** A.1–A.5 trên VPS thật.

**DoD:** `GET /health` prod OK; owner thật login; không còn seed password; backup Postgres đã restore thử; ≥1 máy POS bán+sync+đóng ca; khuyến nghị smoke 2 máy.

### Task A.1: Đồng bộ & migrate

- [ ] Xác nhận local theo `origin/main` (`ab65fcc` hoặc mới hơn)

```powershell
git checkout main
git pull origin main
```

- [ ] Trên host: `npx prisma migrate deploy` (gồm migrations Wave 5–9 / final-review-fixes)

### Task A.2: Secrets + owner

**Docs:** `docs/ops/production-secrets.md`

- [ ] Sinh `JWT_SECRET` (≥ 32 bytes); đặt env host — **không** commit
- [ ] Env: `NODE_ENV=production`, `DATABASE_URL`, `PORT`, optional HĐĐT/FCM
- [ ] `npm run create-owner` với Compose `-e OWNER_PHONE` / `-e OWNER_PASSWORD` (xem `production-deploy.md`)
- [ ] Disable/đổi mật khẩu seed `0900000001` nếu từng seed
- [ ] Verify: `/health`; login owner OK; login `123456` fail

### Task A.3: Host + backup

**Docs:** `docs/ops/production-deploy.md`

- [ ] Docker Compose hoặc Node/systemd theo runbook
- [ ] Cron/`pg_dump` hàng ngày; giữ ≥ 7 bản; restore thử 1 lần staging
- [ ] Rollback drill 15 phút (snapshot trước migrate)

### Task A.4: HĐĐT ngày 1

**Docs:** `docs/ops/einvoice-http.md`

- [ ] Có gateway: `EINVOICE_PROVIDER=http` + URL/key; xuất 1 HĐ; lần 2 idempotent; thử cancel/adjust nếu dùng
- [ ] Chưa gateway: giữ `stub`; không xuất HĐ cho khách/CQT; ghi “chưa HĐĐT thật”

### Task A.5: POS prod + smoke

**Docs:** `windows-prod.md`, `android-release.md`, `smoke-multi-device.md`

- [ ] Windows/Android trỏ `API_URL` prod; Android có `key.properties` thật
- [ ] Smoke 1 máy: login → CH → mở ca → bán TM → đồng bộ → báo cáo ngày
- [ ] Smoke 2 máy (B.1): offline A → sync → B pull tồn; đóng ca; owner sổ/VAT/PDF thử 1 lần
- [ ] Ghi kết quả vào note nội bộ / issue GitHub

**Tick checklist:** `docs/ops/go-live-checklist.md` các mục A.* / smoke.

---

## Wave B — CI + release hygiene (P0 khuyến nghị)

> **In-repo:** Done @ `61e607c`.

**DoD:** PR/`main` có pipeline tối thiểu; nhánh cũ dọn; tài liệu phiên bản rõ.

### Task B.1: GitHub Actions tối thiểu

**Create:** `.github/workflows/ci.yml`

- [x] Job API: `npm ci` → `npx prisma generate` → `npm run build` → `npm run test:unit` (e2e optional với service Postgres)
- [x] Job Flutter: `flutter pub get` → `flutter analyze` → `flutter test` (matrix hoặc ubuntu)
- [x] Chạy trên `pull_request` + `push` `main`
- [x] Commit: `ci: thêm workflow API/Flutter và đóng vòng tài liệu`

### Task B.2: Dọn nhánh & tag

- [x] Xóa remote nhánh đã merge nếu còn (`cursor/hoan-thien-gap-thiet-ke` sau khi không cần)
- [x] Ghi tag release gợi ý trong docs (chưa tạo tag): `v0.3.0-design-complete` trên `main`
- [x] Cập nhật `CHANGELOG.md` section version nếu chưa có

### Task B.3: Docs đóng vòng

- [x] README: một dòng “Design §4/§5 feature-complete trên `main`; go-live = Wave A ops”
- [x] Đánh dấu plan `2026-07-25-design-gaps-hoan-thien.md` **Merged via #18**

---

## Wave C — Đối chiếu sao kê NCC (P1, optional)

> **In-repo:** Done @ `1a175d3`. Plan con: `docs/superpowers/plans/2026-07-26-ap-statement-recon.md` (nếu có).

**DoD:** Import CSV phải trả / sao kê NCC; khớp payment/AP; khóa kỳ đối chiếu; e2e; Flutter màn NCC.

**Gợi ý schema:** `SupplierStatementLine`, match tới `SupplierPayment` / payable; fingerprint idempotent.

- [x] Plan con (match rules, lock, roles)
- [x] API import/match/unmatch/lock + e2e
- [x] Flutter UI trên Công nợ NCC
- [x] CHANGELOG

---

## Wave D — Camera barcode (P2, optional)

> **In-repo:** Done @ `2e98b23`.

**DoD:** Trên Android/iOS, nút quét camera → điền query / auto-add như wedge hiện có.

**Files:** `pos_page.dart`, dependency `mobile_scanner` (hoặc tương đương), quyền camera.

- [x] Chỉ bật trên mobile; Windows giữ bàn phím wedge
- [x] Reuse exact-barcode auto-add path
- [x] Tests mock / analyze
- [x] Commit: `feat(pos): quét barcode bằng camera`

---

## Wave E — Tách quyền kế toán ≠ HĐĐT (P2, optional)

> **In-repo:** Done @ `444ac24`; plan con `docs/superpowers/plans/2026-07-26-ledger-einvoice-permissions.md`.  
> **Toolbar fix:** @ `21f38ac` — gắn `canLedger`/`canEinvoice` đúng nút **Sổ kế toán** và **Xuất HĐĐT** trên POS toolbar.

**DoD:** Thu ngân = bán; role/permission riêng cho sổ vs xuất HĐĐT (hiện manager gộp cả hai).

**Hướng đã chọn:** Flags trên User: `canLedger`, `canEinvoice`

- [x] Plan con + migration
- [x] Guards Nest + ẩn/hiện Flutter nav/toolbar
- [x] e2e role matrix
- [x] Seed/docs cập nhật

---

## Wave F — Hardening UX/ops nhỏ (P3)

> **In-repo:** Done @ `a482b8d`.

| # | Mục | Ghi chú |
|---|-----|---------|
| F.1 | Manager vào Ledger UI | Done — `canLedger` POS nav |
| F.2 | PO UI nhiều dòng một lần | Done — multi-line create/receive |
| F.3 | Audit `debt_adjust` API | Done — audit + debt ledger entries |
| F.4 | Batch HĐĐT idempotent re-call | Done — trả invoice cũ thay vì `already_issued` |
| F.5 | `npm audit` quarterly | Done — `docs/ops/npm-audit.md` reminders |

---

## Ngoài scope (không đưa vào kế hoạch này)

- Nộp CQT; SDK Viettel/MISA (trừ khi HTTP fail compliance)
- Website / loyalty / HR / chuỗi lớn
- Đổi WAC → FIFO

---

## Tiêu chí “hoàn thiện tối thiểu” (mở quán)

1. [x] Code design §4/§5 + Phase 3 trên `main` (PR #18)
2. [ ] Wave A live: migrate + JWT + owner + backup restore + POS prod (operator)
3. [ ] Wave A live: smoke ≥ 1 máy (khuyến nghị 2 máy) (operator)
4. [ ] HĐĐT live: gateway thử **hoặc** chấp nhận stub (operator)
5. [x] Wave B: CI xanh trên `main`

**Hoàn thiện 100% plan in-repo** = B–F Done + Wave A handoff Done (`be892e1`).  
**Còn lại:** Wave A live trên VPS (operator).

---

## Cách chạy

| Wave | Cách |
|------|------|
| A | Operator + agent hỗ trợ checklist (Inline) |
| B | Subagent-Driven hoặc Inline |
| C–E | Plan con → Subagent-Driven |
| F | Từng PR nhỏ khi cần |

**Không** bắt Wave C–E trước khi Wave A có backup + owner thật (trừ khi chỉ làm CI Wave B song song).

---

## Self-review (coverage)

| Hạng mục | Wave | In-repo | Live operator |
|----------|------|---------|---------------|
| Checklist + ops handoff | A | Done | VPS deploy/secrets/backup/smoke còn operator |
| CI + tag/docs | B | Done | — |
| Sao kê NCC | C | Done | — |
| Camera barcode | D | Done | — |
| Tách quyền KT/HĐĐT (+ toolbar fix) | E | Done | — |
| UX nhỏ (manager ledger, PO multi-line…) | F | Done | — |
| CQT / SDK vendor / YAGNI | — | Ngoài scope | — |
)
