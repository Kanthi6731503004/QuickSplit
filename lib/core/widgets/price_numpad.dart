import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

/// Quick-select price presets shared by all item entry sheets.
const List<int> kPricePresets = [50, 80, 100, 120, 150, 180, 200, 250, 300, 400, 500];

/// A custom numeric keypad for entering prices without opening the system keyboard.
///
/// Handles decimal input, backspace, and enforces a maximum of 2 decimal places.
class PriceNumpad extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const PriceNumpad({super.key, required this.value, required this.onChanged});

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  void _handleKey(String key) {
    String next = value;

    if (key == '⌫') {
      if (next.isEmpty) return;
      next = next.substring(0, next.length - 1);
    } else if (key == '.') {
      if (next.contains('.')) return;
      next = next.isEmpty ? '0.' : '$next.';
    } else {
      // digit
      if (next == '0') {
        next = key;
      } else {
        final dotIdx = next.indexOf('.');
        if (dotIdx != -1 && next.length - dotIdx > 2) return; // cap 2 decimals
        next = '$next$key';
      }
    }

    HapticFeedback.lightImpact();
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bg;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Column(
      children: _rows.map((row) {
        return Row(
          children: row.map((key) {
            final isBackspace = key == '⌫';
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Material(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _handleKey(key),
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: isBackspace
                          ? Icon(
                              Icons.backspace_outlined,
                              size: 20,
                              color: AppColors.textSecondary,
                            )
                          : Text(
                              key,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

/// Displays the current price value with a ฿ prefix.
/// Uses an animated border highlight when a value is entered.
class PriceDisplay extends StatelessWidget {
  final String priceValue;

  const PriceDisplay({super.key, required this.priceValue});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = priceValue.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: hasValue
              ? AppColors.accent
              : (isDark ? AppColors.borderDark : AppColors.border),
          width: hasValue ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '฿',
            style: AppTheme.amountStyle(
              size: 20,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            priceValue.isEmpty ? '0.00' : priceValue,
            style: AppTheme.amountStyle(
              size: 28,
              color: priceValue.isEmpty
                  ? (isDark ? AppColors.textMutedDark : AppColors.textMuted)
                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal scrollable row of quick-select price chips.
class PricePresetChips extends StatelessWidget {
  final String priceValue;
  final ValueChanged<String> onSelected;

  const PricePresetChips({
    super.key,
    required this.priceValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: kPricePresets.map((preset) {
          final isSelected = priceValue == preset.toString();
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('฿$preset'),
              selected: isSelected,
              selectedColor: AppColors.accent.withValues(alpha: 0.2),
              side: BorderSide(
                color: isSelected
                    ? AppColors.accent
                    : (isDark ? AppColors.borderDark : AppColors.border),
              ),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.accent : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              onSelected: (_) {
                HapticFeedback.selectionClick();
                onSelected(preset.toString());
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
