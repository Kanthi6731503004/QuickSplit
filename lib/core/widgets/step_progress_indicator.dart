import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

/// A pill/dot step progress indicator for the bill creation flow.
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
    'Tax',
    'Summary',
  ];

  static const List<IconData> stepIcons = [
    LucideIcons.filePlus,
    LucideIcons.users,
    LucideIcons.utensils,
    LucideIcons.percent,
    LucideIcons.checkCircle,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (i) {
          // Even indexes are steps, odd indexes are connectors
          if (i.isOdd) {
            final stepBefore = (i ~/ 2) + 1;
            final isCompleted = stepBefore < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.primaryLight
                      : (isDark ? AppTheme.darkDivider : AppTheme.divider),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }

          final stepIndex = i ~/ 2;
          final stepNum = stepIndex + 1;
          final isCompleted = stepNum < currentStep;
          final isCurrent = stepNum == currentStep;
          final isActive = isCompleted || isCurrent;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: isCurrent ? 36 : 28,
                height: isCurrent ? 36 : 28,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.primaryLight
                      : isCurrent
                      ? AppTheme.primary
                      : (isDark ? AppTheme.darkCard : const Color(0xFFF0F0F0)),
                  shape: BoxShape.circle,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isCompleted ? LucideIcons.check : stepIcons[stepIndex],
                  size: isCurrent ? 16 : 13,
                  color: isActive
                      ? Colors.white
                      : (isDark
                            ? AppTheme.darkSubtleText
                            : AppTheme.subtleText),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stepLabels[stepIndex],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? (isCurrent ? AppTheme.primary : AppTheme.primaryLight)
                      : (isDark
                            ? AppTheme.darkSubtleText
                            : AppTheme.subtleText),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
