import '../models/calculator_models.dart';

class PricingService {
  // Base hourly rates per provider for a "medium" instance (On-Demand, us-east-1, Linux)
  static const Map<String, double> _baseHourlyRates = {
    'AWS': 0.0416,
    'Azure': 0.0384,
    'GCP': 0.0335,
  };

  // Size multipliers relative to medium
  static const Map<ComputeSize, double> _sizeMultipliers = {
    ComputeSize.small: 0.5,
    ComputeSize.medium: 1.0,
    ComputeSize.large: 2.0,
    ComputeSize.xlarge: 4.0,
  };

  // Storage pricing per GB/month
  static const Map<String, Map<StorageType, double>> _storagePricing = {
    'AWS': {
      StorageType.standardSsd: 0.10,
      StorageType.hdd: 0.045,
      StorageType.archiveStorage: 0.004,
    },
    'Azure': {
      StorageType.standardSsd: 0.096,
      StorageType.hdd: 0.040,
      StorageType.archiveStorage: 0.002,
    },
    'GCP': {
      StorageType.standardSsd: 0.085,
      StorageType.hdd: 0.040,
      StorageType.archiveStorage: 0.0012,
    },
  };

  // Network pricing per GB
  static const Map<String, Map<TrafficType, double>> _networkPricing = {
    'AWS': {
      TrafficType.internetEgress: 0.09,
      TrafficType.interRegion: 0.02,
      TrafficType.sameRegion: 0.01,
    },
    'Azure': {
      TrafficType.internetEgress: 0.087,
      TrafficType.interRegion: 0.02,
      TrafficType.sameRegion: 0.008,
    },
    'GCP': {
      TrafficType.internetEgress: 0.085,
      TrafficType.interRegion: 0.01,
      TrafficType.sameRegion: 0.0,
    },
  };

  // Instance type mappings
  static const Map<String, Map<ComputeSize, String>> _instanceTypes = {
    'AWS': {
      ComputeSize.small: 't3.small',
      ComputeSize.medium: 't3.medium',
      ComputeSize.large: 't3.large',
      ComputeSize.xlarge: 't3.xlarge',
    },
    'Azure': {
      ComputeSize.small: 'B1ms',
      ComputeSize.medium: 'B2s',
      ComputeSize.large: 'B4ms',
      ComputeSize.xlarge: 'B8ms',
    },
    'GCP': {
      ComputeSize.small: 'e2-small',
      ComputeSize.medium: 'e2-standard-2',
      ComputeSize.large: 'e2-standard-4',
      ComputeSize.xlarge: 'e2-standard-8',
    },
  };

  static List<CloudEstimate> calculateEstimates(CalculatorConfig config) {
    final estimates = <CloudEstimate>[];

    for (final provider in ['AWS', 'Azure', 'GCP']) {
      final computeCost = _calculateComputeCost(provider, config);
      final storageCost = _calculateStorageCost(provider, config);
      final networkCost = _calculateNetworkCost(provider, config);
      final total = computeCost + storageCost + networkCost;

      estimates.add(CloudEstimate(
        provider: provider,
        instanceType: _instanceTypes[provider]![config.computeSize]!,
        computeCost: double.parse(computeCost.toStringAsFixed(2)),
        storageCost: double.parse(storageCost.toStringAsFixed(2)),
        networkCost: double.parse(networkCost.toStringAsFixed(2)),
        totalMonthlyCost: double.parse(total.toStringAsFixed(2)),
      ));
    }

    // Mark cheapest
    estimates.sort((a, b) => a.totalMonthlyCost.compareTo(b.totalMonthlyCost));
    final cheapestTotal = estimates.first.totalMonthlyCost;

    return estimates.map((e) {
      return e.copyWith(isCheapest: e.totalMonthlyCost == cheapestTotal);
    }).toList();
  }

