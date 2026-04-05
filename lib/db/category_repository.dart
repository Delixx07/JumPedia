import 'package:sqflite/sqflite.dart';
import '../models/category_model.dart';
import 'database_helper.dart';

/// DATABASE layer — Repository untuk operasi CRUD tabel categories.
///
/// Repository memisahkan SQL queries dari business logic Controller.
/// Controller hanya memanggil method di sini tanpa tahu detail SQL-nya.
class CategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ─── CREATE ────────────────────────────────────────────────────────────────

  /// INSERT kategori baru, mengembalikan id yang baru dibuat
  Future<int> insertCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseHelper.tableCategories,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── READ ──────────────────────────────────────────────────────────────────

  /// SELECT semua kategori, diurutkan berdasarkan nama
  Future<List<Category>> getAllCategories() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableCategories,
      orderBy: 'name ASC',
    );
    return maps.map(Category.fromMap).toList();
  }

  /// SELECT satu kategori berdasarkan id
  Future<Category?> getCategoryById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableCategories,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  // ─── UPDATE ────────────────────────────────────────────────────────────────

  /// UPDATE kategori berdasarkan id
  Future<int> updateCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableCategories,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // ─── DELETE ────────────────────────────────────────────────────────────────

  /// DELETE kategori berdasarkan id
  /// (todos yang punya category_id ini akan di-SET NULL oleh FOREIGN KEY)
  Future<int> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableCategories,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
