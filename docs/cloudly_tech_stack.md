# Cloud.ly — Technical Stack

## Overview
This document summarizes the languages, frameworks, libraries, services, and operational concerns used in the Cloud.ly project.

## Core Languages
- Dart (Flutter) — Frontend (mobile + web)
- JavaScript (Node.js) — Backend (Express)

## Frontend (Flutter)
- Flutter SDK (stable series compatible with Dart SDK ^3.x)
- Key packages:
  - `http` — for REST calls to backend
- Notable files:
  - `lib/screens/calculator_screen.dart`
  - `lib/screens/results_screen.dart`
  - `lib/services/api_service.dart`

## Backend (Node.js + Express)
- Runtime: Node.js (install via nvm or Homebrew)
- Frameworks/packages:
  - `express` — HTTP server
  - `cors` — cross-origin for local dev
  - `dotenv` — environment variable loading
  - `@google/generative-ai` — Gemini client integration
- Files:
  - `backend/server.js`
  - `backend/geminiService.js`
  - `backend/pricingEngine.js`
  - `backend/pricingValidation.js`

## AI Integration
- Provider: Google Gemini (via `@google/generative-ai` SDK)
- Model: `gemini-2.0-flash` (used for parsing workload descriptions and generating pricing suggestions)
- Security: GEMINI_API_KEY stored in `.env` (do not commit)

## Data & Formats
- JSON — primary payload format between Flutter and backend
- Calculator config JSON includes compute/storage/network specs and pricing model

## Dev & Build Tools
- Flutter CLI (`flutter`) for building and analyzing the app
- Node/npm for backend dev server
- Optional: `pandoc` for converting markdown docs to `.pptx` and `.docx`

## Recommended Versions (suggested)
- Flutter: stable channel (current tested version in workspace)
- Dart SDK: 3.10+ (aligned with Flutter SDK)
- Node.js: 18.x or 20.x (LTS)
- npm: latest compatible with Node

## Deployment Options
- Backend:
  - Containerize with Docker for reproducible runtime
  - Host on: Google Cloud Run, AWS Elastic Beanstalk, Heroku, or a small VM
  - Use environment variables for secrets (GEMINI_API_KEY)
- Frontend (production builds):
  - Mobile: distribute via App Store / Play Store
  - Web: host on static site hosting (Netlify, Firebase Hosting)

## CI/CD Suggestions
- GitHub Actions pipeline:
  - Step 1: `flutter analyze`
  - Step 2: backend lint/test (Node.js)
  - Step 3: build artifacts (optional)
  - Step 4: deploy to staging

## Observability & Security
- Logging: structured JSON logs for backend; capture request ids
- Metrics: instrument request latency around Gemini calls and pricing engine
- Secrets: store GEMINI_API_KEY in a secrets manager (GCP Secret Manager, AWS Secrets Manager)
- Rate limiting: protect `/api/ai-estimate` to avoid abuse and cost spikes

## Scaling considerations
- Cache Gemini responses for identical workload descriptions
- Maintain a pricing cache and periodic refresh from official provider APIs (optional)
- Consider batching or queueing heavy AI calls

## Extensions & Roadmap
- Add user authentication + persisted estimates
- Add provider-specific region mapping and real-time price lookups
- Expand AI prompts to provide infrastructure diagrams (Graphviz/mermaid) and cost rationale

