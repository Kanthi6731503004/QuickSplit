import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quicksplit/core/models/models.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

/// Bottom sheet for assigning people to a bill item.
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
        final pricePerPerson =
            assignedCount > 0 ? liveItem.price / assignedCount : liveItem.price;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Item header ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      liveItem.name,
                      style: GoogleFonts.dmSerifDisplay(fontSize: 18),
                    ),
                  ),
                  Text(
                    '฿${liveItem.price.toStringAsFixed(2)}',
                    style: AppTheme.amountStyle(
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── People list ──
              ...provider.people.asMap().entries.map((entry) {
                final index = entry.key;
                final person = entry.value;
                final color = AppTheme.getPersonColor(index);
                final isSelected =
                    liveItem.assignedUserIds.contains(person.id);

                return _PersonRow(
                  person: person,
                  color: color,
                  isSelected: isSelected,
                  shareAmount: isSelected ? pricePerPerson : null,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    provider.togglePersonOnItem(liveItem.id, person.id);
                  },
                );
              }),

              const SizedBox(height: 16),

              // ── Live split info ──
              if (assignedCount > 0)
                Center(
                  child: Text(
                    '฿${pricePerPerson.toStringAsFixed(2)} each · $assignedCount ${assignedCount == 1 ? "person" : "people"}',
                    style: AppTheme.amountStyle(
                      size: 13,
                      color: AppColors.positive,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // ── Action buttons ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        provider.assignItemToEveryone(liveItem.id);
                      },
                      icon: const Icon(LucideIcons.users, size: 16),
                      label: const Text('Everyone'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusButton),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
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

// ── Person Row ───────────────────────────────────────────────────────────────

class _PersonRow extends StatefulWidget {
  final Person person;
  final Color color;
  final bool isSelected;
  final double? shareAmount;
  final bool isDark;
  final VoidCallback onTap;

  const _PersonRow({
    required this.person,
    required this.color,
    required this.isSelected,
    required this.shareAmount,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_PersonRow> createState() => _PersonRowState();
}

class _PersonRowState extends State<_PersonRow>
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
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_PersonRow oldWidget) {
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
    final borderColor =
        widget.isDark ? AppColors.borderDark : AppColors.border;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: CircleAvatar(
                backgroundColor: widget.color,
                radius: 16,
                child: Text(
                  widget.person.initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.person.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: widget.isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (widget.isSelected && widget.shareAmount != null)
                    Text(
                      '฿${widget.shareAmount!.toStringAsFixed(2)}',
                      style: AppTheme.amountStyle(
                        size: 12,
                        color: widget.isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isSelected
                    ? widget.color
                    : Colors.transparent,
                border: Border.all(
                  color: widget.isSelected
                      ? widget.color
                      : borderColor,
                  width: 1.5,
                ),
              ),
              child: widget.isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
