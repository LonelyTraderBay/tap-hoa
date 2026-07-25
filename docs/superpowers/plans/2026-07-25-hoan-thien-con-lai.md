# Hoàn thiện còn lại — Kế hoạch theo thứ tự ưu tiên

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) hoặc `superpowers:executing-plans`. Một wave / một task tại một thời điểm. Wave 3–4 cần **plan con TDD** trước khi code.  
> Master index gốc: `docs/superpowers/plans/2026-07-25-hoan-thien-uu-tien.md` (Wave 0–1 đã Done trên `main` local).

**Goal:** Từ trạng thái “code + runbook go-live đã có trên `main`” → **API/POS prod thật chạy ổn**, rồi vá lỗ sổ & polish.

**Trạng thái (2026-07-25, sau Wave A–E in-repo trên `feat/hoan-thien-remaining`):**

| Hạng mục | Status |
|----------|--------|
| Phase 1–3 features + hardening | Done trên `main` (PR #17 merged) |
| Wave 0 (merge hardening) | **Done** |
| Wave 1 in-repo (Dockerfile, secrets/ops, HĐĐT checklist, Android signing, Windows pointer) | **Done** trên `main` @ `9dd1fad` |
| `main` vs `origin/main` | **Synced** @ `c718984` (A.1 push done) |
| **Wave A in-repo** (checklist A.2–A.5, ops docs) | **Done** |
| **Wave B in-repo** (smoke/FCM runbooks, PDF Unicode font) | **Done** |
| **Wave C in-repo** (wastage journal + plan) | **Done** |
| **Wave D in-repo** (period unlock API + Flutter audit UI) | **Done** |
| **Wave E in-repo** (E.1–E.6 polish; E.7 SDK ngoài scope) | **Done** |
| Deploy VPS / JWT prod / owner thật / backup thật (**A.2–A.5**) | **Chưa** (operator) |
| Smoke 2 máy thật (**B.1**) | **Chưa** (operator) |

## Global Constraints

- Không nộp CQT tự động; không SDK Viettel/MISA nếu HTTP gateway đủ.
- Không `npm audit fix --force`.
- Thay đổi sổ → e2e; Flutter UI → `flutter analyze` sạch.
- Seed `0900000001` / `123456` chỉ dev/test.
- Prod: `JWT_SECRET` ≥ 32 bytes random; `NODE_ENV=production`; chỉ `prisma migrate deploy`.

---

## Thứ tự ưu tiên (còn lại)

```text
Wave A  Push + áp dụng Wave 1 trên host thật     [P0 — chặn mở quán]
Wave B  Smoke 2 máy + PDF Unicode (+ FCM optional)[P1 — ổn định ngày 1–3]
Wave C  Journal xuất hủy (+ optional chuyển kho) [P1 kế toán]
Wave D  Period unlock + audit UI                 [P1–P2]
Wave E  Polish sau ổn định                       [P2]
```

Ops docs neo: `docs/ops/production-secrets.md`, `production-deploy.md`, `einvoice-http.md`, `android-release.md`, `windows-prod.md`, `npm-audit.md` (index trong README).

---

## Wave A — Đưa go-live lên prod thật (P0)

> **In-repo:** Done (checklist + ops docs). **Operator còn lại:** A.2–A.5 trên VPS thật.

**DoD:** `origin/main` có Wave 1; API prod healthy; owner thật login; backup Postgres đã thử restore; POS trỏ API prod bán được ≥ 1 đơn.

### Task A.1: Đồng bộ remote

- [x] **Step 1:** Push `main`

```powershell
cd c:\Users\C-PC\Documents\Projects\tap-hoa
git checkout main
git push origin main
```

Expected: `main` khớp `origin/main` tại `9dd1fad` (hoặc mới hơn).

- [ ] **Step 2 (optional):** Xóa nhánh remote đã xong

```powershell
git push origin --delete chore/go-live-wave1
```

### Task A.2: Secrets + owner trên host

**Docs:** `docs/ops/production-secrets.md`

- [ ] Sinh `JWT_SECRET` (lệnh trong docs); đặt trên host — **không** commit.
- [ ] Env tối thiểu: `NODE_ENV=production`, `DATABASE_URL`, `JWT_SECRET`, `PORT`.
- [ ] `npx prisma migrate deploy` trên DB prod.
- [ ] `npm run create-owner` (Compose: dùng `-e OWNER_PHONE` / `-e OWNER_PASSWORD` như `production-deploy.md`).
- [ ] Disable / đổi mật khẩu seed `0900000001` nếu từng seed trên prod.
- [ ] Verify: `GET /health` → `{ "ok": true }`; login owner thật OK; login `123456` fail.

### Task A.3: Host API + backup

**Docs:** `docs/ops/production-deploy.md`

- [ ] Chọn Docker hoặc Node trên VPS; deploy theo runbook.
- [ ] Cron/`pg_dump` hàng ngày; giữ ≥ 7 bản.
- [ ] Restore thử 1 lần trên staging/DB phụ.
- [ ] Ghi path backup nội bộ (không bắt buộc commit).

### Task A.4: HĐĐT ngày 1 (nhánh)

**Docs:** `docs/ops/einvoice-http.md`

- [ ] **Có gateway:** set `EINVOICE_PROVIDER=http` + URL/key; xuất 1 HĐ từ đơn đã sync; lần 2 idempotent.
- [ ] **Chưa gateway:** giữ `stub`; **không** xuất HĐ cho khách/CQT; ghi “chưa HĐĐT thật”.

### Task A.5: POS prod pointer

**Docs:** `docs/ops/windows-prod.md`, `android-release.md`

- [ ] Windows: build/run với `--dart-define=API_URL=https://…` (URL thật).
- [ ] Android (nếu dùng): tạo keystore local + `key.properties`; `flutter build apk --release` (cần JDK ổn).
- [ ] Smoke 1 máy: login → CH → mở ca → bán TM → đồng bộ → báo cáo ngày.

---

## Wave B — Vận hành ổn định (P1)

> **In-repo:** Done (runbooks B.2–B.3, PDF Unicode). **Operator còn lại:** B.1 smoke 2 máy trên quán.

**DoD:** 2 thiết bị offline→online khớp; PDF kỳ tiếng Việt trên host; FCM on hoặc documented off.

### Task B.1: Smoke multi-device (bắt buộc)

Ghi kết quả vào note nội bộ / issue:

- [ ] Máy A offline: mở ca → bán nợ + TM → online → **Đồng bộ** (`shift_open` trước `sale`).
- [ ] Máy B pull: tồn giảm đúng; báo cáo ngày khớp.
- [ ] Đóng ca A: expected vs thực tế; lệch + ghi chú vẫn đóng được.
- [ ] Owner: sổ kỳ / VAT (nếu bật) / Excel hoặc PDF thử 1 lần.

### Task B.2: FCM (optional)

**Files:** `apps/pos_app/lib/firebase_options.dart`, `FIREBASE_SERVICE_ACCOUNT`

- [ ] `flutterfire configure` **hoặc** ghi runbook quán “FCM off”.
- [ ] Nếu on: SA JSON trên API; thử low-stock alert.

### Task B.3: Font Unicode PDF kỳ (code)

**Branch:** `fix/period-pdf-unicode-font` từ `main` đã push.

**Files:**
- Create: `apps/api/assets/fonts/NotoSans-Regular.ttf` (hoặc NotoSans đã license OK)
- Modify: `apps/api/src/reports/reports.service.ts` (~font load)
- Modify: `apps/api/Dockerfile` / `.dockerignore` nếu cần COPY assets
- Test: e2e hoặc smoke PDF chứa dấu Việt

- [x] Bundle TTF trong repo/image (không phụ thuộc `C:\Windows\Fonts\arial.ttf`).
- [x] `doc.font(<bundled path>)`; fallback Helvetica chỉ khi thiếu file.
- [x] Verify `GET /reports/period/export.pdf`.
- [x] Commit: `fix: embed Unicode font for period PDF export`.

---

## Wave C — Journal xuất hủy / chuyển kho (P1)

> **In-repo:** Done (wastage journal C.1; C.2 transfer optional deferred).

> **Trước code:** plan con `docs/superpowers/plans/YYYY-MM-DD-wastage-transfer-journals.md` (TDD).

**DoD:** Wastage sync → journal đúng CoA; period lock chặn; e2e PASS. Transfer optional.

### Task C.0: Plan con + quyết định CoA

- [x] Chốt tài khoản wastage (bám `postFromStocktake` / journal-builders hiện có).
- [x] Viết plan con với RED/GREEN e2e.

### Task C.1: Journal wastage (bắt buộc)

**Files:** `apps/api/src/ledger/*`, `apps/api/src/sync/stock-ops.service.ts`, `apps/api/test/wastage-journal.e2e-spec.ts`

- [x] Builder + `postFromWastage` (fail-soft, period lock).
- [x] Hook sau persist wastage.
- [x] e2e PASS.

### Task C.2: Journal chuyển kho (optional)

- [ ] Chỉ khi quán hay chuyển điểm; tránh double COGS — quyết định trong plan con.
- [ ] e2e multi-store.

### Task C.3: Docs

- [ ] Tick Deferred trong `2026-07-25-phase2-hardening.md`.
- [ ] CHANGELOG Unreleased.

---

## Wave D — Period unlock + audit UI (P1–P2)

> **In-repo:** Done (API unlock + Flutter audit UI).

> Plan con riêng trước khi implement.

### Task D.1: API

- [x] `POST /ledger/period-locks/:periodYm/unlock` — chỉ `owner` + lý do.
- [x] Ghi `AuditLog`.
- [x] e2e: lock → post 403/blocked → unlock → post OK.

### Task D.2: Flutter

- [x] Section **Sổ kế toán**: lock list + unlock + audit gần đây.
- [x] `flutter analyze` sạch trên path đụng.

---

## Wave E — Polish (P2, sau ổn định quán)

> **In-repo:** Done E.1–E.6. E.7 SDK Viettel/MISA ngoài scope.

Một plan / một mục — không nhồi sprint go-live.

| # | Mục | Khi nào | In-repo |
|---|-----|---------|---------|
| E.1 | Giảm giá theo dòng giỏ | UX bán hàng cần | Done |
| E.2 | Gửi ảnh hóa đơn | Khách hay xin ảnh | Done |
| E.3 | Hủy / điều chỉnh HĐĐT | Có gateway thật | Done |
| E.4 | PO NCC | NCC bắt buộc | Deferred |
| E.5 | Backup SQLite local định kỳ | Rủi ro mất máy quầy | Done |
| E.6 | Theo dõi `npm audit` upstream | Định kỳ | Done (`docs/ops/npm-audit.md`) |
| E.7 | SDK Viettel/MISA | HTTP gateway không đủ | Out of scope |

**Ngoài scope:** nộp CQT; website; loyalty; HR; chuỗi > ~10 điểm.

---

## Tiêu chí “đủ mở quán” (cập nhật)

1. [x] Hardening merged `main` (PR #17)
2. [x] Wave 1 runbook + Docker + signing wiring trong repo
3. [x] `main` đã push `origin`
4. [ ] Prod: migrate + JWT + owner thật + backup restore thử
5. [ ] POS prod bán + sync + đóng ca (≥ 1 máy; khuyến nghị 2 máy = Wave B.1)
6. [ ] HĐĐT: gateway thử **hoặc** chấp nhận stub/off
7. [ ] (Trước tháng KT đầu) Wave C wastage nếu hay xuất hủy

---

## Cách chạy

| Wave | Cách khuyến nghị |
|------|------------------|
| A | Operator + agent hỗ trợ checklist; có thể Inline |
| B.1–B.2 | Operator / Inline |
| B.3, C, D | Subagent-Driven + plan con |
| E | Plan riêng từng mục |

**Không** bắt đầu Wave E khi Wave A chưa có backup + owner thật.

---

## Self-review

| Gap | Wave | Status |
|-----|------|--------|
| Push remote + deploy thật | A | In-repo Done; **operator A.2–A.5** |
| Smoke 2 máy, FCM, PDF Unicode | B | In-repo Done; **operator B.1** |
| Wastage/transfer journals | C | Wastage Done; transfer optional deferred |
| Unlock kỳ + audit UI | D | Done |
| Polish design | E | E.1–E.6 Done; E.7 out of scope |
)
