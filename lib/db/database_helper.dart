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
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
        CREATE TABLE $tableBooks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          isSelected INTEGER DEFAULT 0
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

    await db.insert(tableBooks, {'name': 'Personal', 'isSelected': 1});
    await db.insert(tableBooks, {'name': 'Business', 'isSelected': 0});
  }

  Future _upgradeDB (db, oldVersion, newVersion) async {
  // Check if books table exists
  final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='books'");
  if (tables.isEmpty) {
  await db.execute('''
      CREATE TABLE $tableBooks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        isSelected INTEGER DEFAULT 0
      )
    ''');

  await db.insert(tableBooks, {'name': 'Personal', 'isSelected': 1});
  await db.insert(tableBooks, {'name': 'Business', 'isSelected': 0});
  }
}

Future<int> insertBook(Book book) async {
    final db = await instance.database;
    return await db.insert(tableBooks, book.toMap());
  }

  Future<int> updateBook(Book book) async {
    final db = await instance.database;
    return await db.update(
      tableBooks,
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  Future<int> deleteBook(int id) async {
    final db = await instance.database;
    return await db.delete(
      tableBooks,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Book>> getBooks() async {
    final db = await instance.database;
    final result = await db.query(tableBooks, orderBy: 'id DESC');
    return result.map((e) => Book.fromMap(e)).toList();
  }

  Future<Book?> getSelectedBook() async {
    final db = await instance.database;
    final result = await db.query(
      tableBooks,
      where: 'isSelected = ?',
      whereArgs: [1],
    );
    if (result.isNotEmpty) return Book.fromMap(result.first);
    return null;
  }

  // Select one book and unselect others
  Future<void> setSelectedBook(int bookId) async {
    final db = await instance.database;
    await db.update(tableBooks, {'isSelected': 0}); // Unselect all
    await db.update(
      tableBooks,
      {'isSelected': 1},
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

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
  Future<List<CashRecord>> getAllCashRecords(int bookId) async {
    final db = await instance.database;
    final result = await db.query(
      tableCashRecord,
      where: 'book_id = ?',
      whereArgs: [bookId], // pass your selected book ID here
      orderBy: 'date ASC',
    );
    return result.map((map) => CashRecord.fromMap(map)).toList();
  }

  Future<List<CashRecord>>  getTodayRecords(int bookId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
    SELECT * FROM $tableCashRecord
    WHERE date(date) = date('now', 'localtime')  AND book_id = ?
    ORDER BY date DESC
  ''', [bookId]);
    return result.map((map) => CashRecord.fromMap(map)).toList();
  }

  Future<List<CashRecord>> getRecordsByDate(DateTime date, int bookId) async {
    final db = await instance.database;
    // Format date to 'YYYY-MM-DD' (SQLite date format)
    final formattedDate = date.toIso8601String().split('T').first;

    final result = await db.rawQuery('''
    SELECT * FROM $tableCashRecord
    WHERE date(date) = ? AND book_id = ?
    ORDER BY date DESC
  ''', [formattedDate, bookId]);

    return result.map((map) => CashRecord.fromMap(map)).toList();
  }

  Future<List<CashRecord>> getRecordsByDateRange(
      DateTime startDate, DateTime endDate, int bookId) async {
    final db = await instance.database;

    // Format dates as 'YYYY-MM-DD'
    final start = startDate.toIso8601String().split('T').first;
    final end = endDate.toIso8601String().split('T').first;

    final result = await db.rawQuery('''
    SELECT * FROM $tableCashRecord
    WHERE date(date) BETWEEN ? AND ? AND book_id = ?
    ORDER BY date DESC
  ''', [start, end, bookId]);

    return result.map((map) => CashRecord.fromMap(map)).toList();
  }

  Future<List<CashRecord>> getLast7DaysCashRecords(int bookId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
    SELECT *
    FROM $tableCashRecord
    WHERE date(date) >= date('now', '-6 days', 'localtime')
    AND book_id = ?
  ''', [bookId]);
    return result.map((e) => CashRecord.fromMap(e)).toList();
  }

  Future<List<CashRecord>> getMonthlyCashRecords(int bookId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
    SELECT *
    FROM $tableCashRecord
    WHERE strftime('%Y-%m', date) = strftime('%Y-%m', 'now', 'localtime')
    AND book_id = ?
  ''', [bookId]);
    return result.map((e) => CashRecord.fromMap(e)).toList();
  }

  Future<List<CashRecord>> getYearlyCashRecords(int bookId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
    SELECT *
    FROM $tableCashRecord
    WHERE strftime('%Y', date) = strftime('%Y', 'now', 'localtime')
    AND book_id = ?
  ''', [bookId]);
    return result.map((e) => CashRecord.fromMap(e)).toList();
  }

}
