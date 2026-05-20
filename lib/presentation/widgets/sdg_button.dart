import 'package:flutter/material.dart';

/// ═══════════════════════════════════════
/// SDG BUTTON — Widget Tombol Reusable
/// ═══════════════════════════════════════
/// Tombol bergaya premium yang konsisten di seluruh app.
/// Mendukung primary, secondary, dan danger styles.

enum SdgButtonStyle { primary, secondary, danger }

class SdgButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final SdgButtonStyle style;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;

  const SdgButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.style = SdgButtonStyle.primary,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColors, textColor, borderColor) = switch (style) {
      SdgButtonStyle.primary => (
          [const Color(0xFF2E7D32), const Color(0xFF4CAF50)],
          Colors.white,
          Colors.greenAccent.withValues(alpha: 0.3),
        ),
      SdgButtonStyle.secondary => (
          [const Color(0xFF1A237E), const Color(0xFF3F51B5)],
          Colors.white,
          Colors.blueAccent.withValues(alpha: 0.3),
        ),
      SdgButtonStyle.danger => (
          [const Color(0xFFB71C1C), const Color(0xFFF44336)],
          Colors.white,
          Colors.redAccent.withValues(alpha: 0.3),
        ),
    };

    final button = Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: bgColors,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: bgColors.first.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: textColor,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize:
                        isExpanded ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: textColor, size: 22),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    return isExpanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
