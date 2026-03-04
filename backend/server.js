// ============================================================
// server.js — cloudly Backend API Server
// Express server with Gemini AI + Pricing Engine
// ============================================================

require('dotenv').config({ path: require('path').resolve(__dirname, '..', '.env') });

const express = require('express');
const cors = require('cors');
const { initGemini, estimateInfrastructure, estimatePricing } = require('./geminiService');
const { calculateAllProviders, generateInsights } = require('./pricingEngine');
const { validatePricingData, getFallbackPricing } = require('./pricingValidation');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Initialize Gemini on startup
const geminiReady = initGemini();

// ─────────────────────────────────────────────────────────
// Health Check
// ─────────────────────────────────────────────────────────

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'cloudly-backend',
    gemini: geminiReady ? 'connected' : 'fallback-mode',
    timestamp: new Date().toISOString(),
  });
});

// ─────────────────────────────────────────────────────────
// POST /api/ai-estimate
// Gemini converts natural language → infrastructure config
// ─────────────────────────────────────────────────────────

app.post('/api/ai-estimate', async (req, res) => {
  try {
    const { description } = req.body;

    if (!description || typeof description !== 'string' || description.trim().length < 5) {
      return res.status(400).json({
        error: 'Please provide a workload description (at least 5 characters).',
      });
    }

    console.log(`[AI Estimate] "${description.substring(0, 80)}..."`);

    const infraConfig = await estimateInfrastructure(description.trim());

    res.json({
      success: true,
      source: geminiReady ? 'gemini' : 'fallback',
      config: infraConfig,
    });
  } catch (err) {
    console.error('[AI Estimate] Error:', err.message);
    res.status(500).json({
      error: 'AI estimation failed. Please try again.',
      fallback: true,
    });
  }
});

// ─────────────────────────────────────────────────────────
// POST /api/calculate
// Full pipeline: config → Gemini pricing → validate → compute → results
// ─────────────────────────────────────────────────────────

app.post('/api/calculate', async (req, res) => {
  try {
    const infra = req.body;

    // Validate required fields
    if (!infra || typeof infra !== 'object') {
      return res.status(400).json({ error: 'Invalid infrastructure configuration.' });
    }

    // Set defaults for any missing fields
    const config = {
      vcpu: infra.vcpu || 2,
      ram_gb: infra.ram_gb || 4,
      storage_gb: infra.storage_gb || 100,
      network_gb: infra.network_gb || 50,
      usage_hours: infra.usage_hours || 730,
      pricing_model: infra.pricing_model || 'on-demand',
      region: infra.region || 'us-east-1',
      os: infra.os || 'linux',
      workload_type: infra.workload_type || 'web_application',
      cpu_architecture: infra.cpu_architecture || 'x86',
      auto_scaling: infra.auto_scaling || false,
      backup_storage_gb: infra.backup_storage_gb || 0,
      additional_data_transfer_gb: infra.additional_data_transfer_gb || 0,
      storage_type: infra.storage_type || 'standard_ssd',
      traffic_type: infra.traffic_type || 'internet_egress',
    };

    console.log(`[Calculate] ${config.vcpu} vCPU / ${config.ram_gb}GB RAM / ${config.storage_gb}GB storage`);

    // Step 1: Get pricing inputs from Gemini
    let rawPricing;
    try {
      rawPricing = await estimatePricing(config);
    } catch (err) {
      console.warn('[Calculate] Gemini pricing failed, using fallback:', err.message);
      rawPricing = getFallbackPricing();
    }

    // Step 2: Validate pricing data
    const { pricing: validatedPricing, usedFallback, errors: validationErrors } =
      validatePricingData(rawPricing);

    if (validationErrors.length > 0) {
      console.warn('[Calculate] Validation warnings:', validationErrors);
    }

    // Step 3: Calculate costs using pricing engine
    const results = calculateAllProviders(validatedPricing, config);

    // Step 4: Generate optimization insights
    const insights = generateInsights(config, results);

    // Step 5: Return results
    res.json({
      success: true,
      source: usedFallback ? 'fallback' : (geminiReady ? 'gemini' : 'fallback'),
      config: config,
      pricing_inputs: validatedPricing,
      results: {
        aws: results.aws,
        azure: results.azure,
        gcp: results.gcp,
        cheapest: results.cheapest,
      },
      insights,
      validation_warnings: validationErrors.length > 0 ? validationErrors : undefined,
    });
  } catch (err) {
    console.error('[Calculate] Error:', err.message);
    res.status(500).json({
      error: 'Calculation failed. Please try again.',
    });
  }
});

// ─────────────────────────────────────────────────────────
// POST /api/calculate-local
// Offline mode: uses only fallback pricing (no Gemini call)
// ─────────────────────────────────────────────────────────

app.post('/api/calculate-local', (req, res) => {
  try {
    const infra = req.body;

    const config = {
      vcpu: infra.vcpu || 2,
      ram_gb: infra.ram_gb || 4,
      storage_gb: infra.storage_gb || 100,
      network_gb: infra.network_gb || 50,
      usage_hours: infra.usage_hours || 730,
      pricing_model: infra.pricing_model || 'on-demand',
      region: infra.region || 'us-east-1',
      os: infra.os || 'linux',
      workload_type: infra.workload_type || 'web_application',
      cpu_architecture: infra.cpu_architecture || 'x86',
      auto_scaling: infra.auto_scaling || false,
      backup_storage_gb: infra.backup_storage_gb || 0,
      additional_data_transfer_gb: infra.additional_data_transfer_gb || 0,
    };

    const fallbackPricing = getFallbackPricing();
    const results = calculateAllProviders(fallbackPricing, config);
    const insights = generateInsights(config, results);

    res.json({
      success: true,
      source: 'local',
      config,
      pricing_inputs: fallbackPricing,
      results: {
        aws: results.aws,
        azure: results.azure,
        gcp: results.gcp,
        cheapest: results.cheapest,
      },
      insights,
    });
  } catch (err) {
    console.error('[Calculate Local] Error:', err.message);
    res.status(500).json({ error: 'Calculation failed.' });
  }
});

// ─────────────────────────────────────────────────────────
// Start server
// ─────────────────────────────────────────────────────────

app.listen(PORT, () => {
  console.log(`\n☁️  cloudly backend running on http://localhost:${PORT}`);
  console.log(`   Gemini AI: ${geminiReady ? '✅ Connected' : '⚠️  Fallback Mode'}`);
  console.log(`   Endpoints:`);
  console.log(`     GET  /api/health`);
  console.log(`     POST /api/ai-estimate`);
  console.log(`     POST /api/calculate`);
  console.log(`     POST /api/calculate-local\n`);
});
