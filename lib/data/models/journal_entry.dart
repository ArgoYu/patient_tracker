// lib/data/models/journal_entry.dart

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.medicationId,
    required this.createdAt,
    required this.feelingScore,
    this.tags = const <String>[],
    this.severity,
    this.notes,
  });

  final String id;
  final String medicationId;
  final DateTime createdAt;
  final int feelingScore;
  final List<String> tags;
  final int? severity;
  final String? notes;

  JournalEntry copyWith({
    String? id,
    String? medicationId,
    DateTime? createdAt,
    int? feelingScore,
    List<String>? tags,
    int? severity,
    String? notes,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      createdAt: createdAt ?? this.createdAt,
      feelingScore: feelingScore ?? this.feelingScore,
      tags: tags ?? this.tags,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'medicationId': medicationId,
        'createdAt': createdAt.toIso8601String(),
        'feelingScore': feelingScore,
        'tags': tags,
        'severity': severity,
        'notes': notes,
      };

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    final feelingScoreRaw = map['feelingScore'];
    final legacyFeeling = map['feeling'] as String?;
    final feelingScore = feelingScoreRaw is num
        ? feelingScoreRaw.round().clamp(1, 10)
        : _legacyFeelingToScore(legacyFeeling);
    final tags = (map['tags'] as List?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const <String>[];
    final severityRaw = map['severity'];
    final createdAtRaw = map['createdAt'] as String?;
    return JournalEntry(
      id: (map['id'] as String?) ?? '',
      medicationId: (map['medicationId'] as String?) ?? '',
      createdAt: createdAtRaw == null
          ? DateTime.now()
          : DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
      feelingScore: feelingScore,
      tags: tags,
      severity: severityRaw is num ? severityRaw.toInt() : null,
      notes: map['notes'] as String?,
    );
  }
}

int _legacyFeelingToScore(String? feeling) {
  switch (feeling) {
    case 'bad':
      return 3;
    case 'notGreat':
      return 5;
    case 'ok':
      return 7;
    default:
      return 6;
  }
}
