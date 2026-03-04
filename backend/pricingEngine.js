// ============================================================
// pricingEngine.js — cloudly Pricing Engine
// Computes final costs from pricing inputs (Gemini or fallback)
// ============================================================

/**
 * Calculate costs for a single provider.
 *
 * @param {object} pricingInputs - { compute_price_per_hour, storage_price_per_gb, network_price_per_gb, instance }
 * @param {object} infra - { vcpu, ram_gb, storage_gb, network_gb, usage_hours, pricing_model, os }
 * @returns {object} - { instance, compute_cost, storage_cost, network_cost, total }
 */
function calculateProviderCost(pricingInputs, infra) {
  const usageHours = infra.usage_hours || 730;

  // Compute cost = hourly_price × usage_hours
  let computeCost = pricingInputs.compute_price_per_hour * usageHours;

  // Apply pricing model discount
  const discountFactors = {
    'on-demand': 1.0,
    '1-year-reserved': 0.62,
    '3-year-reserved': 0.40,
    'spot': 0.30,
  };
  const discount = discountFactors[infra.pricing_model] || 1.0;
  computeCost *= discount;

  // Apply OS multiplier (Windows ~46% more)
  if (infra.os === 'windows') {
    computeCost *= 1.46;
  }

  // Apply architecture discount (ARM ~20% cheaper)
  if (infra.cpu_architecture === 'arm') {
    computeCost *= 0.80;
  }

  // Auto-scaling overhead
  if (infra.auto_scaling) {
    computeCost *= 1.15;
  }

  // Storage cost = storage_GB × storage_price_per_GB
  let storageCost = (infra.storage_gb || 0) * pricingInputs.storage_price_per_gb;

  // Backup storage
  if (infra.backup_storage_gb > 0) {
    storageCost += infra.backup_storage_gb * pricingInputs.storage_price_per_gb * 0.5;
  }

  // Network cost = transfer_GB × network_price_per_GB
  const totalTransfer = (infra.network_gb || 0) + (infra.additional_data_transfer_gb || 0);
  const networkCost = totalTransfer * pricingInputs.network_price_per_gb;

  const total = computeCost + storageCost + networkCost;

  return {
    instance: pricingInputs.instance || 'unknown',
    compute_cost: Math.round(computeCost * 100) / 100,
    storage_cost: Math.round(storageCost * 100) / 100,
    network_cost: Math.round(networkCost * 100) / 100,
    total: Math.round(total * 100) / 100,
  };
}

/**
 * Calculate costs for all 3 providers.
 *
 * @param {object} pricingData - { aws: {...}, azure: {...}, gcp: {...} }
 * @param {object} infra - infrastructure config from user/AI
 * @returns {object} - { aws: {costs}, azure: {costs}, gcp: {costs}, cheapest: string }
 */
function calculateAllProviders(pricingData, infra) {
  const result = {};
  let cheapestProvider = null;
  let cheapestTotal = Infinity;

  for (const provider of ['aws', 'azure', 'gcp']) {
    if (pricingData[provider]) {
      result[provider] = calculateProviderCost(pricingData[provider], infra);

      if (result[provider].total < cheapestTotal) {
        cheapestTotal = result[provider].total;
        cheapestProvider = provider;
      }
    }
  }

  // Mark cheapest
  if (cheapestProvider) {
    result[cheapestProvider].is_cheapest = true;
  }

  result.cheapest = cheapestProvider;

  return result;
}

/**
 * Generate optimization insights based on config.
 */
function generateInsights(infra, results) {
  const insights = [];

  // Reserved instance suggestion
  if (infra.pricing_model === 'on-demand') {
    insights.push({
      icon: '💰',
      title: 'Switch to Reserved Instances',
      description: 'You can save ~38% by committing to a 1-Year Reserved plan.',
      savings_percent: 38,
    });
  }

  // Spot suggestion
  if (infra.pricing_model !== 'spot') {
    insights.push({
      icon: '⚡',
      title: 'Consider Spot / Preemptible',
      description: 'Spot instances may reduce compute cost by up to 70% for fault-tolerant workloads.',
      savings_percent: 70,
    });
  }

  if (infra.pricing_model === 'spot') {
    insights.push({
      icon: '⚠️',
      title: 'Spot Instance Warning',
      description: 'Spot instances may be interrupted. Not suitable for stateful workloads.',
      savings_percent: null,
    });
  }

  // ARM
  if (infra.cpu_architecture !== 'arm') {
    insights.push({
      icon: '🔧',
      title: 'Try ARM-based Instances',
      description: 'ARM instances (AWS Graviton, Azure Ampere) offer ~20% savings with great performance.',
      savings_percent: 20,
    });
  }

  // Windows → Linux
  if (infra.os === 'windows') {
    insights.push({
      icon: '🐧',
      title: 'Consider Linux',
      description: 'Switching from Windows to Linux can save ~46% on compute licensing costs.',
      savings_percent: 46,
    });
  }

  // Usage pattern
  if (infra.usage_hours >= 700) {
    insights.push({
      icon: '⏰',
      title: 'Schedule Non-Production Workloads',
      description: 'Running dev/staging only during business hours can save up to 78% on compute.',
      savings_percent: 78,
    });
  }

  return insights;
}

module.exports = {
  calculateProviderCost,
  calculateAllProviders,
  generateInsights,
};
