import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/todo_controller.dart';
import '../models/category_model.dart';

/// VIEW — Halaman manajemen kategori.
///
/// Fitur:
///   - List semua kategori dengan warna & ikon
///   - Tambah kategori baru (bottom sheet)
///   - Edit nama, warna, dan ikon kategori
///   - Hapus kategori (todos terkait akan set null kategorinya)
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TodoController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Kelola Kategori',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: controller.categories.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.label_outline_rounded,
                    size: 64,
                    color: colorScheme.onSurface.withOpacity(0.25),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada kategori',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final cat = controller.categories[index];
                return _CategoryTile(
                  category: cat,
                  onEdit: () => _showCategorySheet(context, cat),
                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: const Text('Hapus Kategori?'),
                        content: Text(
                          'Kategori "${cat.name}" akan dihapus. '
                          'Todo yang memiliki kategori ini akan kehilangan kategorinya.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await controller.deleteCategory(cat.id!);
                    }
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategorySheet(context, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Kategori'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  void _showCategorySheet(BuildContext context, Category? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CategorySheet(existing: existing),
    );
  }
}

// ─── CategoryTile ────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = Color(category.colorValue);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: catColor.withOpacity(isDark ? 0.25 : 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
            color: catColor,
            size: 22,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          '#${category.colorValue.toRadixString(16).toUpperCase().padLeft(8, '0').substring(2)}',
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  size: 20, color: colorScheme.onSurface.withOpacity(0.5)),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 20, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CategorySheet (Bottom Sheet Form) ───────────────────────────────────────

class _CategorySheet extends StatefulWidget {
  final Category? existing;
  const _CategorySheet({this.existing});

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late int _selectedColorValue;
  late int _selectedIconCodePoint;
  bool _isSaving = false;

  bool get isEditing => widget.existing != null;

  // Preset colors
  static const _colors = [
    Color(0xFF6C63FF),
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFF44336),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFE91E63),
    Color(0xFF795548),
    Color(0xFF607D8B),
  ];

  // Preset icons
  static const _icons = [
    (0xe7f4, 'Person', Icons.person),
    (0xe8f9, 'Work', Icons.work),
    (0xe80c, 'Study', Icons.school),
    (0xe560, 'Health', Icons.favorite),
    (0xe8cc, 'Shop', Icons.shopping_cart),
    (0xe838, 'Star', Icons.star),
    (0xe7ef, 'Home', Icons.home),
    (0xe88a, 'Music', Icons.music_note),
    (0xe40a, 'Sports', Icons.sports_soccer),
    (0xe3b4, 'Camera', Icons.camera_alt),
    (0xe873, 'Flight', Icons.flight),
    (0xe53b, 'Food', Icons.restaurant),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _selectedColorValue =
        widget.existing?.colorValue ?? _colors[0].value;
    _selectedIconCodePoint =
        widget.existing?.iconCodePoint ?? _icons[0].$1;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final controller = context.read<TodoController>();

    try {
      final category = Category(
        id: widget.existing?.id,
        name: _nameCtrl.text.trim(),
        colorValue: _selectedColorValue,
        iconCodePoint: _selectedIconCodePoint,
      );

      if (isEditing) {
        await controller.updateCategory(category);
      } else {
        await controller.addCategory(category);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              isEditing ? 'Edit Kategori' : 'Tambah Kategori',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Name field
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nama Kategori',
                prefixIcon: Icon(
                  IconData(_selectedIconCodePoint, fontFamily: 'MaterialIcons'),
                  color: Color(_selectedColorValue),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama kategori wajib diisi'
                  : null,
            ),
            const SizedBox(height: 20),

            // Color picker
            Text('Warna',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = _colors[i];
                  final isSelected = _selectedColorValue == c.value;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedColorValue = c.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? colorScheme.onSurface : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Icon picker
            Text('Ikon',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 10),
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final iconData = _icons[i];
                  final isSelected = _selectedIconCodePoint == iconData.$1;
                  return GestureDetector(
                    onTap: () => setState(
                        () => _selectedIconCodePoint = iconData.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 54, height: 54,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(_selectedColorValue).withOpacity(0.2)
                            : colorScheme.surfaceVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Color(_selectedColorValue)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        iconData.$3,
                        color: isSelected
                            ? Color(_selectedColorValue)
                            : colorScheme.onSurface.withOpacity(0.5),
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded),
              label:
                  Text(isEditing ? 'Simpan Perubahan' : 'Buat Kategori'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Color(_selectedColorValue),
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
