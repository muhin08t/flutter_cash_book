import 'package:flutter/foundation.dart';

import '../db/database_helper.dart';
import '../model/cash_record.dart';

class CashRecordProvider extends ChangeNotifier {
  List<CashRecord> _records = [];
  bool isLoading = false;

  List<CashRecord> get records => _records;

  Future<void> loadCashRecords(String filterType) async {
    isLoading = true;
    _records.clear();
    notifyListeners();
    List<CashRecord> fetchedData = [];
    switch (filterType) {
      case 'all':
        fetchedData = await DatabaseHelper.instance.getAllCashRecords();
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
        print('Invalid filter type');
    }

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
    await loadCashRecords("all"); // reload after insert
    return id;
  }

  Future<int> updateRecord(CashRecord record) async {
    int id = await DatabaseHelper.instance.updateRecord(record);
    await loadCashRecords("all"); // reload after insert
    return id;
  }

  Future<int> deleteRecord(int id) async {
    int idd =  await DatabaseHelper.instance.deleteRecord(id);
    await loadCashRecords("all"); // reload after insert
    return idd;
  }
}
