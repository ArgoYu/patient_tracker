import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/ai_widget.dart';
import '../../../data/storage/ai_layout_storage.dart';

typedef LayoutUpdateListener = void Function(AiLayoutState state);

class AiDashboardController extends ChangeNotifier {
  AiDashboardController({required AiLayoutStorage storage})
      : _storage = storage,
        _layout = AiLayoutState.defaults();

  final AiLayoutStorage _storage;

  final Uuid _uuid = const Uuid();

  AiLayoutState _layout;
  bool _isEditing = false;
  bool _loading = true;
  Timer? _saveDebounce;

  AiLayoutState get layout => _layout;
  bool get isEditing => _isEditing;
  bool get isLoading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final loaded = await _storage.load();
      _layout = _normalizeLayout(loaded);
    } catch (_) {
      _layout = _normalizeLayout(AiLayoutState.defaults());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> persist() async {
    _saveDebounce?.cancel();
    _saveDebounce = null;
    await _storage.save(_layout);
  }

  void enterEditMode() {
    if (_isEditing) return;
    _isEditing = true;
    notifyListeners();
  }

  Future<void> exitEditMode({bool persistChanges = true}) async {
    if (!_isEditing) return;
    _isEditing = false;
    notifyListeners();
    if (persistChanges) {
      await persist();
    } else {
      final original = await _storage.load();
      _layout = _normalizeLayout(original);
      notifyListeners();
    }
  }

  void toggleEditing() {
    _isEditing ? exitEditMode() : enterEditMode();
  }

  void resetToDefaults() {
    _layout = _normalizeLayout(AiLayoutState.defaults());
    notifyListeners();
    _markDirty();
  }

  void updateColumns(int columns) {
    if (columns == _layout.columns) return;
    final clamped = max(2, min(columns, 3));
    final normalized = _normalizeLayout(_layout.copyWith(columns: clamped),
        columnsOverride: clamped);
    _layout = normalized;
    notifyListeners();
    _markDirty();
  }

  void placeWidget(String id, int targetRow, int targetCol) {
    final index = _layout.items.indexWhere((element) => element.id == id);
    if (index == -1) return;
    final item = _layout.items[index];
    final width = min(item.size.widthUnits, _layout.columns);
    final maxCol = _layout.columns - width;
    final newCol = targetCol.clamp(0, maxCol);
    final newRow = max(0, targetRow);

    final updatedItem = item.copyWith(row: newRow, col: newCol);
    final newItems = [..._layout.items]..removeAt(index);
    newItems.add(updatedItem);
    _layout = _normalizeLayout(_layout.copyWith(items: newItems));
    notifyListeners();
    _markDirty();
  }

  void cycleSize(String id) {
    final index = _layout.items.indexWhere((element) => element.id == id);
    if (index == -1) return;
    final current = _layout.items[index];
    final nextSize = current.size.next();
    final updated = current.copyWith(size: nextSize);
    final newItems = [..._layout.items]..removeAt(index);
    newItems.add(updated);
    _layout = _normalizeLayout(_layout.copyWith(items: newItems));
    notifyListeners();
    _markDirty();
  }

  void removeWidget(String id) {
    _layout = _normalizeLayout(
      _layout.copyWith(
        items: _layout.items.where((element) => element.id != id).toList(),
      ),
    );
    notifyListeners();
    _markDirty();
  }

  void addWidget(AiWidgetType type,
      {AiWidgetSize? preferredSize, Map<String, dynamic>? settings}) {
    final instance = AiWidgetInstance(
      id: _uuid.v4(),
      type: type,
      size: preferredSize ?? _defaultSizeFor(type),
      row: 0,
      col: 0,
      settings: settings ?? _defaultSettingsFor(type),
    );
    final newItems = [..._layout.items, instance];
    _layout = _normalizeLayout(_layout.copyWith(items: newItems));
    notifyListeners();
    _markDirty();
  }

  AiWidgetSize _defaultSizeFor(AiWidgetType type) {
    switch (type) {
      case AiWidgetType.quickPrompts:
      case AiWidgetType.dailyBrief:
        return AiWidgetSize.large;
      case AiWidgetType.pinnedChats:
        return AiWidgetSize.medium;
      case AiWidgetType.trends:
        return AiWidgetSize.small;
    }
  }

  Map<String, dynamic> _defaultSettingsFor(AiWidgetType type) {
    switch (type) {
      case AiWidgetType.quickPrompts:
        return {
          'title': 'Quick Prompts',
          'prompts': [
            {'label': 'Check in', 'target': 'doctor'},
            {'label': 'Need support', 'target': 'nurse'},
            {'label': 'Ask a peer', 'target': 'peer'},
            {'label': 'Group share', 'target': 'group'},
            {'label': 'Medication help', 'target': 'doctor'},
            {'label': 'Positive note', 'target': 'peer'},
          ],
        };
      case AiWidgetType.dailyBrief:
        return {
          'title': 'Daily Brief',
          'entries': [
            {
              'icon': 'schedule',
              'text': 'Therapy at 3:00 PM',
              'target': 'doctor'
            },
            {
              'icon': 'pill',
              'text': 'Evening meds due in 2h',
              'target': 'nurse'
            },
            {'icon': 'mood', 'text': 'Mood is steady · 4/5', 'target': 'peer'},
            {
              'icon': 'sleep',
              'text': 'Slept 7h 20m last night',
              'target': 'nurse'
            },
            {'icon': 'steps', 'text': '4,200 steps so far', 'target': 'group'},
            {
              'icon': 'hydration',
              'text': '5 of 8 cups recorded',
              'target': 'group'
            },
          ],
        };
      case AiWidgetType.pinnedChats:
        return {
          'title': 'Pinned Chats',
          'items': [
            {
              'name': 'Dr. Chen',
              'role': 'Care team · doctor',
              'target': 'doctor'
            },
            {'name': 'Coach Riley', 'role': 'Peer mentor', 'target': 'peer'},
            {'name': 'Nurse Lee', 'role': 'Care nurse', 'target': 'nurse'},
          ],
        };
      case AiWidgetType.trends:
        return {
          'title': 'Trends Snapshot',
          'metrics': [
            {'label': 'Mood', 'value': '↑ 12%', 'target': 'doctor'},
            {'label': 'Sleep', 'value': '7.2h', 'target': 'nurse'},
            {'label': 'Steps', 'value': '5.8k', 'target': 'peer'},
            {'label': 'Hydration', 'value': '6/8', 'target': 'group'},
          ],
        };
    }
  }

  AiLayoutState _normalizeLayout(AiLayoutState state, {int? columnsOverride}) {
    final requested = columnsOverride ?? state.columns;
    final targetColumns = max(2, min(requested, 3));
    final ordered = [...state.items]..sort((a, b) {
        if (a.row == b.row) {
          return a.col.compareTo(b.col);
        }
        return a.row.compareTo(b.row);
      });

    final placed = <AiWidgetInstance>[];
    for (final item in ordered) {
      final sanitized = item.copyWith(
        row: max(item.row, 0),
        col: max(item.col, 0),
      );
      final fitted = _fitWithinGrid(sanitized, placed, targetColumns);
      placed.add(fitted);
    }

    return state.copyWith(columns: targetColumns, items: placed);
  }

  AiWidgetInstance _fitWithinGrid(
    AiWidgetInstance candidate,
    List<AiWidgetInstance> others,
    int columns,
  ) {
    final width = min(candidate.size.widthUnits, columns);
    int row = max(candidate.row, 0);
    int col = min(candidate.col, columns - width);

    bool conflicts() {
      for (final other in others) {
        final otherWidth = min(other.size.widthUnits, columns);
        final overlapX =
            col < other.col + otherWidth && col + width > other.col;
        final overlapY = row < other.row + other.size.heightUnits &&
            row + candidate.size.heightUnits > other.row;
        if (overlapX && overlapY) return true;
      }
      return false;
    }

    while (conflicts()) {
      col += width;
      if (col + width > columns) {
        col = 0;
        row += candidate.size.heightUnits;
      }
    }

    return candidate.copyWith(row: row, col: col);
  }

  void _markDirty() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(_storage.save(_layout));
      _saveDebounce = null;
    });
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }
}
