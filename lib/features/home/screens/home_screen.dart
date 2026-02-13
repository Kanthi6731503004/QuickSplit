import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quicksplit/core/models/models.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/providers/theme_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

/// Home screen showing bill history with FAB to create new bill.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _emptyBounceController;

  @override
  void initState() {
    super.initState();
    _emptyBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillProvider>().loadBills();
    });
  }

  @override
  void dispose() {
    _emptyBounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? AppTheme.darkPrimaryGradient
                : AppTheme.primaryGradient,
          ),
          child: AppBar(
            title: const Text('QuickSplit'),
            centerTitle: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                tooltip: isDark ? 'Light mode' : 'Dark mode',
                onPressed: () {
                  context.read<ThemeProvider>().toggleTheme();
                },
              ),
            ],
          ),
        ),
      ),
      body: Consumer<BillProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return _buildShimmerLoading(context);
          }

          if (provider.bills.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildBillList(context, provider);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/bill/new'),
        tooltip: 'New Bill',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  /// Shimmer skeleton loading matching the card layout.
  Widget _buildShimmerLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade300;
    final highlightColor = isDark
        ? const Color(0xFF3C3C3C)
        : Colors.grey.shade100;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: 5,
      itemBuilder: (context, _) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 180,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 160,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Animated empty state with subtle bounce.
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _emptyBounceController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -8 * _emptyBounceController.value),
                  child: child,
                );
              },
              child: Icon(
                Icons.receipt_long,
                size: 80,
                color: AppTheme.subtleText.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No bills yet!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to split your first bill',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.subtleText),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/bill/new'),
                icon: const Icon(Icons.add),
                label: const Text('New Bill'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Staggered animated bill list.
  Widget _buildBillList(BuildContext context, BillProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = AppTheme.getHorizontalPadding(
          constraints.maxWidth,
        );
        final maxWidth = AppTheme.getMaxContentWidth(constraints.maxWidth);

        Widget list = ListView.builder(
          padding: EdgeInsets.only(
            top: 8,
            bottom: 80,
            left: maxWidth != null ? (constraints.maxWidth - maxWidth) / 2 : 0,
            right: maxWidth != null ? (constraints.maxWidth - maxWidth) / 2 : 0,
          ),
          itemCount: provider.bills.length,
          itemBuilder: (context, index) {
            final bill = provider.bills[index];
            return _StaggeredBillCard(
              index: index,
              bill: bill,
              horizontalPadding: horizontalPadding,
              onTap: () => context.push('/bill/${bill.id}'),
              onDelete: () => _confirmDelete(context, provider, bill),
            );
          },
        );

        return list;
      },
    );
  }

  void _confirmDelete(BuildContext context, BillProvider provider, Bill bill) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Bill'),
        content: Text("Delete '${bill.title}'? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteBill(bill.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("'${bill.title}' deleted")),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Bill card with staggered fade-in + slide animation.
class _StaggeredBillCard extends StatefulWidget {
  final int index;
  final Bill bill;
  final double horizontalPadding;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _StaggeredBillCard({
    required this.index,
    required this.bill,
    required this.horizontalPadding,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_StaggeredBillCard> createState() => _StaggeredBillCardState();
}

class _StaggeredBillCardState extends State<_StaggeredBillCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Stagger by index
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: _BillCard(
          bill: widget.bill,
          onTap: widget.onTap,
          onDelete: widget.onDelete,
        ),
      ),
    );
  }
}

/// A card displaying a bill's summary info with person count and total.
class _BillCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BillCard({
    required this.bill,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy').format(bill.date);
    final provider = context.read<BillProvider>();

    return Dismissible(
      key: ValueKey(bill.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Bill info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: bill.isClosed
                            ? AppTheme.primaryLight.withValues(alpha: 0.15)
                            : AppTheme.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            bill.isClosed
                                ? Icons.check_circle
                                : Icons.edit_note,
                            size: 14,
                            color: bill.isClosed
                                ? AppTheme.primaryLight
                                : AppTheme.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            bill.isClosed ? 'Closed' : 'Draft',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: bill.isClosed
                                      ? AppTheme.primaryLight
                                      : AppTheme.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Person count + total amount row
                const SizedBox(height: 8),
                FutureBuilder<({int personCount, double total})>(
                  future: provider.getBillSummary(bill.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(height: 14);
                    }
                    final data = snapshot.data!;
                    final personLabel = data.personCount == 1
                        ? '1 person'
                        : '${data.personCount} people';
                    final totalStr = '฿${data.total.toStringAsFixed(2)}';
                    return Text(
                      data.personCount > 0
                          ? '$personLabel · $totalStr'
                          : 'No participants yet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.subtleText,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
