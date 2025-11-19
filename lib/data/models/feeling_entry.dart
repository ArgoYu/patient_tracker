// lib/data/models/feeling_entry.dart

/// Comment attached to a feeling entry.
class FeelingComment {
  FeelingComment({required this.text, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  final String text;
  final DateTime createdAt;
}

/// Captures a logged feeling along with optional note and comments.
class FeelingEntry {
  FeelingEntry({
    required this.date,
    required this.score,
    this.note,
    List<FeelingComment>? comments,
  }) : comments = comments ?? <FeelingComment>[];

  final DateTime date;
  final int score;
  final String? note;
  final List<FeelingComment> comments;
}
