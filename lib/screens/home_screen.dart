import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(child: _buildAppBar(context)),
              // Hero Section
              SliverToBoxAdapter(child: _buildHeroSection(context)),
              // Features
              SliverToBoxAdapter(child: _buildFeaturesSection(context)),
              // Providers
              SliverToBoxAdapter(child: _buildProvidersSection(context)),
              // Footer
              SliverToBoxAdapter(child: _buildFooter(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.purpleGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'cloud.ly',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const Spacer(),
          // Start Estimating button
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/calculator'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              child: const Text('Start Estimating'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      child: Column(
        children: [
          // Pill badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome,
                    size: 14, color: AppColors.secondaryPurple),
                SizedBox(width: 6),
                Text(
                  'Cloud Cost Calculator',
                  style: TextStyle(
                    color: AppColors.secondaryPurple,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, AppColors.secondaryPurple],
            ).createShader(bounds),
            child: const Text(
              'Estimate and Compare\nCloud Infrastructure\nCosts Instantly',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.15,
                letterSpacing: -1.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Compare AWS, Azure and Google Cloud pricing for compute, storage and network workloads.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/calculator'),
                  icon: const Icon(Icons.calculate_outlined, size: 20),
                  label: const Text('Start Cost Calculation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/example'),
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  label: const Text('View Example Estimate'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat('3', 'Cloud\nProviders'),
              Container(
                width: 1,
                height: 40,
                color: AppColors.inputBorder,
              ),
              _buildStat('5', 'Workload\nTypes'),
              Container(
                width: 1,
                height: 40,
                color: AppColors.inputBorder,
              ),
              _buildStat('∞', 'Config\nOptions'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.secondaryPurple,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    final features = [
      {
        'icon': Icons.compare_arrows,
        'title': 'Multi-Cloud Compare',
        'desc': 'Side-by-side pricing across AWS, Azure and GCP.',
      },
      {
        'icon': Icons.tune,
        'title': 'Fine-Grained Config',
        'desc': 'Compute, storage, network, OS, architecture and more.',
      },
      {
        'icon': Icons.lightbulb_outline,
        'title': 'Smart Insights',
        'desc': 'AI-powered optimization recommendations.',
      },
      {
        'icon': Icons.speed,
        'title': 'Instant Results',
        'desc': 'Real-time cost estimation as you configure.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          const Text(
            'Why cloud.ly?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          ...features.map((f) => GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        f['icon'] as IconData,
                        color: AppColors.accentBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f['title'] as String,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            f['desc'] as String,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
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
      ),
    );
  }

  Widget _buildProvidersSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          const Text(
            'Supported Providers',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildProviderChip('AWS', AppColors.awsOrange, Icons.cloud),
              const SizedBox(width: 10),
              _buildProviderChip(
                  'Azure', AppColors.azureBlue, Icons.cloud_queue),
              const SizedBox(width: 10),
              _buildProviderChip(
                  'GCP', AppColors.gcpMulti, Icons.cloud_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderChip(String label, Color color, IconData icon) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _footerLink('About', () => Navigator.pushNamed(context, '/about')),
              const SizedBox(width: 20),
              _footerLink('Calculator', () => Navigator.pushNamed(context, '/calculator')),
              const SizedBox(width: 20),
              _footerLink('GitHub', () {}),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Cost estimates are approximate and for educational purposes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '© 2026 cloud.ly — All rights reserved',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