  static double _calculateComputeCost(
      String provider, CalculatorConfig config) {
    final baseRate = _baseHourlyRates[provider]!;
    final sizeMultiplier = _sizeMultipliers[config.computeSize]!;
    final regionMultiplier = config.region.pricingMultiplier;
    final pricingDiscount = config.pricingModel.discountFactor;
    final osMultiplier = config.osType.pricingMultiplier;
    final hours = config.effectiveHours;

    double archMultiplier = 1.0;
    if (config.cpuArchitecture == CpuArchitecture.arm) {
      archMultiplier = 0.80; // ARM is typically ~20% cheaper
    }

    double cost = baseRate *
        sizeMultiplier *
        regionMultiplier *
        pricingDiscount *
        osMultiplier *
        archMultiplier *
        hours;

    if (config.autoScaling) {
      cost *= 1.15; // ~15% overhead for auto-scaling buffer
    }

    return cost;
  }

  static double _calculateStorageCost(
      String provider, CalculatorConfig config) {
    final rate = _storagePricing[provider]![config.storageType]!;
    final regionMultiplier = config.region.pricingMultiplier;

    double cost = config.storageGB * rate * regionMultiplier;

    if (config.backupStorageGB > 0) {
      cost += config.backupStorageGB * rate * 0.5 * regionMultiplier;
    }

    return cost;
  }

  static double _calculateNetworkCost(
      String provider, CalculatorConfig config) {
    final rate = _networkPricing[provider]![config.trafficType]!;
    final totalTransfer =
        config.dataTransferGB + config.additionalDataTransferGB;

    return totalTransfer * rate;
  }

  static List<OptimizationInsight> generateInsights(CalculatorConfig config,
      List<CloudEstimate> estimates) {
    final insights = <OptimizationInsight>[];

    // Reserved instance suggestion
    if (config.pricingModel == PricingModel.onDemand) {
      final savings =
          ((1 - PricingModel.reserved1Year.discountFactor) * 100).round();
      insights.add(OptimizationInsight(
        icon: '💰',
        title: 'Switch to Reserved Instances',
        description:
            'You can save ~$savings% by committing to a 1-Year Reserved plan.',
        savingsPercent: savings.toDouble(),
      ));
    }

    // Spot instance suggestion
    if (config.pricingModel != PricingModel.spotPreemptible) {
      insights.add(OptimizationInsight(
        icon: '⚡',
        title: 'Consider Spot / Preemptible',
        description:
            'Spot instances may reduce compute cost by up to 70% for fault-tolerant workloads.',
        savingsPercent: 70,
      ));
    }

    // ARM architecture
    if (config.cpuArchitecture == CpuArchitecture.x86) {
      insights.add(OptimizationInsight(
        icon: '🔧',
        title: 'Try ARM-based Instances',
        description:
            'ARM instances (AWS Graviton, Azure Ampere) offer ~20% savings with great performance.',
        savingsPercent: 20,
      ));
    }

    // Windows to Linux
    if (config.osType == OSType.windows) {
      insights.add(OptimizationInsight(
        icon: '🐧',
        title: 'Consider Linux',
        description:
            'Switching from Windows to Linux can save ~46% on compute licensing costs.',
        savingsPercent: 46,
      ));
    }

    // Storage optimization
    if (config.storageType == StorageType.standardSsd && config.storageGB > 200) {
      insights.add(OptimizationInsight(
        icon: '📦',
        title: 'Review Storage Tier',
        description:
            'For infrequently accessed data, switching to HDD or Archive can reduce storage costs significantly.',
      ));
    }

    // Usage pattern
    if (config.usagePattern == UsagePattern.fullTime) {
      insights.add(OptimizationInsight(
        icon: '⏰',
        title: 'Schedule Non-Production Workloads',
        description:
            'Running dev/staging only during business hours can save up to 78% on compute.',
        savingsPercent: 78,
      ));
    }

    return insights;
  }

  static Map<String, String> getExampleEstimate() {
    return {
      'workload': 'Web Application',
      'compute': 'Medium (4 vCPU / 8GB RAM)',
      'region': 'US East (N. Virginia)',
      'pricing': 'On-Demand',
      'storage': '100 GB SSD',
      'network': '50 GB Internet Egress',
      'aws': '\$45.38',
      'azure': '\$42.14',
      'gcp': '\$38.92',
    };
  }
}
