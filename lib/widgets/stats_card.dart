import 'package:flutter/material.dart';

/// WIDGET — Card statistik untuk dashboard HomeScreen.
///
/// Menampilkan satu angka statistik (total / completed / pending)
/// dengan ikon, label, dan warna yang bisa dikustomisasi.
class StatsCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark
              ? color.withOpacity(0.15)
              : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
