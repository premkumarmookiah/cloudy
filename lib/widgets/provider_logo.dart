import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ProviderLogo extends StatelessWidget {
  final String provider;
  final double size;

  const ProviderLogo({super.key, required this.provider, this.size = 40});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (provider) {
      case 'AWS':
        color = AppColors.awsOrange;
        icon = Icons.cloud;
        break;
      case 'Azure':
        color = AppColors.azureBlue;
        icon = Icons.cloud_queue;
        break;
      case 'GCP':
        color = AppColors.gcpMulti;
        icon = Icons.cloud_outlined;
        break;
      default:
        color = AppColors.textMuted;
        icon = Icons.cloud;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }

  static String getFullName(String provider) {
    switch (provider) {
      case 'AWS':
        return 'Amazon Web Services';
      case 'Azure':
        return 'Microsoft Azure';
      case 'GCP':
        return 'Google Cloud Platform';
      default:
        return provider;
    }
  }
}
