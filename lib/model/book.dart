class Book {
  final int? id;
  final String name;
  final String? createdAt;
  final bool isSelected;

  Book({this.id, required this.name,
    this.createdAt, this.isSelected = false,});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'created_at': createdAt,
    'isSelected': isSelected ? 1 : 0,
  };

  static Book fromMap(Map<String, dynamic> map) => Book(
    id: map['id'],
    name: map['name'],
    createdAt: map['created_at'],
    isSelected: (map['isSelected'] ?? 0) == 1,
  );
}
