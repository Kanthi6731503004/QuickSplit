import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quicksplit/core/models/models.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';
import 'package:quicksplit/core/widgets/food_preset_grid.dart';
import 'package:quicksplit/core/widgets/price_numpad.dart';
import 'package:quicksplit/features/bill/widgets/add_item_sheet.dart';
import 'package:quicksplit/features/bill/widgets/assign_item_sheet.dart';
import 'package:quicksplit/features/home/widgets/quick_setup_sheet.dart';

/// The main bill editing workspace — items, assignments, running totals.
class BillEditorScreen extends StatefulWidget {
  final String billId;
  const BillEditorScreen({super.key, required this.billId});

  @override
  State<BillEditorScreen> createState() => _BillEditorScreenState();
}

class _BillEditorScreenState extends State<BillEditorScreen> {
  String? _filterPersonId;
  double _taxRate = 7.0;
  double _serviceRate = 10.0;

  static const _taxPresets = [0.0, 5.0, 7.0, 10.0, 15.0];
  static const _servicePresets = [0.0, 5.0, 10.0, 15.0, 20.0];

  void _onTaxChanged(double value) {
    HapticFeedback.selectionClick();
    setState(() => _taxRate = value);
    context.read<BillProvider>().updateTaxAndService(taxRate: value);
  }

