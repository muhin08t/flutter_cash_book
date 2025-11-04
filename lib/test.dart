//
//
// void _openCashbookDialog() async {
//   final provider = Provider.of<CashRecordProvider>(context, listen: true);
//   provider.loadBooks();
//
//   final result = await showDialog<String>(
//     context: context,
//     builder: (context) {
//       return AlertDialog(
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.zero, // 👈 removes rounded corners
//         ),
//         title: const Text('Select Cashbook'),
//         content: SizedBox(
//           width: double.maxFinite,
//           height: 250,
//           child: Column(
//             children: [
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: _cashbooks.length,
//                   itemBuilder: (context, index) {
//                     final name = _cashbooks[index];
//                     return ListTile(
//                       title: Text(name),
//                       trailing: name == _selectedCashbook
//                           ? const Icon(Icons.check, color: Colors.blue)
//                           : null,
//                       onTap: () {
//                         Navigator.pop(context, name);
//                       },
//                     );
//                   },
//                 ),
//               ),
//               const Divider(),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   ElevatedButton.icon(
//                     onPressed: () {
//                       // handle add existing
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text("Add tapped")),
//                       );
//                     },
//                     icon: const Icon(Icons.add),
//                     label: const Text('Add New'),
//                   ),
//                   ElevatedButton.icon(
//                     onPressed: () {
//                       // handle create new
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text("Create tapped")),
//                       );
//                     },
//                     icon: const Icon(Icons.edit),
//                     label: const Text('Edit'),
//                   ),
//                 ],
//               )
//             ],
//           ),
//         ),
//       );
//     },
//   );
//
//   if (result != null && result.isNotEmpty) {
//     setState(() {
//       _selectedCashbook = result;
//     });
//   }
// }
