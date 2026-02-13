import 'package:flutter/material.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

/// A linear step progress indicator for the bill creation flow.
///
/// Steps: 1=Create, 2=People, 3=Items, 4=Tax, 5=Summary
class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 5,
  });

  static const List<String> stepLabels = [
    'Create',
    'People',
    'Items',
    'Tax & Tip',
    'Summary',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface
            : AppTheme.primary.withValues(alpha: 0.05),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: currentStep / totalSteps),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 4,
                  backgroundColor: isDark
                      ? AppTheme.darkDivider
                      : AppTheme.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryLight,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          // Step labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (i) {
              final isActive = i < currentStep;
              final isCurrent = i == currentStep - 1;
              return Expanded(
                child: Text(
                  stepLabels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                    color: isActive
                        ? AppTheme.primaryLight
                        : (isDark
                              ? AppTheme.darkSubtleText
                              : AppTheme.subtleText),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
