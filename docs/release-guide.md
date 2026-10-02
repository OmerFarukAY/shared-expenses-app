# Denk — Android Production Release & Signing Guide

This guide describes how to sign, verify, and build production Android App Bundles (`.aab`) for Denk (`com.omerfarukay.denk`), along with configuring Firebase Console SHA fingerprints.

---

## 1. Architecture Overview

Denk uses a secure, decoupled signing architecture:
* **Release Signing Config:** Defined in `android/app/build.gradle.kts`.
* **Properties File:** `android/key.properties` (never committed to git).
* **Upload Keystore:** `android/upload-keystore.jks` (never committed to git).
* **Template:** `android/key.properties.example` provides the schema for new environments.
* **ProGuard / R8:** Code shrinking, obfuscation, and resource optimization are enabled in `buildTypes.release` with custom rules in `android/app/proguard-rules.pro`.

---

## 2. Keystore Generation (For New Environments)

If setting up on a new build machine, generate an upload keystore:

```bash
keytool -genkeypair -v \
  -keystore android/upload-keystore.jks \
  -storetype PKCS12 \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload \
  -dname "CN=Omer Faruk Ay, OU=Denk Mobile, O=Denk, L=Istanbul, ST=Istanbul, C=TR"
```

Then create `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

> [!CAUTION]
> **Backup your keystore:** Keep a secure, encrypted backup of `upload-keystore.jks` and its passwords in a password manager (e.g. 1Password / Bitwarden). If lost, you cannot update existing installs unless Google Play App Signing key reset is requested from Google support.

---

## 3. Extracting SHA-1 & SHA-256 Fingerprints

To extract the public certificate fingerprints:

```bash
keytool -list -v \
  -keystore android/upload-keystore.jks \
  -alias upload
```

Look for the **Certificate fingerprints** section:
```text
Certificate fingerprints:
  SHA1:   XX:XX:XX:...
  SHA256: XX:XX:XX:...
```

---

## 4. Firebase Console Configuration

To ensure Google Sign-In, Firebase Authentication, and Firebase App Check work in production:

1. Open [Firebase Console](https://console.firebase.google.com/project/denk-262c0/overview).
2. Go to **Project Settings** (gear icon) &rarr; **General** tab.
3. Scroll down to **Your apps** and select the Android app (`com.omerfarukay.denk`).
4. Under **SHA certificate fingerprints**, click **Add fingerprint**:
   - Paste the **SHA-1** fingerprint from your upload certificate.
   - Click **Add fingerprint** again and paste the **SHA-256** fingerprint.
5. If **Google Play App Signing** is enabled in the Google Play Console:
   - Navigate to Google Play Console &rarr; **Setup** &rarr; **App signing**.
   - Copy the **App signing key certificate** SHA-1 and SHA-256.
   - Add those to Firebase Console as well (since Google re-signs the bundle before distributing to users).
6. Download the updated `google-services.json` and replace `android/app/google-services.json` if new OAuth client IDs were generated.

---

## 5. Building the Production Release Bundle (AAB)

To compile the release bundle:

```bash
flutter build appbundle --release
```

The output bundle will be located at:
```text
build/app/outputs/bundle/release/app-release.aab
```

### Verifying the Bundle
Verify that the generated AAB is signed with the release certificate:

```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

---

## 6. Git & Security Checklist

Verify that sensitive files are ignored before committing:
```bash
git status
# Confirm android/key.properties and android/*.jks do NOT appear in untracked files
```

Rule in `.gitignore`:
```gitignore
*.jks
*.keystore
**/key.properties
**/android/key.properties
```
