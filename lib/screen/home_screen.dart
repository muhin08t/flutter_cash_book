import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCashbook = 'Personal';
  final List<String> _cashbooks = ['Personal', 'Business', 'Savings'];

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

  void _onMenuSelected(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Selected: $value'),
    ));
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
      body: SingleChildScrollView(
        child: Column(
          children: List.generate(
            20,
                (index) => ListTile(title: Text("Item $index")),
          ),
        ),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Handle Cash In
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Handle Cash Out
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
                  child: const Center(child: Text("Cell 1")),
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
                  child: const Center(child: Text("Cell 2")),
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
                  child: const Center(child: Text("Cell 3")),
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