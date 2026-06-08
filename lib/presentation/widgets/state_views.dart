import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

/// ═══════════════════════════════════════
/// STATE VIEWS — JumPedia
/// ═══════════════════════════════════════
/// Tampilan seragam untuk kondisi loading / empty / error di seluruh app,
/// supaya tidak ada lagi "CircularProgressIndicator telanjang" atau teks
/// error mentah yang membuat app terlihat belum jadi.

class LoadingView extends StatelessWidget {
  final String? message;
  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: AppDimens.md),
            Text(message!,
                style: const TextStyle(color: AppColors.textLo, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const EmptyView({
    super.key,
    this.icon = Icons.inbox_rounded,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.lg),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: AppDimens.lg),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textHi,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: AppDimens.xs),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textLo, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AppColors.danger),
            const SizedBox(height: AppDimens.md),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textLo, fontSize: 13)),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimens.lg),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryLabel ?? 'Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton blok abu untuk placeholder loading (mis. kartu stat).
class SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? radius;
  const SkeletonBox({super.key, required this.height, this.width, this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.textLo.withValues(alpha: 0.12),
        borderRadius: radius ?? AppDimens.brMd,
      ),
    );
  }
}
