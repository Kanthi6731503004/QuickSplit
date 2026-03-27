import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

/// A row of tappable number buttons (2–8) to set how many people are splitting.
class PeopleCountSelector extends StatelessWidget {
  final int? selectedCount;
  final ValueChanged<int> onCountSelected;

  const PeopleCountSelector({
    super.key,
    required this.selectedCount,
    required this.onCountSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: List.generate(7, (i) {
        final count = i + 2; // 2 through 8
        final isSelected = selectedCount == count;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onCountSelected(count);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent
                      : (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent
                        : (isDark ? AppColors.borderDark : AppColors.border),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
