import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';
import 'package:quicksplit/core/widgets/step_progress_indicator.dart';

/// Screen to create a new bill (title + date).
class CreateBillScreen extends StatefulWidget {
  const CreateBillScreen({super.key});

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool get _isValid => _titleController.text.trim().isNotEmpty;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _createBill() async {
    if (!_isValid || _isCreating) return;

    setState(() => _isCreating = true);

    try {
      HapticFeedback.lightImpact();
      final bill = await context.read<BillProvider>().createBill(
        title: _titleController.text.trim(),
        date: _selectedDate,
      );

      if (mounted) {
        context.go('/bill/${bill.id}/people');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating bill: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Inline Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/'),
                      icon: const Icon(LucideIcons.arrowLeft, size: 22),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.filePlus,
                      size: 22,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Create Bill',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),

            // ── Step Indicator ──
            const SliverToBoxAdapter(
              child: StepProgressIndicator(currentStep: 1),
            ),

            // ── Form Content ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bill Name Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusCard,
                        ),
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkDivider
                              : AppTheme.divider,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.type,
                                size: 16,
                                color: AppTheme.primaryLight,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Bill Name',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _titleController,
                            autofocus: true,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Pizza Night',
                            ),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _createBill(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Date Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusCard,
                        ),
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkDivider
                              : AppTheme.divider,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.calendar,
                                size: 16,
                                color: AppTheme.primaryLight,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusCard,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.darkSurface
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusCard,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.calendarDays,
                                    size: 20,
                                    color: AppTheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat(
                                      'MMMM d, yyyy',
                                    ).format(_selectedDate),
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    LucideIcons.chevronDown,
                                    size: 18,
                                    color: isDark
                                        ? AppTheme.darkSubtleText
                                        : AppTheme.subtleText,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),

                    // Next Button
                    ElevatedButton(
                      onPressed: _isValid && !_isCreating ? _createBill : null,
                      child: _isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Next: Add People'),
                                const SizedBox(width: 8),
                                Icon(LucideIcons.arrowRight, size: 18),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
