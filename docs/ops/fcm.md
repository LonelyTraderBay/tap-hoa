# FCM push notifications (Wave B — Task B.2, optional)

**Default for day 1:** **FCM off**. The POS and API run without Firebase configured.
Push token registration and low-stock alerts are logged or skipped — no crash, no
blocker for go-live.

Enable FCM only when the store wants device push (sync errors, low stock, large
customer debt alerts). Never commit Firebase service-account JSON or real
`firebase_options.dart` project keys.

---

## Default path — FCM off (recommended day 1)

- [ ] **API:** do **not** set `FIREBASE_SERVICE_ACCOUNT` in `apps/api/.env.production`
  (see [production-secrets.md](production-secrets.md)).
- [ ] **POS:** leave `apps/pos_app/lib/firebase_options.dart` as the repo placeholder
  (`REPLACE_ME` / `tap-hoa-unconfigured`). Do not run `flutterfire configure` unless
  turning FCM on.
- [ ] **Verify:** POS login, sell, and **Đồng bộ** work; no Firebase init crash.
- [ ] **Document store:** note internally **FCM off** — staff will not receive push
  until configured.

Without Firebase, the API still accepts `POST /devices/push-token`; send paths log and
skip. The app continues without push delivery.

Large-debt alerts are also off until each store sets
`largeDebtThresholdVnd` (owner store settings; `null`/blank = off). When enabled,
the API sends a best-effort push to owners/store managers after a debt sale makes a
customer balance cross from below the threshold to at/above it. Debt payments reduce
balances and do not trigger a "large debt" push.

---

## Optional path — enable FCM

Only when push is required:

### API host

- [ ] Create a Firebase **service account** JSON on the host only (not in git).
- [ ] Set absolute path: `FIREBASE_SERVICE_ACCOUNT=/absolute/path/to/sa.json` in
  production env; restart API ([production-deploy.md](production-deploy.md)).
- [ ] Confirm API starts; no error loading the JSON path.

### POS client

- [ ] Install FlutterFire CLI; run `flutterfire configure` in `apps/pos_app` for the
  store’s Firebase project.
- [ ] Replace generated output in `apps/pos_app/lib/firebase_options.dart` (build-time
  only — do not commit real keys to a public repo).
- [ ] Rebuild POS with prod `API_URL`; install on devices.

### Smoke (when FCM on)

- [ ] Register: open POS while online; confirm token posts to API without error.
- [ ] Trigger a low-stock, sync-reject, or configured large-debt-threshold scenario;
  confirm push received on a test device (or API log shows successful send).

---

## Related docs

- [production-secrets.md](production-secrets.md) — `FIREBASE_SERVICE_ACCOUNT` comment
- [production-deploy.md](production-deploy.md) — optional env in Compose
- README — **Optional FCM** summary
