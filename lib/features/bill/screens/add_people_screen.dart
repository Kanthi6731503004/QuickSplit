import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';
import 'package:quicksplit/core/widgets/step_progress_indicator.dart';

/// Screen to add participants to the bill.
class AddPeopleScreen extends StatefulWidget {
  final String billId;
  const AddPeopleScreen({super.key, required this.billId});

  @override
  State<AddPeopleScreen> createState() => _AddPeopleScreenState();
}

class _AddPeopleScreenState extends State<AddPeopleScreen> {
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BillProvider>();
      if (provider.currentBill?.id != widget.billId) {
        provider.loadBill(widget.billId);
      }
      provider.loadRecentFriends();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addPerson() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    HapticFeedback.lightImpact();
    context.read<BillProvider>().addPerson(name);
    _nameController.clear();
    _focusNode.requestFocus();
  }

  void _addRecentFriend(String name) {
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
                        'Add People',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),

                // ── Step Indicator ──
                const StepProgressIndicator(currentStep: 2),

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
                    onPressed: provider.people.length >= 2
                        ? () => context.go('/bill/${widget.billId}')
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          provider.people.length < 2
                              ? 'Add at least 2 people'
                              : 'Next: Add Items',
                        ),
                        if (provider.people.length >= 2) ...[
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
