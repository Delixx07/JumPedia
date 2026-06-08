import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/i18n/app_strings.dart';
import '../core/utils/logger.dart';
import 'language_provider.dart' show sharedPreferencesProvider;

/// ═══════════════════════════════════════
/// UI LANGUAGE PROVIDER — JumPedia
/// ═══════════════════════════════════════
/// Bahasa untuk seluruh teks UI (tombol, menu, dialog). TERPISAH dari
/// factLanguageProvider yang hanya mengatur bahasa konten fun fact.
/// Persisten via SharedPreferences. Default: Bahasa Indonesia.

const _prefsKey = 'ui_language';

class UiLanguageNotifier extends StateNotifier<UiLanguage> {
  UiLanguageNotifier(this._prefs)
      : super(UiLanguage.fromStorage(_prefs.getString(_prefsKey)));

  final SharedPreferences _prefs;

  Future<void> setLanguage(UiLanguage language) async {
    state = language;
    await _prefs.setString(_prefsKey, language.storageKey);
    AppLogger.info('UI language set to: ${language.label}', tag: 'i18n');
  }
}

/// Provider bahasa UI aktif.
final uiLanguageProvider =
    StateNotifierProvider<UiLanguageNotifier, UiLanguage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UiLanguageNotifier(prefs);
});

/// Teks UI untuk bahasa aktif. Watch ini di widget untuk dapat string.
final uiStringsProvider = Provider<AppStrings>((ref) {
  return AppStrings(ref.watch(uiLanguageProvider));
});
