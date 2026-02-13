import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quicksplit/core/models/models.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

/// Bottom sheet for assigning people to a bill item (the 2-tap flow).
/// Features scale-bounce animation on avatar toggle.
class AssignItemSheet extends StatelessWidget {
  final BillItem item;
  const AssignItemSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, provider, _) {
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

              Text(
                "Who's sharing this?",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),

              // Person toggle grid with scale-bounce
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

                  return _BounceToggleAvatar(
                    isSelected: isSelected,
                    color: color,
                    person: person,
                    width: (MediaQuery.of(context).size.width - 72) / 2,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      provider.togglePersonOnItem(liveItem.id, person.id);
                    },
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
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        provider.assignItemToEveryone(liveItem.id);
                      },
                      child: const Text('Everyone'),
                    ),
                  ),
                  const SizedBox(width: 12),
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

/// A person avatar tile that plays a scale-bounce (1.0 → 1.2 → 1.0) when toggled.
class _BounceToggleAvatar extends StatefulWidget {
  final bool isSelected;
  final Color color;
  final Person person;
  final double width;
  final VoidCallback onTap;

  const _BounceToggleAvatar({
    required this.isSelected,
    required this.color,
    required this.person,
    required this.width,
    required this.onTap,
  });

  @override
  State<_BounceToggleAvatar> createState() => _BounceToggleAvatarState();
}

class _BounceToggleAvatarState extends State<_BounceToggleAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _prevSelected = false;

  @override
  void initState() {
    super.initState();
    _prevSelected = widget.isSelected;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_BounceToggleAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != _prevSelected) {
      _prevSelected = widget.isSelected;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.color.withValues(alpha: 0.15)
                : Colors.transparent,
            border: Border.all(
              color: widget.isSelected ? widget.color : AppTheme.divider,
              width: widget.isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: widget.color,
                radius: 20,
                child: Text(
                  widget.person.initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.person.name,
                style: TextStyle(
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryLight,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
