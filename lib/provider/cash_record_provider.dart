import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cash_book/model/book.dart';
import 'package:path/path.dart';
import 'package:pdf/pdf.dart';

import '../db/database_helper.dart';
import '../model/cash_record.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

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
        fetchedData = await DatabaseHelper.instance.getTodayRecords(bookId);
        break;
      case 'weekly':
        fetchedData = await DatabaseHelper.instance.getLast7DaysCashRecords(bookId);
        break;
      case 'monthly':
        fetchedData = await DatabaseHelper.instance.getMonthlyCashRecords(bookId);
        break;
      case 'yearly':
        fetchedData = await DatabaseHelper.instance.getYearlyCashRecords(bookId);
        break;
      default:
        fetchedData = await DatabaseHelper.instance.getAllCashRecords(bookId);
        break;
    }

    _records = calculateRunningBalance(fetchedData);
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadSingleDateRecord(DateTime dateTime, int bookId) async {
    isLoading = true;
    _records.clear();
    notifyListeners();
    List<CashRecord> fetchedData = [];
    fetchedData = await DatabaseHelper.instance.getRecordsByDate(dateTime, bookId);

    _records = calculateRunningBalance(fetchedData);
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadRecordByDateRange(DateTime startDateTime,
      DateTime endDateTime, int bookId) async {
    isLoading = true;
    _records.clear();
    notifyListeners();
    List<CashRecord> fetchedData = [];
    fetchedData = await DatabaseHelper.instance.getRecordsByDateRange(startDateTime, endDateTime, bookId);

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

  Future<int> insertBook(Book book) async {
    int id =  await DatabaseHelper.instance.insertBook(book);
    return id;
  }

  Future<int> deleteBook(int id) async {
    int idd =  await DatabaseHelper.instance.deleteBook(id);
    loadBooks();
    return idd;
  }

  Future<int> updateBook(Book book) async {
    int id = await DatabaseHelper.instance.updateBook(book);
    loadBooks();
    return id;
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

  Future<void> generateCashbookReport({
    required String bookName,
    required String dateRange,
    required BuildContext context,
  }) async {
    final pdf = pw.Document();

    // Create table data
    final tableData = records.map((record) {
      final cashIn = record.isCashOut ? 0.0 : record.amount;
      final cashOut = record.isCashOut ? record.amount : 0.0;

      return [
        _formatDate(record.date),
        record.note ?? '',
        cashIn == 0 ? '' : cashIn.toStringAsFixed(2),
        cashOut == 0 ? '' : cashOut.toStringAsFixed(2),
        record.balance.toStringAsFixed(2),
      ];
    }).toList();

    // Build the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          // Header section
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Cashbook Report',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Book Name: $bookName',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('Date Range: $dateRange',
                  style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 15),
            ],
          ),

          // Data table
          pw.Table.fromTextArray(
            headers: ['Date', 'Notes', 'Cash In', 'Cash Out', 'Balance'],
            data: tableData,
            border: pw.TableBorder.all(width: 0.5),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey900),
            cellStyle: pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.center,
          ),

          pw.SizedBox(height: 20),

          // Summary footer
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Final Balance: ${records.isNotEmpty ? records.last.balance.toStringAsFixed(2) : '0.00'}',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    // OPEN PDF INSIDE APP (No save dialog)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreview(
          build: (format) => pdf.save(),
          pdfFileName: "cashbook_report.pdf",
        ),
      ),
    );

  }

// Helper: Format date (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';
  }

  String getDateRange(List<CashRecord> records) {
    if (records.isEmpty) return 'No data';

    // Sort by date (just to be sure)
    records.sort((a, b) => a.date.compareTo(b.date));

    final start = records.first.date;
    final end = records.last.date;

    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

}
