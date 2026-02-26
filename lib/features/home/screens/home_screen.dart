import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quicksplit/core/models/models.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/providers/theme_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

/// Home screen with greeting header, stats card, segmented filter, and rich bill cards.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _emptyBounceController;
  int _filterIndex = 0; // 0 = All, 1 = Active, 2 = Closed

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

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  List<Bill> _filteredBills(List<Bill> bills) {
    switch (_filterIndex) {
      case 1:
        return bills.where((b) => !b.isClosed).toList();
      case 2:
        return bills.where((b) => b.isClosed).toList();
      default:
        return bills;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Consumer<BillProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return _buildShimmerLoading(context);
            }

            final activeBills = provider.bills.where((b) => !b.isClosed).length;
            final closedBills = provider.bills.where((b) => b.isClosed).length;
            final filtered = _filteredBills(provider.bills);

            return CustomScrollView(
              slivers: [
                // ── Greeting Header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_greeting 👋',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: isDark
                                          ? AppTheme.darkSubtleText
                                          : AppTheme.subtleText,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.zap,
                                    size: 20,
                                    color: AppTheme.primaryLight,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'QuickSplit',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
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

                // ── Stats Card & CTA ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF1B3A1E),
                                  const Color(0xFF0D2B12),
                                ]
                              : [AppTheme.primary, AppTheme.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(
                              alpha: isDark ? 0.2 : 0.3,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tagline
                          Row(
                            children: [
                              Icon(
                                LucideIcons.zap,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Split bills, not friendships',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Stats row
                          Row(
                            children: [
                              _StatPill(
                                icon: LucideIcons.fileText,
                                label: 'Active',
                                value: '$activeBills',
                              ),
                              const SizedBox(width: 12),
                              _StatPill(
                                icon: LucideIcons.checkCircle,
                                label: 'Closed',
                                value: '$closedBills',
                              ),
                              const SizedBox(width: 12),
                              _StatPill(
                                icon: LucideIcons.users,
                                label: 'Total',
                                value: '${provider.bills.length}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // New Bill CTA
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                context.push('/bill/new');
                              },
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text('New Bill'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Resume Banner ──
                if (provider.bills.any((b) => !b.isClosed))
                  SliverToBoxAdapter(
                    child: _ResumeBanner(
                      bill: provider.bills.firstWhere((b) => !b.isClosed),
                      isDark: isDark,
                      onTap: () => context.push(
                        '/bill/${provider.bills.firstWhere((b) => !b.isClosed).id}',
                      ),
                    ),
                  ),

                // ── Segmented Tabs ──
                if (provider.bills.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SegmentedFilter(
                              labels: [
                                'All (${provider.bills.length})',
                                'Active ($activeBills)',
                                'Closed ($closedBills)',
                              ],
                              selectedIndex: _filterIndex,
                              onChanged: (i) =>
                                  setState(() => _filterIndex = i),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Bill List or Empty ──
                if (provider.bills.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _filterIndex == 1
                                  ? LucideIcons.fileText
                                  : LucideIcons.checkCircle,
                              size: 48,
                              color: AppTheme.subtleText.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _filterIndex == 1
                                  ? 'No active bills'
                                  : 'No closed bills',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: isDark
                                        ? AppTheme.darkSubtleText
                                        : AppTheme.subtleText,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final bill = filtered[index];
                        return _StaggeredBillCard(
                          index: index,
                          bill: bill,
                          onTap: () => context.push('/bill/${bill.id}'),
                          onDelete: () =>
                              _confirmDelete(context, provider, bill),
                        );
                      }, childCount: filtered.length),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          context.push('/bill/new');
        },
        tooltip: 'New Bill',
        icon: const Icon(Icons.add, size: 22),
        label: const Text('Split a bill'),
      ),
    );
  }

  /// Shimmer skeleton loading.
  Widget _buildShimmerLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade300;
    final highlightColor = isDark
        ? const Color(0xFF3C3C3C)
        : Colors.grey.shade100;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 80),
        children: [
          // Shimmer greeting
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 14, decoration: _shimmerBox()),
                  const SizedBox(height: 8),
                  Container(width: 160, height: 22, decoration: _shimmerBox()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Shimmer stats card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Shimmer cards
          ...List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _shimmerBox() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(4),
  );

  /// How-it-works empty state.
  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
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
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.receipt,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No bills yet',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              "Here's how QuickSplit works",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.darkSubtleText : AppTheme.subtleText,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HowItWorksStep(
                  number: '1',
                  icon: LucideIcons.users,
                  label: 'Setup',
                  desc: 'Name the bill & add friends',
                  isDark: isDark,
                ),
                _HowItWorksArrow(isDark: isDark),
                _HowItWorksStep(
                  number: '2',
                  icon: LucideIcons.utensils,
                  label: 'Items',
                  desc: 'Add items & assign each one',
                  isDark: isDark,
                ),
                _HowItWorksArrow(isDark: isDark),
                _HowItWorksStep(
                  number: '3',
                  icon: LucideIcons.checkCircle,
                  label: 'Summary',
                  desc: 'See who owes what',
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push('/bill/new');
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Create your first bill'),
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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

// ── Stat Pill (inside green card) ──────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Segmented Filter ───────────────────────────────────────────────

class _SegmentedFilter extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const _SegmentedFilter({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? (isDark ? AppTheme.darkSurface : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? (isDark ? AppTheme.darkOnSurface : AppTheme.onSurface)
                        : (isDark
                              ? AppTheme.darkSubtleText
                              : AppTheme.subtleText),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Staggered Bill Card (animation wrapper) ────────────────────────

class _StaggeredBillCard extends StatefulWidget {
  final int index;
  final Bill bill;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _StaggeredBillCard({
    required this.index,
    required this.bill,
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
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
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
        child: _RichBillCard(
          bill: widget.bill,
          onTap: widget.onTap,
          onDelete: widget.onDelete,
        ),
      ),
    );
  }
}

// ── Rich Bill Card ─────────────────────────────────────────────────

class _RichBillCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RichBillCard({
    required this.bill,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('MMM d, yyyy').format(bill.date);
    final provider = context.read<BillProvider>();

    return Dismissible(
      key: ValueKey(bill.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: isDark ? AppTheme.darkCard : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar
                Container(
                  width: 5,
                  color: bill.isClosed ? AppTheme.primaryLight : AppTheme.accent,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FutureBuilder<
                      ({int personCount, double total, List<String> peopleNames})
                    >(
                    future: provider.getBillSummary(bill.id),
                    builder: (context, snapshot) {
                      final data = snapshot.data;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: title + status dot
                          Row(
                            children: [
                              // Status dot
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: bill.isClosed
                                      ? AppTheme.primaryLight
                                      : AppTheme.accent,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Title
                              Expanded(
                                child: Text(
                                  bill.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Amount badge
                              if (data != null && data.total > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.primary.withValues(
                                            alpha: 0.2,
                                          )
                                        : AppTheme.primaryLight.withValues(
                                            alpha: 0.12,
                                          ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '฿${data.total.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppTheme.primaryLight
                                          : AppTheme.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Bottom row: date + avatars + status label
                          Row(
                            children: [
                              // Date
                              Icon(
                                LucideIcons.calendar,
                                size: 13,
                                color: isDark
                                    ? AppTheme.darkSubtleText
                                    : AppTheme.subtleText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateStr,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: isDark
                                          ? AppTheme.darkSubtleText
                                          : AppTheme.subtleText,
                                    ),
                              ),
                              const SizedBox(width: 12),
                              // Person avatars (stacked)
                              if (data != null && data.peopleNames.isNotEmpty)
                                _StackedAvatars(names: data.peopleNames),
                              const Spacer(),
                              // Status label
                              Text(
                                bill.isClosed ? 'Closed' : 'Draft',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: bill.isClosed
                                          ? AppTheme.primaryLight
                                          : AppTheme.accent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stacked Avatars ────────────────────────────────────────────────

class _StackedAvatars extends StatelessWidget {
  final List<String> names;
  static const double _size = 24;
  static const double _overlap = 8;
  static const int _maxShow = 4;

  const _StackedAvatars({required this.names});

  @override
  Widget build(BuildContext context) {
    final show = names.take(_maxShow).toList();
    final extra = names.length - _maxShow;
    final totalWidth =
        _size +
        (show.length - 1) * (_size - _overlap) +
        (extra > 0 ? _size - _overlap : 0);

    return SizedBox(
      width: totalWidth,
      height: _size,
      child: Stack(
        children: [
          ...show.asMap().entries.map((entry) {
            final i = entry.key;
            final name = entry.value;
            final color = AppTheme.getPersonColor(i);
            return Positioned(
              left: i * (_size - _overlap),
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkCard
                        : AppTheme.surface,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }),
          if (extra > 0)
            Positioned(
              left: show.length * (_size - _overlap),
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkSurface
                      : const Color(0xFFE0E0E0),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkCard
                        : AppTheme.surface,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$extra',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkOnSurface
                        : AppTheme.onSurface,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Resume Banner ──────────────────────────────────────────────────

class _ResumeBanner extends StatelessWidget {
  final Bill bill;
  final bool isDark;
  final VoidCallback onTap;

  const _ResumeBanner({
    required this.bill,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: isDark
            ? AppTheme.accent.withValues(alpha: 0.12)
            : AppTheme.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.utensils,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Continue where you left off',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppTheme.darkSubtleText
                              : AppTheme.subtleText,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        bill.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTheme.darkOnSurface
                              : AppTheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Resume',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(LucideIcons.arrowRight, size: 14, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── How It Works Step ──────────────────────────────────────────────

class _HowItWorksStep extends StatelessWidget {
  final String number;
  final IconData icon;
  final String label;
  final String desc;
  final bool isDark;

  const _HowItWorksStep({
    required this.number,
    required this.icon,
    required this.label,
    required this.desc,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkBackground
                          : AppTheme.background,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkOnSurface : AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppTheme.darkSubtleText : AppTheme.subtleText,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── How It Works Arrow ─────────────────────────────────────────────

class _HowItWorksArrow extends StatelessWidget {
  final bool isDark;

  const _HowItWorksArrow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 52),
      child: Icon(
        LucideIcons.arrowRight,
        size: 16,
        color: isDark
            ? AppTheme.darkSubtleText.withValues(alpha: 0.5)
            : AppTheme.subtleText.withValues(alpha: 0.5),
      ),
    );
  }
}
