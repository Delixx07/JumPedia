/// ═══════════════════════════════════════
/// APP STRINGS — JumPedia (i18n ringan)
/// ═══════════════════════════════════════
/// Pendekatan ringan tanpa codegen: satu enum bahasa UI + dua map teks
/// (English / Indonesia). Diakses lewat [uiStringsProvider] di Riverpod.
///
/// Menambah teks baru:
///   1. tambah getter di [AppStrings]
///   2. isi nilainya di _en & _id
library;

enum UiLanguage {
  english,
  indonesian;

  String get label => switch (this) {
        UiLanguage.english => 'English',
        UiLanguage.indonesian => 'Bahasa Indonesia',
      };

  String get storageKey => name;

  static UiLanguage fromStorage(String? value) =>
      UiLanguage.values.firstWhere(
        (e) => e.name == value,
        orElse: () => UiLanguage.indonesian, // default: Indonesia
      );
}

/// Akses teks UI untuk bahasa terpilih.
class AppStrings {
  final UiLanguage lang;
  const AppStrings(this.lang);

  String _t(String en, String id) =>
      lang == UiLanguage.english ? en : id;

  // ─── Navigasi / umum ──────────────────
  String get home => _t('Home', 'Beranda');
  String get funFacts => _t('Fun Facts', 'Fakta Seru');
  String get leaderboard => _t('Leaderboard', 'Papan Skor');
  String get settings => _t('Settings', 'Pengaturan');
  String get profile => _t('Profile', 'Profil');
  String get save => _t('Save', 'Simpan');
  String get cancel => _t('Cancel', 'Batal');
  String get close => _t('Close', 'Tutup');
  String get delete => _t('Delete', 'Hapus');
  String get reset => _t('Reset', 'Atur Ulang');
  String get error => _t('Error', 'Kesalahan');
  String get player => _t('Player', 'Pemain');

  // ─── Home ─────────────────────────────
  String greeting(String name) => _t('Hello, $name', 'Halo, $name');
  String get homeSubtitle =>
      _t('Ready to jump higher today?', 'Siap melompat lebih tinggi hari ini?');
  String get settingUpProfile => _t('Setting up profile...', 'Menyiapkan profil...');
  String get justAMoment => _t('Just a moment...', 'Sebentar ya...');
  String get tagline => _t('Jump high, collect knowledge! 📚',
      'Lompat tinggi, kumpulkan ilmu! 📚');
  String get bestScore => _t('Best Score', 'Skor Terbaik');
  String get gamesPlayed => _t('Games Played', 'Total Main');
  String get startPlaying => _t('Start Playing', 'Mulai Bermain');
  String get guestAccountTitle => _t('Your account is guest', 'Akun kamu adalah tamu');
  String get guestAccountDesc => _t(
      'Link to Google to keep your progress across devices.',
      'Tautkan ke Google agar progres tersimpan di semua perangkat.');
  String get linkNowGoogle => _t('Link Now with Google', 'Tautkan dengan Google');
  String get accountLinked =>
      _t('Account linked successfully!', 'Akun berhasil ditautkan!');
  String get googleInUse => _t(
      'This Google account is already used by another account.',
      'Akun Google ini sudah dipakai akun lain.');
  String get logout => _t('Logout', 'Keluar');

  // ─── Login ────────────────────────────
  String get loginLine1 => _t('Choose how', 'Pilih cara');
  String get loginLine2 => _t('you sign in', 'kamu masuk');
  String get continueGoogle => _t('Continue with Google', 'Lanjut dengan Google');
  String get playAsGuest => _t('Play as guest', 'Main sebagai tamu');
  String get guestNoProgress => _t(
      'Guest mode does not save progress across devices.',
      'Mode tamu tidak menyimpan progres antar perangkat.');
  String signInFailed(String e) => _t('Sign-in failed: $e', 'Gagal masuk: $e');
  String guestSignInFailed(String e) =>
      _t('Guest sign-in failed: $e', 'Gagal masuk sebagai tamu: $e');

  // ─── Settings ─────────────────────────
  String get funFactLanguage => _t('Fun Fact Language', 'Bahasa Fakta Seru');
  String get funFactLanguageDesc => _t(
      'Language used for the science fun facts shown during the game.',
      'Bahasa untuk fakta sains yang muncul saat bermain.');
  String get appLanguage => _t('App Language', 'Bahasa Aplikasi');
  String get appLanguageDesc => _t(
      'Language for all buttons and menus in the app.',
      'Bahasa untuk semua tombol dan menu di aplikasi.');
  String get backgroundMusic => _t('Background Music', 'Musik Latar');
  String get backgroundMusicDesc => _t(
      'Volume of the looping music played in the background.',
      'Volume musik yang diputar berulang di latar.');
  String get soundEffects => _t('Sound Effects', 'Efek Suara');
  String get soundEffectsDesc => _t(
      'Volume of jump and game-over sounds.',
      'Volume suara lompat dan kalah.');
  String get muteAll => _t('Mute All Audio', 'Bisukan Semua Suara');
  String get muteAllDesc => _t(
      'Silence music & sound effects instantly.',
      'Matikan musik & efek suara seketika.');
  String get vibration => _t('Vibration', 'Getaran');
  String get vibrationDesc => _t(
      'Vibrate when jumping and on game over.',
      'Bergetar saat lompat dan saat kalah.');
  String get aboutApp => _t('About App', 'Tentang Aplikasi');
  String get aboutAppDesc => _t(
      'Version, credits, and the SDG behind JumPedia.',
      'Versi, kredit, dan SDG di balik JumPedia.');

