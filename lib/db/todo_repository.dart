import 'package:sqflite/sqflite.dart';
import '../models/todo_model.dart';
import 'database_helper.dart';

/// DATABASE layer — Repository untuk operasi CRUD tabel todos.
///
/// Setiap method merepresentasikan SATU operasi database yang spesifik.
/// Controller tidak perlu tahu SQL — cukup panggil method ini.
class TodoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ─── CREATE ────────────────────────────────────────────────────────────────

  /// INSERT todo baru ke database, mengembalikan id-nya
  Future<int> insertTodo(Todo todo) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseHelper.tableTodos,
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── READ ──────────────────────────────────────────────────────────────────

  /// SELECT semua todos, diurutkan: belum selesai dulu, lalu berdasarkan created_at
  Future<List<Todo>> getAllTodos() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableTodos,
      orderBy: 'is_completed ASC, created_at DESC',
    );
    return maps.map(Todo.fromMap).toList();
  }

  /// SELECT todos berdasarkan kategori
  Future<List<Todo>> getTodosByCategory(int categoryId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableTodos,
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'is_completed ASC, created_at DESC',
    );
    return maps.map(Todo.fromMap).toList();
  }

  /// SELECT todos berdasarkan status completed
  Future<List<Todo>> getTodosByStatus({required bool isCompleted}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableTodos,
      where: 'is_completed = ?',
      whereArgs: [isCompleted ? 1 : 0],
      orderBy: 'created_at DESC',
    );
    return maps.map(Todo.fromMap).toList();
  }

  /// SEARCH todos berdasarkan teks di title atau description
  /// Menggunakan SQL LIKE dengan wildcard %keyword%
  Future<List<Todo>> searchTodos(String query) async {
    final db = await _dbHelper.database;
    final keyword = '%$query%';
    final maps = await db.query(
      DatabaseHelper.tableTodos,
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: [keyword, keyword],
      orderBy: 'is_completed ASC, created_at DESC',
    );
    return maps.map(Todo.fromMap).toList();
  }

  /// SELECT todos yang due date-nya hari ini atau sudah lewat (overdue)
  Future<List<Todo>> getOverdueTodos() async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final maps = await db.query(
      DatabaseHelper.tableTodos,
      where: 'due_date IS NOT NULL AND due_date <= ? AND is_completed = 0',
      whereArgs: ['${today}T23:59:59.999'],
      orderBy: 'due_date ASC',
    );
    return maps.map(Todo.fromMap).toList();
  }

  /// SELECT satu todo berdasarkan id
  Future<Todo?> getTodoById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableTodos,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Todo.fromMap(maps.first);
  }

  // ─── UPDATE ────────────────────────────────────────────────────────────────

  /// UPDATE semua field todo berdasarkan id
  Future<int> updateTodo(Todo todo) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableTodos,
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  /// UPDATE hanya field is_completed (lebih efisien daripada update semua field)
  Future<int> toggleTodoStatus(int id, bool isCompleted) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableTodos,
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── DELETE ────────────────────────────────────────────────────────────────

  /// DELETE todo berdasarkan id
  Future<int> deleteTodo(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableTodos,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// DELETE semua todos yang sudah completed (fitur "clear completed")
  Future<int> deleteCompletedTodos() async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableTodos,
      where: 'is_completed = ?',
      whereArgs: [1],
    );
  }

  // ─── STATISTICS ────────────────────────────────────────────────────────────

  /// Mengembalikan statistik: total, completed, pending count
  Future<Map<String, int>> getStats() async {
    final db = await _dbHelper.database;

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableTodos}',
    );
    final completedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableTodos} WHERE is_completed = 1',
    );

    final total = Sqflite.firstIntValue(totalResult) ?? 0;
    final completed = Sqflite.firstIntValue(completedResult) ?? 0;

    return {
      'total': total,
      'completed': completed,
      'pending': total - completed,
    };
  }
}
