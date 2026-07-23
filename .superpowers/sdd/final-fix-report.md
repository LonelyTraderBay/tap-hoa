# Phase 1 Final Review Fix Report

## Commits

- `a1fe1cb` — `fix(api): secure offline sync foundation`
- `62b6ad0` — `fix(pos): sync shift outbox before sales`
- `d919c28` — `test(api): serialize shared-database e2e suites`

## Changes

- Sync now sends pending shift opens before sales and shift closes after sales in one ordered push. Shift opens/closes are idempotent by client ID, use the JWT user, and preserve client event timestamps.
- Sale sync validates positive decimal quantities, non-negative safe-integer money fields, line totals, discounts, sale totals, and payment totals. The server always writes `soldById` from the JWT.
- Sale sync verifies shift store, owner, and whether the shift was open at `clientCreatedAt`.
- Stock decrements use an atomic PostgreSQL `UPDATE ... qty = qty - delta ... RETURNING` inside the sale transaction. Valid offline sales may drive stock negative.
- Pull captures its response watermark before product/stock queries.
- Customers now have a required `storeId`; create/list/debt balance operations are store-scoped and access-checked.
- Added the PostgreSQL partial unique index for one open shift per `(storeId, userId)`.
- Login and JWT validation reject inactive users. JWT configuration fails without `JWT_SECRET` except for an explicit `NODE_ENV=development` fallback that emits a warning; e2e tests set their own secret.
- Deleted the three committed root task report files.
- Added regression coverage for ordered shift/sale sync, server-owned identity, money/quantity validation, concurrent negative stock, shift ownership, customer scoping, and inactive users.

## Verification

- `cd apps/api && npm run test:e2e` — PASS, 8 suites / 24 tests.
- `cd apps/api && npm run build` — PASS.
- `npx prisma validate` and `npx prisma generate` — PASS.
- `npx prisma migrate deploy` — PASS against the configured local Supabase PostgreSQL database.
- `cd apps/pos_app && flutter analyze` — PASS, no issues.
- Flutter tests were attempted but Flutter crashed while copying `sqlite3.dll` because another native-assets test process already held the destination. No Flutter test result is claimed.

## Remaining Concerns

- Re-run the Flutter test suite after the existing `sqlite3.dll`/native-assets lock is released.
- The pre-existing untracked `apps/api/supabase/` directory was left untouched and was not committed.
