import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';
import 'package:quicksplit/core/widgets/step_progress_indicator.dart';

/// Final summary screen showing the complete breakdown per person.
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
              body: SafeArea(
                child: Column(
                  children: [
                    // ── Inline Header ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 12, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(LucideIcons.arrowLeft, size: 22),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.checkCircle,
                            size: 22,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bill.title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _shareText(context),
                            icon: Icon(
                              LucideIcons.share2,
                              size: 20,
                              color: isDark
                                  ? AppTheme.darkSubtleText
                                  : AppTheme.subtleText,
                            ),
                            tooltip: 'Share',
                          ),
                        ],
                      ),
                    ),

                    // ── Step Indicator ──
                    const StepProgressIndicator(currentStep: 5),

                    // ── Content ──
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Gradient Bill Header Card ──
                            Container(
                              decoration: BoxDecoration(
                                gradient: isDark
                                    ? AppTheme.darkPrimaryGradient
                                    : AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusCard,
                                ),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.calendar,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        dateStr,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _headerPill(
                                        '${provider.people.length} people',
                                        LucideIcons.users,
                                      ),
                                      const SizedBox(width: 8),
                                      _headerPill(
                                        '${provider.items.length} items',
                                        LucideIcons.utensils,
                                      ),
                                    ],
                                  ),
                                  if (bill.taxRate > 0 ||
                                      bill.serviceChargeRate > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        children: [
                                          if (bill.taxRate > 0)
                                            _headerPill(
                                              'VAT ${bill.taxRate}%',
                                              LucideIcons.landmark,
                                            ),
                                          if (bill.taxRate > 0 &&
                                              bill.serviceChargeRate > 0)
                                            const SizedBox(width: 8),
                                          if (bill.serviceChargeRate > 0)
                                            _headerPill(
                                              'Service ${bill.serviceChargeRate}%',
                                              LucideIcons.heartHandshake,
                                            ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 16),
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
                            const SizedBox(height: 16),

                            // ── Per-Person Cards ──
                            ...provider.splits.asMap().entries.map((entry) {
                              final index = entry.key;
                              final split = entry.value;
                              final color = AppTheme.getPersonColor(index);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.darkCard
                                      : Colors.white,
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
                                  children: [
                                    // Person header with color accent
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.06),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: color,
                                            radius: 18,
                                            child: Text(
                                              split.person.initial,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              split.person.name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          TweenAnimationBuilder<double>(
                                            tween: Tween(
                                              begin: 0,
                                              end: split.total,
                                            ),
                                            duration: Duration(
                                              milliseconds: 600 + index * 150,
                                            ),
                                            curve: Curves.easeOut,
                                            builder: (context, value, _) =>
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: color.withValues(
                                                      alpha: 0.15,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '฿${value.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: color,
                                                    ),
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Item shares
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        8,
                                        16,
                                        8,
                                      ),
                                      child: Column(
                                        children: [
                                          ...split.itemShares.map((share) {
                                            final splitLabel =
                                                share.splitCount > 1
                                                ? ' (1/${share.splitCount})'
                                                : '';
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 3,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    LucideIcons.dot,
                                                    size: 18,
                                                    color: color,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      '${share.item.name}$splitLabel',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '฿${share.amount.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                          Divider(
                                            height: 16,
                                            color: isDark
                                                ? AppTheme.darkDivider
                                                : AppTheme.divider,
                                          ),
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
                                  ],
                                ),
                              );
                            }),

                            const SizedBox(height: 8),

                            // ── Grand Total Container ──
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusCard,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.calculator,
                                        size: 18,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Grand Total',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(
                                      begin: 0,
                                      end: provider.grandTotal,
                                    ),
                                    duration: const Duration(
                                      milliseconds: 1000,
                                    ),
                                    curve: Curves.easeOut,
                                    builder: (context, value, _) => Text(
                                      '฿${value.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Action Buttons ──
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _copyText(context),
                                    icon: const Icon(
                                      LucideIcons.copy,
                                      size: 18,
                                    ),
                                    label: const Text('Copy'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _closeBill(context),
                                    icon: Icon(
                                      LucideIcons.checkCircle,
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
                    // ── Save for Later bar ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: isDark
                                ? AppTheme.darkDivider
                                : AppTheme.divider,
                          ),
                        ),
                      ),
                      child: Center(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/'),
                          icon: Icon(LucideIcons.home, size: 16),
                          label: const Text('Save for Later'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: const StadiumBorder(),
                            side: BorderSide(
                              color: isDark
                                  ? AppTheme.darkDivider
                                  : AppTheme.primaryLight
                                      .withValues(alpha: 0.5),
                            ),
                            foregroundColor: AppTheme.primaryLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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

  Widget _headerPill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value, {
    bool subtle = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: subtle
                  ? (isDark ? AppTheme.darkSubtleText : AppTheme.subtleText)
                  : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: subtle
                  ? (isDark ? AppTheme.darkSubtleText : AppTheme.subtleText)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
