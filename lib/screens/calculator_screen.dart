import 'package:flutter/material.dart';
import '../models/calculator_models.dart';
import '../services/pricing_service.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/step_indicator.dart';
import 'results_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  final _config = CalculatorConfig();
  final _pageController = PageController();
  final _aiDescriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isAiLoading = false;
  bool _useBackend = true; // true = backend+Gemini, false = local-only
  bool _backendAvailable = false;
  String? _aiSource; // 'gemini' or 'fallback'

  final _steps = ['Workload', 'Compute', 'Storage', 'Network', 'Results'];

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    final healthy = await ApiService.checkHealth();
    if (mounted) {
      setState(() {
        _backendAvailable = healthy;
        _useBackend = healthy;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      if (_currentStep == 3) {
        // Going to Results step — calculate
        _goToResults();
        return;
      }
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _goToResults() async {
    setState(() => _isLoading = true);

    List<CloudEstimate> estimates;
    List<OptimizationInsight> insights;
    String? dataSource;

    if (_useBackend && _backendAvailable) {
      // Try backend (Gemini-powered)
      final result = await ApiService.calculate(_config);
      if (result.success) {
        estimates = result.toCloudEstimates();
        insights = result.toOptimizationInsights();
        dataSource = result.source;
      } else {
        // Backend call failed, try local fallback from backend
        final localResult = await ApiService.calculateLocal(_config);
        if (localResult.success) {
          estimates = localResult.toCloudEstimates();
          insights = localResult.toOptimizationInsights();
          dataSource = 'local-fallback';
        } else {
          // All backend calls failed, use client-side calculation
          estimates = PricingService.calculateEstimates(_config);
          insights = PricingService.generateInsights(_config, estimates);
          dataSource = 'offline';
        }
      }
    } else {
      // Local-only mode
      estimates = PricingService.calculateEstimates(_config);
      insights = PricingService.generateInsights(_config, estimates);
      dataSource = 'offline';
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          config: _config,
          estimates: estimates,
          insights: insights,
          dataSource: dataSource,
        ),
      ),
    );
  }

  /// AI: Convert natural language to infra config
  Future<void> _handleAiEstimate() async {
    final description = _aiDescriptionController.text.trim();
    if (description.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe your workload (at least 5 characters).'),
          backgroundColor: AppColors.cardBg,
        ),
      );
      return;
    }

    setState(() => _isAiLoading = true);
    final result = await ApiService.getAiEstimate(description);
    if (!mounted) return;
    setState(() => _isAiLoading = false);

    if (result.success && result.config != null) {
      final ai = result.config!;
      setState(() {
        _aiSource = result.source;
        // Map AI vcpu/ram to closest ComputeSize
        if (ai.vcpu <= 2) {
          _config.computeSize = ComputeSize.small;
        } else if (ai.vcpu <= 4) {
          _config.computeSize = ComputeSize.medium;
        } else if (ai.vcpu <= 8) {
          _config.computeSize = ComputeSize.large;
        } else {
          _config.computeSize = ComputeSize.xlarge;
        }

        // Storage
        _config.storageGB = ai.storageGb.toDouble().clamp(10, 2000);

        // Network
        _config.dataTransferGB = ai.networkGb.toDouble().clamp(0, 1000);

        // Region
        final regionMap = {
          'us-east-1': CloudRegion.usEast1,
          'ap-south-1': CloudRegion.apSouth1,
          'eu-central-1': CloudRegion.euCentral1,
          'us-west-2': CloudRegion.usWest2,
          'ap-southeast-1': CloudRegion.apSoutheast1,
        };
        _config.region = regionMap[ai.region] ?? CloudRegion.usEast1;

        // OS
        _config.osType =
            ai.os == 'windows' ? OSType.windows : OSType.linux;

        // Pricing model
        final pmMap = {
          'on-demand': PricingModel.onDemand,
          '1-year-reserved': PricingModel.reserved1Year,
          '3-year-reserved': PricingModel.reserved3Year,
          'spot': PricingModel.spotPreemptible,
        };
        _config.pricingModel =
            pmMap[ai.pricingModel] ?? PricingModel.onDemand;

        // Workload type
        final wtMap = {
          'web_application': WorkloadType.webApplication,
          'database_server': WorkloadType.databaseServer,
          'ai_ml_workload': WorkloadType.aiMlWorkload,
          'dev_environment': WorkloadType.devEnvironment,
          'custom_infrastructure': WorkloadType.customInfrastructure,
        };
        _config.workloadType =
            wtMap[ai.workloadType] ?? WorkloadType.webApplication;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.secondaryPurple, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI configured: ${ai.vcpu} vCPU / ${ai.ramGb}GB RAM — ${result.source}',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.cardBg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI estimate failed: ${result.errorMessage ?? "Unknown error"}'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _aiDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 8),
              StepIndicator(currentStep: _currentStep, steps: _steps),
              const SizedBox(height: 8),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildWorkloadStep(),
                    _buildComputeStep(),
                    _buildStorageStep(),
                    _buildNetworkStep(),
                    const SizedBox(), // placeholder, we navigate to results screen
                  ],
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
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
              'Cost Calculator',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Backend/AI mode toggle
          GestureDetector(
            onTap: () {
              if (_backendAvailable) {
                setState(() => _useBackend = !_useBackend);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _useBackend && _backendAvailable
                    ? AppColors.accentBlue.withValues(alpha: 0.15)
                    : AppColors.inputBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _useBackend && _backendAvailable
                      ? AppColors.accentBlue.withValues(alpha: 0.4)
                      : AppColors.inputBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _useBackend && _backendAvailable
                        ? Icons.auto_awesome
                        : Icons.cloud_off,
                    size: 14,
                    color: _useBackend && _backendAvailable
                        ? AppColors.accentBlue
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _useBackend && _backendAvailable ? 'AI' : 'Local',
                    style: TextStyle(
                      color: _useBackend && _backendAvailable
                          ? AppColors.accentBlue
                          : AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _prevStep,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _nextStep,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _currentStep == 3
                          ? Icons.calculate
                          : Icons.arrow_forward,
                      size: 18,
                    ),
              label: Text(
                _isLoading
                    ? 'Calculating...'
                    : _currentStep == 3
                        ? 'Calculate Cost'
                        : 'Continue',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STEP 1: WORKLOAD ====================

  Widget _buildWorkloadStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── AI WORKLOAD INTERPRETER ──
          if (_backendAvailable) ...[
            GlassCard(
              highlighted: true,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: AppColors.secondaryPurple, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'AI Infrastructure Estimator',
                        style: TextStyle(
                          color: AppColors.secondaryPurple,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Describe your workload in plain English and let Gemini configure everything automatically.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _aiDescriptionController,
                    maxLines: 3,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText:
                          'e.g. "I want to run a small ecommerce website with 10k monthly users"',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: AppColors.primaryDark.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.accentBlue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _isAiLoading ? null : _handleAiEstimate,
                      icon: _isAiLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome, size: 16),
                      label: Text(
                          _isAiLoading ? 'Analyzing...' : 'Generate Config'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryPurple,
                        foregroundColor: AppColors.primaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  if (_aiSource != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.success, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Config auto-filled via $_aiSource',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.inputBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR select manually',
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.inputBorder)),
              ],
            ),
            const SizedBox(height: 16),
          ],
          // ── MANUAL WORKLOAD SELECTION ──
          const Text(
            'Select Workload Type',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose the type of infrastructure you want to estimate.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ...WorkloadType.values.map((type) => GlassCard(
                highlighted: _config.workloadType == type,
                onTap: () => setState(() => _config.workloadType = type),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(type.icon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.label,
                            style: TextStyle(
                              color: _config.workloadType == type
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            type.description,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_config.workloadType == type)
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.accentBlue,
                        size: 22,
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ==================== STEP 2: COMPUTE ====================

  Widget _buildComputeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Compute Configuration',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Configure your virtual machine specifications.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Region
          _buildLabel('Region'),
          _buildDropdown<CloudRegion>(
            value: _config.region,
            items: CloudRegion.values,
            labelFn: (r) => '${r.label} — ${r.code}',
            onChanged: (v) => setState(() => _config.region = v!),
          ),
          const SizedBox(height: 16),

          // Pricing Model
          _buildLabel('Pricing Model'),
          _buildDropdown<PricingModel>(
            value: _config.pricingModel,
            items: PricingModel.values,
            labelFn: (p) => p.label,
            onChanged: (v) => setState(() => _config.pricingModel = v!),
          ),
          const SizedBox(height: 16),

          // Usage Pattern
          _buildLabel('Usage Pattern'),
          _buildDropdown<UsagePattern>(
            value: _config.usagePattern,
            items: UsagePattern.values,
            labelFn: (u) => u.label,
            onChanged: (v) => setState(() => _config.usagePattern = v!),
          ),
          if (_config.usagePattern == UsagePattern.custom) ...[
            const SizedBox(height: 10),
            _buildLabel('Custom Hours / Month'),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              margin: EdgeInsets.zero,
              child: Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _config.customHours,
                      min: 10,
                      max: 730,
                      divisions: 72,
                      label: '${_config.customHours.round()} hrs',
                      onChanged: (v) =>
                          setState(() => _config.customHours = v),
                    ),
                  ),
                  Text(
                    '${_config.customHours.round()} hrs',
                    style: const TextStyle(
                      color: AppColors.secondaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Compute Size
          _buildLabel('Compute Size'),
          ...ComputeSize.values.map((size) => GlassCard(
                highlighted: _config.computeSize == size,
                onTap: () => setState(() => _config.computeSize = size),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _config.computeSize == size
                            ? AppColors.accentBlue.withValues(alpha: 0.2)
                            : AppColors.inputBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${size.vcpu}',
                          style: TextStyle(
                            color: _config.computeSize == size
                                ? AppColors.accentBlue
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            size.label,
                            style: TextStyle(
                              color: _config.computeSize == size
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_config.computeSize == size)
                      const Icon(Icons.check_circle,
                          color: AppColors.accentBlue, size: 20),
                  ],
                ),
              )),
          const SizedBox(height: 16),

          // OS Selection
          _buildLabel('Operating System'),
          Row(
            children: OSType.values.map((os) {
              final selected = _config.osType == os;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _config.osType = os),
                  child: Container(
                    margin: EdgeInsets.only(
                        right: os == OSType.linux ? 8 : 0,
                        left: os == OSType.windows ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accentBlue.withValues(alpha: 0.12)
                          : AppColors.inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.accentBlue
                            : AppColors.inputBorder,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          os == OSType.linux
                              ? Icons.terminal
                              : Icons.window,
                          color: selected
                              ? AppColors.accentBlue
                              : AppColors.textMuted,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          os.label,
                          style: TextStyle(
                            color: selected
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==================== STEP 3: STORAGE ====================

  Widget _buildStorageStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Storage Configuration',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Configure your storage requirements.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildLabel('Storage Size'),
          GlassCard(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GB',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_config.storageGB.round()} GB',
                        style: const TextStyle(
                          color: AppColors.accentBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _config.storageGB,
                  min: 10,
                  max: 2000,
                  divisions: 199,
                  label: '${_config.storageGB.round()} GB',
                  onChanged: (v) => setState(() => _config.storageGB = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('10 GB',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                    Text('2 TB',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildLabel('Storage Type'),
          ...StorageType.values.map((type) => GlassCard(
                highlighted: _config.storageType == type,
                onTap: () => setState(() => _config.storageType = type),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      type == StorageType.standardSsd
                          ? Icons.flash_on
                          : type == StorageType.hdd
                              ? Icons.storage
                              : Icons.archive,
                      color: _config.storageType == type
                          ? AppColors.accentBlue
                          : AppColors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        type.label,
                        style: TextStyle(
                          color: _config.storageType == type
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_config.storageType == type)
                      const Icon(Icons.check_circle,
                          color: AppColors.accentBlue, size: 20),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ==================== STEP 4: NETWORK ====================

  Widget _buildNetworkStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Network Configuration',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Configure your network and data transfer needs.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildLabel('Data Transfer Out'),
          GlassCard(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GB',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_config.dataTransferGB.round()} GB',
                        style: const TextStyle(
                          color: AppColors.accentBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _config.dataTransferGB,
                  min: 0,
                  max: 1000,
                  divisions: 100,
                  label: '${_config.dataTransferGB.round()} GB',
                  onChanged: (v) =>
                      setState(() => _config.dataTransferGB = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('0 GB',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                    Text('1 TB',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildLabel('Traffic Type'),
          ...TrafficType.values.map((type) => GlassCard(
                highlighted: _config.trafficType == type,
                onTap: () => setState(() => _config.trafficType = type),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      type == TrafficType.internetEgress
                          ? Icons.public
                          : type == TrafficType.interRegion
                              ? Icons.swap_horiz
                              : Icons.near_me,
                      color: _config.trafficType == type
                          ? AppColors.accentBlue
                          : AppColors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        type.label,
                        style: TextStyle(
                          color: _config.trafficType == type
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_config.trafficType == type)
                      const Icon(Icons.check_circle,
                          color: AppColors.accentBlue, size: 20),
                  ],
                ),
              )),

          // Advanced Settings
          const SizedBox(height: 24),
          _buildAdvancedSettings(),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      collapsedIconColor: AppColors.textMuted,
      iconColor: AppColors.accentBlue,
      title: const Row(
        children: [
          Icon(Icons.tune, color: AppColors.secondaryPurple, size: 18),
          SizedBox(width: 8),
          Text(
            'Advanced Settings',
            style: TextStyle(
              color: AppColors.secondaryPurple,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      children: [
        const SizedBox(height: 8),
        // CPU Architecture
        _buildLabel('CPU Architecture'),
        Row(
          children: CpuArchitecture.values.map((arch) {
            final selected = _config.cpuArchitecture == arch;
            return Expanded(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _config.cpuArchitecture = arch),
                child: Container(
                  margin: EdgeInsets.only(
                      right: arch == CpuArchitecture.x86 ? 6 : 0,
                      left: arch == CpuArchitecture.arm ? 6 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accentBlue.withValues(alpha: 0.12)
                        : AppColors.inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppColors.accentBlue
                          : AppColors.inputBorder,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      arch.label,
                      style: TextStyle(
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Auto Scaling
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Auto Scaling',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Switch(
                value: _config.autoScaling,
                onChanged: (v) =>
                    setState(() => _config.autoScaling = v),
                activeThumbColor: AppColors.accentBlue,
              ),
            ],
          ),
        ),
        // Backup Storage
        _buildLabel('Backup Storage (GB)'),
        GlassCard(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Slider(
                  value: _config.backupStorageGB,
                  min: 0,
                  max: 500,
                  divisions: 50,
                  onChanged: (v) =>
                      setState(() => _config.backupStorageGB = v),
                ),
              ),
              Text(
                '${_config.backupStorageGB.round()} GB',
                style: const TextStyle(
                  color: AppColors.secondaryPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Additional Data Transfer
        _buildLabel('Additional Data Transfer (GB)'),
        GlassCard(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Expanded(
                child: Slider(
                  value: _config.additionalDataTransferGB,
                  min: 0,
                  max: 500,
                  divisions: 50,
                  onChanged: (v) => setState(
                      () => _config.additionalDataTransferGB = v),
                ),
              ),
              Text(
                '${_config.additionalDataTransferGB.round()} GB',
                style: const TextStyle(
                  color: AppColors.secondaryPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== HELPERS ====================

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelFn,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppColors.surfaceLight,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        icon: const Icon(Icons.keyboard_arrow_down,
            color: AppColors.textMuted),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    labelFn(item),
                    style: const TextStyle(fontSize: 14),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
