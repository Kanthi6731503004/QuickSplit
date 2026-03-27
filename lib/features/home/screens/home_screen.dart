import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quicksplit/core/models/models.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/providers/theme_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';
import 'package:quicksplit/features/home/widgets/quick_setup_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _filterIndex = 0; // 0 = All, 1 = Active, 2 = Closed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillProvider>().loadBills();
    });
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

  void _showQuickSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickSetupSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Consumer<BillProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final activeBills = provider.bills.where((b) => !b.isClosed).length;
            final closedBills = provider.bills.where((b) => b.isClosed).length;
            final filtered = _filteredBills(provider.bills);

            return CustomScrollView(
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                    child: Row(
                      children: [
                        Text(
                          'QuickSplit',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 22,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            isDark
                                ? LucideIcons.sun
                                : LucideIcons.moon,
                            size: 20,
                          ),
                          tooltip: isDark ? 'Light mode' : 'Dark mode',
                          onPressed: () =>
                              context.read<ThemeProvider>().toggleTheme(),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── New Split Button ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showQuickSetup();
                        },
                        child: const Text('New split'),
                      ),
                    ),
                  ),
                ),

                // ── Stats Row ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Text(
                          '$activeBills active',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                        _verticalDivider(isDark),
                        Text(
                          '$closedBills closed',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                        _verticalDivider(isDark),
                        Text(
                          '${provider.bills.length} total',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Segmented Filter ──
                if (provider.bills.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _SegmentedFilter(
                        labels: const ['All', 'Active', 'Closed'],
                        selectedIndex: _filterIndex,
                        isDark: isDark,
                        onChanged: (i) => setState(() => _filterIndex = i),
                      ),
                    ),
                  ),

                // ── Bill List or Empty ──
                if (provider.bills.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(isDark),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _filterIndex == 1
                                ? LucideIcons.fileText
                                : LucideIcons.checkCircle,
                            size: 40,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _filterIndex == 1
                                ? 'No active splits'
                                : 'No closed splits',
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
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final bill = filtered[index];
                          return _BillCard(
                            bill: bill,
                            isDark: isDark,
                            onTap: () {
                              if (bill.isClosed) {
                                context.push('/bill/${bill.id}/summary');
                              } else {
                                context.push('/bill/${bill.id}');
                              }
                            },
                            onDelete: () =>
                                _confirmDelete(context, provider, bill),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _verticalDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: 1,
        height: 14,
        color: isDark ? AppColors.borderDark : AppColors.border,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.receipt,
              size: 48,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No splits yet',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 20,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap New split to get started',
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
    );
  }

  void _confirmDelete(
    BuildContext context,
    BillProvider provider,
    Bill bill,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete split?',
          style: GoogleFonts.dmSerifDisplay(fontSize: 18),
        ),
        content: Text(
          '"${bill.title}" will be permanently deleted.',
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteBill(bill.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(0, 40),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Segmented Filter ────────────────────────────────────────────────────────

class _SegmentedFilter extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const _SegmentedFilter({
    required this.labels,
    required this.selectedIndex,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: labels.asMap().entries.map((entry) {
          final i = entry.key;
          final label = entry.value;
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.accent
                          : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 2,
                    width: isSelected ? 24 : 0,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Bill Card ───────────────────────────────────────────────────────────────

class _BillCard extends StatelessWidget {
  final Bill bill;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BillCard({
    required this.bill,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final dateStr = DateFormat('MMM d').format(bill.date);

    return Dismissible(
      key: ValueKey(bill.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.dangerSubtle,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(LucideIcons.trash2, color: AppColors.danger),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bill.title,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          dateStr,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(isClosed: bill.isClosed),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isClosed;

  const _StatusBadge({required this.isClosed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isClosed ? AppColors.positiveSubtle : AppColors.accentSubtle,
        border: Border.all(
          color: isClosed ? AppColors.positive : AppColors.accent,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        isClosed ? 'Done' : 'Active',
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isClosed ? AppColors.positive : AppColors.accent,
        ),
      ),
    );
  }
}
