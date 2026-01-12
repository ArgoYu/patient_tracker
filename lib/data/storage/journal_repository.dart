// lib/data/storage/journal_repository.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/journal_entry.dart';

class JournalRepository {
  static String _keyFor(String accountId) => 'journal_entries_$accountId';

  Future<List<JournalEntry>> loadEntries(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(accountId));
    if (raw == null || raw.isEmpty) return <JournalEntry>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <JournalEntry>[];
      return decoded
          .whereType<Map>()
          .map((item) => JournalEntry.fromMap(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false);
    } catch (_) {
      return <JournalEntry>[];
    }
  }

  Future<void> saveEntries(String accountId, List<JournalEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      entries.map((entry) => entry.toMap()).toList(growable: false),
    );
    await prefs.setString(_keyFor(accountId), encoded);
  }
}
