# Finance Tracker

A cross-platform mobile application for international personal finance management with multi-currency support, offline-first operation, and regional adaptability.

## Author

**Abdulrasheed**

## Features

- 💰 **Multi-Currency Support** - Track transactions in multiple international currencies with real-time exchange rates
- 📱 **Offline-First** - Full functionality without internet connection, with automatic cloud sync when online
- 🎯 **Savings Goals** - Create and track multiple savings goals with progress visualization
- 📊 **Budget Planning** - Set monthly budgets per category with smart alerts
- 🧾 **Receipt Scanning** - OCR-powered receipt processing for quick expense entry
- 🌍 **International** - Support for 8+ languages with locale-aware formatting
- 📈 **Reports & Insights** - Visual spending analysis with PDF/CSV export
- 🔒 **Secure Authentication** - OTP and Firebase authentication
- 💳 **Payment Integration** - Regional payment gateway support (Paystack, Flutterwave, Stripe, PayPal, Razorpay)

## Technology Stack

- **Framework**: Flutter 3.x with Dart
- **State Management**: Riverpod
- **Local Storage**: Hive
- **Cloud**: Firebase (Auth, Firestore, Cloud Messaging)
- **Architecture**: Clean Architecture (Domain → Infrastructure → Application → Presentation)

## Getting Started

### Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Firebase account (for backend services)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/finance-tracker.git
cd finance-tracker
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Add your `google-services.json` to `android/app/`
   - Add your `GoogleService-Info.plist` to `ios/Runner/`

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── domain/          # Business logic and entities
├── infrastructure/  # Data sources and repositories
├── application/     # Use cases and services
└── presentation/    # UI components and screens
```

## Supported Platforms

- ✅ Android
- ✅ iOS

## Supported Languages

- English
- French
- Spanish
- German
- Portuguese
- Arabic
- Hindi
- Chinese

## Package Information

- **Package Name**: com.personalfinance.zarachtech
- **Version**: 1.0.0
- **License**: All rights reserved

## Copyright

© 2024 Abdulrasheed. All rights reserved.

## Contact

For questions or support, please open an issue in the repository.
