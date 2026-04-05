/// MODEL layer — Data class untuk kategori todo.
/// color dan icon disimpan sebagai int di SQLite (Color.value dan IconData.codePoint).

class Category {
  final int? id;
  final String name;
  final int colorValue; // Color.value
  final int iconCodePoint; // Icons.xxx.codePoint

  const Category({
    this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
  });

  Category copyWith({
    int? id,
    String? name,
    int? colorValue,
    int? iconCodePoint,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color': colorValue,
      'icon': iconCodePoint,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorValue: map['color'] as int,
      iconCodePoint: map['icon'] as int,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name)';
}
