import 'package:flutter_test/flutter_test.dart';

import 'package:patient_tracker/data/models/journal_entry.dart';

void main() {
  test('JournalEntry round-trips with severity and notes', () {
    final entry = JournalEntry(
      id: 'id-1',
      medicationId: 'Sertraline',
      createdAt: DateTime(2025, 1, 15, 9, 30),
      feeling: JournalFeeling.notGreat,
      tags: const ['nausea', 'headache'],
      severity: 7,
      notes: 'Felt dizzy after breakfast.',
    );

    final decoded = JournalEntry.fromMap(entry.toMap());

    expect(decoded.id, entry.id);
    expect(decoded.medicationId, entry.medicationId);
    expect(decoded.createdAt, entry.createdAt);
    expect(decoded.feeling, entry.feeling);
    expect(decoded.tags, entry.tags);
    expect(decoded.severity, entry.severity);
    expect(decoded.notes, entry.notes);
  });

  test('JournalEntry supports optional severity and notes', () {
    final entry = JournalEntry(
      id: 'id-2',
      medicationId: 'Quetiapine',
      createdAt: DateTime(2025, 1, 16, 20, 0),
      feeling: JournalFeeling.ok,
      tags: const [],
    );

    final decoded = JournalEntry.fromMap(entry.toMap());

    expect(decoded.severity, isNull);
    expect(decoded.notes, isNull);
  });
}
