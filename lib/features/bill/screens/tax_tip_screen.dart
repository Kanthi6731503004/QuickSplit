import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/theme/app_theme.dart';
import 'package:quicksplit/core/widgets/step_progress_indicator.dart';

/// Screen for setting tax rate and service charge with sliders + preset chips.
class TaxTipScreen extends StatefulWidget {
  final String billId;
  const TaxTipScreen({super.key, required this.billId});

  @override
  State<TaxTipScreen> createState() => _TaxTipScreenState();
}

class _TaxTipScreenState extends State<TaxTipScreen> {
  late double _taxRate;
  late double _serviceRate;

  static const _taxPresets = [0.0, 5.0, 7.0, 10.0, 15.0];
  static const _servicePresets = [0.0, 5.0, 10.0, 15.0, 20.0];

  @override
  void initState() {
    super.initState();
    final provider = context.read<BillProvider>();
    _taxRate = provider.currentBill?.taxRate ?? 7.0;
    _serviceRate = provider.currentBill?.serviceChargeRate ?? 10.0;
  }

  void _onTaxChanged(double value) {
    HapticFeedback.selectionClick();
    setState(() => _taxRate = value);
    context.read<BillProvider>().updateTaxAndService(taxRate: value);
  }

  void _onServiceChanged(double value) {
    HapticFeedback.selectionClick();
    setState(() => _serviceRate = value);
    context.read<BillProvider>().updateTaxAndService(serviceChargeRate: value);
  }

  Widget _buildPresetChips({
    required List<double> presets,
    required double currentValue,
    required ValueChanged<double> onSelected,
    required Color activeColor,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: presets.map((preset) {
        final isActive = (currentValue - preset).abs() < 0.05;
        return ChoiceChip(
          label: Text('${preset.toStringAsFixed(0)}%'),
          selected: isActive,
          selectedColor: activeColor.withValues(alpha: 0.2),
          side: BorderSide(color: isActive ? activeColor : AppTheme.divider),
          labelStyle: TextStyle(
            color: isActive ? activeColor : null,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
          onSelected: (_) {
            HapticFeedback.lightImpact();
            onSelected(preset);
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Consumer<BillProvider>(
          builder: (context, provider, _) {
            final subtotal = provider.subtotal;
            final taxAmount = subtotal * (_taxRate / 100);
            final serviceAmount = subtotal * (_serviceRate / 100);
            final grandTotal = subtotal + taxAmount + serviceAmount;

            return Column(
              children: [
                // ── Inline Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(LucideIcons.arrowLeft, size: 22),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.percent,
                        size: 22,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tax & Tip',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),

                // ── Step Indicator ──
                const StepProgressIndicator(currentStep: 4),

                // ── Content ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Subtotal container
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : Colors.white,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.receipt,
                                    size: 16,
                                    color: AppTheme.primaryLight,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Subtotal',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '฿${subtotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tax section container
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : Colors.white,
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
                                    LucideIcons.landmark,
                                    size: 16,
                                    color: AppTheme.primaryLight,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'VAT / Tax',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildPresetChips(
                                presets: _taxPresets,
                                currentValue: _taxRate,
                                onSelected: _onTaxChanged,
                                activeColor: AppTheme.primaryLight,
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tax amount',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppTheme.darkSubtleText
                                          : AppTheme.subtleText,
                                    ),
                                  ),
                                  Text(
                                    '฿${taxAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppTheme.darkSubtleText
                                          : AppTheme.subtleText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Service charge container
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : Colors.white,
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
                                    LucideIcons.heartHandshake,
                                    size: 16,
                                    color: AppTheme.accent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Service Charge',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildPresetChips(
                                presets: _servicePresets,
                                currentValue: _serviceRate,
                                onSelected: _onServiceChanged,
                                activeColor: AppTheme.accent,
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
                                      label:
                                          '${_serviceRate.toStringAsFixed(1)}%',
                                      activeColor: AppTheme.accent,
                                      onChanged: _onServiceChanged,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 55,
                                    child: Text(
                                      '${_serviceRate.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Service amount',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppTheme.darkSubtleText
                                          : AppTheme.subtleText,
                                    ),
                                  ),
                                  Text(
                                    '฿${serviceAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppTheme.darkSubtleText
                                          : AppTheme.subtleText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Grand Total container
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusCard,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.calculator,
                                    size: 18,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Grand Total',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '฿${grandTotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Per-person preview container
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : Colors.white,
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
                                    LucideIcons.split,
                                    size: 16,
                                    color: AppTheme.primaryLight,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Proportional Split',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...provider.splits.asMap().entries.map((entry) {
                                final index = entry.key;
                                final split = entry.value;
                                final color = AppTheme.getPersonColor(index);

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: color,
                                        radius: 14,
                                        child: Text(
                                          split.person.initial,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          split.person.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          '฿${split.total.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // See Full Summary button
                        ElevatedButton(
                          onPressed: () =>
                              context.push('/bill/${widget.billId}/summary'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('See Full Summary'),
                              const SizedBox(width: 8),
                              Icon(LucideIcons.arrowRight, size: 18),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Save for Later — go home without closing
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () => context.go('/'),
                            icon: Icon(LucideIcons.home, size: 18),
                            label: const Text('Save for Later'),
                          ),
                        ),
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
