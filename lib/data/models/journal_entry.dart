// lib/data/models/journal_entry.dart

enum JournalFeeling { ok, notGreat, bad }

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.medicationId,
    required this.createdAt,
    required this.feeling,
    this.tags = const <String>[],
    this.severity,
    this.notes,
  });

  final String id;
  final String medicationId;
  final DateTime createdAt;
  final JournalFeeling feeling;
  final List<String> tags;
  final int? severity;
  final String? notes;

  JournalEntry copyWith({
    String? id,
    String? medicationId,
    DateTime? createdAt,
    JournalFeeling? feeling,
    List<String>? tags,
    int? severity,
    String? notes,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      createdAt: createdAt ?? this.createdAt,
      feeling: feeling ?? this.feeling,
      tags: tags ?? this.tags,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'medicationId': medicationId,
        'createdAt': createdAt.toIso8601String(),
        'feeling': feeling.name,
        'tags': tags,
        'severity': severity,
        'notes': notes,
      };

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    final feelingName = map['feeling'] as String?;
    final feeling = JournalFeeling.values.firstWhere(
      (value) => value.name == feelingName,
      orElse: () => JournalFeeling.ok,
    );
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
      feeling: feeling,
      tags: tags,
      severity: severityRaw is num ? severityRaw.toInt() : null,
      notes: map['notes'] as String?,
    );
  }
}
