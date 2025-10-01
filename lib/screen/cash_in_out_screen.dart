import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../db/database_helper.dart';
import '../model/cash_record.dart';
import '../provider/cash_record_provider.dart';

class CashInOutScreen extends StatefulWidget {
  final bool isCashOut;
  const CashInOutScreen({super.key, required this.isCashOut});

  @override
  State<CashInOutScreen> createState() => _CashInOutScreenState();
}

class _CashInOutScreenState extends State<CashInOutScreen> {
  String selected = "No button pressed"; // 👈 state variable
  late bool isCashOut;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isCashOut = widget.isCashOut; // 👈 initialize from constructor
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _saveCashRecord(bool isCashOut, bool isExit) async {
    if (amountController.text.isEmpty) return;

    final amount = double.tryParse(amountController.text);
    if (amount == null) return;
    final provider = Provider.of<CashRecordProvider>(context, listen: false);
    final record = CashRecord(
      amount: amount,
      note: notesController.text,
      isCashOut: isCashOut,
      date: selectedDate,
      balance: 0,
    );

     provider.insertRecord(record);
     ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Record inserted successfully!")),
    );
    amountController.clear();
    notesController.clear();

    // Delay pop slightly so user sees the message
    if(isExit) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  Future<void> _loadRecords() async {
    final data = await DatabaseHelper.instance.getCashRecords();
    print(data.map((r) => r.toMap()).toList());
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Cash Book"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Toggle buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ChoiceChip(
                  label: const Text("Cash In"),
                  selected: !isCashOut,
                  selectedColor: Colors.green,
                  backgroundColor: Colors.grey,
                  labelStyle: TextStyle( color: isCashOut ? Colors.black : Colors.white),
                  onSelected: (val) {
                    setState(() {
                      isCashOut = false;
                    });
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Cash Out"),
                  selected: isCashOut,
                  selectedColor: Colors.red,
                  backgroundColor: Colors.grey,
                  labelStyle: TextStyle( color: isCashOut ? Colors.white : Colors.black),
                  onSelected: (val) {
                    setState(() {
                      isCashOut = true;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amount input
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next, // 👈 shows "Next" button
              decoration: InputDecoration(
                labelText: isCashOut ? "Cash Out" : "Cash In",
                labelStyle: TextStyle(
                  color: isCashOut ? Colors.red : Colors.green,
                ),
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calculate),
              ),
            ),
            const SizedBox(height: 12),

            // Notes
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: "Notes",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.camera_alt),
              ),
            ),
            const SizedBox(height: 12),

            // Date and Time pickers
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat("d MMM yyyy").format(selectedDate),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(
                        selectedTime.format(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // Bottom buttons
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 8,
          right: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 8, // 👈 moves button above keyboard
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _saveCashRecord(isCashOut,true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue.shade100,
                ),
                child: const Text("Save and exit", style: TextStyle(color: Colors.blue)),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _saveCashRecord(isCashOut, false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text("Save and continue",
                  style: TextStyle(
                    color: Colors.white, // 👈 set your desired color here
                  ),),
              ),
            ),
          ],
        ),
      ),

    );
  }
}
