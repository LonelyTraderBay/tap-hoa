# npm audit tracking (API)

Periodic dependency security review for `apps/api` production dependencies.
This is **documentation and process only** — do not run `npm audit fix --force`.

See also:

- `docs/superpowers/plans/2026-07-25-phase3-hardening.md` — Phase 3 hardening audit baseline
- `docs/ops/production-deploy.md` — deploy runbook (no force-fix during deploy windows)

## Policy

- Run **`npm audit --omit=dev`** in `apps/api` (production dependency tree only).
- **Do not** run `npm audit fix --force`. It would downgrade `exceljs` to 3.x (breaking change) and may apply other semver-breaking upgrades without review.
- Safe `npm audit fix` (non-breaking) may be evaluated case-by-case on a branch with e2e; default stance is **track upstream**, not auto-fix in prod hot paths.
- Re-check after major dependency bumps (`exceljs`, `firebase-admin`, `@nestjs/*`) or quarterly.
- Calendar reminder: schedule this quarterly review for the first business week of each quarter.

## Baseline (2026-07-25)

Command:

```powershell
cd apps/api
npm audit --omit=dev
```

Snapshot: **27** vulnerabilities (14 moderate, 12 high, 1 critical).

| Source | Transitive chain | Notes |
|--------|------------------|-------|
| **exceljs** (^4.4.0) | `exceljs` → `archiver` → `glob` / `brace-expansion`; `exceljs` → `uuid` | Period Excel export (`GET /reports/period/export.xlsx`). Force-fix targets exceljs 3.4.0 — **reject**. |
| **firebase-admin** (^13.10.0) | `firebase-admin` → `@google-cloud/firestore` / `storage` → `google-gax` → `uuid` | Optional FCM when `FIREBASE_SERVICE_ACCOUNT` is set; no-op otherwise. |
| **@nestjs/** stack | `@nestjs/core`, `@nestjs/platform-express`, `multer`, `body-parser`, `qs` | Framework HTTP stack; force-fix may jump to breaking Nest minors — review on branch. |
| **tar** (critical) | `@mapbox/node-pre-gyp` → `tar` | Native optional deps; not on hot request path for typical API deploy. |

### Risk acceptance (Phase 3 hardening)

- **`uuid` buffer bounds** (moderate): transitive via exceljs and google-gax; our direct IDs use v4 random generation, not the affected v3/v5/v6 buffer API.
- **exceljs / archiver chain**: accepted until upstream exceljs 4.x releases patched transitive deps; monitor [exceljs releases](https://github.com/exceljs/exceljs/releases).
- **firebase-admin / google-gax**: accepted while FCM remains optional; bump `firebase-admin` on a test branch when release notes mention dependency fixes.

## Periodic check procedure

Run every **quarter** or before a production migration window:

1. `cd apps/api && npm audit --omit=dev` — record counts and any **new direct** advisories.
2. Compare `exceljs` and `firebase-admin` latest versions on npm; note if a minor/patch bump is available without `--force`.
3. If counts change materially, add a one-line note to `CHANGELOG.md` Unreleased (ops) — still no `--force`.
4. If a **direct** dependency has a non-breaking fix (`npm audit fix` without `--force`), open a branch, apply fix, run `npm test` / e2e, then merge — never on prod host ad hoc.

Optional JSON snapshot for diffing (host or CI, not committed):

```powershell
cd apps/api
npm audit --omit=dev --json > audit-omit-dev.json
```

Store snapshots outside the repo; do not commit audit JSON with environment-specific noise.

## Out of scope

- `npm audit fix --force`
- Replacing exceljs with another XLSX library without a product decision
- Vendor SDK additions (Wave E.7 Viettel/MISA) — separate track
