import 'package:flutter/foundation.dart';
import 'package:flutter_cash_book/model/book.dart';

import '../db/database_helper.dart';
import '../model/cash_record.dart';

class CashRecordProvider extends ChangeNotifier {
  List<CashRecord> _records = [];
  List<Book> _books = [];
  bool isLoading = false;
  Book? _selectedBook;

  List<CashRecord> get records => _records;
  List<Book> get books => _books;
  Book? get selectedBook => _selectedBook;

  Future<void> loadCashRecords(String filterType, int bookId) async {
    isLoading = true;
    _records.clear();
    notifyListeners();
    List<CashRecord> fetchedData = [];
    switch (filterType) {
      case 'all':
        fetchedData = await DatabaseHelper.instance.getAllCashRecords(bookId);
        break;
      case 'today':
        fetchedData = await DatabaseHelper.instance.getTodayRecords();
        break;
      case 'weekly':
        fetchedData = await DatabaseHelper.instance.getLast7DaysCashRecords();
        break;
      case 'monthly':
        fetchedData = await DatabaseHelper.instance.getMonthlyCashRecords();
        break;
      case 'yearly':
        fetchedData = await DatabaseHelper.instance.getYearlyCashRecords();
        break;
      default:
        fetchedData = await DatabaseHelper.instance.getAllCashRecords(bookId);
        break;
    }

    _records = calculateRunningBalance(fetchedData);
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadSingleDateRecord(DateTime dateTime) async {
    isLoading = true;
    _records.clear();
    notifyListeners();
    List<CashRecord> fetchedData = [];
    fetchedData = await DatabaseHelper.instance.getRecordsByDate(dateTime);

    _records = calculateRunningBalance(fetchedData);
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadRecordByDateRange(DateTime startDateTime,
      DateTime endDateTime) async {
    isLoading = true;
    _records.clear();
    notifyListeners();
    List<CashRecord> fetchedData = [];
    fetchedData = await DatabaseHelper.instance.getRecordsByDateRange(startDateTime, endDateTime);

    _records = calculateRunningBalance(fetchedData);
    isLoading = false;
    notifyListeners();
  }

  List<CashRecord> calculateRunningBalance(List<CashRecord> fetchedData) {
    double runningBalance = 0;
    List<CashRecord> updatedData = [];

    for (var r in fetchedData) {
      runningBalance += r.isCashOut ? -r.amount : r.amount;
      updatedData.add(r.copyWithBalance(runningBalance));
    }

    // Reverse if you want newest first
    return updatedData.reversed.toList();
  }


  Future<int> insertRecord(CashRecord record) async {
    int id =  await DatabaseHelper.instance.insertCashRecord(record);
    await loadCashRecords("all",record.bookId); // reload after insert
    return id;
  }

  Future<int> updateRecord(CashRecord record) async {
    int id = await DatabaseHelper.instance.updateRecord(record);
    await loadCashRecords("all", record.bookId); // reload after insert
    return id;
  }

  Future<int> deleteRecord(int id, int bookId) async {
    int idd =  await DatabaseHelper.instance.deleteRecord(id);
    await loadCashRecords("all",bookId); // reload after insert
    return idd;
  }

  Future<void> loadBooks() async {
    isLoading = true;
    _books.clear();
    notifyListeners();
    _books = await DatabaseHelper.instance.getBooks();
    isLoading = false;
    notifyListeners();
  }

  Future<void> setSelectedBook(int bookId) async {
    await DatabaseHelper.instance.setSelectedBook(bookId);
  }

  Future<void> loadSelectedBook() async {
    _selectedBook =  await DatabaseHelper.instance.getSelectedBook();
    notifyListeners();
  }
}
