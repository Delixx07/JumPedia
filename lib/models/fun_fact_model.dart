import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk koleksi 'fun_facts' di Firestore.
/// Berisi fakta-fakta edukatif bertema SDG 4 (Pendidikan Berkualitas).
/// Data diisi melalui Firebase Console / admin dashboard, bukan dari app.
class FunFactModel {
  final String factId;
  final String content;
  final String category;

  const FunFactModel({
    required this.factId,
    required this.content,
    required this.category,
  });

  /// Factory constructor dari Firestore DocumentSnapshot.
  factory FunFactModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FunFactModel(
      factId: data['fact_id'] as String? ?? doc.id,
      content: data['content'] as String? ?? '',
      category: data['category'] as String? ?? 'general',
    );
  }

  /// Konversi ke Map (untuk referensi, biasanya tidak dipakai dari app).
  Map<String, dynamic> toFirestore() {
    return {
      'fact_id': factId,
      'content': content,
      'category': category,
    };
  }
}
