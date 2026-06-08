import 'package:google_generative_ai/google_generative_ai.dart';

import '../core/config/api_keys.dart';
import '../core/utils/logger.dart';
import '../models/fun_fact_model.dart';
import '../providers/language_provider.dart';

/// ═══════════════════════════════════════
/// GEMINI FUN FACT SERVICE — JumPedia
/// ═══════════════════════════════════════
/// Meng-generate fun fact IPA (Sains) tingkat SD secara real-time
/// menggunakan Google Gemini, alih-alih membaca dari Firestore.
/// Dipanggil saat player mencapai checkpoint (kelipatan skor tertentu).
///
/// Target pemain: anak SD. Bahasa mengikuti pilihan di pengaturan
/// (English / Bahasa Indonesia).
///
/// Kunci API diambil dari (urutan prioritas):
///   1. --dart-define=GEMINI_API_KEY=xxxx  (cara aman untuk build rilis)
///   2. ApiKeys.geminiApiKeyFallback        (file lokal, di-gitignore)
class GeminiFunFactService {
  GeminiFunFactService() : _model = _buildModel();

  final GenerativeModel? _model;

  /// Resolusi kunci API: dart-define dulu, baru fallback file lokal.
  static String get _apiKey {
    const fromDefine = String.fromEnvironment('GEMINI_API_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;
    return ApiKeys.geminiApiKeyFallback;
  }

  static GenerativeModel? _buildModel() {
    final key = _apiKey;
    if (key.isEmpty || key == 'PASTE_YOUR_GEMINI_KEY_HERE') {
      AppLogger.warning(
        'GEMINI_API_KEY belum diisi — fun fact AI tidak aktif, '
        'akan dipakai fakta cadangan.',
        tag: 'Gemini',
      );
      return null;
    }
    return GenerativeModel(
      // flash-lite: thinking minimal, jadi teks fakta tidak terpotong.
      // (model 'gemini-2.5-flash' penuh memakai banyak token untuk "thinking"
      // sehingga teks kepotong — lihat finishReason MAX_TOKENS.)
      model: 'gemini-2.5-flash-lite',
      apiKey: key,
      // maxOutputTokens dibuat lapang agar muat thinking minimal + 2 kalimat.
      generationConfig: GenerationConfig(
        temperature: 1.0,
        maxOutputTokens: 400,
      ),
    );
  }

  /// Topik IPA SD. Dipilih acak untuk variasi — sekaligus jadi label kategori
  /// pada kartu koleksi.
  static const List<String> _topics = [
    'animals',
    'plants',
    'human body',
    'weather',
    'the solar system and space',
    'water and air',
    'simple energy and motion',
  ];

  /// Topik checkpoint sebelumnya — supaya tidak diulang berturut-turut.
  String? _lastTopic;

  /// Ringkasan fakta yang sudah diberikan dalam sesi ini, dikirim ke AI
  /// sebagai daftar "jangan diulang". Dibatasi agar prompt tidak membengkak.
  final List<String> _recentFacts = [];

  /// Pilih topik acak yang berbeda dari [_lastTopic] bila memungkinkan.
  String _pickTopic() {
    final candidates = _topics.where((t) => t != _lastTopic).toList();
    final pool = candidates.isNotEmpty ? candidates : _topics.toList();
    pool.shuffle();
    return pool.first;
  }

  /// Bangun prompt sesuai topik & bahasa terpilih, plus instruksi anti-duplikat.
  String _promptFor(String topic, FactLanguage language) {
    final avoid = _recentFacts.isEmpty
        ? ''
        : 'Do NOT repeat any of these facts already shown: '
            '${_recentFacts.map((f) => '"$f"').join('; ')}. ';
    return 'You are writing for elementary school children (ages 7-12). '
        'Give ONE short, fun science fact about "$topic" '
        '(maximum 2 sentences). '
        'Make it a fresh, surprising fact — not the most common one. '
        '$avoid'
        'Keep it simple, accurate, and exciting for kids. '
        'Write the fact in ${language.promptName}. '
        'Reply with the fact text ONLY — no numbering, no quotes, no prefix.';
  }

  /// ═══════════════════════════════════════
  /// GENERATE FACT
  /// ═══════════════════════════════════════
  /// Menghasilkan satu [FunFactModel] IPA SD dari AI dalam [language].
  /// Jika gagal (offline / kunci kosong / error), mengembalikan fakta
  /// cadangan agar game tetap jalan.
  Future<FunFactModel> generateFact({
    required FactLanguage language,
    Set<String> avoidContents = const {},
  }) async {
    // Gabungkan fakta sesi ini + fakta yang sudah dikoleksi user (anti-duplikat
    // lintas-sesi). Daftar dibatasi agar prompt tidak membengkak.
    if (avoidContents.isNotEmpty) {
      for (final c in avoidContents) {
        if (!_recentFacts.contains(c)) _recentFacts.add(c);
      }
      while (_recentFacts.length > 8) {
        _recentFacts.removeAt(0);
      }
    }

    // Pilih topik acak (hindari topik checkpoint sebelumnya).
    final topic = _pickTopic();
    _lastTopic = topic;

    if (_model == null) {
      return _fallbackFact(language);
    }

    try {
      final response = await _model.generateContent([
        Content.text(_promptFor(topic, language)),
      ]);

      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        AppLogger.warning('Gemini mengembalikan teks kosong — pakai cadangan.',
            tag: 'Gemini');
        return _fallbackFact(language);
      }

      // Tolak teks yang terpotong / terlalu pendek (mis. "Did you know that")
      // — biasanya akibat output kepotong; lebih baik pakai fakta cadangan.
      if (text.length < 25 || !text.contains(' ')) {
        AppLogger.warning('Teks Gemini terlalu pendek ("$text") — pakai cadangan.',
            tag: 'Gemini');
        return _fallbackFact(language);
      }

      AppLogger.info('Fun fact IPA berhasil dibuat ($topic, ${language.label}).',
          tag: 'Gemini');

      _rememberFact(text);

      // factId unik berbasis waktu agar setiap fakta AI tersimpan terpisah
      // di koleksi user (collected_facts).
      return FunFactModel(
        factId: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        content: text,
        category: topic,
      );
    } catch (e, st) {
      AppLogger.error('Gagal generate fun fact dari Gemini',
          tag: 'Gemini', error: e, stackTrace: st);
      return _fallbackFact(language);
    }
  }

