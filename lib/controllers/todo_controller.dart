import 'package:flutter/material.dart';
import '../db/category_repository.dart';
import '../db/todo_repository.dart';
import '../models/category_model.dart';
import '../models/todo_model.dart';

/// CONTROLLER layer — Otak dari aplikasi.
///
/// Bertanggung jawab atas:
///   - Menyimpan state (list todos, categories, filter, search query)
///   - Memanggil Repository untuk operasi database
///   - Memanggil notifyListeners() sehingga View otomatis rebuild
///
/// View TIDAK boleh langsung menyentuh Repository, harus lewat Controller ini.
///
/// Pattern: ChangeNotifier + Provider
///   - `context.watch<TodoController>()` → View akan rebuild saat data berubah
///   - `context.read<TodoController>()` → View hanya membaca sekali (tidak subscribe)
class TodoController extends ChangeNotifier {
  final TodoRepository _todoRepo = TodoRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  // ─── STATE ─────────────────────────────────────────────────────────────────

  List<Todo> _allTodos = [];
  List<Todo> _filteredTodos = [];
  List<Category> _categories = [];
  Map<String, int> _stats = {'total': 0, 'completed': 0, 'pending': 0};

  bool _isLoading = false;
  String _searchQuery = '';
  int? _selectedCategoryId; // null = tampilkan semua kategori
  FilterStatus _filterStatus = FilterStatus.all;

  // ─── GETTERS ───────────────────────────────────────────────────────────────

  List<Todo> get todos => _filteredTodos;
  List<Category> get categories => _categories;
  Map<String, int> get stats => _stats;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  FilterStatus get filterStatus => _filterStatus;

  // ─── INITIALIZATION ────────────────────────────────────────────────────────

  /// Dipanggil sekali saat app pertama kali dibuka
  Future<void> initialize() async {
    await Future.wait([
      loadTodos(),
      loadCategories(),
    ]);
  }

  // ─── TODO CRUD ─────────────────────────────────────────────────────────────

  /// CREATE: Tambah todo baru ke database, lalu refresh list
  Future<void> addTodo(Todo todo) async {
    _setLoading(true);
    try {
      await _todoRepo.insertTodo(todo);
      await loadTodos();
    } finally {
      _setLoading(false);
    }
  }

  /// READ: Muat semua todos dari database, lalu terapkan filter yang aktif
  Future<void> loadTodos() async {
    _allTodos = await _todoRepo.getAllTodos();
    _stats = await _todoRepo.getStats();
    _applyFilters();
    notifyListeners();
  }

  /// UPDATE: Perbarui todo yang sudah ada
  Future<void> updateTodo(Todo todo) async {
    _setLoading(true);
    try {
      await _todoRepo.updateTodo(todo);
      await loadTodos();
    } finally {
      _setLoading(false);
    }
  }

  /// UPDATE (partial): Toggle status selesai/belum
  /// Lebih efisien dari updateTodo karena hanya update 1 field
  Future<void> toggleTodo(Todo todo) async {
    await _todoRepo.toggleTodoStatus(todo.id!, !todo.isCompleted);
    // Optimistic UI update: ubah state lokal dulu sebelum reload
    final idx = _allTodos.indexWhere((t) => t.id == todo.id);
    if (idx != -1) {
      _allTodos[idx] = todo.copyWith(isCompleted: !todo.isCompleted);
      _stats = await _todoRepo.getStats();
      _applyFilters();
      notifyListeners();
    }
  }

  /// DELETE: Hapus satu todo berdasarkan id
  Future<void> deleteTodo(int id) async {
    await _todoRepo.deleteTodo(id);
    _allTodos.removeWhere((t) => t.id == id);
    _stats = await _todoRepo.getStats();
    _applyFilters();
    notifyListeners();
  }

  /// DELETE semua todos yang sudah completed
  Future<void> clearCompletedTodos() async {
    await _todoRepo.deleteCompletedTodos();
    await loadTodos();
  }

  // ─── CATEGORY CRUD ─────────────────────────────────────────────────────────

  Future<void> loadCategories() async {
    _categories = await _categoryRepo.getAllCategories();
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    await _categoryRepo.insertCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(Category category) async {
    await _categoryRepo.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    // Jika kategori yang dihapus sedang dipilih, reset filter
    if (_selectedCategoryId == id) _selectedCategoryId = null;
    await _categoryRepo.deleteCategory(id);
    await Future.wait([loadCategories(), loadTodos()]);
  }

  // ─── FILTER & SEARCH ───────────────────────────────────────────────────────

  /// Set query pencarian dan terapkan filter
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Set filter kategori (null = semua)
  void setCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
    notifyListeners();
  }

  /// Set filter status (all / pending / completed)
  void setFilterStatus(FilterStatus status) {
    _filterStatus = status;
    _applyFilters();
    notifyListeners();
  }

  /// Internal: terapkan semua filter yang aktif ke _allTodos
  void _applyFilters() {
    _filteredTodos = _allTodos.where((todo) {
      // Filter status
      if (_filterStatus == FilterStatus.pending && todo.isCompleted) return false;
      if (_filterStatus == FilterStatus.completed && !todo.isCompleted) return false;

      // Filter kategori
      if (_selectedCategoryId != null && todo.categoryId != _selectedCategoryId) {
        return false;
      }

      // Filter search (case-insensitive)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!todo.title.toLowerCase().contains(q) &&
            !todo.description.toLowerCase().contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  /// Dapatkan objek Category berdasarkan id (dari cache, bukan database)
  Category? getCategoryById(int? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

/// Enum untuk filter status todo
enum FilterStatus { all, pending, completed }
