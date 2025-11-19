import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_widget.dart';

class AiLayoutStorage {
  static const String _kHiveBox = 'ai_layout_box';
  static const String _kHiveKey = 'layout_json';
  static const String _kLegacyPrefsKey = 'ai_layout_state_v1';

  const AiLayoutStorage();

  Future<Box<String>> _openBox() async {
    if (Hive.isBoxOpen(_kHiveBox)) {
      return Hive.box<String>(_kHiveBox);
    }
    return Hive.openBox<String>(_kHiveBox);
  }

  Future<AiLayoutState> load() async {
    final box = await _openBox();
    final stored = box.get(_kHiveKey);
    if (stored != null) {
      try {
        final raw = json.decode(stored);
        if (raw is Map<String, dynamic>) {
          return AiLayoutState.fromJson(raw);
        }
      } catch (_) {
        await box.delete(_kHiveKey);
      }
    }

    // Legacy migration from shared_preferences if present.
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_kLegacyPrefsKey);
    if (legacy != null) {
      try {
        final raw = json.decode(legacy);
        if (raw is Map<String, dynamic>) {
          final decoded = AiLayoutState.fromJson(raw);
          await box.put(_kHiveKey, json.encode(decoded.toJson()));
          await prefs.remove(_kLegacyPrefsKey);
          return decoded;
        }
      } catch (_) {
        await prefs.remove(_kLegacyPrefsKey);
      }
    }

    final defaultState = AiLayoutState.defaults();
    await box.put(_kHiveKey, json.encode(defaultState.toJson()));
    return defaultState;
  }

  Future<void> save(AiLayoutState state) async {
    final box = await _openBox();
    await box.put(_kHiveKey, json.encode(state.toJson()));
  }

  Future<void> clear() async {
    final box = await _openBox();
    await box.delete(_kHiveKey);
  }
}
