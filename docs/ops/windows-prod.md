# Windows POS — production build and smoke

Wave 1 go-live: point the Flutter POS at the production API with
`--dart-define=API_URL`. No secrets are stored in the app binary beyond the
public API base URL.

See also:

- `docs/ops/production-deploy.md` — API host, migrate, backup, rollback
- `docs/ops/production-secrets.md` — `JWT_SECRET`, real owner account
- `docs/ops/einvoice-http.md` — HĐĐT HTTP gateway vs stub
- `docs/ops/android-release.md` — Android release signing and APK build

## 1. Set the production API URL

Replace `https://api.example.com` with the HTTPS base URL of the deployed API
(no trailing slash). Confirm the host responds before building the client:

```powershell
Invoke-RestMethod https://api.example.com/health
```

Expected: `{ "ok": true }`.

## 2. Run from source (operator workstation)

```powershell
cd apps\pos_app
flutter pub get
flutter run -d windows --dart-define=API_URL=https://api.example.com
```

Use this for first-day validation or troubleshooting. For daily use at the
counter, prefer a release build (below).

## 3. Build a release executable

```powershell
cd apps\pos_app
flutter pub get
flutter build windows --release --dart-define=API_URL=https://api.example.com
```

Output: `apps\pos_app\build\windows\x64\runner\Release\`. Copy the whole
`Release` folder to each Windows POS machine (or distribute via your internal
installer). Rebuild when the API URL or app version changes.

## 4. Operator smoke checklist (production)

Run once per store after API go-live and after each new Windows build deployed
to the counter. Use the **real owner account** from `docs/ops/production-secrets.md`
— never the dev seed `0900000001` / `123456` on production.

- [ ] **Đăng nhập** — sign in with the production owner/staff account.
- [ ] **Chọn cửa hàng** — select CH1 or CH2 (or the live store).
- [ ] **Mở ca** — enter opening cash; confirm selling is blocked until the shift is open.
- [ ] **Bán 1 đơn tiền mặt** — complete one cash sale (TM) for a known product.
- [ ] **Đồng bộ** — run **Đồng bộ** (or wait for auto sync); confirm no sync errors.
- [ ] **Báo cáo ngày** — open the day report; revenue for today includes the test sale.

Optional follow-up (not required for Wave 1 Windows pointer): second device pull,
đóng ca, HĐĐT — see `docs/ops/einvoice-http.md` and Wave 2 checklists in
`docs/superpowers/plans/2026-07-25-hoan-thien-uu-tien.md`.
