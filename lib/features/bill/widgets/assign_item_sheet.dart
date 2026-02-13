import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quicksplit/core/models/models.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

/// Bottom sheet for assigning people to a bill item (the 2-tap flow).
class AssignItemSheet extends StatelessWidget {
  final BillItem item;
  const AssignItemSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, provider, _) {
        // Get the live version of this item
        final liveItem = provider.items.firstWhere(
          (i) => i.id == item.id,
          orElse: () => item,
        );
        final assignedCount = liveItem.assignedUserIds.length;
        final pricePerPerson = assignedCount > 0
            ? liveItem.price / assignedCount
            : liveItem.price;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Item info
              Text(
                'Assign: ${liveItem.name}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                '฿${liveItem.price.toStringAsFixed(2)}',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppTheme.subtleText),
              ),
              const SizedBox(height: 20),

              // Question
              Text(
                "Who's sharing this?",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),

              // Person toggle grid
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: provider.people.asMap().entries.map((entry) {
                  final index = entry.key;
                  final person = entry.value;
                  final color = AppTheme.getPersonColor(index);
                  final isSelected = liveItem.assignedUserIds.contains(
                    person.id,
                  );

                  return GestureDetector(
                    onTap: () {
                      provider.togglePersonOnItem(liveItem.id, person.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: (MediaQuery.of(context).size.width - 72) / 2,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? color : AppTheme.divider,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: color,
                            radius: 20,
                            child: Text(
                              person.initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            person.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppTheme.primaryLight,
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Live split info
              if (assignedCount > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Split: ฿${pricePerPerson.toStringAsFixed(2)} each ($assignedCount ${assignedCount == 1 ? "person" : "people"})',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  // Everyone button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        provider.assignItemToEveryone(liveItem.id);
                      },
                      child: const Text('Everyone'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Done button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
