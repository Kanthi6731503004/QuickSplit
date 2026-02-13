import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

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
      // Load bill if not already loaded
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

    context.read<BillProvider>().addPerson(name);
    _nameController.clear();
    _focusNode.requestFocus();
  }

  void _addRecentFriend(String name) {
    final provider = context.read<BillProvider>();
    // Don't add if already in the list
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add People')),
      body: Consumer<BillProvider>(
        builder: (context, provider, _) {
          // Filter recent friends to exclude already added people
          final currentNames = provider.people
              .map((p) => p.name.toLowerCase())
              .toSet();
          final availableFriends = provider.recentFriends
              .where((name) => !currentNames.contains(name.toLowerCase()))
              .toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  "Who's splitting?",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                // Input row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        focusNode: _focusNode,
                        textCapitalization: TextCapitalization.words,
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Icon(Icons.add, size: 24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Added people list
                if (provider.people.isNotEmpty) ...[
                  Text(
                    'Added (${provider.people.length})',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.subtleText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                Expanded(
                  child: ListView(
                    children: [
                      // People list
                      ...provider.people.asMap().entries.map((entry) {
                        final index = entry.key;
                        final person = entry.value;
                        final color = AppTheme.getPersonColor(index);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color,
                            radius: 18,
                            child: Text(
                              person.initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          title: Text(person.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              provider.removePerson(person.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${person.name} removed'),
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
                        );
                      }),

                      // Recent friends section
                      if (availableFriends.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Recent Friends',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.subtleText,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableFriends.map((name) {
                            return ActionChip(
                              label: Text(name),
                              onPressed: () => _addRecentFriend(name),
                              avatar: const Icon(Icons.add, size: 16),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Next button
                const SizedBox(height: 16),
                ElevatedButton(
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
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
