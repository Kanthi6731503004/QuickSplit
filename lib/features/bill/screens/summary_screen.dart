import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

/// Final summary screen — receipt style, per-person breakdown.
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
    final text = context.read<BillProvider>().generateShareText();
    SharePlus.instance.share(ShareParams(text: text));
  }

  void _copyText(BuildContext context) {
    final text = context.read<BillProvider>().generateShareText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!')),
    );
  }

  void _closeBill(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Close bill',
          style: GoogleFonts.dmSerifDisplay(fontSize: 18),
        ),
        content: Text(
          'Mark this bill as complete? You can still view it in history.',
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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
            final borderColor =
                isDark ? AppColors.borderDark : AppColors.border;
            final surfaceColor =
                isDark ? AppColors.surfaceDark : AppColors.surface;

            return Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    // ── Header ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(LucideIcons.arrowLeft, size: 22),
                          ),
                          Expanded(
                            child: Text(
                              bill.title,
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 18,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Content ──
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Receipt Header Card ──
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusCard,
                                ),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          bill.title,
                                          style: GoogleFonts.dmSerifDisplay(
                                            fontSize: 20,
                                            color: isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        dateStr,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        '${provider.people.length} people',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          '·',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.textMutedDark
                                                : AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${provider.items.length} items',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _DashedDivider(
                                    color: borderColor,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Text(
                                        'Grand total',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      const Spacer(),
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(
                                          begin: 0,
                                          end: provider.grandTotal,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 800,
                                        ),
                                        curve: Curves.easeOut,
                                        builder: (context, value, _) =>
                                            Text(
                                          '฿${value.toStringAsFixed(2)}',
                                          style: AppTheme.amountStyle(
                                            size: 24,
                                            color: AppColors.positive,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _copyText(context),
                                        icon: const Icon(
                                          LucideIcons.copy,
                                          size: 14,
                                        ),
                                        label: const Text('Copy'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize
                                                  .shrinkWrap,
                                          textStyle: GoogleFonts.dmSans(
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      TextButton.icon(
                                        onPressed: () =>
                                            _shareText(context),
                                        icon: const Icon(
                                          LucideIcons.share2,
                                          size: 14,
                                        ),
                                        label: const Text('Share'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize
                                                  .shrinkWrap,
                                          textStyle: GoogleFonts.dmSans(
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ── Per-Person Cards ──
                            ...provider.splits.asMap().entries.map((entry) {
                              final index = entry.key;
                              final split = entry.value;
                              final color =
                                  AppTheme.getPersonColor(index);

                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 12),
                                child: _PersonCard(
                                  split: split,
                                  color: color,
                                  taxRate: bill.taxRate,
                                  serviceRate: bill.serviceChargeRate,
                                  isDark: isDark,
                                  animIndex: index,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    // ── Sticky Bottom Bar ──
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        border: Border(
                          top: BorderSide(color: borderColor),
                        ),
                        boxShadow: const [AppTheme.floatingShadow],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: ElevatedButton(
                            onPressed: () => _closeBill(context),
                            child: const Text('Close bill ✓'),
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

        // ── Confetti overlay ──
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
              AppColors.accent,
              AppColors.positive,
              Color(0xFF3B82F6),
              Color(0xFF9333EA),
              Color(0xFFE85D3F),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Person Card ──────────────────────────────────────────────────────────────

class _PersonCard extends StatelessWidget {
  final dynamic split;
  final Color color;
  final double taxRate;
  final double serviceRate;
  final bool isDark;
  final int animIndex;

  const _PersonCard({
    required this.split,
    required this.color,
    required this.taxRate,
    required this.serviceRate,
    required this.isDark,
    required this.animIndex,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          left: BorderSide(color: color, width: 3),
          top: BorderSide(color: borderColor),
          right: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        children: [
          // Person header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  radius: 16,
                  child: Text(
                    split.person.initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    split.person.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: split.total as double),
                  duration: Duration(
                    milliseconds: 600 + animIndex * 150,
                  ),
                  curve: Curves.easeOut,
                  builder: (context, value, _) => Text(
                    '฿${value.toStringAsFixed(2)}',
                    style: AppTheme.amountStyle(
                      size: 16,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: borderColor),

          // Item breakdown
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Column(
              children: [
                ...split.itemShares.map((share) {
                  final splitLabel =
                      share.splitCount > 1 ? ' (1/${share.splitCount})' : '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Text(
                          '· ',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: color,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${share.item.name}$splitLabel',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '฿${share.amount.toStringAsFixed(2)}',
                          style: AppTheme.amountStyle(
                            size: 13,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                Divider(height: 16, color: borderColor),

                _summaryRow(
                  'Subtotal',
                  '฿${split.subtotal.toStringAsFixed(2)}',
                  isDark,
                  false,
                ),
                if (taxRate > 0)
                  _summaryRow(
                    'Tax ($taxRate%)',
                    '฿${split.taxAmount.toStringAsFixed(2)}',
                    isDark,
                    true,
                  ),
                if (serviceRate > 0)
                  _summaryRow(
                    'Service ($serviceRate%)',
                    '฿${split.serviceChargeAmount.toStringAsFixed(2)}',
                    isDark,
                    true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value,
    bool isDark,
    bool subtle,
  ) {
    final textColor = subtle
        ? (isDark ? AppColors.textMutedDark : AppColors.textMuted)
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 13, color: textColor),
          ),
          Text(
            value,
            style: AppTheme.amountStyle(size: 13, color: textColor),
          ),
        ],
      ),
    );
  }
}

// ── Dashed Divider ───────────────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  final Color color;

  const _DashedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedLinePainter(color: color),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    double startX = 0;
    const dashWidth = 6.0;
    const dashSpace = 4.0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
