import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quicksplit/core/models/models.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';
import 'package:quicksplit/core/widgets/step_progress_indicator.dart';
import 'package:quicksplit/features/bill/widgets/add_item_sheet.dart';
import 'package:quicksplit/features/bill/widgets/assign_item_sheet.dart';

/// The main bill editing workspace — items, assignments, running totals.
class BillEditorScreen extends StatefulWidget {
  final String billId;
  const BillEditorScreen({super.key, required this.billId});

  @override
  State<BillEditorScreen> createState() => _BillEditorScreenState();
}

class _BillEditorScreenState extends State<BillEditorScreen>
    with TickerProviderStateMixin {
  String? _filterPersonId;
  late AnimationController _emptyBounceController;

  @override
  void initState() {
    super.initState();
    _emptyBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BillProvider>();
      if (provider.currentBill?.id != widget.billId) {
        provider.loadBill(widget.billId);
      }
    });
  }

  @override
  void dispose() {
    _emptyBounceController.dispose();
    super.dispose();
  }

  void _showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const AddItemSheet(),
      ),
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
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(
      text: item.price.toStringAsFixed(2),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Price (฿)',
                prefixText: '฿ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text);
              if (name.isNotEmpty && price != null && price > 0) {
                context.read<BillProvider>().updateItem(
                  item.id,
                  name: name,
                  price: price,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
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
          title: const Text('Unassigned Items'),
          content: Text(
            '${provider.unassignedItems.length} item(s) have not been assigned to anyone. '
            'They will not be included in the split.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Go Back'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/bill/${widget.billId}/tax');
              },
              child: const Text('Continue Anyway'),
            ),
          ],
        ),
      );
    } else {
      context.push('/bill/${widget.billId}/tax');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final bill = provider.currentBill;
        if (bill == null) {
          return const Scaffold(body: Center(child: Text('Bill not found')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(bill.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart),
                tooltip: 'Summary',
                onPressed: provider.items.isNotEmpty
                    ? () => context.push('/bill/${widget.billId}/summary')
                    : null,
              ),
            ],
          ),
          body: Column(
            children: [
              const StepProgressIndicator(currentStep: 3),

              // ── People Bar (horizontal scroll with names + subtotals) ──
              if (provider.people.isNotEmpty) _buildPeopleBar(provider),

              const Divider(height: 1),

              // ── Items List ─────────────────────────────────────
              Expanded(
                child: provider.items.isEmpty
                    ? _buildEmptyItems()
                    : _buildItemsList(provider),
              ),

              // ── Calculate Button ───────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _onCalculate,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Calculate Split'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddItemSheet,
            tooltip: 'Add Item',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  /// Horizontal scrollable bar showing each person with their name, avatar, and running subtotal.
  /// Tap a person to filter items to only those assigned to them.
  Widget _buildPeopleBar(BillProvider provider) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: provider.people.length,
        itemBuilder: (context, index) {
          final person = provider.people[index];
          final color = AppTheme.getPersonColor(index);
          final isFiltered = _filterPersonId == person.id;

          // Calculate running subtotal for this person
          double subtotal = 0;
          for (final item in provider.items) {
            subtotal += item.getShareForPerson(person.id);
          }

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _filterPersonId = _filterPersonId == person.id
                    ? null
                    : person.id;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isFiltered ? color.withValues(alpha: 0.15) : null,
                borderRadius: BorderRadius.circular(12),
                border: isFiltered ? Border.all(color: color, width: 2) : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: color,
                    radius: 18,
                    child: Text(
                      person.initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 56,
                    child: Text(
                      person.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: isFiltered
                            ? FontWeight.w700
                            : FontWeight.w400,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Text(
                    '฿${subtotal.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
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

  Widget _buildEmptyItems() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _emptyBounceController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -6 * _emptyBounceController.value),
                child: child,
              );
            },
            child: Icon(
              Icons.restaurant_menu,
              size: 64,
              color: AppTheme.subtleText.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No items yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppTheme.subtleText),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add menu items',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.subtleText),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(BillProvider provider) {
    // Filter items by selected person
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
            Icon(Icons.filter_list_off, size: 48, color: AppTheme.subtleText),
            const SizedBox(height: 8),
            Text(
              'No items assigned to this person',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.subtleText),
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
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _ItemCard(
          item: item,
          people: provider.people,
          onTap: () => _showAssignSheet(item),
          onEdit: () => _showEditItemDialog(item),
          onDelete: () {
            provider.removeItem(item.id);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("'${item.name}' removed")));
          },
        );
      },
    );
  }
}

/// Card displaying an item with multi-action swipe (edit + delete) using flutter_slidable.
class _ItemCard extends StatelessWidget {
  final BillItem item;
  final List<Person> people;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.people,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isWarning = !item.isAssigned;

    return Slidable(
      key: ValueKey(item.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          side: isWarning
              ? const BorderSide(color: AppTheme.accent, width: 1.5)
              : BorderSide.none,
        ),
        color: isWarning ? AppTheme.accent.withValues(alpha: 0.04) : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item name and price
                Row(
                  children: [
                    if (isWarning)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.warning_amber,
                          size: 18,
                          color: AppTheme.accent,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        item.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Text(
                      '฿${item.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Assigned avatars or hint
                if (isWarning)
                  Text(
                    'Tap to assign people',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accent,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Row(
                    children: [
                      ...item.assignedUserIds.map((uid) {
                        final personIndex = people.indexWhere(
                          (p) => p.id == uid,
                        );
                        if (personIndex < 0) return const SizedBox();
                        final person = people[personIndex];
                        final color = AppTheme.getPersonColor(personIndex);

                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: CircleAvatar(
                            backgroundColor: color,
                            radius: 12,
                            child: Text(
                              person.initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          item.splitCount == 1
                              ? 'Solo · ฿${item.price.toStringAsFixed(2)}'
                              : 'Split ${item.splitCount} ways · ฿${item.pricePerPerson.toStringAsFixed(2)} each',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
