import 'package:uuid/uuid.dart';

/// Represents a participant in a bill.
class Person {
  final String id;
  final String name;
  final String billId;

  Person({String? id, required this.name, required this.billId})
    : id = id ?? const Uuid().v4();

  Person copyWith({String? name}) {
    return Person(id: id, name: name ?? this.name, billId: billId);
  }

  /// Convert to a Map for SQLite storage.
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'billId': billId};
  }

  /// Create a Person from a SQLite Map.
  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'] as String,
      name: map['name'] as String,
      billId: map['billId'] as String,
    );
  }

  /// Get the initial letter for the avatar.
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Person && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Person(id: $id, name: $name, billId: $billId)';
}
