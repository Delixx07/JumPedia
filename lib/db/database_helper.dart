import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// DATABASE layer — Singleton yang mengelola koneksi SQLite.
///
/// Pola Singleton memastikan hanya ada SATU instance database
/// di seluruh lifecycle aplikasi → mencegah konflik baca/tulis.
///
/// Cara kerja:
///   1. Pertama kali DatabaseHelper.database dipanggil, database dibuka/dibuat.
///   2. Panggilan berikutnya langsung mengembalikan instance yang sudah ada.
class DatabaseHelper {
  // Konstanta schema
  static const _databaseName = 'todo_list.db';
  static const _databaseVersion = 1;

  static const tableCategories = 'categories';
  static const tableTodos = 'todos';

  // Singleton private constructor
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Cache instance database (lazy initialization)
  static Database? _database;

  /// Getter: mengembalikan database yang sudah ada, atau membuat baru
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Inisialisasi database: tentukan path dan jalankan onCreate
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON'); // aktifkan FOREIGN KEY constraint
      },
    );
  }

  /// Buat semua tabel saat database pertama kali dibuat
  Future<void> _onCreate(Database db, int version) async {
    // Tabel categories (dibuat duluan karena todos mereferensikannya)
    await db.execute('''
      CREATE TABLE $tableCategories (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        name     TEXT    NOT NULL,
        color    INTEGER NOT NULL,
        icon     INTEGER NOT NULL
      )
    ''');

    // Tabel todos dengan FOREIGN KEY ke categories
    await db.execute('''
      CREATE TABLE $tableTodos (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        title        TEXT    NOT NULL,
        description  TEXT    NOT NULL DEFAULT '',
        is_completed INTEGER NOT NULL DEFAULT 0,
        priority     TEXT    NOT NULL DEFAULT 'medium',
        due_date     TEXT,
        category_id  INTEGER,
        created_at   TEXT    NOT NULL,
        FOREIGN KEY (category_id) REFERENCES $tableCategories(id)
          ON DELETE SET NULL
      )
    ''');

    // Seed data: default categories
    await _seedDefaultCategories(db);
  }

  /// Insert kategori default agar user langsung bisa memakai aplikasi
  Future<void> _seedDefaultCategories(Database db) async {
    final defaultCategories = [
      {'name': 'Personal',  'color': 0xFF6C63FF, 'icon': 0xe7f4}, // Icons.person
      {'name': 'Work',      'color': 0xFF2196F3, 'icon': 0xe8f9}, // Icons.work
      {'name': 'Study',     'color': 0xFF4CAF50, 'icon': 0xe80c}, // Icons.school
      {'name': 'Health',    'color': 0xFFF44336, 'icon': 0xe560}, // Icons.favorite
      {'name': 'Shopping',  'color': 0xFFFF9800, 'icon': 0xe8cc}, // Icons.shopping_cart
    ];
    for (final cat in defaultCategories) {
      await db.insert(tableCategories, cat);
    }
  }

  /// Helper: hapus semua data (berguna untuk testing)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(tableTodos);
    await db.delete(tableCategories);
  }
}
