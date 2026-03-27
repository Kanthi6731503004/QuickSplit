import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';
import 'package:quicksplit/core/widgets/people_count_selector.dart';

/// Bottom sheet that replaces the AddPeopleScreen route.
/// Fully tap-based: choose a count (2–8) and people are auto-named.
/// Tap any chip to rename. No text entry required on the happy path.
///
/// Pass [existingBillId] to open in edit mode (pre-fills from provider).
class QuickSetupSheet extends StatefulWidget {
  final String? existingBillId;

  const QuickSetupSheet({super.key, this.existingBillId});

  @override
  State<QuickSetupSheet> createState() => _QuickSetupSheetState();
}

class _QuickSetupSheetState extends State<QuickSetupSheet> {
  final _nameController = TextEditingController();

  DateTime _date = DateTime.now();
  List<String> _people = [];
  int? _selectedCount;
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
    _people = provider.people.map((p) => p.name).toList();
    if (_people.isNotEmpty) {
      _selectedCount = _people.length.clamp(2, 8);
    }
  }

  void _onCountSelected(int count) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCount = count;
      if (count > _people.length) {
        for (int i = _people.length + 1; i <= count; i++) {
          _people.add('Person $i');
        }
      } else {
        _people = _people.sublist(0, count);
      }
    });
  }

  Future<void> _renamePerson(int index) async {
    final ctrl = TextEditingController(text: _people[index]);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rename', style: GoogleFonts.dmSerifDisplay(fontSize: 18)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Enter name'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null && result.isNotEmpty) {
      setState(() => _people[index] = result);
    }
  }

  Future<void> _renameBill() async {
    final ctrl = TextEditingController(text: _nameController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Split name',
          style: GoogleFonts.dmSerifDisplay(fontSize: 18),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Pizza night'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null && result.isNotEmpty) {
      setState(() => _nameController.text = result);
    }
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
        final existing = provider.people.toList();
        final minLen = min(existing.length, _people.length);

        // Rename changed people
        for (int i = 0; i < minLen; i++) {
          if (existing[i].name != _people[i]) {
            await provider.updatePerson(existing[i].id, _people[i]);
          }
        }
        // Add new people
        for (int i = existing.length; i < _people.length; i++) {
          await provider.addPerson(_people[i]);
        }
        // Remove extra people (reverse order to keep indices stable)
        for (int i = existing.length - 1; i >= _people.length; i--) {
          await provider.removePerson(existing[i].id);
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
                // Handle bar
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ── Section 1: Bill name (tap pencil to rename) ──
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _nameController.text,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 20,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.pencil,
                        size: 16,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                      onPressed: _renameBill,
                      tooltip: 'Rename split',
                    ),
                  ],
                ),
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

                // ── Section 2: How many people? ──
                Text(
                  "HOW MANY PEOPLE?",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                PeopleCountSelector(
                  selectedCount: _selectedCount,
                  onCountSelected: _onCountSelected,
                ),

                // ── Person chips (tap to rename) ──
                if (_people.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'TAP A NAME TO RENAME',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _people.asMap().entries.map((entry) {
                      final index = entry.key;
                      final name = entry.value;
                      final color = AppTheme.getPersonColor(index);
                      return GestureDetector(
                        onTap: () => _renamePerson(index),
                        child: Container(
                          height: 36,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            border: Border.all(
                              color: color.withValues(alpha: 0.4),
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
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?',
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
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                LucideIcons.pencil,
                                size: 11,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Proceed button ──
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
                      : Text(
                          _isEditMode
                              ? 'Save changes'
                              : 'Start adding items →',
                        ),
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
