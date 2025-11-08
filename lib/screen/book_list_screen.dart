import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/book.dart';
import '../provider/cash_record_provider.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {

  @override
  void initState() {
    super.initState();
    // load once when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CashRecordProvider>(context, listen: false).loadBooks();
    });
  }

  void _editBook(BuildContext context, Book book) async {
    TextEditingController controller = TextEditingController(text: book.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Book'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Book Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      final provider = Provider.of<CashRecordProvider>(context, listen: false);
      Book updatedBook = book.copyWith(name: newName);
      int id = await provider.updateBook(updatedBook);
      if (!context.mounted) return;

      if(id > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Book updated successfully!")),
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Update failed")),
        );
      }
    }
  }

  void _deleteBook(BuildContext context, Book book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "${book.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<CashRecordProvider>(context, listen: false);
      int id = await provider.deleteBook(book.id!);
      if (!context.mounted) return;

      if(id > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Book deleted successfully!")),
        );


      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Delete failed")),
        );
      }
    }
  }

  void _addBook(BuildContext context) async {
    final provider = Provider.of<CashRecordProvider>(context, listen: false);
    TextEditingController controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Book'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Book Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Add')),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
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
      provider.loadBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Books'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Book',
            onPressed: () {
              _addBook(context);
            },
          ),
        ],
      ),
      body: Consumer<CashRecordProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.books.isEmpty) {
            return const Center(child: Text('No books found.'));
          }
      return ListView.builder(
        itemCount: provider.books.length,
        itemBuilder: (context, index) {
          final book = provider.books[index];
          print('book created date ${book.createdAt}');
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
            child: ListTile(
              title: Text(book.name, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('Created: ${book.createdAt}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      _editBook(context, book);
                    },
                  ),
                  IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _deleteBook(context, book);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
  },
  ),
    );
  }
}
