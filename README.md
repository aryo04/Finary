# Finary

Finary is a personal finance management application built with Flutter and Supabase. It combines multi-wallet expense tracking, conversational transaction logging, receipt scanning, and client-side data encryption.

## Overview

Tracking daily expenses manually can be repetitive and inconsistent, especially when managing multiple payment methods such as cash, bank accounts, and digital wallets. Finary addresses this by allowing users to record transactions either through standard forms or through a conversational chat interface. Users can type natural-language messages or upload photos of shopping receipts to extract transaction items automatically, while maintaining control over their financial data with optional client-side encryption.

## Features

- **Authentication and User Onboarding**: Email and password authentication via Supabase Auth, with database triggers that automatically initialize user profiles and seed three default wallets (`Dompet Tunai`, `Rekening Bank`, and `E-Wallet`).
- **Multi-Wallet Management**: Create, edit, and manage multiple wallets across cash, bank, and e-wallet types. Supports balance adjustments, inter-wallet fund transfers via the `transfer_wallet_funds` PostgreSQL RPC (without skewing income or expense totals), and transfer history tracking.
- **Transaction and Category Management**: Record income and expense entries, filter transactions by date or type, navigate paginated transaction lists, and manage transaction categories.
- **AI Financial Assistant and Receipt Scanning**: Conversational chatbot backed by a Supabase Edge Function (`ai-chat`) and OpenAI (`gpt-4o-mini` / `gpt-4o`), paired with an offline rule-based local NLP fallback engine (`LocalNlpEngine`). Supports natural-language expense logging, multi-item category grouping, receipt image parsing, and financial summary queries powered by the `get_financial_summary` RPC.
- **Dashboard and Financial Reports**: Home dashboard displaying net balance, wallet carousels, income-versus-expense summaries, and recent transactions. Dedicated reports view with monthly navigation, category breakdowns, donut charts, weekly bar charts, and summary metrics.
- **Client-Side Encryption and App Lock**: Optional Zero-Knowledge Vault that encrypts transaction descriptions on the device using AES-256-CBC before sending data to the server. Encryption keys are derived from a 6-digit PIN using multi-round HMAC-SHA256, accompanied by PIN and biometric app lock support.

## Tech Stack

- **Framework**: Flutter (Dart SDK `^3.13.1`)
- **State Management**: Provider (`provider`)
- **Navigation**: GoRouter (`go_router`)
- **Backend and Database**: Supabase (PostgreSQL 17, Supabase Auth, Row-Level Security, PL/pgSQL Triggers and RPCs)
- **Serverless Functions**: Supabase Edge Functions (Deno / TypeScript)
- **AI Integration**: OpenAI Chat Completions API (`gpt-4o-mini`, `gpt-4o`) and a local Dart NLP parser
- **Security and Cryptography**: `encrypt` (AES-256-CBC), `crypto` (HMAC-SHA256), `local_auth` (biometric authentication), `shared_preferences`
- **UI and Utilities**: `google_fonts`, `flutter_svg`, `image_picker`, `intl`

## Project Structure

```text
finary/
├── assets/
│   ├── animations/
│   ├── icons/
│   └── images/
├── lib/
│   ├── app/                  # Root application widget and GoRouter configuration
│   ├── core/                 # Constants, error handling, theme, formatters, and core services
│   │   └── services/         # Supabase, AES-256 encryption, vault security, and biometric services
│   ├── features/             # Feature modules (data and presentation layers)
│   │   ├── auth/             # Login, registration, and session management
│   │   ├── categories/       # Income and expense category management
│   │   ├── chatbot/          # AI chat interface, receipt cards, and local NLP engine
│   │   ├── dashboard/        # Balance summary, wallet carousel, and recent transactions
│   │   ├── profile/          # User profile settings
│   │   ├── reports/          # Monthly analytics, charts, and category breakdowns
│   │   ├── security/         # PIN lock screen, PIN setup, and privacy settings
│   │   ├── transactions/     # Transaction list, filters, pagination, and entry forms
│   │   └── wallets/          # Wallet management, balance adjustments, and fund transfers
│   ├── shared/               # Reusable widgets and main navigation shell
│   └── main.dart             # Application entry point and provider initialization
├── supabase/
│   ├── config.toml           # Local Supabase CLI configuration
│   ├── functions/
│   │   └── ai-chat/          # Deno Edge Function for transaction parsing, receipt OCR, and financial Q&A
│   └── migrations/           # SQL migrations for tables, triggers, and RPC functions
└── pubspec.yaml              # Flutter dependencies and asset declarations
```

## Prerequisites

- **Flutter SDK**: Version `^3.13.1` (with Dart SDK)
- **Supabase CLI**: Required for running local database migrations or deploying the `ai-chat` Edge Function
- **Supabase Project**: A hosted or local Supabase instance
- **OpenAI API Key**: Required for the `ai-chat` Supabase Edge Function (receipt scanning and AI chat)
- **Platform Toolchain**: Android Studio / Android SDK, Xcode (for iOS/macOS), or Visual Studio (for Windows desktop)

## Installation and Setup

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd finary
   ```

2. **Install Flutter dependencies**

   ```bash
   flutter pub get
   ```

3. **Set up the Supabase database**

   Link your Supabase project or start a local Supabase instance, then apply the SQL migrations located in `supabase/migrations/`:

   ```bash
   supabase link --project-ref <your-project-ref>
   supabase db push
   ```

   Alternatively, for local development:

   ```bash
   supabase start
   supabase db reset
   ```

4. **Deploy and configure the Edge Function**

   Set the required OpenAI API key secret in Supabase and deploy the `ai-chat` function:

   ```bash
   supabase secrets set OPENAIAPI=<your-openai-api-key>
   supabase functions deploy ai-chat
   ```

5. **Configure the Flutter client connection**

   Open `lib/core/constants/app_constants.dart` and update `supabaseUrl` and `supabaseAnonKey` with your Supabase project credentials:

   ```dart
   static const String supabaseUrl = 'https://your-project-ref.supabase.co';
   static const String supabaseAnonKey = 'your-supabase-anon-key';
   ```

## Running the Project

To run the application on a connected device or emulator:

```bash
flutter run
```

To build a release APK for Android:

```bash
flutter build apk --release
```

To run static analysis and tests:

```bash
flutter analyze
flutter test
```

## Environment Variables

### Flutter Client (`lib/core/constants/app_constants.dart`)

The Flutter client reads the Supabase connection parameters from `AppConstants`:

```dart
static const String supabaseUrl = 'https://<your-project-ref>.supabase.co';
static const String supabaseAnonKey = '<your-supabase-anon-or-publishable-key>';
```

### Supabase Edge Functions (`supabase/functions/ai-chat`)

The `ai-chat` Edge Function requires the following environment variables ( `SUPABASE_URL` and `SUPABASE_ANON_KEY` are automatically injected by the Supabase runtime):

```env
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_ANON_KEY=<your-supabase-anon-key>
OPENAIAPI=sk-<your-openai-api-key>
```

