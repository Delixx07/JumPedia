import 'package:flutter/material.dart';

/// WIDGET — Tampilkan animasi dan teks saat list kosong.
///
/// Ditampilkan oleh HomeScreen saat tidak ada todo yang cocok dengan filter.
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;

  const EmptyState({
    super.key,
    this.title = 'Tidak ada todo',
    this.subtitle = 'Tap + untuk menambahkan todo baru',
    this.icon = Icons.task_alt_rounded,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikon dengan background lingkaran
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 50,
                color: colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
