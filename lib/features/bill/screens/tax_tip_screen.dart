import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

/// Screen for setting tax rate and service charge with sliders.
class TaxTipScreen extends StatefulWidget {
  final String billId;
  const TaxTipScreen({super.key, required this.billId});

  @override
  State<TaxTipScreen> createState() => _TaxTipScreenState();
}

class _TaxTipScreenState extends State<TaxTipScreen> {
  late double _taxRate;
  late double _serviceRate;

  @override
  void initState() {
    super.initState();
    final provider = context.read<BillProvider>();
    _taxRate = provider.currentBill?.taxRate ?? 7.0;
    _serviceRate = provider.currentBill?.serviceChargeRate ?? 10.0;
  }

  void _onTaxChanged(double value) {
    setState(() => _taxRate = value);
    context.read<BillProvider>().updateTaxAndService(taxRate: value);
  }

  void _onServiceChanged(double value) {
    setState(() => _serviceRate = value);
    context.read<BillProvider>().updateTaxAndService(serviceChargeRate: value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tax & Tip')),
      body: Consumer<BillProvider>(
        builder: (context, provider, _) {
          final subtotal = provider.subtotal;
          final taxAmount = subtotal * (_taxRate / 100);
          final serviceAmount = subtotal * (_serviceRate / 100);
          final grandTotal = subtotal + taxAmount + serviceAmount;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Subtotal
                _buildRow(
                  context,
                  'Subtotal',
                  '฿${subtotal.toStringAsFixed(2)}',
                ),
                const Divider(height: 32),

                // Tax slider
                Text(
                  'VAT / Tax',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _taxRate,
                        min: 0,
                        max: 20,
                        divisions: 40,
                        label: '${_taxRate.toStringAsFixed(1)}%',
                        activeColor: AppTheme.primaryLight,
                        onChanged: _onTaxChanged,
                      ),
                    ),
                    SizedBox(
                      width: 55,
                      child: Text(
                        '${_taxRate.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                _buildRow(
                  context,
                  'Tax amount',
                  '฿${taxAmount.toStringAsFixed(2)}',
                  subtle: true,
                ),
                const SizedBox(height: 20),

                // Service charge slider
                Text(
                  'Service Charge',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _serviceRate,
                        min: 0,
                        max: 25,
                        divisions: 50,
                        label: '${_serviceRate.toStringAsFixed(1)}%',
                        activeColor: AppTheme.accent,
                        onChanged: _onServiceChanged,
                      ),
                    ),
                    SizedBox(
                      width: 55,
                      child: Text(
                        '${_serviceRate.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                _buildRow(
                  context,
                  'Service amount',
                  '฿${serviceAmount.toStringAsFixed(2)}',
                  subtle: true,
                ),
                const Divider(height: 32),

                // Grand total
                _buildRow(
                  context,
                  'Grand Total',
                  '฿${grandTotal.toStringAsFixed(2)}',
                  bold: true,
                  large: true,
                ),
                const SizedBox(height: 24),

                // Per-person preview
                Text(
                  'Proportional split:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.subtleText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...provider.splits.asMap().entries.map((entry) {
                  final index = entry.key;
                  final split = entry.value;
                  final color = AppTheme.getPersonColor(index);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color,
                          radius: 12,
                          child: Text(
                            split.person.initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(split.person.name)),
                        Text(
                          '฿${split.subtotal.toStringAsFixed(0)} → ฿${split.total.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 32),

                // See Full Summary button
                ElevatedButton(
                  onPressed: () =>
                      context.push('/bill/${widget.billId}/summary'),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('See Full Summary'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
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

  Widget _buildRow(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
    bool large = false,
    bool subtle = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: large
                ? Theme.of(context).textTheme.headlineSmall
                : Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: subtle ? AppTheme.subtleText : null,
                  ),
          ),
          Text(
            value,
            style: large
                ? Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  )
                : Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: subtle ? AppTheme.subtleText : null,
                  ),
          ),
        ],
      ),
    );
  }
}
