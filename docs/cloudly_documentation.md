# Cloud.ly — Project Documentation

## 1. Project Overview

Cloud.ly is a mobile-first cloud cost comparison and estimation app. It accepts a workload description (natural language), uses an AI service (Gemini) to infer infrastructure requirements, validates pricing, computes costs for AWS/Azure/GCP, and presents a side-by-side comparison.

## 2. Repository Layout (key files)

- `lib/` — Flutter application
  - `main.dart` — app entry
  - `lib/screens/calculator_screen.dart` — main calculator UI, includes AI description panel
  - `lib/screens/results_screen.dart` — results UI (accepts `dataSource` badge)
  - `lib/services/api_service.dart` — HTTP client to backend
  - `lib/models` — data models and converters

- `backend/` — Node.js Express server
  - `server.js` — Express app and API routes
  - `geminiService.js` — Gemini AI integration and parsing
  - `pricingEngine.js` — cost calculation logic
  - `pricingValidation.js` — validation & fallback pricing

- `package.json` — backend dependencies and start script
- `.env` — GEMINI_API_KEY, PORT
- `pubspec.yaml` — Flutter dependencies (added `http` package)

## 3. Backend API Reference

### GET /api/health
- Purpose: check backend availability
- Response: 200 OK { status: 'ok' }

### POST /api/ai-estimate
- Purpose: Use Gemini to parse a natural-language workload into an infra config and estimated unit prices
- Request JSON: { "description": "string" }
- Response JSON (example):
  {
    "infra": { "compute": {...}, "storage": {...}, "network": {...} },
    "pricing": { "aws": {...}, "azure": {...}, "gcp": {...} },
    "source": "gemini"
  }
- Notes: If Gemini fails or returns unrealistic prices, the validation layer will adjust or fall back.

### POST /api/calculate
- Purpose: Compute full cost estimates and insights
- Request JSON: { "config": { ... } }
- Response JSON: { "estimates": [ { provider, computeMonthly, storageMonthly, networkMonthly, totalMonthly } ], "insights": [ ... ], "source": "gemini|fallback|local" }

### POST /api/calculate-local
- Purpose: Local-only pricing (no AI), used as fallback when backend is unreachable

## 4. Data Model (high-level)

- CalculatorConfig: workloadType, region, compute, storage, network, os, pricingModel, durationHours
- CloudEstimate: providerName, computeMonthly, storageMonthly, networkMonthly, totalMonthly, breakdown
- OptimizationInsight: suggestion text and potential savings

## 5. AI Integration Details

- Model: `gemini-2.0-flash` (configured in `geminiService.js`)
- Two roles of AI:
  - Infrastructure Estimator (`/api/ai-estimate`) — produce structured infra JSON from free text
  - Pricing Data Generator — suggest unit prices for compute/storage/network per provider
- The backend sanitizes and validates AI output, replacing unrealistic values using `pricingValidation.js`.

## 6. Pricing Engine

See `pricingEngine.js` for formulas. Key ideas:
- Compute hourly price × hours × discount × modifiers
- Storage as GB × unit price
- Network transfer as GB × unit price
- Discounts applied based on pricing model

## 7. Running Locally

Prerequisites:
- Flutter SDK installed (for mobile app)
- Node.js + npm installed (for backend)

Start backend:

```bash
cd /Users/premkumar/develop/flutter_projects/demo
# Add GEMINI_API_KEY to .env
npm install
npm start
```

Start Flutter app:

```bash
cd /Users/premkumar/develop/flutter_projects/demo
flutter pub get
flutter run
```

If the backend is not available, the Flutter app will use a local pricing fallback so the app still functions.

## 8. Environment Variables

- `GEMINI_API_KEY` — required for AI features
- `PORT` — optional, default 3000

## 9. Testing & Validation

- `flutter analyze` — static analysis (project currently reports `No issues found`)
- Backend unit tests: not included; recommend adding tests around `pricingEngine.calculateProviderCost()` and `pricingValidation.validatePricingData()`.

## 10. Troubleshooting

- "Node.js not found": install Node.js (Homebrew: `brew install node` or nvm)
- Gemini API errors: ensure `GEMINI_API_KEY` is valid and has access to the `gemini-2.0-flash` model
- Flutter build issues: run `flutter pub get` then `flutter analyze` to surface problems

## 11. Recommended Next Tasks

- Add unit tests for backend pricing & validation
- Add CI (GitHub Actions) to run `flutter analyze` and backend tests
- Add persistent storage for saved estimates and user accounts
- Add logging & observability (structured logs, metrics)

## 12. Contacts & Notes

- Repo location: local workspace
- For conversion to Word/PPT, use `pandoc` or Microsoft Office to import the markdown files (see README_CONVERT.md)

