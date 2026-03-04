enum WorkloadType {
  webApplication,
  databaseServer,
  aiMlWorkload,
  devEnvironment,
  customInfrastructure,
}

extension WorkloadTypeExt on WorkloadType {
  String get label {
    switch (this) {
      case WorkloadType.webApplication:
        return 'Web Application';
      case WorkloadType.databaseServer:
        return 'Database Server';
      case WorkloadType.aiMlWorkload:
        return 'AI / ML Workload';
      case WorkloadType.devEnvironment:
        return 'Dev Environment';
      case WorkloadType.customInfrastructure:
        return 'Custom Infrastructure';
    }
  }

  String get icon {
    switch (this) {
      case WorkloadType.webApplication:
        return '🌐';
      case WorkloadType.databaseServer:
        return '🗄️';
      case WorkloadType.aiMlWorkload:
        return '🤖';
      case WorkloadType.devEnvironment:
        return '💻';
      case WorkloadType.customInfrastructure:
        return '⚙️';
    }
  }

  String get description {
    switch (this) {
      case WorkloadType.webApplication:
        return 'Frontend/backend services, APIs, microservices';
      case WorkloadType.databaseServer:
        return 'SQL, NoSQL, caching, data warehousing';
      case WorkloadType.aiMlWorkload:
        return 'Training, inference, GPU-accelerated';
      case WorkloadType.devEnvironment:
        return 'CI/CD, staging, development servers';
      case WorkloadType.customInfrastructure:
        return 'Custom configuration for your needs';
    }
  }
}

enum CloudRegion {
  usEast1,
  apSouth1,
  euCentral1,
  usWest2,
  apSoutheast1,
}

extension CloudRegionExt on CloudRegion {
  String get label {
    switch (this) {
      case CloudRegion.usEast1:
        return 'US East (N. Virginia)';
      case CloudRegion.apSouth1:
        return 'Asia Pacific (Mumbai)';
      case CloudRegion.euCentral1:
        return 'Europe (Frankfurt)';
      case CloudRegion.usWest2:
        return 'US West (Oregon)';
      case CloudRegion.apSoutheast1:
        return 'Asia Pacific (Singapore)';
    }
  }

  String get code {
    switch (this) {
      case CloudRegion.usEast1:
        return 'us-east-1';
      case CloudRegion.apSouth1:
        return 'ap-south-1';
      case CloudRegion.euCentral1:
        return 'eu-central-1';
      case CloudRegion.usWest2:
        return 'us-west-2';
      case CloudRegion.apSoutheast1:
        return 'ap-southeast-1';
    }
  }

  double get pricingMultiplier {
    switch (this) {
      case CloudRegion.usEast1:
        return 1.0;
      case CloudRegion.apSouth1:
        return 0.85;
      case CloudRegion.euCentral1:
        return 1.12;
      case CloudRegion.usWest2:
        return 1.02;
      case CloudRegion.apSoutheast1:
        return 1.08;
    }
  }
}

enum PricingModel {
  onDemand,
  reserved1Year,
  reserved3Year,
  spotPreemptible,
}

extension PricingModelExt on PricingModel {
  String get label {
    switch (this) {
      case PricingModel.onDemand:
        return 'On-Demand';
      case PricingModel.reserved1Year:
        return '1 Year Reserved';
      case PricingModel.reserved3Year:
        return '3 Year Reserved';
      case PricingModel.spotPreemptible:
        return 'Spot / Preemptible';
    }
  }

  double get discountFactor {
    switch (this) {
      case PricingModel.onDemand:
        return 1.0;
      case PricingModel.reserved1Year:
        return 0.62;
      case PricingModel.reserved3Year:
        return 0.40;
      case PricingModel.spotPreemptible:
        return 0.30;
    }
  }
}

enum UsagePattern {
  fullTime,
  businessHours,
  custom,
}

extension UsagePatternExt on UsagePattern {
  String get label {
    switch (this) {
      case UsagePattern.fullTime:
        return '24/7 (730 hrs/mo)';
      case UsagePattern.businessHours:
        return 'Business Hours (160 hrs/mo)';
      case UsagePattern.custom:
        return 'Custom Hours';
    }
  }

  double get hours {
    switch (this) {
      case UsagePattern.fullTime:
        return 730;
      case UsagePattern.businessHours:
        return 160;
      case UsagePattern.custom:
        return 0;
    }
  }
}

enum ComputeSize {
  small,
  medium,
  large,
  xlarge,
}

