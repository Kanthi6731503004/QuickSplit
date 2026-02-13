import 'package:quicksplit/core/models/models.dart';

/// Holds the calculated result for a single person.
class PersonSplit {
  final Person person;
  final List<ItemShare> itemShares;
  final double subtotal;
  final double taxAmount;
  final double serviceChargeAmount;
  final double total;

  PersonSplit({
    required this.person,
    required this.itemShares,
    required this.subtotal,
    required this.taxAmount,
    required this.serviceChargeAmount,
    required this.total,
  });
}

/// A single item's share for a person.
class ItemShare {
  final BillItem item;
  final double amount;
  final int splitCount;

  ItemShare({
    required this.item,
    required this.amount,
    required this.splitCount,
  });
}

/// Pure calculation engine — no side effects, easily testable.
class SplitCalculator {
  /// Calculate the split for all people in a bill.
  ///
  /// Handles:
  /// - Items assigned to one person (100%)
  /// - Items split among multiple people (equal shares)
  /// - Proportional tax and service charge
  /// - Rounding (first person absorbs the penny remainder)
  static List<PersonSplit> calculate({
    required List<Person> people,
    required List<BillItem> items,
    required double taxRate,
    required double serviceChargeRate,
  }) {
    if (people.isEmpty) return [];

    // Step 1: Calculate each person's subtotal from assigned items
    final Map<String, List<ItemShare>> personShares = {};
    final Map<String, double> personSubtotals = {};

    for (final person in people) {
      personShares[person.id] = [];
      personSubtotals[person.id] = 0.0;
    }

    for (final item in items) {
      if (!item.isAssigned) continue;

      for (final personId in item.assignedUserIds) {
        if (!personSubtotals.containsKey(personId)) continue;

        final share = item.getShareForPerson(personId);
        personShares[personId]!.add(
          ItemShare(item: item, amount: share, splitCount: item.splitCount),
        );
        personSubtotals[personId] = personSubtotals[personId]! + share;
      }
    }

    // Step 2: Calculate grand subtotal for proportional distribution
    final grandSubtotal = personSubtotals.values.fold(0.0, (sum, v) => sum + v);

    // Step 3: Calculate each person's proportional tax & service
    final results = <PersonSplit>[];

    for (final person in people) {
      final subtotal = personSubtotals[person.id] ?? 0.0;
      final proportion = grandSubtotal > 0 ? subtotal / grandSubtotal : 0.0;

      final taxAmount = _roundCurrency(
        grandSubtotal * (taxRate / 100) * proportion,
      );
      final serviceAmount = _roundCurrency(
        grandSubtotal * (serviceChargeRate / 100) * proportion,
      );
      final total = _roundCurrency(subtotal + taxAmount + serviceAmount);

      results.add(
        PersonSplit(
          person: person,
          itemShares: personShares[person.id] ?? [],
          subtotal: _roundCurrency(subtotal),
          taxAmount: taxAmount,
          serviceChargeAmount: serviceAmount,
          total: total,
        ),
      );
    }

    // Step 4: Fix rounding — ensure individual totals sum to grand total
    _fixRounding(results, grandSubtotal, taxRate, serviceChargeRate);

    return results;
  }

  /// Round to 2 decimal places.
  static double _roundCurrency(double value) {
    return (value * 100).round() / 100;
  }

  /// Adjust the first person's total so the sum matches exactly.
  static void _fixRounding(
    List<PersonSplit> results,
    double grandSubtotal,
    double taxRate,
    double serviceChargeRate,
  ) {
    if (results.isEmpty) return;

    final expectedTotal = _roundCurrency(
      grandSubtotal * (1 + taxRate / 100 + serviceChargeRate / 100),
    );
    final actualTotal = results.fold(0.0, (sum, r) => sum + r.total);
    final diff = _roundCurrency(expectedTotal - actualTotal);

    if (diff != 0.0) {
      // Adjust the first person
      final first = results[0];
      results[0] = PersonSplit(
        person: first.person,
        itemShares: first.itemShares,
        subtotal: first.subtotal,
        taxAmount: first.taxAmount,
        serviceChargeAmount: first.serviceChargeAmount,
        total: _roundCurrency(first.total + diff),
      );
    }
  }

  /// Generate a shareable text summary of the split.
  static String generateShareText({
    required Bill bill,
    required List<PersonSplit> splits,
    required double grandTotal,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🧾 QuickSplit: ${bill.title}');
    buffer.writeln('📅 ${bill.date.day}/${bill.date.month}/${bill.date.year}');
    buffer.writeln();

    for (final split in splits) {
      buffer.writeln(
        '• ${split.person.name}: ฿${split.total.toStringAsFixed(2)}',
      );
    }

    buffer.writeln();
    buffer.writeln('💰 Grand Total: ฿${grandTotal.toStringAsFixed(2)}');

    if (bill.taxRate > 0 || bill.serviceChargeRate > 0) {
      final parts = <String>[];
      if (bill.taxRate > 0) parts.add('${bill.taxRate}% VAT');
      if (bill.serviceChargeRate > 0) {
        parts.add('${bill.serviceChargeRate}% Service');
      }
      buffer.writeln('(incl. ${parts.join(' + ')})');
    }

    buffer.writeln();
    buffer.writeln('Split with QuickSplit ⚡');

    return buffer.toString();
  }
}
