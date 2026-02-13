import 'package:flutter_test/flutter_test.dart';
import 'package:quicksplit/core/models/models.dart';
import 'package:quicksplit/core/services/split_calculator.dart';

void main() {
  group('SplitCalculator', () {
    // ── Test Data ──────────────────────────────────────────────
    final billId = 'test-bill-id';

    Person makePerson(String id, String name) =>
        Person(id: id, name: name, billId: billId);

    BillItem makeItem(String name, double price, List<String> assignedIds) =>
        BillItem(
          id: 'item-$name',
          name: name,
          price: price,
          billId: billId,
          assignedUserIds: assignedIds,
        );

    // ── The "Penny" Test ─────────────────────────────────────
    test('100 THB split 3 ways should total exactly 100', () {
      final people = [
        makePerson('p1', 'Alice'),
        makePerson('p2', 'Bob'),
        makePerson('p3', 'Charlie'),
      ];
      final items = [
        makeItem('Shared Dish', 100.0, ['p1', 'p2', 'p3']),
      ];

      final splits = SplitCalculator.calculate(
        people: people,
        items: items,
        taxRate: 0,
        serviceChargeRate: 0,
      );

      final totalSum = splits.fold(0.0, (sum, s) => sum + s.total);
      expect(totalSum, closeTo(100.0, 0.01));

      // Each person should pay ~33.33
      for (final split in splits) {
        expect(split.total, greaterThanOrEqualTo(33.33));
        expect(split.total, lessThanOrEqualTo(33.34));
      }
    });

    // ── The "Empty" Test ─────────────────────────────────────
    test('0 people should return empty list, not crash', () {
      final splits = SplitCalculator.calculate(
        people: [],
        items: [makeItem('Pizza', 300, [])],
        taxRate: 7.0,
        serviceChargeRate: 10.0,
      );

      expect(splits, isEmpty);
    });

    // ── The "Tax" Test ───────────────────────────────────────
    test('tax calculates on original price proportionally', () {
      final people = [makePerson('p1', 'Alice'), makePerson('p2', 'Bob')];
      final items = [
        makeItem('Expensive', 200.0, ['p1']),
        makeItem('Cheap', 100.0, ['p2']),
      ];

      final splits = SplitCalculator.calculate(
        people: people,
        items: items,
        taxRate: 10.0,
        serviceChargeRate: 0,
      );

      // Alice has 200/300 = 66.67% of the bill
      // Bob has 100/300 = 33.33%
      // Tax on 300 = 30
      // Alice's tax = 30 * (200/300) = 20
      // Bob's tax = 30 * (100/300) = 10
      final alice = splits.firstWhere((s) => s.person.id == 'p1');
      final bob = splits.firstWhere((s) => s.person.id == 'p2');

      expect(alice.subtotal, closeTo(200.0, 0.01));
      expect(alice.taxAmount, closeTo(20.0, 0.01));
      expect(alice.total, closeTo(220.0, 0.01));

      expect(bob.subtotal, closeTo(100.0, 0.01));
      expect(bob.taxAmount, closeTo(10.0, 0.01));
      expect(bob.total, closeTo(110.0, 0.01));
    });

    // ── Proportional Service Charge ──────────────────────────
    test('service charge distributes proportionally', () {
      final people = [makePerson('p1', 'Alice'), makePerson('p2', 'Bob')];
      final items = [
        makeItem('Item A', 300.0, ['p1']),
        makeItem('Item B', 100.0, ['p2']),
      ];

      final splits = SplitCalculator.calculate(
        people: people,
        items: items,
        taxRate: 7.0,
        serviceChargeRate: 10.0,
      );

      // Grand subtotal = 400
      // Tax = 400 * 0.07 = 28
      // Service = 400 * 0.10 = 40
      // Grand total = 468
      final totalSum = splits.fold(0.0, (sum, s) => sum + s.total);
      expect(totalSum, closeTo(468.0, 0.01));
    });

    // ── Solo Item ────────────────────────────────────────────
    test('solo item assigns 100% to one person', () {
      final people = [makePerson('p1', 'Alice'), makePerson('p2', 'Bob')];
      final items = [
        makeItem('Solo Dish', 250.0, ['p1']),
      ];

      final splits = SplitCalculator.calculate(
        people: people,
        items: items,
        taxRate: 0,
        serviceChargeRate: 0,
      );

      final alice = splits.firstWhere((s) => s.person.id == 'p1');
      final bob = splits.firstWhere((s) => s.person.id == 'p2');

      expect(alice.total, closeTo(250.0, 0.01));
      expect(bob.total, closeTo(0.0, 0.01));
    });

    // ── Unassigned Items Are Ignored ─────────────────────────
    test('unassigned items are not included in split', () {
      final people = [makePerson('p1', 'Alice')];
      final items = [
        makeItem('Assigned', 100.0, ['p1']),
        makeItem('Unassigned', 200.0, []),
      ];

      final splits = SplitCalculator.calculate(
        people: people,
        items: items,
        taxRate: 0,
        serviceChargeRate: 0,
      );

      expect(splits.first.total, closeTo(100.0, 0.01));
    });

    // ── Share Text Generation ────────────────────────────────
    test('generates correct share text', () {
      final bill = Bill(
        id: billId,
        title: 'Pizza Night',
        date: DateTime(2026, 2, 13),
        taxRate: 7.0,
        serviceChargeRate: 10.0,
      );

      final splits = [
        PersonSplit(
          person: makePerson('p1', 'Alice'),
          itemShares: [],
          subtotal: 200.0,
          taxAmount: 14.0,
          serviceChargeAmount: 20.0,
          total: 234.0,
        ),
      ];

      final text = SplitCalculator.generateShareText(
        bill: bill,
        splits: splits,
        grandTotal: 234.0,
      );

      expect(text, contains('QuickSplit'));
      expect(text, contains('Pizza Night'));
      expect(text, contains('Alice'));
      expect(text, contains('234.00'));
      expect(text, contains('7.0% VAT'));
    });
  });

  group('BillItem', () {
    test('getShareForPerson handles rounding correctly', () {
      final item = BillItem(
        name: 'Test',
        price: 100.0,
        billId: 'bill',
        assignedUserIds: ['a', 'b', 'c'],
      );

      final shareA = item.getShareForPerson('a');
      final shareB = item.getShareForPerson('b');
      final shareC = item.getShareForPerson('c');

      // Total should equal exactly 100
      expect(shareA + shareB + shareC, closeTo(100.0, 0.01));
    });

    test('getShareForPerson returns 0 for non-assigned person', () {
      final item = BillItem(
        name: 'Test',
        price: 100.0,
        billId: 'bill',
        assignedUserIds: ['a', 'b'],
      );

      expect(item.getShareForPerson('z'), equals(0.0));
    });
  });
}
