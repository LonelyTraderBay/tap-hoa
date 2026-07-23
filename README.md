# tap-hoa

Offline-first grocery POS monorepo (Phase 1).

## Apps

| Path | Stack | Purpose |
|------|-------|---------|
| `apps/api` | NestJS 10 | Central API (health, auth, sync) |
| `apps/pos_app` | Flutter 3 | POS client (Windows, Android, iOS) |

## Quick start

### API

```bash
cd apps/api
npm install
npm run start:dev   # http://localhost:3000
npm run test:e2e
```

`GET /health` returns `{ "ok": true }`.

### POS app

```bash
cd apps/pos_app
flutter pub get
flutter run
flutter test
```
