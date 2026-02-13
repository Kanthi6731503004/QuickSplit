import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

/// Bottom sheet for adding a new item to the bill.
class AddItemSheet extends StatefulWidget {
  const AddItemSheet({super.key});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final Set<String> _selectedPeople = {};

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _priceController.text.isNotEmpty &&
      (double.tryParse(_priceController.text) ?? 0) > 0;

  void _addItem() {
    if (!_isValid) return;

    final provider = context.read<BillProvider>();
    provider.addItem(
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text),
      assignedUserIds: _selectedPeople.isNotEmpty
          ? _selectedPeople.toList()
          : null,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<BillProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text('Add Item', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),

          // Item Name
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Item Name',
              hintText: 'e.g. Pad Thai',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Price
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              labelText: 'Price (฿)',
              hintText: '0.00',
              prefixText: '฿ ',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Quick assign
          Text(
            'Quick assign (optional)',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.subtleText),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.people.asMap().entries.map((entry) {
              final index = entry.key;
              final person = entry.value;
              final color = AppTheme.getPersonColor(index);
              final isSelected = _selectedPeople.contains(person.id);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedPeople.remove(person.id);
                    } else {
                      _selectedPeople.add(person.id);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.2) : null,
                    border: Border.all(
                      color: isSelected ? color : AppTheme.divider,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
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
                      const SizedBox(width: 6),
                      Text(
                        person.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Add button
          ElevatedButton(
            onPressed: _isValid ? _addItem : null,
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }
}
