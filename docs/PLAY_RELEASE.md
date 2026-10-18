# Google Play Release & Deployment Guide

This guide covers building, signing, and releasing Finwise on Google Play, as well as testing in-app updates and reviews.

---

## 1. Application ID & Versioning

Configuration file: `android/app/build.gradle` (or `pubspec.yaml`):

```yaml
# pubspec.yaml
version: 1.0.1+2
```

- **`versionName` (`1.0.1`)**: Semantic user-facing version displayed in Settings and store listing.
- **`versionCode` (`2`)**: Monotonically increasing positive integer. Every production or internal testing build uploaded to Google Play Console must have a higher `versionCode` than the previous one.

---

## 2. Release Signing with Local Keystore

> Never commit keystore files (`.jks`, `.keystore`) or credentials (`key.properties`) to version control. They are strictly ignored in `.gitignore`.

### 2.1 Generate Release Key (One-time)

```bash
keytool -genkey -v -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 2.2 Configure `key.properties`

Create `android/key.properties` (ignored by git):

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=../upload-keystore.jks
```

### 2.3 Build App Bundle (AAB)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## 3. Strict Offline Verification

Finwise is strictly offline. Ensure no `INTERNET` permission is introduced:

1. Build release APK:
   ```bash
   flutter build apk --release
   ```
2. Inspect the merged manifest:
   ```bash
   cat build/app/intermediates/merged_manifests/release/AndroidManifest.xml | grep -i INTERNET
   ```
3. In `android/app/src/main/AndroidManifest.xml`, the node removal rule guarantees safety:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" tools:node="remove"/>
   ```

---

## 4. Testing Google Play In-App Updates

In-app updates (`in_app_update`) rely strictly on the Google Play Core API and Play Store app installed on the device.

### 4.1 Internal App Sharing or Internal Testing
1. Upload your signed build (e.g. `versionCode: 1`) to **Internal App Sharing** or the **Internal testing** track in Google Play Console.
2. Install the app on a physical test device with a Google Account enrolled as an internal tester.
3. Build and upload a newer version with a higher `versionCode` (e.g. `versionCode: 2`).
4. **Do NOT update the app immediately from Play Store.**
5. Launch the older app on the test device.
6. The app checks once per 24 hours automatically on launch, or tap **Settings → Check for updates** to trigger the manual check.
7. For flexible updates, Play UI downloads the update in background; when complete, a standard snackbar displays `"Update ready"` with `"Restart"` action.
8. For critical updates (priority >= 4), Play displays its full-screen immediate update flow.

---

## 5. Testing Google Play In-App Reviews

In-app reviews (`in_app_review`) use the Google Play In-App Review API.

### 5.1 Rules & Quotas
- Quotas are enforced strictly by Google Play. Even if requested, Google Play may suppress the dialog if the user has recently reviewed or quota is exceeded.
- The app automatically triggers a review check on the **3rd successful scenario save**, rate-limited to at most once per 60 days.
- Users can manually tap **Settings → Rate Finwise** to open the prompt or direct Play Store listing.

### 5.2 Verification
- Test using an account enrolled in the Internal test track downloaded from Google Play Console.
- When running in debug mode or on devices without Google Play, calls fail silently and gracefully without showing any errors or crashes.

---

## 6. Automated Fastlane Pipeline & Git Archiving

Fastlane is configured in `android/fastlane/` with complete Google Play deployment lanes and automated Git version archiving.

### 6.1 Prerequisites
1. **Google Play API Key**:
   - Provide via `PLAY_STORE_JSON_KEY` environment variable, or
   - Place as `android/fastlane/api-key.json`, or
   - Place as `api-key.json` / `app.json` in the root directory (ignored by git).
2. **Ruby & Bundler**: Run `bundle install` inside `android/` directory.

### 6.2 Available Deployment Lanes
All release lanes automatically bump `pubspec.yaml`, build release artifacts, upload to Google Play, and trigger automated Git archiving.

- **Run Tests**:
  ```bash
  cd android && bundle exec fastlane test
  ```
- **Build AAB only** (without uploading):
  ```bash
  cd android && bundle exec fastlane build
  # Or with custom build number:
  cd android && bundle exec fastlane build build_number:40
  ```
- **Deploy to Closed Testing** (default track: `alpha`):
  ```bash
  cd android && bundle exec fastlane closed
  # Or specify track & build number:
  cd android && bundle exec fastlane closed track:"alpha" build_number:3
  ```
- **Deploy to Internal Testing**:
  ```bash
  cd android && bundle exec fastlane internal
  ```
- **Deploy to Beta Track**:
  ```bash
  cd android && bundle exec fastlane beta
  ```
- **Deploy to Production** (supports optional rollout):
  ```bash
  cd android && bundle exec fastlane production rollout:0.2
  ```
- **Promote Internal Build to Closed Testing**:
  ```bash
  cd android && bundle exec fastlane promote_to_closed to_track:"alpha"
  ```

### 6.3 Automated Git Version Archiving Workflow
Whenever any release lane runs (`closed`, `internal`, `beta`, `production`):
1. Modified files including bumped `pubspec.yaml` are staged (`git add -A`).
2. Release commit is created: `chore(release): publish build #<num> (<version>+<num>) to <track> [skip ci]`.
3. Active branch is pushed to `origin`.
4. Dedicated version branch `v<build_number>` (e.g. `v40`) is force-created and pushed to `origin`.
5. Release tag `v<version>+<build_number>` (e.g. `v1.0.1+40`) is force-created and pushed to `origin`.
6. Developer stays on their working branch seamlessly without checkout or stash conflicts.
