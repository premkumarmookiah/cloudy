import 'package:flutter/material.dart';
import '../models/calculator_models.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/provider_logo.dart';

class ResultsScreen extends StatelessWidget {
  final CalculatorConfig config;
  final List<CloudEstimate> estimates;
  final List<OptimizationInsight> insights;
  final String? dataSource;

  const ResultsScreen({
    super.key,
    required this.config,
    required this.estimates,
    required this.insights,
    this.dataSource,
  });

  @override
  Widget build(BuildContext context) {
    // Sort so cheapest is first
    final sorted = List<CloudEstimate>.from(estimates)
      ..sort((a, b) => a.totalMonthlyCost.compareTo(b.totalMonthlyCost));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildComparisonCards(sorted),
                      const SizedBox(height: 24),
                      _buildCostBreakdown(sorted),
                      const SizedBox(height: 24),
                      _buildInsights(),
                      const SizedBox(height: 24),
                      _buildConfigSummary(),
                      const SizedBox(height: 24),
                      _buildActions(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textSecondary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Cost Estimate',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined,
                color: AppColors.textSecondary, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String sourceLabel;
    Color sourceColor;
    IconData sourceIcon;
    switch (dataSource) {
      case 'gemini':
        sourceLabel = 'AI-Powered (Gemini)';
        sourceColor = AppColors.secondaryPurple;
        sourceIcon = Icons.auto_awesome;
        break;
      case 'fallback':
        sourceLabel = 'Fallback Pricing';
        sourceColor = AppColors.warning;
        sourceIcon = Icons.warning_amber_rounded;
        break;
      case 'offline':
        sourceLabel = 'Offline Estimate';
        sourceColor = AppColors.textMuted;
        sourceIcon = Icons.cloud_off;
        break;
      default:
        sourceLabel = 'Local Estimate';
        sourceColor = AppColors.accentBlue;
        sourceIcon = Icons.computer;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle,
                      color: AppColors.success, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Estimate Ready',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: sourceColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(sourceIcon, color: sourceColor, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    sourceLabel,
                    style: TextStyle(
                      color: sourceColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Cloud Cost Comparison',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${config.workloadType.label} • ${config.region.label}',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonCards(List<CloudEstimate> sorted) {
    return Column(
      children: sorted.map((estimate) {
        return GlassCard(
          highlighted: estimate.isCheapest,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  ProviderLogo(provider: estimate.provider, size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              estimate.provider,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (estimate.isCheapest) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color:
                                          AppColors.success.withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  'Best Price',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          estimate.instanceType,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${estimate.totalMonthlyCost.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: estimate.isCheapest
                              ? AppColors.success
                              : AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        '/ month',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (estimate.isCheapest) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success.withValues(alpha: 0.6),
                        AppColors.success.withValues(alpha: 0.0),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCostBreakdown(List<CloudEstimate> sorted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.pie_chart_outline,
                color: AppColors.secondaryPurple, size: 20),
            SizedBox(width: 8),
            Text(
              'Cost Breakdown',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header row
              const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('Category',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('AWS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.awsOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Azure',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.azureBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('GCP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.gcpMulti,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 12),
              _buildBreakdownRow(
                  'Compute',
                  sorted.map((e) => e.computeCost).toList(),
                  sorted.map((e) => e.provider).toList()),
              const SizedBox(height: 10),
              _buildBreakdownRow(
                  'Storage',
                  sorted.map((e) => e.storageCost).toList(),
                  sorted.map((e) => e.provider).toList()),
              const SizedBox(height: 10),
              _buildBreakdownRow(
                  'Network',
                  sorted.map((e) => e.networkCost).toList(),
                  sorted.map((e) => e.provider).toList()),
              const SizedBox(height: 12),
              const Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 12),
              _buildBreakdownRow(
                  'Total',
                  sorted.map((e) => e.totalMonthlyCost).toList(),
                  sorted.map((e) => e.provider).toList(),
                  isTotal: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(
      String label, List<double> values, List<String> providers,
      {bool isTotal = false}) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(
              color:
                  isTotal ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        ...List.generate(values.length, (i) {
          return Expanded(
            flex: 2,
            child: Text(
              '\$${values[i].toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isTotal
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: isTotal ? 14 : 13,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInsights() {
    if (insights.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.lightbulb_outline,
                color: AppColors.warning, size: 20),
            SizedBox(width: 8),
            Text(
              'Optimization Insights',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...insights.map((insight) => GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insight.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                insight.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (insight.savingsPercent != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '~${insight.savingsPercent!.round()}% save',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insight.description,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildConfigSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.settings_outlined,
                color: AppColors.textMuted, size: 20),
            SizedBox(width: 8),
            Text(
              'Configuration Summary',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _configRow('Workload', config.workloadType.label),
              _configRow('Region', config.region.label),
              _configRow('Pricing', config.pricingModel.label),
              _configRow('Usage', config.usagePattern == UsagePattern.custom
                  ? '${config.customHours.round()} hrs/mo'
                  : config.usagePattern.label),
              _configRow('Compute', config.computeSize.label),
              _configRow('OS', config.osType.label),
              _configRow('Storage', '${config.storageGB.round()} GB ${config.storageType.label}'),
              _configRow('Network', '${config.dataTransferGB.round()} GB ${config.trafficType.label}'),
              if (config.cpuArchitecture == CpuArchitecture.arm)
                _configRow('Architecture', 'ARM'),
              if (config.autoScaling)
                _configRow('Auto Scaling', 'Enabled'),
              if (config.backupStorageGB > 0)
                _configRow('Backup', '${config.backupStorageGB.round()} GB'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _configRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.pushNamed(context, '/calculator');
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Recalculate'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
            icon: const Icon(Icons.home_outlined, size: 18),
            label: const Text('Back to Home'),
          ),
        ),
      ],
    );
  }
}
