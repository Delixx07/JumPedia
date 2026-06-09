/// ═══════════════════════════════════════
/// API KEYS — TEMPLATE (boleh di-commit)
/// ═══════════════════════════════════════
/// Salin file ini menjadi `api_keys.dart` lalu isi kunci asli kamu.
/// File `api_keys.dart` sudah masuk .gitignore agar kunci tidak ter-commit.
///
/// Cara mendapat kunci Gemini gratis:
///   https://aistudio.google.com/app/apikey
class ApiKeys {
  ApiKeys._();

  /// Tempel kunci Gemini kamu di sini untuk run lokal.
  static const String geminiApiKeyFallback = 'PASTE_YOUR_GEMINI_KEY_HERE';

  // ─── Supabase (Storage foto profil) ─────
  /// Dari Supabase → Settings → API.
  static const String supabaseUrl = 'PASTE_SUPABASE_URL_HERE';
  static const String supabaseAnonKey = 'PASTE_SUPABASE_ANON_KEY_HERE';

  static bool get hasSupabase =>
      supabaseUrl.startsWith('http') &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'PASTE_SUPABASE_ANON_KEY_HERE';
}
