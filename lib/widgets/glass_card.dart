import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool highlighted;
  final VoidCallback? onTap;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.highlighted = false,
    this.onTap,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.only(bottom: 12),
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: highlighted
                ? [
                    AppColors.accentBlue.withValues(alpha: 0.15),
                    AppColors.secondaryPurple.withValues(alpha: 0.08),
                  ]
                : [
                    AppColors.cardBg.withValues(alpha: 0.9),
                    AppColors.surface.withValues(alpha: 0.7),
                  ],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: highlighted
                ? AppColors.accentBlue.withValues(alpha: 0.4)
                : AppColors.cardBorder,
            width: highlighted ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: highlighted
                  ? AppColors.accentBlue.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
