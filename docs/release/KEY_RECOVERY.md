# Finwise Signing Key Recovery & Security Guide

This document details the signing key architecture, backup locations, and recovery procedures for the Finwise Android release pipeline.

> [!CAUTION]
> **NEVER LOSE OR DELETE THE PRODUCTION UPLOAD KEYSTORE.**  
> If this keystore is permanently lost, you will not be able to upload updates to Google Play without submitting an identity verification and key reset request to Google Play Developer Support.

---

## 1. Key Architecture & Google Play App Signing

- **Upload Key (`upload-keystore.jks`):** The cryptographic private key used locally and in CI/CD to sign the Android App Bundle (AAB) before uploading to Google Play Console.
- **Google Play App Signing Key:** The master app signing key managed by Google Cloud KMS inside Google's secure infrastructure. When users download Finwise from Google Play, Google verifies the bundle with your upload key, strips it, and signs the delivered APKs with the Google App Signing Key.
- **Distinction:** Even though Google signs the final distributed APKs, Google Play will **reject** any uploaded AAB that is not signed with your registered Upload Key.

---

## 2. Keystore Metadata & Fingerprints

- **Keystore Format:** PKCS12
- **Key Alias:** `finwise-upload`
- **Key Algorithm:** RSA 2048-bit
- **Signature Algorithm:** `SHA384withRSA`
- **Creation Date:** October 12, 2026
- **Validity:** 10,000 days (Expires February 27, 2054)
- **Distinguished Name (DN):**  
  `CN=Finwise Release, OU=Mobile Engineering, O=Finwise, L=Bangalore, ST=Karnataka, C=IN`
- **Certificate Fingerprints:**
  - **SHA-256:** `6B:2C:BC:72:EC:ED:0C:2E:2A:CC:72:5A:E7:6A:AD:EE:7B:E9:63:E7:C2:33:EA:15:FD:44:20:E4:45:DD:36:CE`
  - **SHA-1:** `1F:B3:22:A4:68:95:60:B5:4D:6A:C7:5D:68:E0:33:0A:7F:70:DA:B8`

---

## 3. Secure Backup Locations

The keystore and credential records are backed up outside the Git repository in two independent locations:

1. **Primary Backup Directory:**
   ```
   C:\Users\karan\AndroidReleaseBackups\Finwise\
   ├── upload-keystore.jks        (Binary PKCS12 keystore)
   ├── backup.txt                 (Recovery instructions & confidential passwords)
   ├── backup_manifest.json       (File hashes, timestamps, and sizes)
   ├── certificate_info.txt       (Full keytool certificate inspection output)
   └── key.properties.template    (Template file for developers)
   ```

2. **Secondary Backup Directory:**
   ```
   C:\Users\karan\.android_backups\Finwise\
   ├── upload-keystore.jks
   ├── backup.txt
   ├── backup_manifest.json
   ├── certificate_info.txt
   └── key.properties.template
   ```

3. **Access Controls:**
   File permissions on `backup.txt` have been restricted so that only the authorized developer account has access.

---

## 4. Key Recovery & Restoration Procedure

If you clone the repository onto a new machine or lose your local development copy:

1. **Copy Keystore:**  
   Copy `upload-keystore.jks` from `C:\Users\karan\AndroidReleaseBackups\Finwise\` into the `android/` directory of the project:
   ```bash
   cp "C:\Users\karan\AndroidReleaseBackups\Finwise\upload-keystore.jks" "android/upload-keystore.jks"
   ```
2. **Restore `android/key.properties`:**  
   Open `backup.txt` from the backup directory and copy the stored credentials into `android/key.properties`:
   ```properties
   storePassword=<PASSWORD_FROM_BACKUP_TXT>
   keyPassword=<PASSWORD_FROM_BACKUP_TXT>
   keyAlias=finwise-upload
   storeFile=upload-keystore.jks
   ```
3. **Verify Keystore Integrity:**  
   Run:
   ```bash
   keytool -list -v -keystore android/upload-keystore.jks -alias finwise-upload
   ```
   Compare the displayed SHA-256 fingerprint with:
   `6B:2C:BC:72:EC:ED:0C:2E:2A:CC:72:5A:E7:6A:AD:EE:7B:E9:63:E7:C2:33:EA:15:FD:44:20:E4:45:DD:36:CE`

---

## 5. Emergency Key Loss Procedure (Google Play Reset)

If all copies of the upload key are permanently lost:
1. Log in to the [Google Play Console](https://play.google.com/console).
2. Navigate to **Release → Setup → App Integrity**.
3. Under **App signing**, select **Request upload key reset**.
4. Generate a new upload key using `keytool` and generate a `.pem` certificate:
   ```bash
   keytool -export -rfc -keystore upload-keystore-new.jks -alias finwise-upload -file upload_certificate.pem
   ```
5. Upload `upload_certificate.pem` to Google Play Support.
6. Once approved (usually within 2 business days), use the new upload key for all subsequent releases.
