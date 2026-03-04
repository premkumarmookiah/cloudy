import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: steps.length,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemBuilder: (context, index) {
          final isActive = index == currentStep;
          final isCompleted = index < currentStep;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isActive || isCompleted
                            ? AppColors.purpleGradient
                            : null,
                        color: isActive || isCompleted
                            ? null
                            : AppColors.inputBg,
                        border: Border.all(
                          color: isActive
                              ? AppColors.accentBlue
                              : isCompleted
                                  ? AppColors.secondaryPurple
                                  : AppColors.inputBorder,
                          width: isActive ? 2 : 1,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.accentBlue.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.textMuted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[index],
                      style: TextStyle(
                        color: isActive
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 24,
                    height: 1.5,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.accentBlue
                          : AppColors.inputBorder,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
