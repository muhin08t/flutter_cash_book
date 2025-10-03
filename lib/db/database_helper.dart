import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../model/cash_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static final String dbName = 'cash.db';
  static final String tableCashRecord = 'cash_records';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableCashRecord (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        note TEXT,
        isCashOut INTEGER NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  // Future<int> insertCashRecord(double amount, String note, bool isCashOut) async {
  //   final db = await instance.database;
  //   return await db.insert(tableCashRecord, {
  //     'amount': amount,
  //     'note': note,
  //     'isCashOut': isCashOut ? 1 : 0,
  //     'date': DateTime.now().toIso8601String(),
  //   });
  // }

  // Insert record
  Future<int> insertCashRecord(CashRecord record) async {
    final db = await instance.database;
    return await db.insert(tableCashRecord, record.toMap());
  }

  Future<int> updateRecord(CashRecord record) async {
    final db = await instance.database;
    return await db.update(
      tableCashRecord,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteRecord(int id) async {
    final db = await instance.database;
    return await db.delete(
      tableCashRecord,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Read all records
  Future<List<CashRecord>> getCashRecords() async {
    final db = await instance.database;
    final result = await db.query(tableCashRecord, orderBy: "date ASC");
    return result.map((map) => CashRecord.fromMap(map)).toList();
  }
}
