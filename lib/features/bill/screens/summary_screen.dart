import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

/// Final summary screen showing the complete breakdown per person.
class SummaryScreen extends StatelessWidget {
  final String billId;
  const SummaryScreen({super.key, required this.billId});

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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BillProvider>().closeBill();
              context.go('/');
            },
            child: const Text('Close Bill'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, provider, _) {
        final bill = provider.currentBill;
        if (bill == null) {
          return const Scaffold(body: Center(child: Text('Bill not found')));
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Bill Header Card ─────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.subtleText),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.people.length} people · ${provider.items.length} items',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (bill.taxRate > 0 || bill.serviceChargeRate > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'VAT ${bill.taxRate}% + Service ${bill.serviceChargeRate}%',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.subtleText),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Per-Person Breakdown Cards ───────────────────
                ...provider.splits.asMap().entries.map((entry) {
                  final index = entry.key;
                  final split = entry.value;
                  final color = AppTheme.getPersonColor(index);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 6,
                    ),
                    child: Padding(
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
                            ],
                          ),
                          const Divider(height: 20),

                          // Item shares
                          ...split.itemShares.map((share) {
                            final splitLabel = share.splitCount > 1
                                ? ' (1/${share.splitCount})'
                                : '';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
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
                          const SizedBox(height: 4),

                          // Total
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TOTAL',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  '฿${split.total.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: AppTheme.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // ── Grand Total ──────────────────────────────────
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Grand Total',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        '฿${provider.grandTotal.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                const SizedBox(height: 16),

                // ── Action Buttons ───────────────────────────────
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
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Close Bill'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
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
