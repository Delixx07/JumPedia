import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/logger.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import 'language_provider.dart' show sharedPreferencesProvider;

/// ═══════════════════════════════════════
/// AUDIO PROVIDER — JumPedia
/// ═══════════════════════════════════════
/// Menyimpan volume musik latar (BGM) & efek suara (SFX) di SharedPreferences
/// agar persisten antar sesi. Saat berubah, langsung diteruskan ke
/// [AudioService] sehingga audio yang berbunyi ikut menyesuaikan.

const _bgmKey = 'audio_bgm_volume';
const _sfxKey = 'audio_sfx_volume';
const _mutedKey = 'audio_muted';
const _hapticKey = 'haptic_enabled';

const _defaultBgm = 0.5;
const _defaultSfx = 0.8;

/// Pasangan volume audio (BGM & SFX), masing-masing 0.0–1.0.
class AudioVolumes {
  final double bgm;
  final double sfx;

  const AudioVolumes({required this.bgm, required this.sfx});

  AudioVolumes copyWith({double? bgm, double? sfx}) =>
      AudioVolumes(bgm: bgm ?? this.bgm, sfx: sfx ?? this.sfx);
}

class AudioVolumeNotifier extends StateNotifier<AudioVolumes> {
  AudioVolumeNotifier(this._prefs)
      : super(AudioVolumes(
          bgm: _prefs.getDouble(_bgmKey) ?? _defaultBgm,
          sfx: _prefs.getDouble(_sfxKey) ?? _defaultSfx,
        )) {
    // Sinkronkan nilai awal ke AudioService.
    AudioService.setBgmVolume(state.bgm);
    AudioService.setSfxVolume(state.sfx);
  }

  final SharedPreferences _prefs;

  Future<void> setBgmVolume(double value) async {
    state = state.copyWith(bgm: value);
    AudioService.setBgmVolume(value);
    await _prefs.setDouble(_bgmKey, value);
    AppLogger.info('BGM volume set to: $value', tag: 'Audio');
  }

  Future<void> setSfxVolume(double value) async {
    state = state.copyWith(sfx: value);
    AudioService.setSfxVolume(value);
    await _prefs.setDouble(_sfxKey, value);
    AppLogger.info('SFX volume set to: $value', tag: 'Audio');
  }
}

/// Provider volume audio aktif.
final audioVolumeProvider =
    StateNotifierProvider<AudioVolumeNotifier, AudioVolumes>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AudioVolumeNotifier(prefs);
});

/// ─── Master mute (tombol mute cepat) ───
/// Mematikan SEMUA audio tanpa mengubah nilai slider. Persisten.
class MutedNotifier extends StateNotifier<bool> {
  MutedNotifier(this._prefs) : super(_prefs.getBool(_mutedKey) ?? false) {
    AudioService.setMuted(state);
  }

  final SharedPreferences _prefs;

  Future<void> toggle() => setMuted(!state);

  Future<void> setMuted(bool muted) async {
    state = muted;
    AudioService.setMuted(muted);
    await _prefs.setBool(_mutedKey, muted);
    AppLogger.info('Audio muted: $muted', tag: 'Audio');
  }
}

final mutedProvider = StateNotifierProvider<MutedNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MutedNotifier(prefs);
});

/// ─── Haptic / getaran ───
/// Toggle getaran saat lompat & mati. Persisten. Default: aktif.
class HapticEnabledNotifier extends StateNotifier<bool> {
  HapticEnabledNotifier(this._prefs)
      : super(_prefs.getBool(_hapticKey) ?? true) {
    HapticService.setEnabled(state);
  }

  final SharedPreferences _prefs;

  Future<void> toggle() => setEnabled(!state);

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    HapticService.setEnabled(enabled);
    await _prefs.setBool(_hapticKey, enabled);
    AppLogger.info('Haptic enabled: $enabled', tag: 'Haptic');
  }
}

final hapticEnabledProvider =
    StateNotifierProvider<HapticEnabledNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HapticEnabledNotifier(prefs);
});
