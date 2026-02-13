import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Manages the SQLite database for QuickSplit.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  /// Call this before using the database on web.
  static void initForWeb() {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      return await openDatabase(
        'quicksplit.db',
        version: 1,
        onCreate: _onCreate,
      );
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'quicksplit.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Bills table
    await db.execute('''
      CREATE TABLE bills (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        taxRate REAL NOT NULL DEFAULT 7.0,
        serviceChargeRate REAL NOT NULL DEFAULT 10.0,
        isClosed INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // People table
    await db.execute('''
      CREATE TABLE people (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        billId TEXT NOT NULL,
        FOREIGN KEY (billId) REFERENCES bills(id) ON DELETE CASCADE
      )
    ''');

    // Bill items table
    await db.execute('''
      CREATE TABLE bill_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        billId TEXT NOT NULL,
        FOREIGN KEY (billId) REFERENCES bills(id) ON DELETE CASCADE
      )
    ''');

    // Junction table for item-person assignments (many-to-many)
    await db.execute('''
      CREATE TABLE item_assignments (
        itemId TEXT NOT NULL,
        personId TEXT NOT NULL,
        PRIMARY KEY (itemId, personId),
        FOREIGN KEY (itemId) REFERENCES bill_items(id) ON DELETE CASCADE,
        FOREIGN KEY (personId) REFERENCES people(id) ON DELETE CASCADE
      )
    ''');

    // Indexes for performance
    await db.execute('CREATE INDEX idx_people_billId ON people(billId)');
    await db.execute(
      'CREATE INDEX idx_bill_items_billId ON bill_items(billId)',
    );
    await db.execute(
      'CREATE INDEX idx_item_assignments_itemId ON item_assignments(itemId)',
    );
    await db.execute(
      'CREATE INDEX idx_item_assignments_personId ON item_assignments(personId)',
    );
  }

  // ── Bill CRUD ──────────────────────────────────────────────────

  Future<void> insertBill(Map<String, dynamic> bill) async {
    final db = await database;
    await db.insert(
      'bills',
      bill,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllBills() async {
    final db = await database;
    return await db.query('bills', orderBy: 'createdAt DESC');
  }

  Future<Map<String, dynamic>?> getBill(String id) async {
    final db = await database;
    final results = await db.query('bills', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateBill(String id, Map<String, dynamic> bill) async {
    final db = await database;
    await db.update('bills', bill, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteBill(String id) async {
    final db = await database;
    // Cascade deletes handled by foreign keys, but sqflite needs explicit
    await db.delete(
      'item_assignments',
      where: 'itemId IN (SELECT id FROM bill_items WHERE billId = ?)',
      whereArgs: [id],
    );
    await db.delete('bill_items', where: 'billId = ?', whereArgs: [id]);
    await db.delete('people', where: 'billId = ?', whereArgs: [id]);
    await db.delete('bills', where: 'id = ?', whereArgs: [id]);
  }

  // ── Person CRUD ────────────────────────────────────────────────

  Future<void> insertPerson(Map<String, dynamic> person) async {
    final db = await database;
    await db.insert(
      'people',
      person,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPeopleForBill(String billId) async {
    final db = await database;
    return await db.query('people', where: 'billId = ?', whereArgs: [billId]);
  }

  Future<void> updatePerson(String id, Map<String, dynamic> person) async {
    final db = await database;
    await db.update('people', person, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deletePerson(String id) async {
    final db = await database;
    await db.delete('item_assignments', where: 'personId = ?', whereArgs: [id]);
    await db.delete('people', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all unique person names from past bills (for "Recent Friends").
  Future<List<String>> getRecentFriendNames() async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT DISTINCT name FROM people ORDER BY name ASC',
    );
    return results.map((r) => r['name'] as String).toList();
  }

  // ── BillItem CRUD ──────────────────────────────────────────────

  Future<void> insertBillItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert(
      'bill_items',
      item,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getItemsForBill(String billId) async {
    final db = await database;
    return await db.query(
      'bill_items',
      where: 'billId = ?',
      whereArgs: [billId],
    );
  }

  Future<void> updateBillItem(String id, Map<String, dynamic> item) async {
    final db = await database;
    await db.update('bill_items', item, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteBillItem(String id) async {
    final db = await database;
    await db.delete('item_assignments', where: 'itemId = ?', whereArgs: [id]);
    await db.delete('bill_items', where: 'id = ?', whereArgs: [id]);
  }

  // ── Assignment CRUD ────────────────────────────────────────────

  Future<void> assignItemToPerson(String itemId, String personId) async {
    final db = await database;
    await db.insert('item_assignments', {
      'itemId': itemId,
      'personId': personId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> unassignItemFromPerson(String itemId, String personId) async {
    final db = await database;
    await db.delete(
      'item_assignments',
      where: 'itemId = ? AND personId = ?',
      whereArgs: [itemId, personId],
    );
  }

  Future<void> setItemAssignments(String itemId, List<String> personIds) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'item_assignments',
        where: 'itemId = ?',
        whereArgs: [itemId],
      );
      for (final personId in personIds) {
        await txn.insert('item_assignments', {
          'itemId': itemId,
          'personId': personId,
        });
      }
    });
  }

  Future<List<String>> getAssignedUserIds(String itemId) async {
    final db = await database;
    final results = await db.query(
      'item_assignments',
      columns: ['personId'],
      where: 'itemId = ?',
      whereArgs: [itemId],
    );
    return results.map((r) => r['personId'] as String).toList();
  }

  // ── Utility ────────────────────────────────────────────────────

  /// Get people names for a bill (for home screen card avatars).
  Future<List<String>> getPeopleNames(String billId) async {
    final db = await database;
    final result = await db.query(
      'people',
      columns: ['name'],
      where: 'billId = ?',
      whereArgs: [billId],
    );
    return result.map((r) => r['name'] as String).toList();
  }

  /// Get person count for a bill (for display on home screen).
  Future<int> getPersonCount(String billId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM people WHERE billId = ?',
      [billId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get total price of items in a bill.
  Future<double> getBillTotal(String billId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(price) as total FROM bill_items WHERE billId = ?',
      [billId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Close the database.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
