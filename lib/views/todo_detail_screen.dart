import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';
import '../widgets/priority_badge.dart';
import 'todo_form_screen.dart';
import 'package:provider/provider.dart';
import '../controllers/todo_controller.dart';

/// VIEW — Halaman detail satu todo.
///
/// Menampilkan semua informasi todo secara lengkap:
///   - Judul, deskripsi, status, prioritas
///   - Kategori dan due date
///   - Tombol edit dan toggle selesai
class TodoDetailScreen extends StatelessWidget {
  final Todo todo;

  const TodoDetailScreen({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TodoController>();

    // Ambil todo terbaru dari controller (mungkin sudah diupdate)
    final currentTodo = controller.todos.firstWhere(
      (t) => t.id == todo.id,
      orElse: () => todo,
    );

    final category = controller.getCategoryById(currentTodo.categoryId);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool isOverdue = currentTodo.dueDate != null &&
        !currentTodo.isCompleted &&
        currentTodo.dueDate!.isBefore(DateTime.now());

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Detail Task',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => TodoFormScreen(todo: currentTodo)),
            ),
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text('Hapus Task?'),
                  content:
                      const Text('Task yang dihapus tidak dapat dikembalikan.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style:
                          FilledButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await controller.deleteTodo(currentTodo.id!);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Status Banner ────────────────────────────────────
            _StatusBanner(todo: currentTodo),
            const SizedBox(height: 20),

            // ─── Title & Description ──────────────────────────────
            Text(
              currentTodo.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                decoration: currentTodo.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: colorScheme.onSurface.withOpacity(0.4),
              ),
            ),

            if (currentTodo.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                currentTodo.description,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ─── Info Cards ───────────────────────────────────────
            _InfoSection(
              children: [
                // Priority
                _InfoRow(
                  icon: Icons.flag_outlined,
                  label: 'Prioritas',
                  child: PriorityBadge(priority: currentTodo.priority),
                ),

                // Category
                if (category != null)
                  _InfoRow(
                    icon: IconData(category.iconCodePoint,
                        fontFamily: 'MaterialIcons'),
                    iconColor: Color(category.colorValue),
                    label: 'Kategori',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Color(category.colorValue)
                            .withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(category.colorValue),
                        ),
                      ),
                    ),
                  ),

                // Due date
                _InfoRow(
                  icon: isOverdue
                      ? Icons.warning_amber_rounded
                      : Icons.calendar_today_rounded,
                  iconColor: isOverdue ? Colors.red : null,
                  label: 'Deadline',
                  child: currentTodo.dueDate != null
                      ? Text(
                          DateFormat('EEEE, d MMMM yyyy')
                              .format(currentTodo.dueDate!),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: isOverdue
                                ? Colors.red
                                : colorScheme.onSurface,
                          ),
                        )
                      : Text(
                          'Tidak ada deadline',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.4),
                            fontSize: 13,
                          ),
                        ),
                ),

                // Created at
                _InfoRow(
                  icon: Icons.access_time_rounded,
                  label: 'Dibuat',
                  child: Text(
                    DateFormat('d MMM yyyy, HH:mm')
                        .format(currentTodo.createdAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ─── Toggle Done Button ────────────────────────────────
            FilledButton.icon(
              onPressed: () => controller.toggleTodo(currentTodo),
              icon: Icon(currentTodo.isCompleted
                  ? Icons.refresh_rounded
                  : Icons.check_circle_outline_rounded),
              label: Text(currentTodo.isCompleted
                  ? 'Tandai Belum Selesai'
                  : 'Tandai Selesai'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: currentTodo.isCompleted
                    ? colorScheme.secondaryContainer
                    : colorScheme.primary,
                foregroundColor: currentTodo.isCompleted
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final Todo todo;
  const _StatusBanner({required this.todo});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompleted = todo.isCompleted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF4CAF50).withOpacity(0.12)
            : colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF4CAF50).withOpacity(0.4)
              : colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: isCompleted ? const Color(0xFF4CAF50) : colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            isCompleted ? 'Task Selesai ✓' : 'Belum Selesai',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isCompleted
                  ? const Color(0xFF4CAF50)
                  : colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final List<Widget> children;
  const _InfoSection({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        children: children
            .expand((w) => [
                  w,
                  if (w != children.last)
                    Divider(
                        height: 1,
                        color: colorScheme.outlineVariant.withOpacity(0.3)),
                ])
            .toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final Widget child;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.child,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18,
              color: iconColor ?? colorScheme.onSurface.withOpacity(0.45)),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
