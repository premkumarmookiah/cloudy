# Cloud.ly — Cloud Cost Calculator (demo)

---

## Slide 1 — Title

Cloud.ly

Cloud Cost Comparison & Estimator

- AI-assisted infrastructure estimation (Gemini)
- Backend pricing engine with validation & fallbacks
- Flutter front-end with dark SaaS theme

---

## Slide 2 — Problem

Organizations need a quick way to compare monthly cloud costs across AWS, Azure, and GCP for a given workload. Manual estimates are time-consuming and error-prone.

---

## Slide 3 — Solution Overview

Cloud.ly provides:
- Natural-language workload input (AI) → inferred infra
- Backend pricing engine to compute costs per provider
- Validation & fallback pricing to avoid unrealistic values
- Flutter mobile UI to configure and view comparisons

---

## Slide 4 — Key Features

- Gemini-powered AI interpreter for workload descriptions
- Pricing engine with discount models (on-demand, 1yr, 3yr, spot)
- Compute, storage, and network cost breakdowns
- Results screen: comparison & optimization insights

---

## Slide 5 — Architecture

- Flutter app (mobile/web) ↔ Express backend (Node.js)
- Backend calls Gemini API (gemini-2.0-flash)
- Validation layer ensures sane pricing
- Pricing engine calculates provider costs

---

## Slide 6 — Backend Endpoints

- `GET /api/health` — health check
- `POST /api/ai-estimate` — { description } → infra & pricing
- `POST /api/calculate` — { config } → estimates + insights
- `POST /api/calculate-local` — same as /calculate but without AI assistance

---

## Slide 7 — AI Flow

1. User writes workload description
2. Flutter sends to `/api/ai-estimate`
3. Backend queries Gemini → JSON infra + unit prices
4. Validation cleans values → pricing engine computes costs

---

## Slide 8 — Pricing Model

- Compute cost: hourly_price × hours × discount × os_multiplier × arch_multiplier
- Storage cost: gb × price_per_gb
- Network cost: transfer_gb × price_per_gb
- Discounts supported: on-demand (1.0), 1yr (0.62), 3yr (0.40), spot (0.30)

---

## Slide 9 — UI Highlights

- Dark SaaS theme, glassmorphism cards
- Step-based calculator: Workload → Compute → Storage → Network → Review
- Results view with cheapest-first sorting
- AI toggle to prefer backend estimates

---

## Slide 10 — How to demo

1. Start backend (Node.js + .env with GEMINI_API_KEY)
2. Run Flutter app (simulator or device)
3. On Workload step, enter natural language and press "Generate Config"
4. Run calculation and view results screen

---

## Slide 11 — Next steps

- Add auth + per-user saved estimates
- Persist pricing data and history
- Add richer AI prompts and explainability
- CI/CD for backend + automated tests

---

## Slide 12 — Contact

Repo: local workspace
Questions: ask for a README or walkthrough

