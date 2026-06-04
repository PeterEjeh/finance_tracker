# 📱 Finance Tracker

A full-featured personal finance tracker built with Flutter and Hive for secure, offline-first financial management.

## Core Features

- 💰 **Manual Income & Expense Tracking** – Record transactions with notes, dates, and categories
- 📂 **Custom Categories** – Create and organize your own spending categories
- 💼 **Budget Management** – Set monthly limits per category and track spending
- 🎯 **Savings Goals** – Create and monitor progress toward specific financial targets
- 💱 **Multi-Currency Support** – Real-time currency conversion for global transactions
- 🔐 **Offline-First** – Full functionality without internet; data synced locally via Hive

## Tech Stack

- **Frontend:** Flutter
- **Local Database:** Hive
- **Currency API:** Fixer.io, Currency Layer, or Open Exchange Rates

## Getting Started

1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Run the app: `flutter run`

## Data Models

- Transaction
- Budget
- Goal
- CurrencyRate

## Services

- `local_storage.dart` – Hive adapters and local storage management
- `currency_service.dart` – API integration and currency rate caching

## License

[Add your license here]
