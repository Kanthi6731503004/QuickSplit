import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';
import 'package:quicksplit/core/widgets/food_preset_grid.dart';
import 'package:quicksplit/core/widgets/price_numpad.dart';

/// Bottom sheet for adding a new item — fully tap-based, no keyboard required.
/// Uses FoodPresetGrid for item name and PriceNumpad for price entry.
class AddItemSheet extends StatefulWidget {
  const AddItemSheet({super.key});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  String _itemName = '';
  String _priceValue = '';
  final Set<String> _selectedPeople = {};

  bool get _isValid =>
      _itemName.isNotEmpty && (double.tryParse(_priceValue) ?? 0) > 0;

  void _addItem() {
    if (!_isValid) return;
    HapticFeedback.lightImpact();
    context.read<BillProvider>().addItem(
      name: _itemName,
      price: double.parse(_priceValue),
      assignedUserIds:
          _selectedPeople.isNotEmpty ? _selectedPeople.toList() : null,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<BillProvider>();
    final dividerColor = isDark ? AppColors.borderDark : AppColors.border;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'Add item',
                style: GoogleFonts.dmSerifDisplay(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap a category, then set the price',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // ── Food preset grid ──
              FoodPresetGrid(
                selectedName: _itemName.isEmpty ? null : _itemName,
                onSelected: (name) => setState(() => _itemName = name),
              ),

              const SizedBox(height: 16),
              Divider(color: dividerColor, height: 1),
              const SizedBox(height: 16),

              // ── Price section ──
              Text(
                'PRICE',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              PriceDisplay(priceValue: _priceValue),
              const SizedBox(height: 12),
              PricePresetChips(
                priceValue: _priceValue,
                onSelected: (v) => setState(() => _priceValue = v),
              ),
              const SizedBox(height: 12),
              PriceNumpad(
                value: _priceValue,
                onChanged: (v) => setState(() => _priceValue = v),
              ),

              // ── Quick assign ──
              if (provider.people.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(color: dividerColor, height: 1),
                const SizedBox(height: 12),
                Text(
                  'ASSIGN TO',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: provider.people.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final person = entry.value;
                    final color = AppTheme.getPersonColor(idx);
                    final isSelected = _selectedPeople.contains(person.id);

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (isSelected) {
                            _selectedPeople.remove(person.id);
                          } else {
                            _selectedPeople.add(person.id);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.15)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? color
                                : (isDark
                                      ? AppColors.borderDark
                                      : AppColors.border),
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              backgroundColor: color,
                              radius: 10,
                              child: Text(
                                person.initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              person.name,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 4),
                              Icon(
                                LucideIcons.check,
                                size: 12,
                                color: color,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 20),

              // ── Add button ──
              ElevatedButton(
                onPressed: _isValid ? _addItem : null,
                child: const Text('Add item'),
              ),
            ],
          ),
        );
      },
    );
  }
}
