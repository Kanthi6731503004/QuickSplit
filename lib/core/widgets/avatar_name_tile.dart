import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

/// A person avatar card showing their color, initial, and name.
/// Tapping the pencil icon opens a rename dialog (keyboard only on explicit tap).
class AvatarNameTile extends StatelessWidget {
  final String personId;
  final String name;
  final int colorIndex;
  final VoidCallback onRemove;
  final Future<void> Function(String personId, String newName) onRename;

  const AvatarNameTile({
    super.key,
    required this.personId,
    required this.name,
    required this.colorIndex,
    required this.onRemove,
    required this.onRename,
  });

  Future<void> _showRenameDialog(BuildContext context) async {
    final ctrl = TextEditingController(text: name);
    final color = AppTheme.getPersonColor(colorIndex);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 16,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Rename'),
          ],
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Enter name...'),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) Navigator.pop(ctx, v.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx, ctrl.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await onRename(personId, result);
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppTheme.getPersonColor(colorIndex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 18,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
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
              name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: Icon(
              LucideIcons.pencil,
              size: 16,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showRenameDialog(context);
            },
            tooltip: 'Rename',
          ),
          IconButton(
            icon: Icon(
              LucideIcons.x,
              size: 18,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            onPressed: onRemove,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
