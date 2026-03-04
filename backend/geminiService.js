// ============================================================
// geminiService.js — cloudly Gemini AI Integration
// Uses Google Gemini API for infrastructure estimation & pricing
// ============================================================

const { GoogleGenerativeAI } = require('@google/generative-ai');
const { getFallbackPricing } = require('./pricingValidation');

// Initialize Gemini client
let genAI = null;
let model = null;

function initGemini() {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || apiKey === 'your_gemini_api_key') {
    console.warn('[Gemini] No valid API key found. AI features will use fallback data.');
    return false;
  }
  try {
    genAI = new GoogleGenerativeAI(apiKey);
    model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
    console.log('[Gemini] Initialized successfully.');
    return true;
  } catch (err) {
    console.error('[Gemini] Init failed:', err.message);
    return false;
  }
}

/**
 * Parse JSON from Gemini response (handles markdown code blocks).
 */
function parseGeminiJson(text) {
  // Strip markdown code fences if present
  let cleaned = text.trim();
  if (cleaned.startsWith('```json')) {
    cleaned = cleaned.slice(7);
  } else if (cleaned.startsWith('```')) {
    cleaned = cleaned.slice(3);
  }
  if (cleaned.endsWith('```')) {
    cleaned = cleaned.slice(0, -3);
  }
  return JSON.parse(cleaned.trim());
}

// ─────────────────────────────────────────────────────────
// 1️⃣  AI Infrastructure Estimator
// ─────────────────────────────────────────────────────────

/**
 * Convert a natural-language workload description into structured infra config.
 *
 * @param {string} description - e.g. "I want to run a small ecommerce website with 10k monthly users"
 * @returns {object} - { vcpu, ram_gb, storage_gb, network_gb, workload_type, region, os, pricing_model }
 */
async function estimateInfrastructure(description) {
  if (!model) {
    console.warn('[Gemini] Model not available, returning default config.');
    return getDefaultInfraEstimate();
  }

  const prompt = `You are a cloud infrastructure sizing expert.

A user describes their workload:
"${description}"

Based on this description, estimate the required cloud infrastructure configuration.

Return ONLY valid JSON with no explanation. Required format:

{
  "vcpu": <number, 1-64>,
  "ram_gb": <number, 1-256>,
  "storage_gb": <number, 10-10000>,
  "network_gb": <number, 1-5000>,
  "workload_type": <string, one of: "web_application", "database_server", "ai_ml_workload", "dev_environment", "custom_infrastructure">,
  "region": <string, e.g. "us-east-1">,
  "os": <string, "linux" or "windows">,
  "pricing_model": <string, one of: "on-demand", "1-year-reserved", "3-year-reserved", "spot">
}

Be practical and realistic. For small apps use small instances. For ML/AI use GPU-capable sizes.`;

  try {
    const result = await model.generateContent(prompt);
    const text = result.response.text();
    const parsed = parseGeminiJson(text);

    // Validate and sanitize the response
    return sanitizeInfraEstimate(parsed);
  } catch (err) {
    console.error('[Gemini] Infrastructure estimation failed:', err.message);
    return getDefaultInfraEstimate();
  }
}

/**
 * Sanitize AI infrastructure output.
 */
function sanitizeInfraEstimate(data) {
  return {
    vcpu: clamp(data.vcpu || 2, 1, 64),
    ram_gb: clamp(data.ram_gb || 4, 1, 256),
    storage_gb: clamp(data.storage_gb || 100, 10, 10000),
    network_gb: clamp(data.network_gb || 50, 1, 5000),
    workload_type: validateEnum(data.workload_type, [
      'web_application', 'database_server', 'ai_ml_workload',
      'dev_environment', 'custom_infrastructure',
    ], 'web_application'),
    region: data.region || 'us-east-1',
    os: validateEnum(data.os, ['linux', 'windows'], 'linux'),
    pricing_model: validateEnum(data.pricing_model, [
      'on-demand', '1-year-reserved', '3-year-reserved', 'spot',
    ], 'on-demand'),
  };
}

function getDefaultInfraEstimate() {
  return {
    vcpu: 2,
    ram_gb: 4,
    storage_gb: 100,
    network_gb: 50,
    workload_type: 'web_application',
    region: 'us-east-1',
    os: 'linux',
    pricing_model: 'on-demand',
  };
}

// ─────────────────────────────────────────────────────────
// 2️⃣  Pricing Data Generator
// ─────────────────────────────────────────────────────────

/**
 * Ask Gemini to estimate unit pricing for the given infrastructure.
 *
 * @param {object} infra - { vcpu, ram_gb, storage_gb, network_gb, region, ... }
 * @returns {object} - { aws: {instance, compute_price_per_hour, ...}, azure: {...}, gcp: {...} }
 */
async function estimatePricing(infra) {
  if (!model) {
    console.warn('[Gemini] Model not available, returning fallback pricing.');
    return getFallbackPricing();
  }

  const prompt = `You are a cloud pricing assistant.

Given infrastructure configuration:

${infra.vcpu} vCPU
${infra.ram_gb}GB RAM
${infra.storage_gb}GB SSD storage
${infra.network_gb}GB monthly network transfer
region: ${infra.region || 'us-east-1'}

Return JSON containing estimated pricing inputs for AWS, Azure, and GCP.

Return ONLY valid JSON with no explanation.

Required format:

{
  "aws": {
    "instance": "<instance type like t3.medium>",
    "compute_price_per_hour": <number>,
    "storage_price_per_gb": <number>,
    "network_price_per_gb": <number>
  },
  "azure": {
    "instance": "<instance type like B2s>",
    "compute_price_per_hour": <number>,
    "storage_price_per_gb": <number>,
    "network_price_per_gb": <number>
  },
  "gcp": {
    "instance": "<instance type like e2-standard-2>",
    "compute_price_per_hour": <number>,
    "storage_price_per_gb": <number>,
    "network_price_per_gb": <number>
  }
}

Use realistic 2025/2026 pricing. Be accurate.`;

  try {
    const result = await model.generateContent(prompt);
    const text = result.response.text();
    return parseGeminiJson(text);
  } catch (err) {
    console.error('[Gemini] Pricing estimation failed:', err.message);
    return getFallbackPricing();
  }
}

// ─────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────

function clamp(val, min, max) {
  if (typeof val !== 'number' || isNaN(val)) return min;
  return Math.max(min, Math.min(max, val));
}

function validateEnum(val, allowed, fallback) {
  if (typeof val === 'string' && allowed.includes(val.toLowerCase())) {
    return val.toLowerCase();
  }
  return fallback;
}

module.exports = {
  initGemini,
  estimateInfrastructure,
  estimatePricing,
  getDefaultInfraEstimate,
};
