import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

/// Kartu permukaan standar: putih, radius & shadow konsisten dari design token.
/// Pakai ini menggantikan Container(decoration: BoxDecoration(...)) berulang.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimens.lg),
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: AppColors.bgMid,
      borderRadius: AppDimens.brMd,
      border: Border.all(
        color: borderColor ?? AppColors.textLo.withValues(alpha: 0.12),
      ),
      boxShadow: AppDimens.cardShadow,
    );

    if (onTap == null) {
      return Container(padding: padding, decoration: decoration, child: child);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimens.brMd,
        child: Ink(
          padding: padding,
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }
}

/// Judul section seragam (huruf kapital kecil, tracking lebar).
class SectionHeader extends StatelessWidget {
  final String text;
  const SectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }
}
