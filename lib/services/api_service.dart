import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/calculator_models.dart';

/// Service to communicate with the cloudly Node.js backend.
class ApiService {
  /// Base URL for the backend server.
  /// Android emulator uses 10.0.2.2 to reach host localhost.
  /// iOS simulator and web use localhost directly.
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    } catch (_) {}
    return 'http://localhost:3000';
  }

  // ─────────────────────────────────────────────────────
  // Health Check
  // ─────────────────────────────────────────────────────

  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────
  // POST /api/ai-estimate
  // Send natural language → get infrastructure config
  // ─────────────────────────────────────────────────────

  static Future<AiEstimateResult> getAiEstimate(String description) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/ai-estimate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'description': description}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return AiEstimateResult.fromJson(data);
        }
      }

      return AiEstimateResult.error('Server returned ${response.statusCode}');
    } catch (e) {
      return AiEstimateResult.error(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────
  // POST /api/calculate
  // Send config → get full cost comparison (Gemini-powered)
  // ─────────────────────────────────────────────────────

  static Future<CalculateResult> calculate(CalculatorConfig config) async {
    try {
      final body = _configToJson(config);

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/calculate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return CalculateResult.fromJson(data);
        }
      }

      return CalculateResult.error('Server returned ${response.statusCode}');
    } catch (e) {
      return CalculateResult.error(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────
  // POST /api/calculate-local
  // Fallback: no Gemini, uses server-side default pricing
  // ─────────────────────────────────────────────────────

  static Future<CalculateResult> calculateLocal(CalculatorConfig config) async {
    try {
      final body = _configToJson(config);

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/calculate-local'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return CalculateResult.fromJson(data);
        }
      }

      return CalculateResult.error('Server returned ${response.statusCode}');
    } catch (e) {
      return CalculateResult.error(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────

  static Map<String, dynamic> _configToJson(CalculatorConfig config) {
    return {
      'vcpu': config.computeSize.vcpu,
      'ram_gb': config.computeSize.ram,
      'storage_gb': config.storageGB.round(),
      'network_gb': config.dataTransferGB.round(),
      'usage_hours': config.effectiveHours.round(),
      'pricing_model': _pricingModelToString(config.pricingModel),
      'region': config.region.code,
      'os': config.osType == OSType.linux ? 'linux' : 'windows',
      'workload_type': _workloadTypeToString(config.workloadType),
      'cpu_architecture':
          config.cpuArchitecture == CpuArchitecture.arm ? 'arm' : 'x86',
      'auto_scaling': config.autoScaling,
      'backup_storage_gb': config.backupStorageGB.round(),
      'additional_data_transfer_gb':
          config.additionalDataTransferGB.round(),
      'storage_type': _storageTypeToString(config.storageType),
      'traffic_type': _trafficTypeToString(config.trafficType),
    };
  }

  static String _pricingModelToString(PricingModel model) {
    switch (model) {
      case PricingModel.onDemand:
        return 'on-demand';
      case PricingModel.reserved1Year:
        return '1-year-reserved';
      case PricingModel.reserved3Year:
        return '3-year-reserved';
      case PricingModel.spotPreemptible:
        return 'spot';
    }
  }

  static String _workloadTypeToString(WorkloadType type) {
    switch (type) {
      case WorkloadType.webApplication:
        return 'web_application';
      case WorkloadType.databaseServer:
        return 'database_server';
      case WorkloadType.aiMlWorkload:
        return 'ai_ml_workload';
      case WorkloadType.devEnvironment:
        return 'dev_environment';
      case WorkloadType.customInfrastructure:
        return 'custom_infrastructure';
    }
  }

  static String _storageTypeToString(StorageType type) {
    switch (type) {
      case StorageType.standardSsd:
        return 'standard_ssd';
      case StorageType.hdd:
        return 'hdd';
      case StorageType.archiveStorage:
        return 'archive';
    }
  }

  static String _trafficTypeToString(TrafficType type) {
    switch (type) {
      case TrafficType.internetEgress:
        return 'internet_egress';
      case TrafficType.interRegion:
        return 'inter_region';
      case TrafficType.sameRegion:
        return 'same_region';
    }
  }
}

// ─────────────────────────────────────────────────────────
// Response Models
// ─────────────────────────────────────────────────────────

class AiEstimateResult {
  final bool success;
  final String source;
  final AiInfraConfig? config;
  final String? errorMessage;

  AiEstimateResult({
    required this.success,
    this.source = 'unknown',
    this.config,
    this.errorMessage,
  });

  factory AiEstimateResult.fromJson(Map<String, dynamic> json) {
    return AiEstimateResult(
      success: true,
      source: json['source'] ?? 'unknown',
      config: AiInfraConfig.fromJson(json['config'] as Map<String, dynamic>),
    );
  }

  factory AiEstimateResult.error(String message) {
    return AiEstimateResult(
      success: false,
      errorMessage: message,
    );
  }
}

class AiInfraConfig {
  final int vcpu;
  final int ramGb;
  final int storageGb;
  final int networkGb;
  final String workloadType;
  final String region;
  final String os;
  final String pricingModel;

  AiInfraConfig({
    required this.vcpu,
    required this.ramGb,
    required this.storageGb,
    required this.networkGb,
    required this.workloadType,
    required this.region,
    required this.os,
    required this.pricingModel,
  });

  factory AiInfraConfig.fromJson(Map<String, dynamic> json) {
    return AiInfraConfig(
      vcpu: (json['vcpu'] as num?)?.toInt() ?? 2,
      ramGb: (json['ram_gb'] as num?)?.toInt() ?? 4,
      storageGb: (json['storage_gb'] as num?)?.toInt() ?? 100,
      networkGb: (json['network_gb'] as num?)?.toInt() ?? 50,
      workloadType: json['workload_type'] as String? ?? 'web_application',
      region: json['region'] as String? ?? 'us-east-1',
      os: json['os'] as String? ?? 'linux',
      pricingModel: json['pricing_model'] as String? ?? 'on-demand',
    );
  }
}

class CalculateResult {
  final bool success;
  final String source;
  final Map<String, ProviderResult>? providers;
  final String? cheapest;
  final List<BackendInsight>? insights;
  final String? errorMessage;

  CalculateResult({
    required this.success,
    this.source = 'unknown',
    this.providers,
    this.cheapest,
    this.insights,
    this.errorMessage,
  });

  factory CalculateResult.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as Map<String, dynamic>;
    final providers = <String, ProviderResult>{};

    for (final key in ['aws', 'azure', 'gcp']) {
      if (results[key] != null) {
        providers[key] = ProviderResult.fromJson(
            results[key] as Map<String, dynamic>, key);
      }
    }

    final insightsJson = json['insights'] as List<dynamic>?;
    final insights = insightsJson
        ?.map((i) => BackendInsight.fromJson(i as Map<String, dynamic>))
        .toList();

    return CalculateResult(
      success: true,
      source: json['source'] ?? 'unknown',
      providers: providers,
      cheapest: results['cheapest'] as String?,
      insights: insights,
    );
  }

  factory CalculateResult.error(String message) {
    return CalculateResult(
      success: false,
      errorMessage: message,
    );
  }

  /// Convert to the existing CloudEstimate model list for UI compatibility.
  List<CloudEstimate> toCloudEstimates() {
    if (providers == null) return [];

    final nameMap = {'aws': 'AWS', 'azure': 'Azure', 'gcp': 'GCP'};

    return providers!.entries.map((entry) {
      final p = entry.value;
      return CloudEstimate(
        provider: nameMap[entry.key] ?? entry.key.toUpperCase(),
        instanceType: p.instance,
        computeCost: p.computeCost,
        storageCost: p.storageCost,
        networkCost: p.networkCost,
        totalMonthlyCost: p.total,
        isCheapest: entry.key == cheapest,
      );
    }).toList();
  }

  /// Convert backend insights to the existing model.
  List<OptimizationInsight> toOptimizationInsights() {
    if (insights == null) return [];
    return insights!
        .map((i) => OptimizationInsight(
              icon: i.icon,
              title: i.title,
              description: i.description,
              savingsPercent: i.savingsPercent,
            ))
        .toList();
  }
}

class ProviderResult {
  final String provider;
  final String instance;
  final double computeCost;
  final double storageCost;
  final double networkCost;
  final double total;
  final bool isCheapest;

  ProviderResult({
    required this.provider,
    required this.instance,
    required this.computeCost,
    required this.storageCost,
    required this.networkCost,
    required this.total,
    this.isCheapest = false,
  });

  factory ProviderResult.fromJson(Map<String, dynamic> json, String provider) {
    return ProviderResult(
      provider: provider,
      instance: json['instance'] as String? ?? 'unknown',
      computeCost: (json['compute_cost'] as num?)?.toDouble() ?? 0,
      storageCost: (json['storage_cost'] as num?)?.toDouble() ?? 0,
      networkCost: (json['network_cost'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      isCheapest: json['is_cheapest'] == true,
    );
  }
}

class BackendInsight {
  final String icon;
  final String title;
  final String description;
  final double? savingsPercent;

  BackendInsight({
    required this.icon,
    required this.title,
    required this.description,
    this.savingsPercent,
  });

  factory BackendInsight.fromJson(Map<String, dynamic> json) {
    return BackendInsight(
      icon: json['icon'] as String? ?? '💡',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      savingsPercent: (json['savings_percent'] as num?)?.toDouble(),
    );
  }
}
