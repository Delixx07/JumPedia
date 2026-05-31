import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk subcollection 'users/{uid}/collected_facts'.
/// Menyimpan snapshot fun fact pada saat user pertama kali mendapatkannya
/// di dalam game.
class CollectedFactModel {
  final String factId;
  final String content;
  final String category;
  final Timestamp collectedAt;
  final bool isFavorite;

  const CollectedFactModel({
    required this.factId,
    required this.content,
    required this.category,
    required this.collectedAt,
    this.isFavorite = false,
  });

  factory CollectedFactModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CollectedFactModel(
      factId: data['fact_id'] as String? ?? doc.id,
      content: data['content'] as String? ?? '',
      category: data['category'] as String? ?? 'general',
      collectedAt: data['collected_at'] as Timestamp? ?? Timestamp.now(),
      isFavorite: data['is_favorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fact_id': factId,
      'content': content,
      'category': category,
      'collected_at': collectedAt,
      'is_favorite': isFavorite,
    };
  }
}
