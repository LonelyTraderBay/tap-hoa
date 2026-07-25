# Period unlock + audit UI — Implementation Plan

> **For agentic workers:** Use subagent-driven-development. Checkbox tasks.

**Goal:** Owner can unlock a locked accounting period with a reason; unlock/lock appear in audit list; Flutter sổ exposes unlock + recent audit.

**Architecture:** Extend existing `LedgerService.lockPeriod` / `AuditLog` / Flutter `LedgerPage`. No new tables.

**Tech Stack:** NestJS, Prisma `PeriodLock` + `AuditLog`, Flutter Dio ledger page.

## Global Constraints

- Unlock: **owner only**
- Require non-empty `reason` (trim, min 3 chars)
- After unlock, posting journals for that `periodYm` works again
- Manager/cashier cannot unlock (403)
- e2e required; `flutter analyze` clean on touched Dart files

---

### Task 1: API unlock + list audit

**Files:**
- Modify: `apps/api/src/ledger/ledger.service.ts`
- Modify: `apps/api/src/ledger/ledger.controller.ts`
- Create: `apps/api/test/period-unlock.e2e-spec.ts`

**API:**
- `POST /ledger/period-locks/:periodYm/unlock` body `{ "reason": string }`
  - owner only; validate `periodYm` `YYYY-MM`; reason required
  - delete `PeriodLock` if exists (idempotent OK if already unlocked — return 200 with `{ unlocked: true, periodYm }`)
  - `writeAudit({ action: 'period_unlock', entityType: 'period_lock', entityId: periodYm, detail: { reason } })`
- `GET /ledger/audit?limit=50` — owner + store_manager; filter recent actions `period_lock` | `period_unlock` | `journal_blocked_period_lock` ordered by `at` desc

- [x] Write e2e RED then GREEN: lock → sale journal blocked → unlock with reason → journal posts; manager 403 on unlock; audit contains unlock

---

### Task 2: Flutter unlock + audit section

**Files:**
- Modify: `apps/pos_app/lib/features/ledger/ledger_page.dart` (+ repository methods)

- [x] `unlockPeriod(periodYm, reason)` → POST unlock
- [x] `listAudit({limit})` → GET audit
- [x] UI: for each locked period shown, owner sees **Mở khóa** → dialog nhập lý do → refresh locks
- [x] Section **Nhật ký khóa sổ** listing recent audit rows (action, entityId, at, reason if any)
- [x] `flutter analyze` on touched files

---

### Task 3: Docs

- [x] Note in CHANGELOG Unreleased
- [ ] Optional one-liner in `hoan-thien-con-lai.md` Wave D Done when merged
