# Denk — Shared Expenses, Settled Simply

A privacy-first, real-time shared-expenses mobile application built with Flutter and Firebase.

Designed for roommates, couples, families, trips, shared households, events, and any group sharing life and finances together.

---

## Features

- **Privacy-First**: No email, phone number, password, or social login required. Uses Firebase Anonymous Authentication with local display names.
- **Fair & Flexible Splits**:
  - Independent payers and participants.
  - Multi-payer support (different members can contribute different amounts to a single expense).
  - Equal split (with integer-remainder distribution), custom amount split, and percentage split.
- **Accurate Financial Calculations**:
  - Zero floating-point arithmetic.
  - All amounts stored in integer minor currency units (cents, kuruş, centimes).
- **Deterministic Settlement Engine**:
  - Computes net member balances.
  - Performs debt simplification into minimal, direct transactions.
  - Multi-currency support without silent exchange conversions.
- **Real-Time Synchronization**:
  - Instant live updates across all group devices powered by Cloud Firestore.
  - Robust offline support with local cache persistence.
- **Clean, Human-Centric Design**:
  - Built with calm typography, restrained spacing, and deliberate visual hierarchy.
  - Thoughtful light and dark themes.
  - Designed for speed: log a simple expense in under 5 seconds.
- **Multilingual Support**:
  - English (`en`)
  - Turkish (`tr`)
  - Spanish (`es`)
  - French (`fr`)
  - Italian (`it`)

---

## Technical Stack

- **Frontend**: Flutter 3.49+ / Dart 3.12+
- **State Management**: Flutter Riverpod (`flutter_riverpod`)
- **Backend**: Firebase Anonymous Authentication & Cloud Firestore
- **Localization**: Official Flutter `intl` & ARB architecture
- **Design System**: Custom typography, tokens, and components (no AI slop, no generic purple gradients)

---

## Documentation

- [Architecture & Design Details](docs/architecture.md)
- [Privacy Philosophy & Data Model](docs/privacy.md)
- [Implementation Progress Tracker](docs/implementation-progress.md)

---

## Getting Started

### Prerequisites

- Flutter SDK (3.49 or newer)
- Dart SDK (3.12 or newer)
- Firebase CLI (`firebase-tools`)

### Running Locally

```bash
# Get dependencies
flutter pub get

# Run development mode
flutter run
```

---

## License

MIT License.
