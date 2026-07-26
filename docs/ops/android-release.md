# Android release signing

See also: `docs/ops/windows-prod.md` (Windows prod `API_URL` and smoke checklist).

Release APKs are signed from a local `apps/pos_app/android/key.properties` file.
This file and all keystores are ignored by git; never commit real passwords or keystore files.

## 1. Create the keystore locally

Run from PowerShell, replacing the alias or output path only if you also update `key.properties`:

```powershell
mkdir "$HOME\keystores"
keytool -genkey -v -keystore "$HOME\keystores\tap-hoa-release.jks" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias tap-hoa-release
```

Back up the keystore and passwords somewhere secure. Losing the release key prevents updates signed with the same key.

## 2. Configure local signing secrets

```powershell
cd apps\pos_app\android
copy key.properties.example key.properties
```

Edit `key.properties` with real local values:

```properties
storePassword=<real store password>
keyPassword=<real key password>
keyAlias=tap-hoa-release
storeFile=C:/path/to/keystores/tap-hoa-release.jks
```

`storeFile` is absolute, or relative to `apps/pos_app/android`. Use the same keystore created in step 1 (`$HOME\keystores\tap-hoa-release.jks`).
Release builds fail closed with a clear error when `key.properties` or the keystore file is missing.

## 3. Build the release APK

```powershell
cd apps\pos_app
flutter build apk --release --dart-define=API_URL=https://api.example.com
```