extension ComputeSizeExt on ComputeSize {
  String get label {
    switch (this) {
      case ComputeSize.small:
        return 'Small (2 vCPU / 4GB RAM)';
      case ComputeSize.medium:
        return 'Medium (4 vCPU / 8GB RAM)';
      case ComputeSize.large:
        return 'Large (8 vCPU / 16GB RAM)';
      case ComputeSize.xlarge:
        return 'XLarge (16 vCPU / 32GB RAM)';
    }
  }

  int get vcpu {
    switch (this) {
      case ComputeSize.small:
        return 2;
      case ComputeSize.medium:
        return 4;
      case ComputeSize.large:
        return 8;
      case ComputeSize.xlarge:
        return 16;
    }
  }

  int get ram {
    switch (this) {
      case ComputeSize.small:
        return 4;
      case ComputeSize.medium:
        return 8;
      case ComputeSize.large:
        return 16;
      case ComputeSize.xlarge:
        return 32;
    }
  }
}

enum OSType { linux, windows }

extension OSTypeExt on OSType {
  String get label {
    switch (this) {
      case OSType.linux:
        return 'Linux';
      case OSType.windows:
        return 'Windows';
    }
  }

  double get pricingMultiplier {
    switch (this) {
      case OSType.linux:
        return 1.0;
      case OSType.windows:
        return 1.46;
    }
  }
}

enum StorageType {
  standardSsd,
  hdd,
  archiveStorage,
}

extension StorageTypeExt on StorageType {
  String get label {
    switch (this) {
      case StorageType.standardSsd:
        return 'Standard SSD';
      case StorageType.hdd:
        return 'HDD';
      case StorageType.archiveStorage:
        return 'Archive Storage';
    }
  }
}

enum TrafficType {
  internetEgress,
  interRegion,
  sameRegion,
}

extension TrafficTypeExt on TrafficType {
  String get label {
    switch (this) {
      case TrafficType.internetEgress:
        return 'Internet Egress';
      case TrafficType.interRegion:
        return 'Inter-Region Traffic';
      case TrafficType.sameRegion:
        return 'Same Region';
    }
  }
}

enum CpuArchitecture { x86, arm }

extension CpuArchitectureExt on CpuArchitecture {
  String get label {
    switch (this) {
      case CpuArchitecture.x86:
        return 'x86';
      case CpuArchitecture.arm:
        return 'ARM (Graviton/Ampere)';
    }
  }
}

class CalculatorConfig {
  WorkloadType workloadType;
  CloudRegion region;
  PricingModel pricingModel;
  UsagePattern usagePattern;
  double customHours;
  ComputeSize computeSize;
  OSType osType;
  double storageGB;
  StorageType storageType;
  double dataTransferGB;
  TrafficType trafficType;

  // Advanced
  CpuArchitecture cpuArchitecture;
  bool autoScaling;
  double backupStorageGB;
  double additionalDataTransferGB;

  CalculatorConfig({
    this.workloadType = WorkloadType.webApplication,
    this.region = CloudRegion.usEast1,
    this.pricingModel = PricingModel.onDemand,
    this.usagePattern = UsagePattern.fullTime,
    this.customHours = 400,
    this.computeSize = ComputeSize.medium,
    this.osType = OSType.linux,
    this.storageGB = 100,
    this.storageType = StorageType.standardSsd,
    this.dataTransferGB = 50,
    this.trafficType = TrafficType.internetEgress,
    this.cpuArchitecture = CpuArchitecture.x86,
    this.autoScaling = false,
    this.backupStorageGB = 0,
    this.additionalDataTransferGB = 0,
  });

  double get effectiveHours {
    if (usagePattern == UsagePattern.custom) return customHours;
    return usagePattern.hours;
  }
}

class CloudEstimate {
  final String provider;
  final String instanceType;
  final double computeCost;
  final double storageCost;
  final double networkCost;
  final double totalMonthlyCost;
  final bool isCheapest;

  CloudEstimate({
    required this.provider,
    required this.instanceType,
    required this.computeCost,
    required this.storageCost,
    required this.networkCost,
    required this.totalMonthlyCost,
    this.isCheapest = false,
  });

  CloudEstimate copyWith({bool? isCheapest}) {
    return CloudEstimate(
      provider: provider,
      instanceType: instanceType,
      computeCost: computeCost,
      storageCost: storageCost,
      networkCost: networkCost,
      totalMonthlyCost: totalMonthlyCost,
      isCheapest: isCheapest ?? this.isCheapest,
    );
  }
}

class OptimizationInsight {
  final String icon;
  final String title;
  final String description;
  final double? savingsPercent;

  OptimizationInsight({
    required this.icon,
    required this.title,
    required this.description,
    this.savingsPercent,
  });
}
