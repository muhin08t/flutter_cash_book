import 'package:flutter/foundation.dart';

import '../db/database_helper.dart';
import '../model/cash_record.dart';

class CashRecordProvider extends ChangeNotifier {
  List<CashRecord> _records = [];

  List<CashRecord> get records => _records;

  Future<void> loadRecords() async {
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

    notifyListeners(); // 👈 update UI
  }

  Future<void> insertRecord(CashRecord record) async {
    await DatabaseHelper.instance.insertCashRecord(record);
    await loadRecords(); // reload after insert
  }
}
