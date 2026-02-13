import 'package:uuid/uuid.dart';

/// Represents a bill/session for splitting expenses.
class Bill {
  final String id;
  final String title;
  final DateTime date;
  final double taxRate;
  final double serviceChargeRate;
  final bool isClosed;
  final DateTime createdAt;

  Bill({
    String? id,
    required this.title,
    required this.date,
    this.taxRate = 7.0,
    this.serviceChargeRate = 10.0,
    this.isClosed = false,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Bill copyWith({
    String? title,
    DateTime? date,
    double? taxRate,
    double? serviceChargeRate,
    bool? isClosed,
  }) {
    return Bill(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      taxRate: taxRate ?? this.taxRate,
      serviceChargeRate: serviceChargeRate ?? this.serviceChargeRate,
      isClosed: isClosed ?? this.isClosed,
      createdAt: createdAt,
    );
  }

  /// Convert to a Map for SQLite storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'taxRate': taxRate,
      'serviceChargeRate': serviceChargeRate,
      'isClosed': isClosed ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a Bill from a SQLite Map.
  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'] as String,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      taxRate: (map['taxRate'] as num).toDouble(),
      serviceChargeRate: (map['serviceChargeRate'] as num).toDouble(),
      isClosed: (map['isClosed'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Bill && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Bill(id: $id, title: $title, date: $date)';
}
