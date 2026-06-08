import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/i18n/app_strings.dart';
import '../../providers/audio_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/ui_language_provider.dart';

/// Settings Screen — switch bahasa fun fact & pengaturan volume audio.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volumes = ref.watch(audioVolumeProvider);
    final s = ref.watch(uiStringsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.scaffold,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  IconButton(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.arrow_back_ios, color: AppColors.textHi),
                  ),
                  Text(s.settings,
                      style: const TextStyle(
                          color: AppColors.textHi,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 32),

                // ─── App Language (UI) ────────────────
                _SectionLabel(s.appLanguage),
                const SizedBox(height: 4),
                Text(s.appLanguageDesc,
                    style: const TextStyle(color: AppColors.textLo, fontSize: 12)),
                const SizedBox(height: 12),
                _UiLanguageSelector(
                  selected: ref.watch(uiLanguageProvider),
                  onChanged: (lang) =>
                      ref.read(uiLanguageProvider.notifier).setLanguage(lang),
                ),
                const SizedBox(height: 32),

                // ─── Fun Fact Language ────────────────
                _SectionLabel(s.funFactLanguage),
                const SizedBox(height: 4),
                Text(s.funFactLanguageDesc,
                    style: const TextStyle(color: AppColors.textLo, fontSize: 12)),
                const SizedBox(height: 12),
                _LanguageSelector(
                  selected: ref.watch(factLanguageProvider),
                  onChanged: (lang) =>
                      ref.read(factLanguageProvider.notifier).setLanguage(lang),
                ),
                const SizedBox(height: 32),

                // ─── Background Music Volume ──────────
                _SectionLabel(s.backgroundMusic),
                const SizedBox(height: 4),
                Text(s.backgroundMusicDesc,
                    style: const TextStyle(color: AppColors.textLo, fontSize: 12)),
                const SizedBox(height: 4),
                _VolumeSlider(
                  icon: Icons.music_note_rounded,
                  value: volumes.bgm,
                  onChanged: (v) =>
                      ref.read(audioVolumeProvider.notifier).setBgmVolume(v),
                ),
                const SizedBox(height: 24),

                // ─── Sound Effects Volume ─────────────
                _SectionLabel(s.soundEffects),
                const SizedBox(height: 4),
                Text(s.soundEffectsDesc,
                    style: const TextStyle(color: AppColors.textLo, fontSize: 12)),
                const SizedBox(height: 4),
                _VolumeSlider(
                  icon: Icons.graphic_eq_rounded,
                  value: volumes.sfx,
                  onChanged: (v) =>
                      ref.read(audioVolumeProvider.notifier).setSfxVolume(v),
                ),
                const SizedBox(height: 24),

                // ─── Mute All ─────────────────────────
                _ToggleRow(
                  icon: ref.watch(mutedProvider)
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  title: s.muteAll,
                  subtitle: s.muteAllDesc,
                  value: ref.watch(mutedProvider),
                  onChanged: (_) =>
                      ref.read(mutedProvider.notifier).toggle(),
                ),
                const SizedBox(height: 8),

                // ─── Haptic / Vibration ───────────────
                _ToggleRow(
                  icon: Icons.vibration_rounded,
                  title: s.vibration,
                  subtitle: s.vibrationDesc,
                  value: ref.watch(hapticEnabledProvider),
                  onChanged: (_) =>
                      ref.read(hapticEnabledProvider.notifier).toggle(),
                ),
                const SizedBox(height: 24),

                // ─── About App ────────────────────────
                InkWell(
                  onTap: () => context.go('/about'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.aboutApp,
                                  style: const TextStyle(
                                      color: AppColors.textHi,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              Text(s.aboutAppDesc,
                                  style: const TextStyle(
                                      color: AppColors.textLo, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textLo),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Label section seragam.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          color: AppColors.textHi, fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}

/// Slider volume 0–100% dengan ikon + label persen.
class _VolumeSlider extends StatelessWidget {
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;

  const _VolumeSlider({
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.end,
            style: const TextStyle(
                color: AppColors.textHi, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Baris toggle dengan ikon, judul, subjudul, dan switch.
class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textHi,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppColors.textLo, fontSize: 12)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }
}

/// Pemilih bahasa UI — toggle (English / Bahasa Indonesia).
class _UiLanguageSelector extends StatelessWidget {
  final UiLanguage selected;
  final ValueChanged<UiLanguage> onChanged;

  const _UiLanguageSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final lang in UiLanguage.values) ...[
          Expanded(
            child: _LanguageChip(
              label: lang.label,
              isSelected: lang == selected,
              onTap: () => onChanged(lang),
            ),
          ),
          if (lang != UiLanguage.values.last) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

/// Pemilih bahasa fun fact — dua pilihan toggle (English / Bahasa Indonesia).
class _LanguageSelector extends StatelessWidget {
  final FactLanguage selected;
  final ValueChanged<FactLanguage> onChanged;

  const _LanguageSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final lang in FactLanguage.values) ...[
          Expanded(
            child: _LanguageChip(
              label: lang.label,
              isSelected: lang == selected,
              onTap: () => onChanged(lang),
            ),
          ),
          if (lang != FactLanguage.values.last) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.bgMid,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textLo.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check, color: Colors.white, size: 18),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textHi,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
