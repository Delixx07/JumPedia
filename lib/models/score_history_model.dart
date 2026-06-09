import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk dokumen di subcollection 'users/{uid}/score_history'
class ScoreHistoryModel {
  final String? id;
  final int score;
  final Timestamp timestamp;

  const ScoreHistoryModel({this.id, required this.score, required this.timestamp});

  factory ScoreHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScoreHistoryModel(
      id: doc.id,
      score: data['score'] as int? ?? 0,
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'score': score,
        'timestamp': timestamp,
      };
}
