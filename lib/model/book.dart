class Book {
  final int? id;
  final String name;
  final String? createdAt;
  final bool isSelected;

  Book({this.id, required this.name,
    this.createdAt, this.isSelected = false,});

  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'name': name,
      'isSelected': isSelected ? 1 : 0,
    };

    if (createdAt != null) {
      map['created_at'] = createdAt;
    }

    return map;
  }

  static Book fromMap(Map<String, dynamic> map) => Book(
    id: map['id'],
    name: map['name'],
    createdAt: map['created_at'],
    isSelected: (map['isSelected'] ?? 0) == 1,
  );

  Book copyWith({int? id, String? name, String? createdAt, bool? isSelected}) {
    return Book(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isSelected: isSelected ??  this.isSelected,
    );
  }
}
