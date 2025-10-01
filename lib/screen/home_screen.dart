import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../db/database_helper.dart';
import '../model/cash_record.dart';
import '../provider/cash_record_provider.dart';
import 'cash_in_out_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCashbook = 'Personal';
  final List<String> _cashbooks = ['Personal', 'Business', 'Savings'];
  int balance = -55000;
  final formatter = NumberFormat('#,###');
  List<CashRecord> cashRecords = [];

  @override
  void initState() {
    super.initState();
    _loadRecords(); // 👈 call here when screen starts
  }

  final List<Map<String, dynamic>> buttonData = [
    {"text": "All", "action": () => print("All pressed")},
    {"text": "Today", "action": () => print("Today pressed")},
    {"text": "Weekly", "action": () => print("Weekly Out pressed")},
    {"text": "Monthly", "action": () => print("Monthly pressed")},
    {"text": "Yearly", "action": () => print("Yearly pressed")},
    {"text": "Date range", "action": () => print("Date range pressed")},
  ];

  final List<Map<String, dynamic>> transactions = [
    {"date": "2025-08-31 00:15:00", "title": "ভাড়া", "cashIn": 10000, "cashOut": 5000, 'balance':5000},
    {"date": "2025-08-31 10:15:00", "title": "ঔষধ", "cashIn": 2000, "cashOut": 3000,'balance':6000},
    {"date": "2025-08-31 14:15:00", "title": "টিস্যু", "cashIn": 0, "cashOut": 7000, 'balance':7000},
    {"date": "2025-08-31 00:15:00", "title": "ভাড়া", "cashIn": 10000, "cashOut": 5000, 'balance':5000},
    {"date": "2025-08-31 10:15:00", "title": "ঔষধ", "cashIn": 2000, "cashOut": 3000,'balance':6000},
    {"date": "2025-08-31 14:15:00", "title": "টিস্যু", "cashIn": 0, "cashOut": 7000, 'balance':7000},
    {"date": "2025-08-31 00:15:00", "title": "ভাড়া", "cashIn": 10000, "cashOut": 5000, 'balance':5000},
    {"date": "2025-08-31 10:15:00", "title": "ঔষধ", "cashIn": 2000, "cashOut": 3000,'balance':6000},
    {"date": "2025-08-31 14:15:00", "title": "টিস্যু", "cashIn": 0, "cashOut": 7000, 'balance':7000},
    {"date": "2025-08-31 00:15:00", "title": "ভাড়া", "cashIn": 10000, "cashOut": 5000, 'balance':5000},
    {"date": "2025-08-31 10:15:00", "title": "ঔষধ", "cashIn": 2000, "cashOut": 3000,'balance':6000},
    {"date": "2025-08-31 14:15:00", "title": "টিস্যু", "cashIn": 0, "cashOut": 7000, 'balance':7000},
    {"date": "2025-08-31 00:15:00", "title": "ভাড়া", "cashIn": 10000, "cashOut": 5000, 'balance':5000},
    {"date": "2025-08-31 10:15:00", "title": "ঔষধ", "cashIn": 2000, "cashOut": 3000,'balance':6000},
    {"date": "2025-08-31 14:15:00", "title": "টিস্যু", "cashIn": 0, "cashOut": 7000, 'balance':7000},
  ];

  void _openCashbookDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // 👈 removes rounded corners
          ),
          title: const Text('Select Cashbook'),
          content: SizedBox(
            width: double.maxFinite,
            height: 250,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _cashbooks.length,
                    itemBuilder: (context, index) {
                      final name = _cashbooks[index];
                      return ListTile(
                        title: Text(name),
                        trailing: name == _selectedCashbook
                            ? const Icon(Icons.check, color: Colors.blue)
                            : null,
                        onTap: () {
                          Navigator.pop(context, name);
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // handle add existing
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Add tapped")),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add New'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // handle create new
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Create tapped")),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _selectedCashbook = result;
      });
    }
  }

  void _onReport() {
    // handle report action
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Report tapped'),
    ));
  }

  void _onAdd() {
    // handle add action
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Add tapped'),
    ));
  }

  Future<void> _loadRecords() async {
    final records  = await DatabaseHelper.instance.getCashRecords();
    //records.sort((a, b) => a.date.compareTo(b.date));
    // 3. Calculate balances
    double runningBalance = 0;
    List<CashRecord> updated = [];

    for (var r in records) {
      if (r.isCashOut) {
        runningBalance -= r.amount;
      } else {
        runningBalance += r.amount;
      }
      updated.add(r.copyWithBalance(runningBalance));
    }
    setState(() {
      cashRecords = updated.reversed.toList();
    });
  }

  void _onMenuSelected(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Selected: $value'),
    ));
  }

  Widget buildFilterButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4), // outer padding
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontSize: 14),
        ),
        child: Text(text),
      ),
    );
  }

  double getTotalCashIn(List<CashRecord> records) {
    return records
        .where((r) => !r.isCashOut)     // only cash in
        .fold(0, (sum, r) => sum + r.amount);
  }

  double getTotalCashOut(List<CashRecord> records) {
    return records
        .where((r) => r.isCashOut)      // only cash out
        .fold(0, (sum, r) => sum + r.amount);
  }

  double getBalance(List<CashRecord> records) {
    return getTotalCashIn(records) - getTotalCashOut(records);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: GestureDetector(
          onTap: _openCashbookDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedCashbook,
                style: const TextStyle(fontSize: 20),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),

        // Right-side icons: report, +, three dots
        actions: [
          IconButton(
            tooltip: 'Report',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _onReport,
          ),
          IconButton(
            tooltip: 'Add',
            icon: const Icon(Icons.add),
            onPressed: _onAdd,
          ),
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Settings', child: Text('Settings')),
              const PopupMenuItem(value: 'Help', child: Text('Help')),
              const PopupMenuItem(value: 'Logout', child: Text('Logout')),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      // Main content (scrollable if needed)
      body: Column(
        children: [
          // 👇 Buttons above the ListView
          Container(
            color: Colors.blue.shade100, // 👈 background applied here
            padding: const EdgeInsets.all(8.0),
            width: double.infinity, // 👈 full screen width
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: buttonData
                    .map((btn) => buildFilterButton(btn["text"], btn["action"]))
                    .toList(),
              ),
            ),
      ),

          // Header row
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade200,
            child: Row(
              children: const [
                Expanded(flex: 2, child: Center(child: Text("Date",  style: TextStyle(color: Colors.black,  fontWeight: FontWeight.bold,)))),
                Expanded(flex: 1, child: Center(child: Text("Cash In",  style: TextStyle(color: Colors.green)))),
                Expanded(flex: 1, child: Center(child: Text("Cash Out",  style: TextStyle(color: Colors.red)))),
              ],
            ),
          ),
          // ListView for rows
          Expanded(
            child: Consumer<CashRecordProvider>(
              builder: (context, provider, child) {
                final records = provider.records;
                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    //final transaction = transactions[index];
                    final record = records[index];
                    final dateTime = record.date;
                    final formattedDate =
                        DateFormat("EEE, dd MMM yyyy hh:mm a").format(dateTime);
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom:
                              BorderSide(color: Colors.grey.shade400, width: 1),
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.note ?? "", // 👈 your extra text
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                // spacing between texts
                                Text(formattedDate),
                                // 👈 your existing date
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Text(
                                record.isCashOut
                                    ? ""
                                    : formatter.format(record.amount),
                                style: const TextStyle(
                                    color: Colors.green, fontSize: 16),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  record.isCashOut
                                      ? formatter.format(record.amount)
                                      : "",
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                // spacing between texts
                                Text(
                                  'Balance ${formatter.format(record.balance)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                // 👈 your existing date
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CashInOutScreen(isCashOut: false)),
                      );
                    },
                    child: const Text(
                      "Cash In",
                      style: TextStyle(
                        color: Colors.white, // 👈 set text color here
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CashInOutScreen(isCashOut: true)),
                      );
                    },
                    child: const Text(
                      "Cash Out",
                      style: TextStyle(
                        color: Colors.white, // 👈 set text color here
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Row with 3 cells
          Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // centers vertically
                    crossAxisAlignment: CrossAxisAlignment.center, // centers horizontally
                    children:  [
                      Text("Total Cash In", style: TextStyle(color: Colors.green)),
                      SizedBox(height: 4), // small spacing
                      Text(formatter.format(getTotalCashIn(cashRecords)), style: TextStyle(color: Colors.green)), // your new text
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.black, width: 1),
                      bottom: BorderSide(color: Colors.black, width: 1),
                      right: BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // centers vertically
                    crossAxisAlignment: CrossAxisAlignment.center, // centers horizontally
                    children:  [
                      Text("Total Cash Out", style: TextStyle(color: Colors.red)),
                      SizedBox(height: 4), // small spacing
                      Text(formatter.format(getTotalCashOut(cashRecords)), style: TextStyle(color: Colors.red)), // your new text
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.black, width: 1),
                      bottom: BorderSide(color: Colors.black, width: 1),
                      right: BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // centers vertically
                    crossAxisAlignment: CrossAxisAlignment.center, // centers horizontally
                    children: [
                      Text("Balance"),
                      SizedBox(height: 4), // small spacing
                      Text(formatter.format(getBalance(cashRecords)),
                        style: TextStyle(
                          color: getBalance(cashRecords) < 0 ? Colors.red : Colors.green,
                        ),
                      ),// your new text
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}