import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';
import 'package:quicksplit/core/widgets/step_progress_indicator.dart';

/// Final summary screen showing the complete breakdown per person.
/// Features: gradient header card, color-coded left borders, animated number
/// reveal, and confetti on bill close.
class SummaryScreen extends StatefulWidget {
  final String billId;
  const SummaryScreen({super.key, required this.billId});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _shareText(BuildContext context) {
    final provider = context.read<BillProvider>();
    final text = provider.generateShareText();
    SharePlus.instance.share(ShareParams(text: text));
  }

  void _copyText(BuildContext context) {
    final provider = context.read<BillProvider>();
    final text = provider.generateShareText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
  }

  void _closeBill(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Bill'),
        content: const Text(
          'Mark this bill as complete? You can still view it in history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              final provider = context.read<BillProvider>();
              final nav = GoRouter.of(context);
              Navigator.pop(ctx);
              _confettiController.play();
              HapticFeedback.heavyImpact();
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (!mounted) return;
                provider.closeBill();
                nav.go('/');
              });
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Close Bill'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Consumer<BillProvider>(
          builder: (context, provider, _) {
            final bill = provider.currentBill;
            if (bill == null) {
              return const Scaffold(
                body: Center(child: Text('Bill not found')),
              );
            }

            final dateStr = DateFormat('MMM d, yyyy').format(bill.date);

            return Scaffold(
              appBar: AppBar(
                title: Text(bill.title),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: 'Share',
                    onPressed: () => _shareText(context),
                  ),
                ],
              ),
              body: Column(
                children: [
                  const StepProgressIndicator(currentStep: 5),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Gradient Bill Header Card ──────────────
                          Container(
                            decoration: BoxDecoration(
                              gradient: isDark
                                  ? AppTheme.darkPrimaryGradient
                                  : AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bill.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${provider.people.length} people · ${provider.items.length} items',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                                ),
                                if (bill.taxRate > 0 ||
                                    bill.serviceChargeRate > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'VAT ${bill.taxRate}% + Service ${bill.serviceChargeRate}%',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                // Animated grand total in header
                                TweenAnimationBuilder<double>(
                                  tween: Tween(
                                    begin: 0,
                                    end: provider.grandTotal,
                                  ),
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOut,
                                  builder: (context, value, _) => Text(
                                    '฿${value.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Per-Person Breakdown Cards ─────────────
                          ...provider.splits.asMap().entries.map((entry) {
                            final index = entry.key;
                            final split = entry.value;
                            final color = AppTheme.getPersonColor(index);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(color: color, width: 4),
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Person header
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: color,
                                          radius: 16,
                                          child: Text(
                                            split.person.initial,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            split.person.name,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.headlineSmall,
                                          ),
                                        ),
                                        // Animated total per person
                                        TweenAnimationBuilder<double>(
                                          tween: Tween(
                                            begin: 0,
                                            end: split.total,
                                          ),
                                          duration: Duration(
                                            milliseconds: 600 + index * 150,
                                          ),
                                          curve: Curves.easeOut,
                                          builder: (context, value, _) => Text(
                                            '฿${value.toStringAsFixed(2)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(color: color),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),

                                    // Item shares
                                    ...split.itemShares.map((share) {
                                      final splitLabel = share.splitCount > 1
                                          ? ' (1/${share.splitCount})'
                                          : '';
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                        ),
                                        child: Row(
                                          children: [
                                            const Text(
                                              '  · ',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            Expanded(
                                              child: Text(
                                                '${share.item.name}$splitLabel',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium,
                                              ),
                                            ),
                                            Text(
                                              '฿${share.amount.toStringAsFixed(2)}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    const Divider(height: 16),

                                    // Subtotal
                                    _summaryRow(
                                      context,
                                      'Subtotal',
                                      '฿${split.subtotal.toStringAsFixed(2)}',
                                    ),
                                    if (bill.taxRate > 0)
                                      _summaryRow(
                                        context,
                                        'Tax (${bill.taxRate}%)',
                                        '฿${split.taxAmount.toStringAsFixed(2)}',
                                        subtle: true,
                                      ),
                                    if (bill.serviceChargeRate > 0)
                                      _summaryRow(
                                        context,
                                        'Service (${bill.serviceChargeRate}%)',
                                        '฿${split.serviceChargeAmount.toStringAsFixed(2)}',
                                        subtle: true,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),

                          // ── Grand Total ────────────────────────────
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Grand Total',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(
                                    begin: 0,
                                    end: provider.grandTotal,
                                  ),
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.easeOut,
                                  builder: (context, value, _) => Text(
                                    '฿${value.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primary,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 16),

                          // ── Action Buttons ─────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _copyText(context),
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Copy'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: () => _closeBill(context),
                                  icon: const Icon(
                                    Icons.check_circle,
                                    size: 18,
                                  ),
                                  label: const Text('Close Bill'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 15,
            minBlastForce: 5,
            emissionFrequency: 0.06,
            numberOfParticles: 20,
            gravity: 0.15,
            colors: const [
              AppTheme.primary,
              AppTheme.primaryLight,
              AppTheme.accent,
              Color(0xFF2196F3),
              Color(0xFFFF9800),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value, {
    bool subtle = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: subtle ? AppTheme.subtleText : null,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: subtle ? AppTheme.subtleText : null,
            ),
          ),
        ],
      ),
    );
  }
}
