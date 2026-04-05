import 'package:flutter/material.dart';
import '../models/todo_model.dart';

/// WIDGET — Badge berwarna untuk menampilkan tingkat prioritas todo.
///
/// Dipakai di TodoCard dan TodoDetailScreen.
/// Menerima Priority enum dan mengembalikan chip berwarna yang sesuai.
class PriorityBadge extends StatelessWidget {
  final Priority priority;
  final bool compact; // mode kecil tanpa label teks

  const PriorityBadge({
    super.key,
    required this.priority,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(priority);

    if (compact) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: config.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: config.color.withOpacity(0.4),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 12, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: config.color,
            ),
          ),
        ],
      ),
    );
  }

  _PriorityConfig _getConfig(Priority priority) {
    switch (priority) {
      case Priority.high:
        return _PriorityConfig(
          color: const Color(0xFFF44336),
          label: 'High',
          icon: Icons.keyboard_double_arrow_up_rounded,
        );
      case Priority.medium:
        return _PriorityConfig(
          color: const Color(0xFFFF9800),
          label: 'Medium',
          icon: Icons.drag_handle_rounded,
        );
      case Priority.low:
        return _PriorityConfig(
          color: const Color(0xFF4CAF50),
          label: 'Low',
          icon: Icons.keyboard_double_arrow_down_rounded,
        );
    }
  }
}

class _PriorityConfig {
  final Color color;
  final String label;
  final IconData icon;

  _PriorityConfig({
    required this.color,
    required this.label,
    required this.icon,
  });
}
