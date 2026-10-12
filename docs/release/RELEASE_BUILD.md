# Finwise Release Build Guide

This document describes how to reliably compile, sign, and verify the production Android App Bundle (AAB) for Finwise.

---

## 1. Prerequisites

- **Flutter SDK:** Version 3.44.x (Channel: Stable)
- **Java Development Kit:** JDK 17 or JDK 22
- **Android SDK:** Build-Tools 34.0.0+ / 35.0.0+, Android Platform SDK 35/36
- **Signing Credentials:** Valid `android/key.properties` and `android/upload-keystore.jks` (or backed up credentials in `~/AndroidReleaseBackups/Finwise/`)

---

## 2. Release Signing Configuration

The Gradle build configuration in `android/app/build.gradle.kts` supports two signing mechanisms:

### Option A: Local Properties File (Default for Local Builds)
Place `key.properties` in `android/key.properties`:
```properties
storePassword=<STORE_PASSWORD>
keyPassword=<KEY_PASSWORD>
keyAlias=finwise-upload
storeFile=upload-keystore.jks
```

### Option B: Environment Variables (Recommended for CI/CD)
Set the following environment variables in your CI/CD pipeline (e.g., GitHub Actions Secrets):
- `KEYSTORE_FILE`: Absolute path to the keystore file (e.g. `/path/to/upload-keystore.jks`)
- `KEYSTORE_PASSWORD`: Keystore password
- `KEY_ALIAS`: Key alias (`finwise-upload`)
- `KEY_PASSWORD`: Key password

---

## 3. Production Build Commands

### Step 3.1: Clean Previous Build Artifacts
```bash
flutter clean
flutter pub get
```

### Step 3.2: Run Automated Tests
```bash
flutter test
```

### Step 3.3: Build Signed Android App Bundle (AAB)
```bash
flutter build appbundle --release
```

### Step 3.4: Build Signed Release APK (For Direct Device Testing)
```bash
flutter build apk --release
```

---

## 4. Output Artifacts

- **Production AAB:** `build/app/outputs/bundle/release/app-release.aab`
- **Production APK:** `build/app/outputs/flutter-apk/app-release.apk`

---

## 5. Artifact Signature Verification

Run `keytool` or `jarsigner` to verify that the generated bundle is signed with the expected production upload key:

```bash
# Using keytool
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab

# Using jarsigner
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

Verify that the output displays:
- **Signer:** `CN=Finwise Release, OU=Mobile Engineering, O=Finwise, L=Bangalore, ST=Karnataka, C=IN`
- **SHA-256 Fingerprint:** `6B:2C:BC:72:EC:ED:0C:2E:2A:CC:72:5A:E7:6A:AD:EE:7B:E9:63:E7:C2:33:EA:15:FD:44:20:E4:45:DD:36:CE`

---

## 6. How to Increment Version for Subsequent Releases

Google Play requires that every new release has a strictly higher `versionCode` than the previous release.

In `pubspec.yaml`:
```yaml
# Format: version: <versionName>+<versionCode>
version: 1.0.2+3
```

- **`1.0.2` (`versionName`)**: The user-visible version number shown in the Play Store and Settings.
- **`3` (`versionCode`)**: The integer build counter uploaded to Google Play Console. Always increment this by at least +1.

When using Fastlane, build numbers are automatically managed:
```bash
cd android
bundle exec fastlane closed build_number:3
```
