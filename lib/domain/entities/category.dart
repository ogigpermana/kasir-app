class Category {
  final int? id;
  final int? parentId;
  final String name;
  final String? description;
  final DateTime? createdAt;
  final List<Category>? children;

  const Category({
    this.id,
    this.parentId,
    required this.name,
    this.description,
    this.createdAt,
    this.children,
  });

  bool get isParent => parentId == null;

  Category copyWith({
    int? id,
    int? parentId,
    String? name,
    String? description,
    DateTime? createdAt,
    List<Category>? children,
  }) {
    return Category(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      children: children ?? this.children,
    );
  }
}
