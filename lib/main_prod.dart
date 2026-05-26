import 'main.dart';

/// ═══════════════════════════════════════
/// ENTRY POINT — FLAVOR PROD
/// ═══════════════════════════════════════
/// Jalankan: flutter run --target lib/main_prod.dart
/// Build: flutter build appbundle --flavor prod --target lib/main_prod.dart
/// Config: Firebase project prod, analytics aktif, debug off.

void main() {
  AppConfig.isDev = false;
  AppConfig.allowScoreReset = false;
  AppConfig.appLabel = 'JumPedia';
  AppConfig.firebaseProject = 'sdg-ecojump-prod';

  mainCommon();
}
