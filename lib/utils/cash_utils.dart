import '../model/cash_record.dart';

class CashUtils {

  static double getTotalCashIn(List<CashRecord> records) {
    return records
        .where((r) => !r.isCashOut) // only cash in
        .fold(0, (sum, r) => sum + r.amount);
  }
  
  static double getTotalCashOut(List<CashRecord> records) {
    return records
        .where((r) => r.isCashOut) // only cash out
        .fold(0, (sum, r) => sum + r.amount);
  }

  static double getBalance(List<CashRecord> records) {
    return getTotalCashIn(records) - getTotalCashOut(records);
  }

  static List<CashRecord> calculateRunningBalance(List<CashRecord> fetchedData) {
    double runningBalance = 0;
    List<CashRecord> updatedData = [];
    for (var r in fetchedData) {
      runningBalance += r.isCashOut ? -r.amount : r.amount;
      updatedData.add(r.copyWithBalance(runningBalance));
    }
    // Reverse if you want newest first
    return updatedData.reversed.toList();
  }
}