  /// Catat fakta yang sudah diberikan (maks 5 terakhir) untuk anti-duplikat.
  void _rememberFact(String fact) {
    _recentFacts.add(fact);
    if (_recentFacts.length > 5) {
      _recentFacts.removeAt(0);
    }
  }

  /// Fakta cadangan saat AI tidak tersedia, supaya overlay tidak pernah kosong.
  /// Tiap entri berpasangan (kategori, teks) agar label cocok dengan isi.
  /// Dipilih acak namun tidak mengulang fakta yang baru saja muncul.
  FunFactModel _fallbackFact(FactLanguage language) {
    // (kategori, teks EN, teks ID)
    const facts = <(String, String, String)>[
      (
        'animals',
        'A honeybee has to visit about 2 million flowers to make just one '
            'jar of honey!',
        'Seekor lebah madu harus mengunjungi sekitar 2 juta bunga untuk '
            'membuat satu toples madu!',
      ),
      (
        'human body',
        'Your heart beats around 100,000 times every single day to keep '
            'your blood moving.',
        'Jantungmu berdetak sekitar 100.000 kali setiap hari untuk '
            'mengalirkan darah.',
      ),
      (
        'the solar system and space',
        'The Sun is so big that about 1.3 million Earths could fit inside it!',
        'Matahari sangat besar — sekitar 1,3 juta planet Bumi bisa muat '
            'di dalamnya!',
      ),
      (
        'plants',
        'Some trees can talk to each other through their roots to share food '
            'and warnings!',
        'Beberapa pohon bisa "berbicara" lewat akarnya untuk berbagi makanan '
            'dan peringatan!',
      ),
      (
        'water and air',
        'A single cloud can weigh more than a million kilograms — as heavy as '
            '100 elephants!',
        'Satu awan bisa berbobot lebih dari satu juta kilogram — seberat '
            '100 ekor gajah!',
      ),
    ];

    // Pilih entri yang teksnya belum baru saja muncul, bila memungkinkan.
    final pool = facts.toList()..shuffle();
    final chosen = pool.firstWhere(
      (f) => !_recentFacts.contains(language == FactLanguage.english ? f.$2 : f.$3),
      orElse: () => pool.first,
    );

    final text = language == FactLanguage.english ? chosen.$2 : chosen.$3;
    _rememberFact(text);

    return FunFactModel(
      factId: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      content: text,
      category: chosen.$1,
    );
  }
}
