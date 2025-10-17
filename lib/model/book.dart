class Book {
  final int? id;
  final String name;
  final String? createdAt;

  Book({this.id, required this.name, this.createdAt});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'created_at': createdAt,
  };

  static Book fromMap(Map<String, dynamic> map) => Book(
    id: map['id'],
    name: map['name'],
    createdAt: map['created_at'],
  );
}
