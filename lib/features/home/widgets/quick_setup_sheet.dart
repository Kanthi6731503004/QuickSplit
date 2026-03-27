import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

/// Bottom sheet that replaces the AddPeopleScreen route.
/// Handles bill creation (name + date + people) in one inline step.
///
/// Pass [existingBillId] to open in edit mode (pre-filled, skips creation).
class QuickSetupSheet extends StatefulWidget {
  final String? existingBillId;

  const QuickSetupSheet({super.key, this.existingBillId});

  @override
  State<QuickSetupSheet> createState() => _QuickSetupSheetState();
}

class _QuickSetupSheetState extends State<QuickSetupSheet> {
  final _nameController = TextEditingController();
  final _addPersonController = TextEditingController();
  final _nameFocus = FocusNode();
  final _addPersonFocus = FocusNode();

  DateTime _date = DateTime.now();
  final List<String> _people = [];
  bool _isLoading = false;

  bool get _isEditMode => widget.existingBillId != null;

  bool get _canProceed =>
      _nameController.text.trim().isNotEmpty && _people.length >= 2;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    if (_isEditMode) {
      _prefillFromProvider();
    } else {
      _nameController.text = _defaultBillName();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addPersonController.dispose();
    _nameFocus.dispose();
    _addPersonFocus.dispose();
    super.dispose();
  }

  String _defaultBillName() {
    final hour = DateTime.now().hour;
    final day = DateFormat('EEEE').format(DateTime.now());
    if (hour < 11) return '$day Breakfast';
    if (hour < 15) return '$day Lunch';
    if (hour < 18) return '$day Coffee';
    return '$day Dinner';
  }

  void _prefillFromProvider() {
    final provider = context.read<BillProvider>();
    final bill = provider.currentBill;
    if (bill != null) {
      _nameController.text = bill.title;
      _date = bill.date;
    }
    for (final p in provider.people) {
      _people.add(p.name);
    }
  }

  void _addPerson() {
    final name = _addPersonController.text.trim();
    if (name.isEmpty) return;
    if (_people.any((p) => p.toLowerCase() == name.toLowerCase())) {
      _addPersonController.clear();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _people.add(name));
    _addPersonController.clear();
    _addPersonFocus.requestFocus();
  }

  void _removePerson(int index) {
    HapticFeedback.selectionClick();
    setState(() => _people.removeAt(index));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _proceed() async {
    if (!_canProceed || _isLoading) return;
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    final provider = context.read<BillProvider>();

    try {
      if (_isEditMode) {
        // Edit mode: sync people additions/removals
        final existing = provider.people.map((p) => p.name).toList();
        for (final name in _people) {
          if (!existing.contains(name)) {
            await provider.addPerson(name);
          }
        }
        for (final p in provider.people) {
          if (!_people.contains(p.name)) {
            await provider.removePerson(p.id);
          }
        }
        if (mounted) Navigator.pop(context);
      } else {
        final bill = await provider.createBill(
          title: _nameController.text.trim(),
          date: _date,
        );
        for (final name in _people) {
          await provider.addPerson(name);
        }
        if (mounted) {
          Navigator.pop(context);
          context.push('/bill/${bill.id}');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surface;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          color: bgColor,
          child: SingleChildScrollView(
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
                // ── Section 1: Bill details ──
                Text(
                  'SPLIT NAME',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 20,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Pizza night',
                    hintStyle: GoogleFonts.dmSerifDisplay(
                      fontSize: 20,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMuted,
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _addPersonFocus.requestFocus(),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickDate,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isToday(_date)
                            ? 'Today, ${DateFormat('MMMM d').format(_date)}'
                            : DateFormat('EEEE, MMMM d').format(_date),
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Divider(color: borderColor, height: 1),
                const SizedBox(height: 20),

                // ── Section 2: People ──
                Row(
                  children: [
                    Text(
                      "WHO'S SPLITTING?",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_people.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceAlt2
                              : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '${_people.length}',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Person chips
                if (_people.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _people.asMap().entries.map((entry) {
                      final index = entry.key;
                      final name = entry.value;
                      final color = AppTheme.getPersonColor(index);
                      return _PersonChip(
                        name: name,
                        color: color,
                        isDark: isDark,
                        onRemove: () => _removePerson(index),
                      );
                    }).toList(),
                  ),

                if (_people.isNotEmpty) const SizedBox(height: 12),

                // Add person row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addPersonController,
                        focusNode: _addPersonFocus,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add a name…',
                          hintStyle: GoogleFonts.dmSans(
                            fontSize: 15,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMuted,
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addPerson(),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _addPerson,
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.surfaceAlt2
                            : AppColors.surfaceAlt,
                        foregroundColor: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusButton,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Add',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                if (_people.length == 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Add at least one more person',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMuted,
                      ),
                    ),
                  ),

                const SizedBox(height: 28),

                // ── Proceed Button ──
                ElevatedButton(
                  onPressed: _canProceed ? _proceed : null,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEditMode ? 'Save changes' : 'Start adding items →'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _PersonChip extends StatelessWidget {
  final String name;
  final Color color;
  final bool isDark;
  final VoidCallback onRemove;

  const _PersonChip({
    required this.name,
    required this.color,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 10,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              LucideIcons.x,
              size: 14,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
