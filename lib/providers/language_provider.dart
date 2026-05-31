import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/logger.dart';

/// ═══════════════════════════════════════
/// LANGUAGE PROVIDER — JumPedia
/// ═══════════════════════════════════════
/// Menyimpan pilihan bahasa untuk fun fact (Inggris / Indonesia).
/// Pilihan disimpan di SharedPreferences agar persisten antar sesi.
/// Default: English.

/// Bahasa yang didukung untuk konten fun fact.
enum FactLanguage {
  english,
  indonesian;

  /// Label untuk ditampilkan di UI pengaturan.
  String get label => switch (this) {
        FactLanguage.english => 'English',
        FactLanguage.indonesian => 'Bahasa Indonesia',
      };

  /// Instruksi bahasa yang disisipkan ke prompt AI.
  String get promptName => switch (this) {
        FactLanguage.english => 'English',
        FactLanguage.indonesian => 'Bahasa Indonesia',
      };

  /// Nilai yang disimpan ke SharedPreferences.
  String get storageKey => name;

  static FactLanguage fromStorage(String? value) {
    return FactLanguage.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FactLanguage.english, // default
    );
  }
}

const _prefsKey = 'fact_language';

/// Override di main() setelah SharedPreferences siap.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider harus di-override di main().',
  );
});

/// Notifier bahasa fun fact — baca/simpan ke SharedPreferences.
class FactLanguageNotifier extends StateNotifier<FactLanguage> {
  FactLanguageNotifier(this._prefs)
      : super(FactLanguage.fromStorage(_prefs.getString(_prefsKey)));

  final SharedPreferences _prefs;

  /// Ganti bahasa & simpan ke disk.
  Future<void> setLanguage(FactLanguage language) async {
    state = language;
    await _prefs.setString(_prefsKey, language.storageKey);
    AppLogger.info('Fun fact language set to: ${language.label}',
        tag: 'Language');
  }
}

/// Provider bahasa fun fact aktif.
final factLanguageProvider =
    StateNotifierProvider<FactLanguageNotifier, FactLanguage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FactLanguageNotifier(prefs);
});
