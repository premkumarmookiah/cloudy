// ============================================================
// pricingValidation.js — cloudly Pricing Validation Layer
// Validates Gemini pricing data, falls back to defaults if bad
// ============================================================

// Fallback pricing (safe defaults)
const FALLBACK_PRICING = {
  aws: {
    instance: 't3.medium',
    compute_price_per_hour: 0.0416,
    storage_price_per_gb: 0.10,
    network_price_per_gb: 0.09,
  },
  azure: {
    instance: 'B2s',
    compute_price_per_hour: 0.0384,
    storage_price_per_gb: 0.096,
    network_price_per_gb: 0.087,
  },
  gcp: {
    instance: 'e2-standard-2',
    compute_price_per_hour: 0.0335,
    storage_price_per_gb: 0.085,
    network_price_per_gb: 0.085,
  },
};

// Validation thresholds
const LIMITS = {
  compute_price_per_hour: { min: 0.001, max: 10 },
  storage_price_per_gb: { min: 0.0001, max: 5 },
  network_price_per_gb: { min: 0, max: 5 },
};

/**
 * Validate a single numeric pricing field.
 */
function isValidPrice(value, field) {
  if (typeof value !== 'number' || isNaN(value)) return false;
  const limit = LIMITS[field];
  if (!limit) return true;
  return value >= limit.min && value <= limit.max;
}

/**
 * Validate a single provider's pricing data.
 * Returns { valid: boolean, data: object, errors: string[] }
 */
function validateProviderPricing(data, provider) {
  const errors = [];

  if (!data || typeof data !== 'object') {
    return {
      valid: false,
      data: FALLBACK_PRICING[provider],
      errors: [`${provider}: No data received, using fallback`],
    };
  }

  const validated = { ...data };
  let usedFallback = false;

  // Validate compute_price_per_hour
  if (!isValidPrice(data.compute_price_per_hour, 'compute_price_per_hour')) {
    errors.push(`${provider}: Invalid compute_price_per_hour (${data.compute_price_per_hour}), using fallback`);
    validated.compute_price_per_hour = FALLBACK_PRICING[provider].compute_price_per_hour;
    usedFallback = true;
  }

  // Validate storage_price_per_gb
  if (!isValidPrice(data.storage_price_per_gb, 'storage_price_per_gb')) {
    errors.push(`${provider}: Invalid storage_price_per_gb (${data.storage_price_per_gb}), using fallback`);
    validated.storage_price_per_gb = FALLBACK_PRICING[provider].storage_price_per_gb;
    usedFallback = true;
  }

  // Validate network_price_per_gb
  if (!isValidPrice(data.network_price_per_gb, 'network_price_per_gb')) {
    errors.push(`${provider}: Invalid network_price_per_gb (${data.network_price_per_gb}), using fallback`);
    validated.network_price_per_gb = FALLBACK_PRICING[provider].network_price_per_gb;
    usedFallback = true;
  }

  // Ensure instance name exists
  if (!validated.instance || typeof validated.instance !== 'string') {
    validated.instance = FALLBACK_PRICING[provider].instance;
  }

  return {
    valid: !usedFallback,
    data: validated,
    errors,
  };
}

/**
 * Validate pricing data for all providers.
 * Returns validated, safe pricing data.
 */
function validatePricingData(pricingData) {
  const allErrors = [];
  const validated = {};
  let usedFallback = false;

  for (const provider of ['aws', 'azure', 'gcp']) {
    const result = validateProviderPricing(
      pricingData ? pricingData[provider] : null,
      provider
    );
    validated[provider] = result.data;
    allErrors.push(...result.errors);
    if (!result.valid) usedFallback = true;
  }

  return {
    pricing: validated,
    usedFallback,
    errors: allErrors,
  };
}

/**
 * Get complete fallback pricing (when Gemini is totally unavailable).
 */
function getFallbackPricing() {
  return JSON.parse(JSON.stringify(FALLBACK_PRICING));
}

module.exports = {
  validatePricingData,
  validateProviderPricing,
  getFallbackPricing,
  FALLBACK_PRICING,
};
