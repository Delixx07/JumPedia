import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/logger.dart';

/// ═══════════════════════════════════════
/// PROFILE PHOTO SERVICE — JumPedia
/// ═══════════════════════════════════════
/// Mengunggah foto profil kustom ke Supabase Storage (bucket 'avatars')
/// dan mengembalikan URL publiknya. URL lalu disimpan ke dokumen user
/// (Firestore) oleh pemanggil.
class ProfilePhotoService {
  static const String _bucket = 'avatars';

  SupabaseClient get _client => Supabase.instance.client;

  /// Upload [file] sebagai foto profil milik [uid]. Mengembalikan URL publik.
  /// Memakai nama file tetap per-user (uid.jpg) + upsert agar menimpa foto lama.
  Future<String> uploadAvatar(String uid, File file) async {
    final path = '$uid.jpg';

    await _client.storage.from(_bucket).upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );

    // Tambah query cache-buster agar URL yang sama menampilkan foto terbaru.
    final base = _client.storage.from(_bucket).getPublicUrl(path);
    final url = '$base?v=${DateTime.now().millisecondsSinceEpoch}';

    AppLogger.info('Avatar uploaded: $url', tag: 'Supabase');
    return url;
  }
}
