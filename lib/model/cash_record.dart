class CashRecord {
  final int? id;
  final double amount;
  final String? note;
  final bool isCashOut;
  final DateTime date;
  final double balance;

  CashRecord({
    this.id,
    required this.amount,
    this.note,
    required this.isCashOut,
    required this.date,
    required this.balance,
  });

  // Convert object → Map (for insert)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'note': note,
      'isCashOut': isCashOut ? 1 : 0,
      'date': date.toIso8601String(),
    };
  }

  // Convert Map → object (for read)
  factory CashRecord.fromMap(Map<String, dynamic> map) {
    return CashRecord(
      id: map['id'] as int?,
      amount: map['amount'] as double,
      note: map['note'] as String?,
      isCashOut: (map['isCashOut'] as int) == 1,
      date: DateTime.parse(map['date'] as String),
      balance: 0,
    );
  }

  CashRecord copyWithBalance(double newBalance) {
    return CashRecord(
      id: id,
      amount: amount,
      note: note,
      isCashOut: isCashOut,
      date: date,
      balance: newBalance,
    );
  }
}
