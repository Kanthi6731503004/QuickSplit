import 'package:flutter/foundation.dart';
import 'package:quicksplit/core/database/database_helper.dart';
import 'package:quicksplit/core/models/models.dart';
import 'package:quicksplit/core/services/split_calculator.dart';

/// Central state management for the entire bill workflow.
///
/// Manages: current bill, people, items, assignments, calculations.
/// Persists all changes to SQLite automatically.
class BillProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  // ── State ──────────────────────────────────────────────────────
  List<Bill> _bills = [];
  Bill? _currentBill;
  List<Person> _people = [];
  List<BillItem> _items = [];
  List<PersonSplit> _splits = [];
  List<String> _recentFriends = [];
  bool _isLoading = false;
  String? _error;

  // ── Getters ────────────────────────────────────────────────────
  List<Bill> get bills => List.unmodifiable(_bills);
  Bill? get currentBill => _currentBill;
  List<Person> get people => List.unmodifiable(_people);
  List<BillItem> get items => List.unmodifiable(_items);
  List<PersonSplit> get splits => List.unmodifiable(_splits);
  List<String> get recentFriends => List.unmodifiable(_recentFriends);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Items that haven't been assigned to anyone.
  List<BillItem> get unassignedItems =>
      _items.where((item) => !item.isAssigned).toList();

  /// Whether all items are assigned.
  bool get allItemsAssigned => _items.every((item) => item.isAssigned);

  /// Subtotal (sum of all item prices).
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.price);

  /// Tax amount based on subtotal.
  double get taxAmount =>
      _currentBill != null ? subtotal * (_currentBill!.taxRate / 100) : 0.0;

  /// Service charge amount based on subtotal.
  double get serviceChargeAmount => _currentBill != null
      ? subtotal * (_currentBill!.serviceChargeRate / 100)
      : 0.0;

  /// Grand total including tax and service charge.
  double get grandTotal => subtotal + taxAmount + serviceChargeAmount;

  // ── Bill Operations ────────────────────────────────────────────

  /// Load all bills from database (for Home screen).
  Future<void> loadBills() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final maps = await _db.getAllBills();
      _bills = maps.map((m) => Bill.fromMap(m)).toList();
    } catch (e) {
      _error = 'Failed to load bills: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create a new bill and set it as current.
  Future<Bill> createBill({
    required String title,
    required DateTime date,
  }) async {
    final bill = Bill(title: title, date: date);
    await _db.insertBill(bill.toMap());
    _bills.insert(0, bill);
    _currentBill = bill;
    _people = [];
    _items = [];
    _splits = [];
    notifyListeners();
    return bill;
  }

  /// Load a bill and all its associated data.
  Future<void> loadBill(String billId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final billMap = await _db.getBill(billId);
      if (billMap == null) {
        _error = 'Bill not found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentBill = Bill.fromMap(billMap);

      // Load people
      final peopleMaps = await _db.getPeopleForBill(billId);
      _people = peopleMaps.map((m) => Person.fromMap(m)).toList();

      // Load items with assignments
      final itemMaps = await _db.getItemsForBill(billId);
      _items = [];
      for (final map in itemMaps) {
        final assignedIds = await _db.getAssignedUserIds(map['id'] as String);
        _items.add(BillItem.fromMap(map, assignedUserIds: assignedIds));
      }

      // Recalculate splits
      _recalculate();
    } catch (e) {
      _error = 'Failed to load bill: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Update the current bill's tax and service charge rates.
  Future<void> updateTaxAndService({
    double? taxRate,
    double? serviceChargeRate,
  }) async {
    if (_currentBill == null) return;

    _currentBill = _currentBill!.copyWith(
      taxRate: taxRate,
      serviceChargeRate: serviceChargeRate,
    );
    await _db.updateBill(_currentBill!.id, _currentBill!.toMap());
    _recalculate();
    notifyListeners();
  }

  /// Close/finalize the bill.
  Future<void> closeBill() async {
    if (_currentBill == null) return;

    _currentBill = _currentBill!.copyWith(isClosed: true);
    await _db.updateBill(_currentBill!.id, _currentBill!.toMap());

    // Update in bills list too
    final idx = _bills.indexWhere((b) => b.id == _currentBill!.id);
    if (idx >= 0) _bills[idx] = _currentBill!;

    notifyListeners();
  }

  /// Delete a bill.
  Future<void> deleteBill(String billId) async {
    await _db.deleteBill(billId);
    _bills.removeWhere((b) => b.id == billId);
    if (_currentBill?.id == billId) {
      _currentBill = null;
      _people = [];
      _items = [];
      _splits = [];
    }
    notifyListeners();
  }

  // ── Person Operations ──────────────────────────────────────────

  /// Add a person to the current bill.
  Future<Person> addPerson(String name) async {
    if (_currentBill == null) throw StateError('No current bill');

    final person = Person(name: name.trim(), billId: _currentBill!.id);
    await _db.insertPerson(person.toMap());
    _people.add(person);
    _recalculate();
    notifyListeners();
    return person;
  }

  /// Update a person's name.
  Future<void> updatePerson(String personId, String newName) async {
    final idx = _people.indexWhere((p) => p.id == personId);
    if (idx < 0) return;

    _people[idx] = _people[idx].copyWith(name: newName.trim());
    await _db.updatePerson(personId, _people[idx].toMap());
    _recalculate();
    notifyListeners();
  }

  /// Remove a person from the current bill.
  Future<void> removePerson(String personId) async {
    await _db.deletePerson(personId);
    _people.removeWhere((p) => p.id == personId);

    // Remove this person from all item assignments
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].assignedUserIds.contains(personId)) {
        final newIds = List<String>.from(_items[i].assignedUserIds)
          ..remove(personId);
        _items[i] = _items[i].copyWith(assignedUserIds: newIds);
        await _db.setItemAssignments(_items[i].id, newIds);
      }
    }

    _recalculate();
    notifyListeners();
  }

  /// Load recent friend names from past bills.
  Future<void> loadRecentFriends() async {
    _recentFriends = await _db.getRecentFriendNames();
    notifyListeners();
  }

  // ── Item Operations ────────────────────────────────────────────

  /// Add an item to the current bill.
  Future<BillItem> addItem({
    required String name,
    required double price,
    List<String>? assignedUserIds,
  }) async {
    if (_currentBill == null) throw StateError('No current bill');

    final item = BillItem(
      name: name.trim(),
      price: price,
      billId: _currentBill!.id,
      assignedUserIds: assignedUserIds,
    );
    await _db.insertBillItem(item.toMap());

    // Save assignments if any
    if (assignedUserIds != null && assignedUserIds.isNotEmpty) {
      await _db.setItemAssignments(item.id, assignedUserIds);
    }

    _items.add(item);
    _recalculate();
    notifyListeners();
    return item;
  }

  /// Update an item's name and/or price.
  Future<void> updateItem(String itemId, {String? name, double? price}) async {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx < 0) return;

    _items[idx] = _items[idx].copyWith(name: name, price: price);
    await _db.updateBillItem(itemId, _items[idx].toMap());
    _recalculate();
    notifyListeners();
  }

  /// Remove an item from the current bill.
  Future<void> removeItem(String itemId) async {
    await _db.deleteBillItem(itemId);
    _items.removeWhere((i) => i.id == itemId);
    _recalculate();
    notifyListeners();
  }

  /// Assign/unassign people to an item.
  Future<void> setItemAssignments(String itemId, List<String> personIds) async {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx < 0) return;

    _items[idx] = _items[idx].copyWith(assignedUserIds: personIds);
    await _db.setItemAssignments(itemId, personIds);
    _recalculate();
    notifyListeners();
  }

  /// Toggle a person's assignment on an item.
  Future<void> togglePersonOnItem(String itemId, String personId) async {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx < 0) return;

    final currentIds = List<String>.from(_items[idx].assignedUserIds);
    if (currentIds.contains(personId)) {
      currentIds.remove(personId);
    } else {
      currentIds.add(personId);
    }

    _items[idx] = _items[idx].copyWith(assignedUserIds: currentIds);
    await _db.setItemAssignments(itemId, currentIds);
    _recalculate();
    notifyListeners();
  }

  /// Assign an item to everyone.
  Future<void> assignItemToEveryone(String itemId) async {
    final allIds = _people.map((p) => p.id).toList();
    await setItemAssignments(itemId, allIds);
  }

  // ── Calculation ────────────────────────────────────────────────

  void _recalculate() {
    if (_currentBill == null || _people.isEmpty) {
      _splits = [];
      return;
    }

    _splits = SplitCalculator.calculate(
      people: _people,
      items: _items,
      taxRate: _currentBill!.taxRate,
      serviceChargeRate: _currentBill!.serviceChargeRate,
    );
  }

  /// Generate share text for the current bill.
  String generateShareText() {
    if (_currentBill == null) return '';
    return SplitCalculator.generateShareText(
      bill: _currentBill!,
      splits: _splits,
      grandTotal: grandTotal,
    );
  }

  // ── Utility ────────────────────────────────────────────────────

  /// Clear the current bill context (when navigating away).
  void clearCurrentBill() {
    _currentBill = null;
    _people = [];
    _items = [];
    _splits = [];
    notifyListeners();
  }

  /// Get person count and total for a bill (for home screen cards).
  Future<({int personCount, double total})> getBillSummary(
    String billId,
  ) async {
    final count = await _db.getPersonCount(billId);
    final total = await _db.getBillTotal(billId);
    return (personCount: count, total: total);
  }
}
