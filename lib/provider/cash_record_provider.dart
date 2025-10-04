import 'package:flutter/foundation.dart';

import '../db/database_helper.dart';
import '../model/cash_record.dart';

class CashRecordProvider extends ChangeNotifier {
  List<CashRecord> _records = [];
  bool isLoading = false;

  List<CashRecord> get records => _records;

  Future<void> loadRecords() async {
    isLoading = true;
    notifyListeners();
    // Fetch from DB (ascending for correct balance)
    var fetched = await DatabaseHelper.instance.getCashRecords();

    // Calculate balances
    double runningBalance = 0;
    List<CashRecord> updated = [];
    for (var r in fetched) {
      runningBalance += r.isCashOut ? -r.amount : r.amount;
      updated.add(r.copyWithBalance(runningBalance));
    }

    // Reverse if you want newest first in UI
    _records = updated.reversed.toList();
    isLoading = false;
    notifyListeners(); // 👈 update UI
  }

  Future<int> insertRecord(CashRecord record) async {
    int id =  await DatabaseHelper.instance.insertCashRecord(record);
    await loadRecords(); // reload after insert
    return id;
  }

  Future<int> updateRecord(CashRecord record) async {
    int id = await DatabaseHelper.instance.updateRecord(record);
    await loadRecords(); // reload after insert
    return id;
  }

  Future<int> deleteRecord(int id) async {
    int idd =  await DatabaseHelper.instance.deleteRecord(id);
    await loadRecords(); // reload after insert
    return idd;
  }
}
