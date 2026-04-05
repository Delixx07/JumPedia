import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CONTROLLER layer — Mengelola state tema (dark/light mode).
///
/// Menggunakan ChangeNotifier sehingga View bisa "listen" perubahan tema.
/// Tema disimpan ke SharedPreferences agar persisten setelah app restart.
///
/// Cara kerja:
///   1. App pertama kali dibuka → loadTheme() membaca preferensi dari disk
///   2. User toggle tema → toggleTheme() mengubah state + simpan ke disk
///   3. notifyListeners() memberi tahu MaterialApp untuk rebuild dengan tema baru
class ThemeController extends ChangeNotifier {
  static const _themeKey = 'is_dark_mode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Dipanggil saat app pertama kali start — baca tema tersimpan dari disk
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey);
    if (isDark == null) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    }
    notifyListeners();
  }

  /// Toggle antara dark dan light, lalu simpan ke SharedPreferences
  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _themeMode == ThemeMode.dark);

    notifyListeners(); // trigger rebuild di MaterialApp
  }

  /// Set tema secara eksplisit
  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.dark) {
      await prefs.setBool(_themeKey, true);
    } else if (mode == ThemeMode.light) {
      await prefs.setBool(_themeKey, false);
    } else {
      await prefs.remove(_themeKey);
    }
    notifyListeners();
  }
}
