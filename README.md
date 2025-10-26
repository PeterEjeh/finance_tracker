# 📱 Finance Tracker – Full Development Plan

## Phase 1 – MVP (Completed ✅)

### Goal

Deliver a working offline-first personal finance tracker with multi-currency.

### Stack

Flutter + Hive (local DB) + Currency API

### Features

- ✅ Onboarding screens
- ✅ Manual income/expense tracking with notes, dates, categories
- ✅ Custom categories
- ✅ Budget creation (monthly limits per category)
- ✅ Savings goals (track progress toward specific targets)
- ✅ Real-time multi-currency conversion (via API like Fixer.io, Currency Layer, or Open Exchange Rates)
- ✅ Hive database for offline-first experience

### Technical Notes

- Models: Transaction, Budget, Goal, CurrencyRate
- Services: local_storage.dart (Hive adapters), currency_service.dart (API fetch + cache)
- UI: Budget screen, Transaction screen, Goals screen, Currency picker
- Sync: Local only (Phase 2 adds cloud)

### Cost Considerations (Phase 1)

- Hive → Free (local)
- Currency API → Free tier (limited calls), ₦3,000–₦10,000/mo (~$5–$15) for higher limits

## Phase 2 – Cloud Sync + Premium Automation

### Goal

Multi-device support, cloud backup, automation for premium users.

### Stack

Flutter + Hive (cache) + Firebase Auth + Firestore + Mono API

### Features

- Firebase Auth (Google, Email, Apple sign-in)
- Firestore as cloud DB (sync with Hive)
- Auto sync between devices (conflict resolution → latest update wins)
- Premium Features (Individual Pro):
  - Bank sync via Mono (Nigeria) / Plaid (global)
  - Automatic transaction imports
  - Push notifications for overspending, reminders
  - Export reports (CSV, PDF)

### Technical Notes

- Repositories: Abstracted data layer → BudgetRepository, TransactionRepository → supports Hive + Firestore
- Sync Engine: Background job checks unsynced Hive entries → pushes to Firestore
- Bank Integration: Mono API → webhook for new transactions → Firestore → sync to Hive

### Cost Considerations

- Firebase Blaze plan (~₦4,000–₦10,000/mo for 5k users, scales with reads/writes)
- Mono API (~₦300–₦500 per connected account/month depending on tier)
- Notifications (FCM → Free)

## Phase 3 – AI Insights + Small Business Tools

### Goal

Smart insights + support for SMEs.

### Stack

Flutter + Firestore + Hive (cache) + Vertex AI + Google ML Kit

### Features

- AI insights (predictive budgeting, savings tips)
- Spending analysis (categorical breakdowns, anomalies)
- Receipt OCR (scan → auto transaction entry)
- Subscription tracking (detect recurring payments, send alerts)
- Small Business Dashboard:
  - Multi-user support (admin + staff)
  - Payroll, inventory, expense categories for business
  - Monthly/quarterly reports with charts, PDFs

### Technical Notes

- AI: Export anonymized spending data → Vertex AI → ML model (forecast + recommendations)
- OCR: Google ML Kit → text extraction → map to Transaction model
- Subscription detection: Look for recurring merchants & dates in Firestore data

### Cost Considerations

- Vertex AI: Pay-per-request (~₦0.25–₦1 per AI call, scalable)
- ML Kit: Free for OCR (on-device), Cloud OCR optional (~₦750 per 1,000 images)
- Firestore cost grows with reports + AI data, expect ₦50k–₦150k monthly at scale

## Phase 4 – Enterprise Expansion

### Goal

Serve SMEs and enterprise clients with advanced features.

### Stack

Flutter + Firestore + ERP Integrations + Cloud Security Add-ons

### Features

- Enterprise plan:
  - Advanced analytics (cashflow, forecasting, investment tracking)
  - Role-based access (accountant, manager, auditor)
  - Integration with QuickBooks, Zoho, Sage, SAP
- Security:
  - 2FA
  - Audit logs
  - Data encryption at rest + in-transit
  - SLA support, dedicated dashboards, and private cloud options

### Technical Notes

- ERP connectors: REST/GraphQL APIs for QuickBooks, Zoho, Sage
- Security: Firebase Authentication + custom claims for roles
- Audit logs: Firestore sub-collections tracking user actions

### Cost Considerations

- ERP integrations: Partner licensing costs (₦200k–₦1m yearly depending on provider)
- Firestore + Vertex AI + API usage → scales with enterprise client size
- Enterprise pricing → ₦500k–₦2m+ per client annually to cover costs
