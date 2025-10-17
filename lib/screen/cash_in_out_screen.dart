import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../db/database_helper.dart';
import '../model/cash_record.dart';
import '../provider/cash_record_provider.dart';

class CashInOutScreen extends StatefulWidget {
  final bool isCashOut;
  final CashRecord? cashRecord;

  const CashInOutScreen({super.key, required this.isCashOut, this.cashRecord});

  @override
  State<CashInOutScreen> createState() => _CashInOutScreenState();
}

class _CashInOutScreenState extends State<CashInOutScreen> {
  String selected = "No button pressed"; // 👈 state variable
  late bool isCashOut;
  late DateTime  selectedDate;
  late TimeOfDay selectedTime;
  late TextEditingController amountController;
  late TextEditingController notesController;

  @override
  void initState() {
    super.initState();
    isCashOut = widget.isCashOut; // 👈 initialize from constructor
    // If record is null -> new entry, else fill with existing
    amountController = TextEditingController(
      text: widget.cashRecord == null
          ? ""
          : (widget.cashRecord!.amount % 1 == 0
          ? widget.cashRecord!.amount.toInt().toString()
          : widget.cashRecord!.amount.toString()),
    );
    notesController = TextEditingController(
      text: widget.cashRecord?.note ?? "",
    );

    if (widget.cashRecord != null) {
      // Use record values
      selectedDate = widget.cashRecord!.date;
      selectedTime = TimeOfDay.fromDateTime(widget.cashRecord!.date);
    } else {
      // Use current date/time
      selectedDate = DateTime.now();
      selectedTime = TimeOfDay.now();
    }
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
        // selectedDate = picked;
        final now = DateTime.now(); // 👈 get current time
        selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          widget.cashRecord == null ? now.hour : selectedDate.hour,
          widget.cashRecord == null ? now.minute : selectedDate.minute,
          widget.cashRecord == null ? now.second : selectedDate.second,
        );
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
        // 👇 merge date + time into a full DateTime
        selectedDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _saveCashRecord(BuildContext context, bool isCashOut, bool isExit) async {
    if (amountController.text.isEmpty) {
      // show alert
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("Validation Error"),
          content: Text("Amount cannot be empty."),
        ),
      );
      return;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null) return;
    final provider = Provider.of<CashRecordProvider>(context, listen: false);
    final record = CashRecord(
      amount: amount,
      bookId: 1,
      note: notesController.text,
      isCashOut: isCashOut,
      date: selectedDate,
      balance: 0,
    );

     int id =  await provider.insertRecord(record);
    if (!context.mounted) return;
     if(id > 0) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Record inserted successfully!")),
       );
       if(isExit) {
         Navigator.pop(context);
       }
     } else {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Insert failed")),
       );
     }
    amountController.clear();
    notesController.clear();
  }

  Future<void> _updateRecord(BuildContext context, bool isCashOut) async {
    if (amountController.text.isEmpty) {
      // show alert
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("Validation Error"),
          content: Text("Amount cannot be empty."),
        ),
      );
      return;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null) return;
    final provider = Provider.of<CashRecordProvider>(context, listen: false);
    final record = CashRecord(
      id: widget.cashRecord?.id,
      bookId: 1,
      amount: amount,
      note: notesController.text,
      isCashOut: isCashOut,
      date: selectedDate,
      balance: 0,
    );

    int id = await provider.updateRecord(record);
    if (!context.mounted) return;

    if(id > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Record updated successfully!")),
      );
        Navigator.pop(context);

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Update failed")),
      );
    }

  }

  Future<void> _deleteRecord(BuildContext context) async {
    final provider = Provider.of<CashRecordProvider>(context, listen: false);
    int id = await provider.deleteRecord(widget.cashRecord!.id!);
    if (!context.mounted) return;

    if(id > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Record deleted successfully!")),
      );
      Navigator.pop(context);

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Delete failed")),
      );
    }
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
            if(widget.cashRecord == null) ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _saveCashRecord(context,isCashOut, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue.shade100,
                  ),
                  child: const Text(
                      "Save and exit", style: TextStyle(color: Colors.blue)),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _saveCashRecord(context, isCashOut, false);
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
              if(widget.cashRecord != null) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _deleteRecord(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                        "Delete", style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _updateRecord(context, isCashOut);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text("Update",
                      style: TextStyle(
                        color: Colors.white, // 👈 set your desired color here
                      ),),
                  ),
                ),
              ],
          ],
        ),
      ),

    );
  }
}
