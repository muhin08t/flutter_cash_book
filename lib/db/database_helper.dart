import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../model/book.dart';
import '../model/cash_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static final String dbName = 'cash_book.db';
  static final String tableBooks = 'books';
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
      version: 2,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
        CREATE TABLE $tableBooks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

    await db.execute('''
      CREATE TABLE $tableCashRecord (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        isCashOut INTEGER NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
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

  Future<int> insertBook(Book book) async {
    final db = await instance.database;
    return await db.insert(tableBooks, book.toMap());
  }

  Future<List<Book>> getBooks() async {
    final db = await instance.database;
    final result = await db.query(tableBooks, orderBy: 'id DESC');
    return result.map((e) => Book.fromMap(e)).toList();
  }


  // Insert record
  Future<int> insertCashRecord(CashRecord record) async {
    final db = await instance.database;
    return await db.insert(tableCashRecord, record.toMap());
  }

  Future<List<CashRecord>> getRecordsByBook(int bookId) async {
    final db = await instance.database;
    final result = await db.query(
      tableCashRecord,
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'date DESC',
    );
    return result.map((e) => CashRecord.fromMap(e)).toList();
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
  Future<List<CashRecord>> getAllCashRecords() async {
    final db = await instance.database;
    final result = await db.query(tableCashRecord, orderBy: "date ASC");
    return result.map((map) => CashRecord.fromMap(map)).toList();
  }

  Future<List<CashRecord>>  getTodayRecords() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
    SELECT * FROM $tableCashRecord
    WHERE date(date) = date('now', 'localtime')
    ORDER BY date DESC
  ''');
    return result.map((map) => CashRecord.fromMap(map)).toList();
  }

  Future<List<CashRecord>> getRecordsByDate(DateTime date) async {
    final db = await instance.database;
    // Format date to 'YYYY-MM-DD' (SQLite date format)
    final formattedDate = date.toIso8601String().split('T').first;

    final result = await db.rawQuery('''
    SELECT * FROM $tableCashRecord
    WHERE date(date) = ?
    ORDER BY date DESC
  ''', [formattedDate]);

    return result.map((map) => CashRecord.fromMap(map)).toList();
  }

  Future<List<CashRecord>> getRecordsByDateRange(
      DateTime startDate, DateTime endDate) async {
    final db = await instance.database;

    // Format dates as 'YYYY-MM-DD'
    final start = startDate.toIso8601String().split('T').first;
    final end = endDate.toIso8601String().split('T').first;

    final result = await db.rawQuery('''
    SELECT * FROM $tableCashRecord
    WHERE date(date) BETWEEN ? AND ?
    ORDER BY date DESC
  ''', [start, end]);

    return result.map((map) => CashRecord.fromMap(map)).toList();
  }

  Future<List<CashRecord>> getLast7DaysCashRecords() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
    SELECT *
    FROM $tableCashRecord
    WHERE date(date) >= date('now', '-6 days', 'localtime')
  ''');
    return result.map((e) => CashRecord.fromMap(e)).toList();
  }

  Future<List<CashRecord>> getMonthlyCashRecords() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
    SELECT *
    FROM $tableCashRecord
    WHERE strftime('%Y-%m', date) = strftime('%Y-%m', 'now', 'localtime')
  ''');
    return result.map((e) => CashRecord.fromMap(e)).toList();
  }

  Future<List<CashRecord>> getYearlyCashRecords() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
    SELECT *
    FROM $tableCashRecord
    WHERE strftime('%Y', date) = strftime('%Y', 'now', 'localtime')
  ''');
    return result.map((e) => CashRecord.fromMap(e)).toList();
  }

}
