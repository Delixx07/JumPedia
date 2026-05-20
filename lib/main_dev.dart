import 'main.dart';

/// ═══════════════════════════════════════
/// ENTRY POINT — FLAVOR DEV
/// ═══════════════════════════════════════
/// Jalankan: flutter run --target lib/main_dev.dart
/// Config: Firebase project dev, logging aktif, fitur debug visible.

void main() {
  AppConfig.isDev = true;
  AppConfig.allowScoreReset = true;
  AppConfig.appLabel = 'EcoJump Dev';
  AppConfig.firebaseProject = 'sdg-ecojump-dev';

  mainCommon();
}
