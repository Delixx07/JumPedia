import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

/// ═══════════════════════════════════════
/// SDG BUTTON — Widget Tombol Reusable (JumPedia)
/// ═══════════════════════════════════════
/// Tombol bergaya flat yang konsisten di seluruh app, dengan animasi
/// "tekan" (sedikit mengecil) agar terasa responsif & premium.
/// Mendukung primary (biru solid), secondary (putih), dan danger styles.

enum SdgButtonStyle { primary, secondary, danger }

class SdgButton extends StatefulWidget {
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
  State<SdgButton> createState() => _SdgButtonState();
}

class _SdgButtonState extends State<SdgButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (!widget.isLoading) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final text = widget.text;
    final icon = widget.icon;
    final isLoading = widget.isLoading;
    final isExpanded = widget.isExpanded;
    final onPressed = widget.onPressed;
    // Desain flat: tiap style satu warna solid (tanpa gradiasi).
    final (bgColor, textColor, borderColor) = switch (style) {
      SdgButtonStyle.primary => (
          AppColors.primary,
          Colors.white,
          AppColors.primaryDark,
        ),
      SdgButtonStyle.secondary => (
          AppColors.bgMid,
          AppColors.primary,
          AppColors.primary,
        ),
      SdgButtonStyle.danger => (
          AppColors.danger,
          Colors.white,
          const Color(0xFFB71C1C),
        ),
    };

    final button = AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: AppDimens.fast,
      curve: Curves.easeOut,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppDimens.brMd,
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: _pressed ? null : AppDimens.shadowOf(bgColor),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            borderRadius: AppDimens.brMd,
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
      ),
    );

    return isExpanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
