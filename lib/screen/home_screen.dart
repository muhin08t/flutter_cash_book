import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../db/database_helper.dart';
import '../model/book.dart';
import '../model/cash_record.dart';
import '../provider/cash_record_provider.dart';
import 'book_list_screen.dart';
import 'cash_in_out_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCashbook = 'select book';
  int selectedBookId = 1;
  final List<String> _cashbooks = ['Personal', 'Business', 'Savings'];
  int balance = -55000;
  final formatter = NumberFormat('#,###');
  List<CashRecord> cashRecords = [];
  late List<Map<String, dynamic>> buttonData;

  @override
  void initState() {
    super.initState();
    buttonData = [
      {"text": "All", "action": handleAll},
      {"text": "Today", "action": handleToday},
      {"text": "Weekly", "action": handleWeekly},
      {"text": "Monthly", "action": handleMonthly},
      {"text": "Yearly", "action": handleYearly},
      {"text": "Single Day", "action": _pickDate},
      {"text": "Date range", "action": _pickDateRange},
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cashRecordProvider =
          Provider.of<CashRecordProvider>(context, listen: false);
      await cashRecordProvider.loadSelectedBook();
      setState(() {
        _selectedCashbook = cashRecordProvider.selectedBook!.name;
      });
      selectedBookId = cashRecordProvider.selectedBook!.id!;
      await cashRecordProvider.loadCashRecords('all', selectedBookId);
    });
  }

  void handleAll() {
    final provider = Provider.of<CashRecordProvider>(context, listen: false);
    provider.loadCashRecords("all", selectedBookId);
  }

  void handleToday() {
    final provider = Provider.of<CashRecordProvider>(context, listen: false);
    provider.loadCashRecords("today", selectedBookId);
  }

  void handleWeekly() {
    final provider = Provider.of<CashRecordProvider>(context, listen: false);
    provider.loadCashRecords("weekly", selectedBookId);
  }

  void handleMonthly() {
    final provider = Provider.of<CashRecordProvider>(context, listen: false);
    provider.loadCashRecords("monthly", selectedBookId);
  }

  void handleYearly() {
    final provider = Provider.of<CashRecordProvider>(context, listen: false);
    provider.loadCashRecords("yearly", selectedBookId);
  }

  Future<void> _pickDate() async {
    DateTime selectedDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (!mounted || picked == null) return;
    selectedDate = picked;
    final provider = Provider.of<CashRecordProvider>(context, listen: false);
    provider.loadSingleDateRecord(selectedDate, selectedBookId);
  }

  Future<void> _pickDateRange() async {
    DateTimeRange? selectedRange;
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000), // earliest date
      lastDate: DateTime(2100), // latest date
      initialDateRange: selectedRange, // preselect previous range (optional)
    );

    if (!mounted || picked == null) return;
    final provider = Provider.of<CashRecordProvider>(context, listen: false);
    provider.loadRecordByDateRange(picked.start, picked.end, selectedBookId);
  }

  void _openCashbookDialog() async {
    final provider = Provider.of<CashRecordProvider>(context, listen: false);

    // Trigger loading before showing dialog
    provider.loadBooks();

    final result = await showDialog<Book>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          title: const Text('Select Cashbook'),
          content: SizedBox(
            width: double.maxFinite,
            height: 250,
            child: Consumer<CashRecordProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  // 🔄 Show loader while fetching
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.books.isEmpty) {
                  return const Center(child: Text('No cashbooks found'));
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: provider.books.length,
                        itemBuilder: (context, index) {
                          final name = provider.books[index].name;
                          return ListTile(
                            title: Text(name),
                            trailing: provider.books[index].isSelected
                                ? const Icon(Icons.check, color: Colors.blue)
                                : null,
                            onTap: () {
                              Navigator.pop(context, provider.books[index]);
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
                             Navigator.pop(context);
                            _showAddBookDialog(context);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add New'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => BookListScreen(
                                  )),
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        ),
                      ],
                    )
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedCashbook = result.name;
      });
      selectedBookId = result.id!;
      await provider.setSelectedBook(result.id!);
      provider.loadCashRecords('all', selectedBookId);
    }
  }

  Future<void> _showAddBookDialog(BuildContext context) async {
    final provider = Provider.of<CashRecordProvider>(context, listen: false);
    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Add New Cash Book'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter book name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Book book = Book(name: name);
                  int id = await provider.insertBook(book);
                  if (!context.mounted) return;
                  if(id > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Book inserted successfully!")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Insert failed")),
                    );
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
    print('records length: ${records.length}');
    return records
        .where((r) => !r.isCashOut) // only cash in
        .fold(0, (sum, r) => sum + r.amount);
  }

  double getTotalCashOut(List<CashRecord> records) {
    return records
        .where((r) => r.isCashOut) // only cash out
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
            onPressed: () {
              _showAddBookDialog(context);
            },
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
                Expanded(
                    flex: 2,
                    child: Center(
                        child: Text("Date",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            )))),
                Expanded(
                    flex: 1,
                    child: Center(
                        child: Text("Cash In",
                            style: TextStyle(color: Colors.green)))),
                Expanded(
                    flex: 1,
                    child: Center(
                        child: Text("Cash Out",
                            style: TextStyle(color: Colors.red)))),
              ],
            ),
          ),
          // ListView for rows
          Expanded(
            child: Consumer<CashRecordProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final records = provider.records;
                cashRecords = List.from(provider.records);
                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    //final transaction = transactions[index];
                    final record = records[index];
                    final dateTime = record.date;
                    final formattedDate =
                        DateFormat("EEE, dd MMM yyyy hh:mm a").format(dateTime);
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CashInOutScreen(
                                    isCashOut: record.isCashOut,
                                    cashRecord: record,
                                    bookId: selectedBookId,
                                  )),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Colors.grey.shade400, width: 1),
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
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
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
                        MaterialPageRoute(
                            builder: (context) => CashInOutScreen(
                                  isCashOut: false,
                                  bookId: selectedBookId,
                                )),
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
                        MaterialPageRoute(
                            builder: (context) => CashInOutScreen(
                                isCashOut: true, bookId: selectedBookId)),
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
            child: Consumer<CashRecordProvider>(
              builder: (context, provider, child) {
                final totalCashIn = getTotalCashIn(provider.records);
                final totalCashOut = getTotalCashOut(provider.records);
                final totalBalance = totalCashIn - totalCashOut;
                return Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // centers vertically
                          crossAxisAlignment:
                              CrossAxisAlignment.center, // centers horizontally
                          children: [
                            Text("Total Cash In",
                                style: TextStyle(color: Colors.green)),
                            SizedBox(height: 4), // small spacing
                            Text(formatter.format(totalCashIn),
                                style: TextStyle(
                                    color: Colors.green)), // your new text
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
                          mainAxisAlignment:
                              MainAxisAlignment.center, // centers vertically
                          crossAxisAlignment:
                              CrossAxisAlignment.center, // centers horizontally
                          children: [
                            Text("Total Cash Out",
                                style: TextStyle(color: Colors.red)),
                            SizedBox(height: 4), // small spacing
                            Text(formatter.format(totalCashOut),
                                style: TextStyle(
                                    color: Colors.red)), // your new text
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
                          mainAxisAlignment:
                              MainAxisAlignment.center, // centers vertically
                          crossAxisAlignment:
                              CrossAxisAlignment.center, // centers horizontally
                          children: [
                            Text("Balance"),
                            SizedBox(height: 4), // small spacing
                            Text(
                              formatter.format(totalBalance),
                              style: TextStyle(
                                color: getBalance(cashRecords) < 0
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ), // your new text
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