  void _onServiceChanged(double value) {
    HapticFeedback.selectionClick();
    setState(() => _serviceRate = value);
    context.read<BillProvider>().updateTaxAndService(serviceChargeRate: value);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BillProvider>();
      if (provider.currentBill?.id != widget.billId) {
        provider.loadBill(widget.billId);
      }
      final bill = provider.currentBill;
      if (bill != null) {
        setState(() {
          _taxRate = bill.taxRate;
          _serviceRate = bill.serviceChargeRate;
        });
      }
    });
  }

  void _showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddItemSheet(),
    );
  }

  void _showAssignSheet(BillItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AssignItemSheet(item: item),
    );
  }

  void _showEditItemDialog(BillItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _EditItemSheet(
        item: item,
        onSave: (name, price) {
          context
              .read<BillProvider>()
              .updateItem(item.id, name: name, price: price);
        },
      ),
    );
  }

  void _showTaxSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TaxSheet(
        taxRate: _taxRate,
        serviceRate: _serviceRate,
        taxPresets: _taxPresets,
        servicePresets: _servicePresets,
        onTaxChanged: _onTaxChanged,
        onServiceChanged: _onServiceChanged,
      ),
    );
  }

  void _showEditPeopleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickSetupSheet(existingBillId: widget.billId),
    );
  }

  void _onCalculate() {
    final provider = context.read<BillProvider>();

    if (provider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item first')),
      );
      return;
    }

    if (!provider.allItemsAssigned) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Unassigned Items',
            style: GoogleFonts.dmSerifDisplay(fontSize: 18),
          ),
          content: Text(
            '${provider.unassignedItems.length} item(s) have not been assigned. '
            'They will not be included in the split.',
            style: GoogleFonts.dmSans(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Go Back'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/bill/${widget.billId}/summary');
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
              child: const Text('Continue Anyway'),
            ),
          ],
        ),
      );
    } else {
      context.push('/bill/${widget.billId}/summary');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<BillProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final bill = provider.currentBill;
        if (bill == null) {
          return const Scaffold(
              body: Center(child: Text('Bill not found')));
        }

        final subtotal = provider.subtotal;
        final grandTotal = subtotal +
            subtotal * (_taxRate / 100) +
            subtotal * (_serviceRate / 100);

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
                        onPressed: () => context.go('/'),
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
                      IconButton(
                        icon: const Icon(LucideIcons.userPlus, size: 20),
                        tooltip: 'Edit people',
                        onPressed: _showEditPeopleSheet,
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.percent, size: 20),
                        tooltip: 'Tax & charges',
                        onPressed: _showTaxSheet,
                      ),
                    ],
                  ),
                ),

                // ── People Bar ──
                if (provider.people.isNotEmpty)
                  _buildPeopleBar(provider, isDark),

                // ── Tax Summary Row ──
                _buildTaxRow(grandTotal, isDark),

                // ── Items List ──
                Expanded(
                  child: provider.items.isEmpty
                      ? _buildEmptyItems(isDark)
                      : _buildItemsList(provider, isDark),
                ),

                // ── Sticky Bottom Bar ──
                _buildBottomBar(grandTotal, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeopleBar(BillProvider provider, bool isDark) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20, right: 8, top: 8, bottom: 4),
        itemCount: provider.people.length,
        itemBuilder: (context, index) {
          final person = provider.people[index];
          final color = AppTheme.getPersonColor(index);
          final isFiltered = _filterPersonId == person.id;

          double subtotal = 0;
          for (final item in provider.items) {
            subtotal += item.getShareForPerson(person.id);
          }

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _filterPersonId =
                    _filterPersonId == person.id ? null : person.id;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isFiltered
                    ? color.withValues(alpha: 0.18)
                    : color.withValues(alpha: 0.08),
                border: Border.all(
                  color: isFiltered
                      ? color
                      : color.withValues(alpha: 0.3),
                  width: isFiltered ? 1.5 : 1,
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
                      person.initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    person.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: isFiltered
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '฿${subtotal.toStringAsFixed(0)}',
                    style: AppTheme.amountStyle(
                      size: 11,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaxRow(double grandTotal, bool isDark) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    return InkWell(
      onTap: _showTaxSheet,
      child: Column(
        children: [
          Divider(color: borderColor, height: 1),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Icon(
                  LucideIcons.percent,
                  size: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text:
                              'VAT ${_taxRate.toStringAsFixed(0)}%  ·  Service ${_serviceRate.toStringAsFixed(0)}%  ·  Total ',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                        WidgetSpan(
                          child: Text(
                            '฿${grandTotal.toStringAsFixed(2)}',
                            style: AppTheme.amountStyle(
                              size: 13,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.pencil,
                  size: 12,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMuted,
                ),
              ],
            ),
          ),
          Divider(color: borderColor, height: 1),
        ],
      ),
    );
  }

  Widget _buildEmptyItems(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.utensils,
            size: 40,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No items yet',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(BillProvider provider, bool isDark) {
    final items = _filterPersonId != null
        ? provider.items
              .where((i) => i.assignedUserIds.contains(_filterPersonId))
              .toList()
        : provider.items;

    if (items.isEmpty && _filterPersonId != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.filterX,
              size: 36,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              'No items for this person',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _filterPersonId = null),
              child: const Text('Clear filter'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _ItemCard(
          item: item,
          people: provider.people,
          isDark: isDark,
          onTap: () => _showAssignSheet(item),
          onEdit: () => _showEditItemDialog(item),
          onDelete: () {
            provider.removeItem(item.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("'${item.name}' removed")),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomBar(double grandTotal, bool isDark) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: borderColor)),
        boxShadow: const [AppTheme.floatingShadow],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMuted,
                ),
              ),
              Text(
                '฿${grandTotal.toStringAsFixed(2)}',
                style: AppTheme.amountStyle(
                  size: 18,
                  color: AppColors.positive,
                ),
              ),
            ],
          ),
          const Spacer(),
          FilledButton.tonal(
            onPressed: _onCalculate,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusButton),
              ),
              minimumSize: const Size(0, 44),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(
              'See split',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _showAddItemSheet,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.plus, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Item',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Item Card ───────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final BillItem item;
  final List<Person> people;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.people,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUnassigned = !item.isAssigned;
    final borderColor = isUnassigned
        ? AppColors.danger.withValues(alpha: 0.4)
        : (isDark ? AppColors.borderDark : AppColors.border);
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;

    return Slidable(
      key: ValueKey(item.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: LucideIcons.pencil,
            label: 'Edit',
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            icon: LucideIcons.trash2,
            label: 'Delete',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: borderColor),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isUnassigned)
                        Row(
                          children: [
                            Icon(
                              LucideIcons.alertTriangle,
                              size: 12,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Unassigned',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            _stackedAvatars(item, people),
                            const SizedBox(width: 6),
                            Text(
                              item.splitCount == 1
                                  ? 'Solo'
                                  : 'split ${item.splitCount} ways',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '฿${item.price.toStringAsFixed(2)}',
                  style: AppTheme.amountStyle(
                    size: 14,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stackedAvatars(BillItem item, List<Person> people) {
    final ids = item.assignedUserIds.take(3).toList();
    return SizedBox(
      width: ids.length * 14.0 + 4,
      height: 20,
      child: Stack(
        children: ids.asMap().entries.map((entry) {
          final idx = entry.key;
          final uid = entry.value;
          final pIdx = people.indexWhere((p) => p.id == uid);
          if (pIdx < 0) return const SizedBox();
          final color = AppTheme.getPersonColor(pIdx);
          return Positioned(
            left: idx * 12.0,
            child: CircleAvatar(
              backgroundColor: color,
              radius: 9,
              child: Text(
                people[pIdx].initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Tax Sheet ───────────────────────────────────────────────────────────────

class _TaxSheet extends StatefulWidget {
  final double taxRate;
  final double serviceRate;
  final List<double> taxPresets;
  final List<double> servicePresets;
  final ValueChanged<double> onTaxChanged;
  final ValueChanged<double> onServiceChanged;

  const _TaxSheet({
    required this.taxRate,
    required this.serviceRate,
    required this.taxPresets,
    required this.servicePresets,
    required this.onTaxChanged,
    required this.onServiceChanged,
  });

  @override
  State<_TaxSheet> createState() => _TaxSheetState();
}

class _TaxSheetState extends State<_TaxSheet> {
  late double _tax;
  late double _service;

  @override
  void initState() {
    super.initState();
    _tax = widget.taxRate;
    _service = widget.serviceRate;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tax & charges',
            style: GoogleFonts.dmSerifDisplay(fontSize: 18),
          ),
          const SizedBox(height: 20),

          Text(
            'VAT / TAX',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          _presetChips(
            widget.taxPresets,
            _tax,
            AppColors.accent,
            isDark,
            (v) {
              setState(() => _tax = v);
              widget.onTaxChanged(v);
            },
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _tax,
                  min: 0,
                  max: 20,
                  divisions: 40,
                  activeColor: AppColors.accent,
                  onChanged: (v) {
                    setState(() => _tax = v);
                    widget.onTaxChanged(v);
                  },
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '${_tax.toStringAsFixed(1)}%',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'SERVICE CHARGE',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          _presetChips(
            widget.servicePresets,
            _service,
            AppColors.accent,
            isDark,
            (v) {
              setState(() => _service = v);
              widget.onServiceChanged(v);
            },
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _service,
                  min: 0,
                  max: 25,
                  divisions: 50,
                  activeColor: AppColors.accent,
                  onChanged: (v) {
                    setState(() => _service = v);
                    widget.onServiceChanged(v);
                  },
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '${_service.toStringAsFixed(1)}%',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _presetChips(
    List<double> presets,
    double current,
    Color activeColor,
    bool isDark,
    ValueChanged<double> onSelected,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: presets.map((p) {
        final isActive = (current - p).abs() < 0.05;
        return ChoiceChip(
          label: Text('${p.toStringAsFixed(0)}%'),
          selected: isActive,
          selectedColor: activeColor.withValues(alpha: 0.15),
          side: BorderSide(
            color: isActive
                ? activeColor
                : (isDark ? AppColors.borderDark : AppColors.border),
          ),
          labelStyle: GoogleFonts.dmSans(
            fontSize: 12,
            color: isActive ? activeColor : null,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
          onSelected: (_) {
            HapticFeedback.lightImpact();
            onSelected(p);
          },
        );
      }).toList(),
    );
  }
}

// ── Edit Item Sheet ──────────────────────────────────────────────────────────

class _EditItemSheet extends StatefulWidget {
  final BillItem item;
  final void Function(String name, double price) onSave;

  const _EditItemSheet({required this.item, required this.onSave});

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  late String _selectedName;
  late String _priceValue;

  @override
  void initState() {
    super.initState();
    _selectedName = widget.item.name;
    final raw = widget.item.price;
    _priceValue = raw == raw.truncateToDouble()
        ? raw.toInt().toString()
        : raw.toStringAsFixed(2);
  }

  bool get _isValid =>
      _selectedName.trim().isNotEmpty &&
      _priceValue.isNotEmpty &&
      (double.tryParse(_priceValue) ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (_, scrollCtrl) {
        return SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Item',
                style: GoogleFonts.dmSerifDisplay(fontSize: 20),
              ),
              const SizedBox(height: 16),

              FoodPresetGrid(
                selectedName: _selectedName,
                onSelected: (name) => setState(() => _selectedName = name),
              ),

              const SizedBox(height: 20),
              Divider(
                color: isDark ? AppColors.borderDark : AppColors.border,
              ),
              const SizedBox(height: 16),

              Text(
                'How much? (฿)',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              PriceDisplay(priceValue: _priceValue),
              const SizedBox(height: 12),

              PricePresetChips(
                priceValue: _priceValue,
                onSelected: (v) => setState(() => _priceValue = v),
              ),
              const SizedBox(height: 12),

              PriceNumpad(
                value: _priceValue,
                onChanged: (v) => setState(() => _priceValue = v),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isValid
                    ? () {
                        widget.onSave(
                          _selectedName.trim(),
                          double.parse(_priceValue),
                        );
                        Navigator.pop(context);
                      }
                    : null,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        );
      },
    );
  }
}
