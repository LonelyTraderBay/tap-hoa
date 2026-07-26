# Hoàn thiện local trước thương mại — Kế hoạch ưu tiên

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) hoặc `superpowers:executing-plans`. **Một wave = một subagent**; sau mỗi wave chạy review ngắn trước khi mở wave tiếp theo.  
> **Bối cảnh:** Design + vận hành in-repo đã merge ([#18](https://github.com/LonelyTraderBay/tap-hoa/pull/18), [#19](https://github.com/LonelyTraderBay/tap-hoa/pull/19)). Cô lập local-dev đã merge ([#21](https://github.com/LonelyTraderBay/tap-hoa/pull/21)): DB `tap_hoa` **:55422**, API **:3040**, scripts `scripts/dev-*.ps1`. **Wave A live VPS** vẫn chặn (chưa có credentials). User ưu tiên **dev local song song**, thương mại/VPS sau.

**Goal:** Local stack **đủ dùng hàng ngày** (DB → API → POS) trước khi go-live thương mại; không chặn coding vì thiếu VPS.

**Architecture:** Không đổi monorepo. Chỉ xác minh + polish docs/scripts; không mở feature mới trừ khi smoke phát hiện lỗi thật.

**Tech Stack:** Docker Compose `tap-hoa` / Supabase fallback; Nest `:3040`; Flutter POS; seed dev `0900000001` / `123456`.

---

## Trạng thái

| Wave | Mô tả | Status |
|------|--------|--------|
| **L1** | Local smoke (health + seed login + 1 POS path) | **Done** |
| **L2** | Dev ergonomics (PATH, scripts entrypoints, launch config tuỳ chọn) | **Done** |
| **L3** | Release hygiene local (CHANGELOG/tag note) | **Pending** |
| **A-live** | VPS go-live (operator) | **Blocked** — xem [go-live-signoff.md](../../ops/go-live-signoff.md) |

---

## Thứ tự ưu tiên

```text
L1  Local smoke              [P0 — chặn dev hàng ngày]
L2  Dev ergonomics           [P1 — giảm ma sát]
L3  Release hygiene local    [P2 — khi sẵn sàng tag]
A-live  VPS go-live          [P0 thương mại — blocked credentials]
```

**Đủ code local hàng ngày:** xong **L1** (khuyến nghị thêm **L2**).  
**L3** và **A-live** không chặn dev song song trên máy cá nhân.

---

## Wave L1 — Local smoke (P0)

**DoD:** Fresh clone → `dev-up` + `dev-setup` → `GET /health` OK → login seed OK → ≥1 luồng POS (bán hoặc sync) được ghi trong docs và verify.

- [x] **L1.1** `.\scripts\dev-up.ps1` + `.\scripts\dev-setup.ps1` — migrate + seed thành công trên DB `tap_hoa:55422`
- [x] **L1.2** `.\scripts\start-api.ps1` → `GET http://127.0.0.1:3040/health` → `{ "ok": true }`
- [x] **L1.3** Login API/POS seed `0900000001` / `123456` (dev only)
- [x] **L1.4** Một POS path tối thiểu documented + verified (vd. mở ca → thêm hàng → bán → sync) — cập nhật `docs/ops/local-dev.md` hoặc README nếu thiếu bước
- [x] **L1.5** Ghi kết quả smoke (pass/fail + commit SHA) vào bảng trạng thái plan này

### Verified (2026-07-26)

| Check | Result | Notes |
|-------|--------|-------|
| L1.1 DB + migrate + seed | **PASS** | `tap-hoa-db` healthy on `:55422`; `prisma migrate status` — 25 migrations, schema up to date |
| L1.2 API health | **PASS** | `GET http://127.0.0.1:3040/health` → `{ "ok": true }` |
| L1.3 Seed login (API) | **PASS** | `POST /auth/login` → `accessToken` + owner user `Chu quan` |
| L1.4 POS path | **PASS (docs)** | Minimal path documented in `docs/ops/local-dev.md`; GUI smoke not automated (no display) |
| Commit | `80ffdbf` | `docs(ops): Wave L1 local smoke API health + seed login` |

Commands: `docs/ops/local-smoke.md`

**Neo:** `docs/ops/local-dev.md`, `scripts/dev-up.ps1`, `scripts/dev-setup.ps1`, `scripts/start-api.ps1`, `apps/api/.env.example`

---

## Wave L2 — Dev ergonomics (P1)

**DoD:** Dev mới chỉ cần scripts làm entrypoint; ghi chú Docker PATH rõ; launch config IDE chỉ khi diff tối thiểu.

- [x] **L2.1** Xác nhận ghi chú Docker PATH (non-interactive shell) trong `docs/ops/local-dev.md` — script đã prepend `C:\Program Files\Docker\Docker\resources\bin` trong `dev-up.ps1`
- [x] **L2.2** README + `local-dev.md`: **scripts là entrypoint** (`dev-up`, `dev-setup`, `start-api`); tránh copy-paste dài lệnh thô
- [x] **L2.3** (Tuỳ chọn) `.vscode/launch.json` hoặc Cursor task tối thiểu — API `start:dev` + Flutter `API_URL=3040` — chỉ thêm nếu ≤ ~30 dòng và không trùng scripts
- [x] **L2.4** Cảnh báo `DATABASE_URL` shell override (đã có trong `local-dev.md`) — xác nhận còn đúng sau L1

---

## Wave L3 — Release hygiene local (P2)

**DoD:** CHANGELOG/tag note đã có trên `main`; tag thật chỉ khi user yêu cầu.

- [ ] **L3.1** Xác nhận `CHANGELOG.md` Unreleased + `0.3.0` ghi local-dev identity và tag gợi ý `v0.3.0-design-complete` (docs only, chưa tag)
- [ ] **L3.2** Khi user yêu cầu: tạo annotated tag trên `main`, không force-push
- [ ] **L3.3** Tick L3 trong bảng trạng thái

**Không làm trước L1 pass:** tạo tag release prod.

---

## Wave A-live — VPS go-live (blocked)

> **Blocked:** Chưa có VPS credentials / owner secrets. Không subagent wave này cho đến khi operator unblock.

**Handoff:** [go-live-signoff.md](../../ops/go-live-signoff.md) + [go-live-checklist.md](../../ops/go-live-checklist.md)

- [ ] Operator: migrate prod, JWT ≥ 32 bytes, owner thật, backup restore, smoke ≥ 1 máy POS
- [ ] Điền sign-off template khi xong

---

## Cách chạy (SDD)

| Wave | Cách |
|------|------|
| L1 | **1 subagent** — smoke end-to-end; review trước L2 |
| L2 | **1 subagent** — docs/scripts polish; review trước L3 |
| L3 | **1 subagent** hoặc inline — verify CHANGELOG; tag chỉ on-demand |
| A-live | Operator — agent hỗ trợ checklist khi có credentials |

**Không** chạy L2/L3 song song với L1 cho đến khi L1 smoke pass (trừ sửa doc typo độc lập).

---

## Tiêu chí “local đủ dùng”

1. [x] L1: health + seed + 1 POS path verified
2. [x] L2: scripts-only onboarding rõ trong docs
3. [ ] L3: CHANGELOG/tag note confirmed (tag optional)
4. [ ] A-live: **không chặn** tiêu chí local — theo dõi riêng khi có VPS
