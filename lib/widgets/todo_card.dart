import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/todo_controller.dart';
import '../models/todo_model.dart';
import 'priority_badge.dart';

class TodoCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const TodoCard({
    super.key,
    required this.todo,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TodoController>();
    final category = controller.getCategoryById(todo.categoryId);
    final cs = Theme.of(context).colorScheme;

    final isOverdue = todo.dueDate != null &&
        !todo.isCompleted &&
        todo.dueDate!.isBefore(DateTime.now());

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(todo.isCompleted ? 0.1 : 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => controller.toggleTodo(todo),
              child: Container(
                width: 22, height: 22,
                margin: const EdgeInsets.only(top: 2, right: 14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: todo.isCompleted ? cs.primary : cs.outline.withOpacity(0.6),
                    width: 2,
                  ),
                  color: todo.isCompleted ? cs.primary : Colors.transparent,
                ),
                child: todo.isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: todo.isCompleted ? cs.onSurface.withOpacity(0.4) : cs.onSurface,
                      decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (todo.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        todo.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (todo.priority == Priority.high && !todo.isCompleted)
                        Text('! High', style: TextStyle(color: Colors.red.shade400, fontSize: 12, fontWeight: FontWeight.bold)),
                      if (category != null)
                        Text(category.name, style: TextStyle(color: Color(category.colorValue).withOpacity(todo.isCompleted ? 0.5 : 1), fontSize: 12, fontWeight: FontWeight.w600)),
                      if (todo.dueDate != null)
                        Text(
                          DateFormat('d MMM').format(todo.dueDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue ? Colors.red : cs.onSurface.withOpacity(0.5),
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (onEdit != null && !todo.isCompleted)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: cs.onSurface.withOpacity(0.3),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
      ),
    );
  }
}
