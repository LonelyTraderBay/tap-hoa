# Go-live sign-off — Wave A (template)

> **Internal operator record.** Copy this file to your password manager or internal wiki.
> Do **not** commit filled copies with real URLs, passwords, API keys, or backup paths.

## Metadata

| Field | Value |
|-------|-------|
| Date | `YYYY-MM-DD` |
| Operator | _(name or initials)_ |
| Environment | Production |
| API base URL | `https://[REDACTED]` _(no trailing slash)_ |
| Store name / code | |
| HĐĐT path | ☐ **stub — chưa HĐĐT thật** (default) &nbsp; ☐ http gateway verified |

---

## Step sign-off

| Step | Check | Pass | Fail | Notes |
|------|-------|:----:|:----:|-------|
| A.1 | `main` matches `origin/main`; `npx prisma migrate deploy` on host | ☐ | ☐ | |
| A.2 | `JWT_SECRET` set on host only; real owner via `create-owner`; login `123456` fails | ☐ | ☐ | |
| A.3 | API `GET /health` → `{ "ok": true }`; daily `pg_dump`; restore trial completed | ☐ | ☐ | |
| A.4 | HĐĐT path completed (see below) | ☐ | ☐ | |
| A.5 | POS built with prod `API_URL`; deployed to ≥ 1 counter/tablet | ☐ | ☐ | |
| Smoke | Login → chọn CH → mở ca → bán 1 đơn TM → **Đồng bộ** → báo cáo ngày shows revenue | ☐ | ☐ | |

---

## A.4 — HĐĐT day 1

### Path A — stub / chưa HĐĐT thật (default when no gateway)

Use when **no** Viettel/MISA HTTP gateway URL + key is available.

- [ ] Host env: `EINVOICE_PROVIDER=stub` (or omit); **do not** set `EINVOICE_HTTP_URL`
- [ ] Store status documented: **chưa HĐĐT thật**
- [ ] Staff briefed: **Xuất HĐĐT** in POS is workflow-only — not legal invoices for customers or CQT
- [ ] _(Optional)_ Test **Xuất HĐĐT** once; confirm `provider: stub` in response/UI

### Path B — real HTTP gateway (only when credentials available)

- [ ] Host env: `EINVOICE_PROVIDER=http`, `EINVOICE_HTTP_URL`, `EINVOICE_HTTP_API_KEY`
- [ ] From POS: sync sale → **Xuất HĐĐT** once; `provider: http` and allowed `status`
- [ ] Re-issue same sale → idempotent (same `invoiceNumber`)

---

## Final attestation

- [ ] All steps A.1–A.5 and Smoke marked **Pass**
- [ ] Backup restore trial date recorded internally: `YYYY-MM-DD`
- Operator: _________________________ &nbsp; Date: __________

**Checklist reference:** [go-live-checklist.md](go-live-checklist.md)  
**Runbooks:** [production-secrets.md](production-secrets.md), [production-deploy.md](production-deploy.md), [einvoice-http.md](einvoice-http.md), [windows-prod.md](windows-prod.md), [android-release.md](android-release.md)
