import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/todo_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/todo_card.dart';
import '../widgets/empty_state.dart';
import 'todo_form_screen.dart';
import 'todo_detail_screen.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoController>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<TodoController>();
    final themeCtrl = context.watch<ThemeController>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        titleSpacing: 20,
        backgroundColor: cs.surface,
        elevation: 0,
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Cari task...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.4)),
                ),
                onChanged: ctrl.setSearchQuery,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Tasks',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          color: cs.onSurface)),
                  if (ctrl.stats['pending'] != null &&
                      ctrl.stats['pending']! > 0)
                    Text('${ctrl.stats['pending']} task pending',
                        style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withOpacity(0.5))),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
                _showSearch ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  ctrl.setSearchQuery('');
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.label_outline_rounded),
            tooltip: 'Kategori',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryScreen()),
            ).then((_) => ctrl.loadCategories()),
          ),
          PopupMenuButton<FilterStatus>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter Task',
            onSelected: ctrl.setFilterStatus,
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: FilterStatus.all, child: Text('Semua Task')),
              const PopupMenuItem(
                  value: FilterStatus.pending, child: Text('Task Pending')),
              const PopupMenuItem(
                  value: FilterStatus.completed, child: Text('Task Selesai')),
            ],
          ),
          IconButton(
            icon: Icon(themeCtrl.isDarkMode
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded),
            onPressed: themeCtrl.toggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ctrl.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ctrl.todos.isEmpty
              ? EmptyState(
                  title: ctrl.searchQuery.isNotEmpty
                      ? 'Tidak ditemukan'
                      : 'Belum ada task',
                  subtitle: ctrl.searchQuery.isNotEmpty
                      ? 'Coba kata kunci lain'
                      : 'Tap + untuk membuat task baru',
                  icon: ctrl.searchQuery.isNotEmpty
                      ? Icons.search_off_rounded
                      : Icons.task_alt_rounded,
                  action: ctrl.filterStatus != FilterStatus.all
                      ? TextButton.icon(
                          icon: const Icon(Icons.clear_all_rounded),
                          label: const Text('Tampilkan Semua'),
                          onPressed: () =>
                              ctrl.setFilterStatus(FilterStatus.all),
                        )
                      : null,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: ctrl.todos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final todo = ctrl.todos[index];
                    return Dismissible(
                      key: ValueKey(todo.id),
                      direction: DismissDirection.endToStart,
                      background: _SwipeDeleteBg(),
                      confirmDismiss: (_) async =>
                          await _confirmDelete(context),
                      onDismissed: (_) {
                        ctrl.deleteTodo(todo.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Task dihapus'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: TodoCard(
                        todo: todo,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TodoDetailScreen(todo: todo)),
                        ).then((_) => ctrl.loadTodos()),
                        onEdit: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TodoFormScreen(todo: todo)),
                        ).then((_) => ctrl.loadTodos()),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        elevation: 2,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TodoFormScreen()),
          );
          if (mounted) await context.read<TodoController>().loadTodos();
        },
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Task?'),
            content: const Text('Sekali dihapus, tidak bisa kembali.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _SwipeDeleteBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete_outline_rounded,
          color: Colors.white, size: 24),
    );
  }
}
