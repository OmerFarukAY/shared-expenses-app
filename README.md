# Denk — Shared Expenses, Settled Simply

A privacy-first, real-time shared-expenses mobile application for iOS and Android built with Flutter and Firebase.

Designed for roommates, couples, families, trips, shared households, events, and any group sharing life and finances together.

---

## 🌟 Core Principles & Features

- **Privacy-First (Strict Data Minimization)**:
  - Zero passwords, emails, phone numbers, or social logins required.
  - Zero contacts, camera, microphone, or GPS location permissions requested.
  - Zero advertising identifiers, telemetry, or analytics tracking SDKs.
  - Authenticated via Firebase Anonymous Authentication; users pick only a friendly display name.
- **Accurate Financial Calculations (Integer Minor Currency Units)**:
  - Zero floating-point arithmetic ($0.1 + 0.2 \neq 0.30000000000000004$).
  - All amounts, splits, and balances are calculated and stored strictly in integer minor currency units (kuruş, cents, centimes).
- **Decoupled Payers & Participants**:
  - A member can pay without participating (e.g. paying on behalf of someone).
  - Multiple payers can fund a single expense (e.g. Ömer paid ₺1000, Ahmet paid ₺600, Mehmet paid ₺400).
  - Equal split (with integer-remainder distribution without losing a single cent), custom amount split, and percentage split.
- **Deterministic Settlement Engine & Debt Simplification**:
  - Bipartite greedy matching algorithm reduces $N$ debts into a minimal set of direct transfers (bounded by at most $N-1$ transactions).
  - Settlements offset outstanding obligations without destroying historical expense records.
- **Real-Time Synchronization & Offline Support**:
  - Live Firestore reactive streams update all group members' screens instantly.
  - Robust offline support with local cache persistence.
- **Human-Centric Visual Design**:
  - Built with warm neutrals, slate-teal primary accents, hairline borders, and tabular figures.
  - Full Light and Dark themes with contrast ratios exceeding WCAG AA standards.
  - Micro-animations, responsive layout tuning, and screen-reader accessibility (`Semantics`).
- **5-Language Localization**:
  - English (`en`), Turkish (`tr`), Spanish (`es`), French (`fr`), and Italian (`it`) with natural phrasing and proper punctuation/diacritics.

---

## 🏗️ Architecture & Technical Stack

- **Framework**: Flutter 3.49+ / Dart 3.12+
- **State Management**: Flutter Riverpod (`flutter_riverpod`)
- **Backend**: Firebase Anonymous Authentication & Cloud Firestore
- **Security**: Firestore Security Rules enforcing strict membership barriers and invariant validation
- **Localization**: Official Flutter `intl` & ARB architecture (`AppLocalizations`)

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.49 or newer)
- Dart SDK (3.12 or newer)
- Android SDK 34+ / Xcode 15+ (for iOS)
- Firebase project configured with Anonymous Authentication & Cloud Firestore

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Generate Localizations

```bash
flutter gen-l10n
```

### 3. Firebase Configuration

Place your Firebase configuration files:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

Deploy the security rules and compound indexes:

```bash
npx -y firebase-tools@latest deploy --only firestore:rules,firestore:indexes
```

### 4. Run Development Build

```bash
flutter run
```

---

## 🧪 Testing & Code Quality

Denk has a comprehensive, deterministic test suite covering unit math, security invariants, accessibility, Riverpod controllers, 5-language localization, and end-to-end integration journeys.

```bash
# Code formatting
dart format lib test

# Static analysis (0 issues enforced)
flutter analyze

# Run full test suite (72 tests)
flutter test
```

---

## 📦 Production Release Builds

### Android Release APK & App Bundle

```bash
# Release APK
flutter build apk --release

# Google Play App Bundle (.aab)
flutter build appbundle --release
```

### iOS Release Build

```bash
flutter build ios --release --no-codesign
```

---

## 📖 Project Documentation

- [Architecture & Domain Details](docs/architecture.md)
- [Privacy Philosophy & Data Model](docs/privacy.md)
- [Implementation Progress Tracker](docs/implementation-progress.md)

---

## ⚖️ License

MIT License. Designed with privacy, correctness, and care.
