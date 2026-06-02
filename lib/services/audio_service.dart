import 'package:flame_audio/flame_audio.dart';

import '../core/utils/logger.dart';

/// ═══════════════════════════════════════
/// AUDIO SERVICE — JumPedia
/// ═══════════════════════════════════════
/// Pembungkus tipis di atas FlameAudio untuk efek suara game.
/// File audio berada di assets/audio/ (didaftarkan di pubspec.yaml).
///
/// Pemakaian:
///   await AudioService.preload();   // sekali di GameWorld.onLoad
///   AudioService.playJump();        // saat player memantul
///   AudioService.playDeath();       // saat game over
class AudioService {
  AudioService._();

  static const String _jump = 'jump_sound.mp3';
  static const String _death = 'death_sound.mp3';

  static bool _ready = false;

  /// Muat file audio ke cache lebih dulu agar tidak ada jeda saat pertama
  /// kali diputar. Aman dipanggil berkali-kali.
  static Future<void> preload() async {
    if (_ready) return;
    try {
      await FlameAudio.audioCache.loadAll([_jump, _death]);
      _ready = true;
      AppLogger.game('Audio preloaded: jump & death');
    } catch (e) {
      AppLogger.warning('Gagal preload audio: $e', tag: 'Audio');
    }
  }

  /// Putar suara lompat (dipanggil tiap player memantul di platform).
  static void playJump() => _play(_jump, volume: 0.6);

  /// Putar suara kalah/mati (dipanggil saat game over).
  static void playDeath() => _play(_death, volume: 0.9);

  static void _play(String file, {double volume = 1.0}) {
    try {
      FlameAudio.play(file, volume: volume);
    } catch (e) {
      AppLogger.warning('Gagal memutar audio $file: $e', tag: 'Audio');
    }
  }
}
