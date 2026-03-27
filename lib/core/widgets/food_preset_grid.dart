import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

/// A grid of common food category icons for tap-to-select item naming.
///
/// Selecting "Other" reveals a text field for custom names.
/// Keyboard never opens unless the user explicitly picks "Other".
class FoodPresetGrid extends StatefulWidget {
  final String? selectedName;
  final ValueChanged<String> onSelected;

  const FoodPresetGrid({
    super.key,
    this.selectedName,
    required this.onSelected,
  });

  @override
  State<FoodPresetGrid> createState() => _FoodPresetGridState();
}

class _FoodPresetGridState extends State<FoodPresetGrid> {
  static const _presets = [
    ('🍜', 'Noodles'),
    ('🍕', 'Pizza'),
    ('🍗', 'Chicken'),
    ('🥤', 'Drink'),
    ('🍚', 'Rice'),
    ('🍣', 'Sushi'),
    ('🍖', 'Meat'),
    ('🥗', 'Salad'),
    ('🍱', 'Set Meal'),
    ('✏️', 'Other'),
  ];

  final _customCtrl = TextEditingController();
  bool _showCustom = false;

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.88,
          children: _presets.map((preset) {
            final emoji = preset.$1;
            final label = preset.$2;
            final isOther = label == 'Other';
            final isSelected = isOther
                ? _showCustom
                : widget.selectedName == label;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                if (isOther) {
                  setState(() {
                    _showCustom = true;
                    _customCtrl.clear();
                  });
                  widget.onSelected('');
                } else {
                  setState(() => _showCustom = false);
                  widget.onSelected(label);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent
                        : (isDark ? AppColors.borderDark : AppColors.border),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.accent : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        if (_showCustom) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Type item name...',
              prefixIcon: Icon(Icons.edit_outlined, size: 18),
            ),
            onChanged: widget.onSelected,
          ),
        ],
      ],
    );
  }
}
