import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/todo_controller.dart';
import '../models/todo_model.dart';
import '../models/category_model.dart';

class TodoFormScreen extends StatefulWidget {
  final Todo? todo;
  const TodoFormScreen({super.key, this.todo});

  @override
  State<TodoFormScreen> createState() => _TodoFormScreenState();
}

class _TodoFormScreenState extends State<TodoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  late Priority _priority;
  DateTime? _dueDate;
  int? _categoryId;
  bool _isSaving = false;

  bool get isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    final t = widget.todo;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _priority = t?.priority ?? Priority.medium;
    _dueDate = t?.dueDate;
    _categoryId = t?.categoryId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final ctrl = context.read<TodoController>();
    try {
      if (isEditing) {
        await ctrl.updateTodo(widget.todo!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          priority: _priority,
          dueDate: _dueDate,
          categoryId: _categoryId,
          clearDueDate: _dueDate == null,
          clearCategory: _categoryId == null,
        ));
      } else {
        await ctrl.addTodo(Todo(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          priority: _priority,
          dueDate: _dueDate,
          categoryId: _categoryId,
          createdAt: DateTime.now(),
        ));
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<TodoController>().categories;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Text(isEditing ? 'Edit Task' : 'Tambah Task',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : TextButton(
                  onPressed: _save,
                  child: Text(isEditing ? 'Simpan' : 'Buat',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: cs.primary)),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Judul
            TextFormField(
              controller: _titleCtrl,
              autofocus: !isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: _dec(context, 'Judul task *', Icons.title_rounded),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
              maxLength: 100,
            ),
            const SizedBox(height: 12),

            // Deskripsi
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _dec(context, 'Deskripsi (opsional)', Icons.notes_rounded),
            ),
            const SizedBox(height: 16),

            // Prioritas
            _label('Prioritas'),
            _PriorityRow(
                selected: _priority,
                onChanged: (p) => setState(() => _priority = p)),
            const SizedBox(height: 16),

            // Kategori
            _label('Kategori'),
            if (categories.isEmpty)
              Text('Belum ada kategori',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.5)))
            else
              _CategoryRow(
                categories: categories,
                selectedId: _categoryId,
                onChanged: (id) => setState(() => _categoryId = id),
              ),
            const SizedBox(height: 16),

            // Due date
            _label('Deadline'),
            _DatePicker(
                dueDate: _dueDate,
                onPick: _pickDate,
                onClear: () => setState(() => _dueDate = null)),
            const SizedBox(height: 24),

            // Save button
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(isEditing ? Icons.save_rounded : Icons.add_task_rounded),
              label: Text(isEditing ? 'Simpan Perubahan' : 'Buat Task'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            // Hapus (edit mode only)
            if (isEditing) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus Task?'),
                      content: const Text(
                          'Task yang dihapus tidak dapat dikembalikan.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal')),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && mounted) {
                    await context
                        .read<TodoController>()
                        .deleteTodo(widget.todo!.id!);
                    if (mounted) Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                label: const Text('Hapus Task',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
      );

  InputDecoration _dec(BuildContext ctx, String hint, IconData icon) {
    final cs = Theme.of(ctx).colorScheme;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: cs.surfaceVariant.withOpacity(0.4),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline.withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2)),
    );
  }
}

// ─── Priority row ─────────────────────────────────────────────────────────────

class _PriorityRow extends StatelessWidget {
  final Priority selected;
  final ValueChanged<Priority> onChanged;
  const _PriorityRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Priority.low, 'Low', Color(0xFF4CAF50)),
      (Priority.medium, 'Medium', Color(0xFFFF9800)),
      (Priority.high, 'High', Color(0xFFF44336)),
    ];

    return Row(
      children: items.map((item) {
        final sel = selected == item.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => onChanged(item.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? item.$3.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: sel ? item.$3 : item.$3.withOpacity(0.3),
                      width: sel ? 2 : 1),
                ),
                alignment: Alignment.center,
                child: Text(item.$2,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: item.$3)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Category row ─────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  const _CategoryRow({
    required this.categories,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        _chip(
          label: 'Semua',
          color: cs.outline,
          isSelected: selectedId == null,
          onTap: () => onChanged(null),
        ),
        ...categories.map((cat) => _chip(
              label: cat.name,
              color: Color(cat.colorValue),
              isSelected: selectedId == cat.id,
              onTap: () => onChanged(cat.id),
            )),
      ],
    );
  }

  Widget _chip({
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: isSelected ? 2 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color)),
      ),
    );
  }
}

// ─── Date picker ──────────────────────────────────────────────────────────────

class _DatePicker extends StatelessWidget {
  final DateTime? dueDate;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DatePicker({
    required this.dueDate,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasDate = dueDate != null;

    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 18,
                color: hasDate ? cs.primary : cs.onSurface.withOpacity(0.4)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasDate
                    ? DateFormat('EEEE, d MMMM yyyy').format(dueDate!)
                    : 'Pilih tanggal deadline...',
                style: TextStyle(
                    color: hasDate
                        ? cs.onSurface
                        : cs.onSurface.withOpacity(0.4),
                    fontSize: 14),
              ),
            ),
            if (hasDate)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded,
                    size: 16, color: cs.onSurface.withOpacity(0.4)),
              ),
          ],
        ),
      ),
    );
  }
}