  // ─── About ────────────────────────────
  String get aboutTitle => _t('About JumPedia', 'Tentang JumPedia');
  String appVersion(String v) => _t('Version $v', 'Versi $v');
  String get aboutDescription => _t(
      'JumPedia is an educational platformer where you jump high, '
      'dodge plastic trash, and collect science fun facts.',
      'JumPedia adalah game platformer edukatif: lompat tinggi, '
      'hindari sampah plastik, dan kumpulkan fakta sains.');
  String get sdgTitle => _t('The SDG We Support', 'SDG yang Kami Dukung');
  String get sdg4 => _t('SDG 4 — Quality Education',
      'SDG 4 — Pendidikan Berkualitas');
  String get sdg4Desc => _t(
      'Ensuring inclusive and equitable quality education and promoting '
      'lifelong learning opportunities for all.',
      'Memastikan pendidikan berkualitas yang inklusif dan merata serta '
      'mendorong kesempatan belajar sepanjang hayat bagi semua.');
  String get creditsTitle => _t('Credits', 'Kredit');
  String get teamName => _t('Team Aities', 'Tim Aities');
  String get madeWith => _t('Made with Flutter & Flame 🎮',
      'Dibuat dengan Flutter & Flame 🎮');

  // ─── Leaderboard ──────────────────────
  String get noScoresYet => _t('No scores yet', 'Belum ada skor');

  // ─── Profile ──────────────────────────
  String get myProfile => _t('My Profile', 'Profil Saya');
  String get googleOnlyTitle => _t('Google Account Only Feature',
      'Fitur Khusus Akun Google');
  String get googleOnlyDesc => _t(
      'Save your game progress and customize your profile by signing in '
      'with Google.',
      'Simpan progres bermain dan kustomisasi profil dengan masuk lewat '
      'Google.');
  String get loginWithGoogleNow =>
      _t('Sign in with Google Now', 'Login dengan Google Sekarang');
  String get backToHome => _t('Back to Home', 'Kembali ke Beranda');
  String get accountInfo => _t('Account Info', 'Info Akun');
  String get emailAddress => _t('Email Address', 'Alamat Email');
  String get guestAccount => _t('Guest Account', 'Akun Tamu');
  String get noEmail => _t('No Email', 'Tanpa Email');
  String get username => _t('Username', 'Nama Pengguna');
  String get enterUsername => _t('Enter your username', 'Masukkan nama pengguna');
  String get gameStatistics => _t('Game Statistics', 'Statistik Permainan');
  String get totalGamesPlayed => _t('Total Games Played', 'Total Game Dimainkan');
  String get preferences => _t('Preferences', 'Preferensi');
  String get eduNotifications =>
      _t('Educational Notifications', 'Notifikasi Edukasi');
  String get eduNotificationsDesc =>
      _t('Receive daily SDG 4 fun facts', 'Terima fakta SDG 4 harian');
  String get saveChanges => _t('Save Changes', 'Simpan Perubahan');
  String get chooseAvatar => _t('Choose Your Avatar', 'Pilih Avatar Kamu');
  String get profileUpdated =>
      _t('Profile updated successfully!', 'Profil berhasil diperbarui!');

  // ─── Game Over ────────────────────────
  String get gameOver => _t('GAME OVER', 'PERMAINAN BERAKHIR');
  String get gameOverSubtitle => _t(
      'Your character is gone... but the knowledge stays 📚',
      'Karaktermu tumbang... tapi ilmunya tetap tinggal 📚');
  String get finalScore => _t('FINAL SCORE', 'SKOR AKHIR');
  String get playAgain => _t('Restart — Play Again', 'Ulang — Main Lagi');
  String get viewLeaderboard => _t('View Leaderboard', 'Lihat Papan Skor');

  // ─── Fun Facts screen ─────────────────
  String get funFactsCollection =>
      _t('Fun Facts Collection', 'Koleksi Fakta Seru');
  String get funFactsCollectionDesc => _t(
      'Collect a science fact at every checkpoint',
      'Kumpulkan fakta sains di setiap checkpoint');
  String get factsCollected => _t('Facts collected', 'Fakta terkumpul');
  String get noFactsYet =>
      _t('No facts collected yet', 'Belum ada fakta terkumpul');
  String get scienceFunFact => _t('Science Fun Fact', 'Fakta Sains Seru');
  String get resetCollection => _t('Reset Collection?', 'Atur Ulang Koleksi?');
  String get resetCollectionDesc => _t(
      'All facts you have collected will be deleted. This action cannot be undone.',
      'Semua fakta yang terkumpul akan dihapus. Tindakan ini tidak bisa dibatalkan.');
}
