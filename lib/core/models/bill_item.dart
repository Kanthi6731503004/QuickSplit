import 'package:uuid/uuid.dart';

/// Represents an item on the bill (e.g., "Pad Thai", ฿120).
class BillItem {
  final String id;
  final String name;
  final double price;
  final String billId;
  final List<String> assignedUserIds;

  BillItem({
    String? id,
    required this.name,
    required this.price,
    required this.billId,
    List<String>? assignedUserIds,
  }) : id = id ?? const Uuid().v4(),
       assignedUserIds = assignedUserIds ?? [];

  BillItem copyWith({
    String? name,
    double? price,
    List<String>? assignedUserIds,
  }) {
    return BillItem(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      billId: billId,
      assignedUserIds: assignedUserIds ?? List.from(this.assignedUserIds),
    );
  }

  /// Whether this item has been assigned to at least one person.
  bool get isAssigned => assignedUserIds.isNotEmpty;

  /// Number of people sharing this item.
  int get splitCount => assignedUserIds.length;

  /// Price per person for this item.
  /// Handles the rounding carefully to avoid lost cents.
  double get pricePerPerson {
    if (assignedUserIds.isEmpty) return price;
    return price / assignedUserIds.length;
  }

  /// Get the share for a specific person (handles rounding remainder).
  /// The first person in the list absorbs the rounding difference.
  double getShareForPerson(String personId) {
    if (!assignedUserIds.contains(personId)) return 0.0;
    if (assignedUserIds.length == 1) return price;

    final count = assignedUserIds.length;
    // Round each share to 2 decimal places
    final baseShare = (price / count * 100).floor() / 100;
    final totalBase = baseShare * count;
    final remainder = ((price - totalBase) * 100).round() / 100;

    // First person gets the remainder to handle the "penny" problem
    if (assignedUserIds.first == personId) {
      return baseShare + remainder;
    }
    return baseShare;
  }

  /// Convert to a Map for SQLite storage.
  /// Note: assignedUserIds are stored in a separate junction table.
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'price': price, 'billId': billId};
  }

  /// Create a BillItem from a SQLite Map + assigned user IDs.
  factory BillItem.fromMap(
    Map<String, dynamic> map, {
    List<String>? assignedUserIds,
  }) {
    return BillItem(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      billId: map['billId'] as String,
      assignedUserIds: assignedUserIds ?? [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BillItem && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BillItem(id: $id, name: $name, price: $price, assigned: $assignedUserIds)';
}
