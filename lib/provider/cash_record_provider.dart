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

  Future<void> insertRecord(CashRecord record) async {
    await DatabaseHelper.instance.insertCashRecord(record);
    await loadRecords(); // reload after insert
  }

  Future<void> updateRecord(CashRecord record) async {
    await DatabaseHelper.instance.updateRecord(record);
    await loadRecords(); // reload after insert
  }

  Future<void> deleteRecord(int id) async {
    await DatabaseHelper.instance.deleteRecord(id);
    await loadRecords(); // reload after insert
  }
}
