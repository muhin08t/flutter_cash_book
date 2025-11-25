import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../model/cash_record.dart';
import 'cash_utils.dart';

class PdfUtils {
  static Future<Uint8List> generateCashbookReport({
    required String bookName,
    required String dateRange,
    required List<CashRecord> records,
  }) async {
    final pdf = pw.Document();

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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
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
          pw.Text('Book Name: $bookName',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          // pw.Text('Date Range: $dateRange',
          //     style: pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 15),

          pw.Table.fromTextArray(
            headers: ['Date', 'Notes', 'Cash In', 'Cash Out', 'Balance'],
            data: tableData,
            border: pw.TableBorder.all(width: 0.5),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey900),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.center,
          ),

          pw.SizedBox(height: 20),

          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Final Balance: ${records.isNotEmpty ? CashUtils.getBalance(records).toStringAsFixed(2) : '0.00'}',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // Helper date formatter
  static String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}