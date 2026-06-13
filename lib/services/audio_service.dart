import 'package:flame_audio/flame_audio.dart';

import '../core/utils/logger.dart';

/// ═══════════════════════════════════════
/// AUDIO SERVICE — JumPedia
/// ═══════════════════════════════════════
/// Pembungkus tipis di atas FlameAudio untuk musik latar (BGM) & efek suara.
/// File audio berada di assets/audio/ (didaftarkan di pubspec.yaml).
///
/// Volume diatur lewat Settings dan disimpan via AudioVolume provider.
/// Saat volume berubah, panggil [setBgmVolume] / [setSfxVolume].
///
/// Pemakaian:
///   await AudioService.preload();   // sekali di GameWorld.onLoad
///   AudioService.playJump();        // saat player memantul
///   AudioService.playDeath();       // saat game over
///   AudioService.startBgm();        // mulai musik latar (loop)
class AudioService {
  AudioService._();

  static const String _jump = 'jump_sound.mp3';
  static const String _death = 'death_sound.mp3';
  static const String _tick = 'tick.mp3';

  /// File musik latar. Letakkan di assets/audio/bgm.mp3 agar berbunyi.
  /// Jika file belum ada, BGM diam tanpa membuat app error.
  static const String _bgm = 'bgm.mp3';

  static bool _ready = false;
  static bool _bgmPlaying = false;

  /// Master mute — mematikan SEMUA audio (BGM + SFX) tanpa mengubah nilai
  /// volume slider. Dipakai oleh tombol mute cepat.
  static bool _muted = false;

  /// Volume tersimpan (0.0–1.0). Default mengikuti nilai lama.
  static double _bgmVolume = 0.5;
  static double _sfxVolume = 0.8;

  /// Volume BGM efektif (0 jika di-mute).
  static double get _effectiveBgmVolume => _muted ? 0.0 : _bgmVolume;

  /// Muat file SFX ke cache lebih dulu agar tidak ada jeda saat pertama
  /// kali diputar. Aman dipanggil berkali-kali.
  static Future<void> preload() async {
    if (_ready) return;
    try {
      await FlameAudio.audioCache.loadAll([_jump, _death, _tick]);
      _ready = true;
      AppLogger.game('Audio preloaded: jump, death, & tick');
    } catch (e) {
      AppLogger.warning('Gagal preload audio: $e', tag: 'Audio');
    }
  }

  // ─── Volume control ───────────────────
  /// Set volume SFX (lompat & mati). Range 0.0–1.0.
  static void setSfxVolume(double value) {
    _sfxVolume = value.clamp(0.0, 1.0);
  }

  /// Set volume BGM. Berlaku langsung ke musik yang sedang berputar.
  static void setBgmVolume(double value) {
    _bgmVolume = value.clamp(0.0, 1.0);
    _applyBgmVolume();
  }

  /// Aktif/nonaktifkan master mute (semua audio). Tidak mengubah nilai slider.
  static void setMuted(bool muted) {
    _muted = muted;
    _applyBgmVolume();
  }

  static bool get isMuted => _muted;

  /// Terapkan volume BGM efektif (memperhitungkan mute) ke player aktif.
  static void _applyBgmVolume() {
    if (!_bgmPlaying) return;
    try {
      FlameAudio.bgm.audioPlayer.setVolume(_effectiveBgmVolume);
    } catch (_) {
      // player belum siap; abaikan
    }
  }

  // ─── Background music ─────────────────
  /// Mulai musik latar (loop). Diam jika file bgm.mp3 belum ada.
  static Future<void> startBgm() async {
    if (_bgmPlaying) return;
    try {
      await FlameAudio.bgm.play(_bgm, volume: _effectiveBgmVolume);
      _bgmPlaying = true;
      AppLogger.game('BGM started');
    } catch (e) {
      // File mungkin belum ada — biarkan diam, jangan crash.
      AppLogger.warning('BGM tidak diputar (file bgm.mp3 belum ada?): $e',
          tag: 'Audio');
    }
  }

  /// Hentikan musik latar.
  static Future<void> stopBgm() async {
    if (!_bgmPlaying) return;
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {
      // abaikan
    }
    _bgmPlaying = false;
  }

  // ─── Sound effects ────────────────────
  /// Putar suara lompat (dipanggil tiap player memantul di platform).
  /// Volume = sfxVolume * bobot per-efek.
  static void playJump() => _play(_jump, weight: 0.75);

  /// Putar suara kalah/mati (dipanggil saat game over).
  static void playDeath() => _play(_death, weight: 1.0);

  /// Putar suara bip countdown.
  static void playTick() => _play(_tick, weight: 0.6);

  static void _play(String file, {double weight = 1.0}) {
    if (_muted || _sfxVolume <= 0) return;
    try {
      FlameAudio.play(file, volume: _sfxVolume * weight);
    } catch (e) {
      AppLogger.warning('Gagal memutar audio $file: $e', tag: 'Audio');
    }
  }
}
