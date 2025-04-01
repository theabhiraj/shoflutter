class Category {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  DateTime? updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    this.updatedAt,
  });

  factory Category.fromMap(String id, Map<dynamic, dynamic> map) {
    return Category(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
