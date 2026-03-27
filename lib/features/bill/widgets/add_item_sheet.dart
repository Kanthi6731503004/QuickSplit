import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

/// Bottom sheet for adding a new item — keyboard-friendly, clean design.
class AddItemSheet extends StatefulWidget {
  const AddItemSheet({super.key});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _nameFocus = FocusNode();
  final _priceFocus = FocusNode();
  final Set<String> _selectedPeople = {};

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _priceController.text.isNotEmpty &&
      (double.tryParse(_priceController.text) ?? 0) > 0;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _nameFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  void _addItem() {
    if (!_isValid) return;
    HapticFeedback.lightImpact();
    context.read<BillProvider>().addItem(
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text),
      assignedUserIds:
          _selectedPeople.isNotEmpty ? _selectedPeople.toList() : null,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<BillProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return SingleChildScrollView(
          controller: scrollCtrl,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add item',
                style: GoogleFonts.dmSerifDisplay(fontSize: 20),
              ),
              const SizedBox(height: 20),

              // ── Name field ──
              TextField(
                controller: _nameController,
                focusNode: _nameFocus,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'What did you order?',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 16,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMuted,
                  ),
                ),
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _priceFocus.requestFocus(),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 16),

              // ── Price field ──
              TextField(
                controller: _priceController,
                focusNode: _priceFocus,
                style: AppTheme.amountStyle(
                  size: 20,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: Text(
                      '฿',
                      style: AppTheme.amountStyle(
                        size: 20,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 24, minHeight: 0),
                  hintText: '0.00',
                  hintStyle: AppTheme.amountStyle(
                    size: 20,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMuted,
                  ),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addItem(),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 20),

              // ── Quick assign ──
              if (provider.people.isNotEmpty) ...[
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10),
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
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 8),

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
