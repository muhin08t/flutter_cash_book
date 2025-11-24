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
}