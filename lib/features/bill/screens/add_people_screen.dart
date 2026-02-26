import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';
import 'package:quicksplit/core/widgets/step_progress_indicator.dart';

/// Combined setup screen: bill name/date + add participants.
///
/// Pass [billId] = null to create a new bill; pass an existing id to edit people.
class AddPeopleScreen extends StatefulWidget {
  final String? billId;
  const AddPeopleScreen({super.key, this.billId});

  @override
  State<AddPeopleScreen> createState() => _AddPeopleScreenState();
}

class _AddPeopleScreenState extends State<AddPeopleScreen> {
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _focusNode = FocusNode();
  DateTime _selectedDate = DateTime.now();
  String? _billId;

  @override
  void initState() {
    super.initState();
    _billId = widget.billId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BillProvider>();
      if (_billId != null && provider.currentBill?.id != _billId) {
        provider.loadBill(_billId!);
        final bill = provider.currentBill;
        if (bill != null) {
          _titleController.text = bill.title;
          setState(() => _selectedDate = bill.date);
        }
      }
      provider.loadRecentFriends();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _titleValid => _titleController.text.trim().isNotEmpty;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  /// Ensures the bill exists in the DB, creating it lazily on first person add.
  Future<String?> _ensureBillCreated() async {
    if (_billId != null) return _billId;
    if (!_titleValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a bill name first')));
      return null;
    }
    final bill = await context.read<BillProvider>().createBill(
      title: _titleController.text.trim(),
      date: _selectedDate,
    );
    if (mounted) setState(() => _billId = bill.id);
    return bill.id;
  }

  Future<void> _addPerson() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final provider = context.read<BillProvider>();
    final id = await _ensureBillCreated();
    if (id == null || !mounted) return;

    HapticFeedback.lightImpact();
    provider.addPerson(name);
    _nameController.clear();
    _focusNode.requestFocus();
  }

  Future<void> _addRecentFriend(String name) async {
    final provider = context.read<BillProvider>();
    final alreadyAdded = provider.people.any(
      (p) => p.name.toLowerCase() == name.toLowerCase(),
    );
    if (alreadyAdded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$name is already added')));
      return;
    }
    final id = await _ensureBillCreated();
    if (id == null || !mounted) return;
    provider.addPerson(name);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Consumer<BillProvider>(
          builder: (context, provider, _) {
            final currentNames = provider.people
                .map((p) => p.name.toLowerCase())
                .toSet();
            final availableFriends = provider.recentFriends
                .where((name) => !currentNames.contains(name.toLowerCase()))
                .toList();

            return Column(
              children: [
                // ── Inline Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/'),
                        icon: const Icon(LucideIcons.arrowLeft, size: 22),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.users,
                        size: 22,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Setup',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),

                // ── Step Indicator ──
                const StepProgressIndicator(currentStep: 1),

                // ── Content ──
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── Bill Name field ──
                              Container(
                                padding: const EdgeInsets.all(20),
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
                                      autofocus: _billId == null,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: const InputDecoration(
                                        hintText: 'e.g. Pizza Night',
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // ── Date picker ──
                              InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusCard,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
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
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.calendarDays,
                                        size: 18,
                                        color: AppTheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        DateFormat(
                                          'MMMM d, yyyy',
                                        ).format(_selectedDate),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        LucideIcons.chevronDown,
                                        size: 16,
                                        color: isDark
                                            ? AppTheme.darkSubtleText
                                            : AppTheme.subtleText,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Input container
                              Container(
                                padding: const EdgeInsets.all(20),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          LucideIcons.userPlus,
                                          size: 16,
                                          color: AppTheme.primaryLight,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Who's splitting?",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _nameController,
                                            focusNode: _focusNode,
                                            textCapitalization:
                                                TextCapitalization.words,
                                            decoration: const InputDecoration(
                                              hintText: 'Enter name...',
                                            ),
                                            onSubmitted: (_) => _addPerson(),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          height: 48,
                                          width: 48,
                                          child: FilledButton(
                                            onPressed: _addPerson,
                                            style: FilledButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Icon(
                                              LucideIcons.plus,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Recent friends
                              if (availableFriends.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            LucideIcons.history,
                                            size: 16,
                                            color: AppTheme.primaryLight,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Recent Friends',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.primaryLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: availableFriends.map((name) {
                                          return ActionChip(
                                            label: Text(name),
                                            onPressed: () =>
                                                _addRecentFriend(name),
                                            avatar: const Icon(
                                              LucideIcons.plus,
                                              size: 14,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // People count badge
                              if (provider.people.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.users,
                                      size: 16,
                                      color: isDark
                                          ? AppTheme.darkSubtleText
                                          : AppTheme.subtleText,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Added (${provider.people.length})',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppTheme.darkSubtleText
                                            : AppTheme.subtleText,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // ── People list as rich cards ──
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final person = provider.people[index];
                            final color = AppTheme.getPersonColor(index);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
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
                                child: Row(
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
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        person.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        LucideIcons.x,
                                        size: 18,
                                        color: isDark
                                            ? AppTheme.darkSubtleText
                                            : AppTheme.subtleText,
                                      ),
                                      onPressed: () {
                                        provider.removePerson(person.id);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${person.name} removed',
                                            ),
                                            action: SnackBarAction(
                                              label: 'Undo',
                                              onPressed: () {
                                                provider.addPerson(person.name);
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }, childCount: provider.people.length),
                        ),
                      ),

                      // Bottom pad
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                ),

                // ── Bottom Next Button ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: ElevatedButton(
                    onPressed: _titleValid && provider.people.length >= 2
                        ? () => context.go('/bill/$_billId')
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          !_titleValid
                              ? 'Enter a bill name'
                              : provider.people.length < 2
                              ? 'Add at least 2 people'
                              : 'Next: Add Items',
                        ),
                        if (_titleValid && provider.people.length >= 2) ...[
                          const SizedBox(width: 8),
                          Icon(LucideIcons.arrowRight, size: 18),
                        ],
                      ],
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
}
