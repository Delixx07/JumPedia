/// MODEL layer — hanya berisi data class, tidak ada logika UI atau SQL.
/// Konversi toMap() dipakai saat INSERT/UPDATE ke SQLite.
/// Konversi fromMap() dipakai saat SELECT dari SQLite.

enum Priority { low, medium, high }

class Todo {
  final int? id;
  final String title;
  final String description;
  final bool isCompleted;
  final Priority priority;
  final DateTime? dueDate;
  final int? categoryId;
  final DateTime createdAt;

  const Todo({
    this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.priority = Priority.medium,
    this.dueDate,
    this.categoryId,
    required this.createdAt,
  });

  /// Buat salinan Todo dengan nilai yang diubah (immutable pattern)
  Todo copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    Priority? priority,
    DateTime? dueDate,
    int? categoryId,
    DateTime? createdAt,
    bool clearDueDate = false,
    bool clearCategory = false,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Konversi ke Map untuk SQLite INSERT/UPDATE
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted ? 1 : 0,
      'priority': priority.name, // 'low' | 'medium' | 'high'
      'due_date': dueDate?.toIso8601String(),
      'category_id': categoryId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Konversi dari Map hasil SQLite SELECT
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      isCompleted: (map['is_completed'] as int) == 1,
      priority: Priority.values.firstWhere(
        (p) => p.name == map['priority'],
        orElse: () => Priority.medium,
      ),
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'] as String)
          : null,
      categoryId: map['category_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() =>
      'Todo(id: $id, title: $title, completed: $isCompleted, priority: ${priority.name})';
}
