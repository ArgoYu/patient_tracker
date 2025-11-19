import 'dart:math';

enum AiWidgetType { quickPrompts, dailyBrief, pinnedChats, trends }

enum AiWidgetSize { small, medium, large }

extension AiWidgetSizeExt on AiWidgetSize {
  int get widthUnits => switch (this) {
        AiWidgetSize.small => 1,
        AiWidgetSize.medium => 2,
        AiWidgetSize.large => 3,
      };

  int get heightUnits => switch (this) {
        AiWidgetSize.small => 1,
        AiWidgetSize.medium => 1,
        AiWidgetSize.large => 2,
      };

  AiWidgetSize next() =>
      AiWidgetSize.values[(index + 1) % AiWidgetSize.values.length];
}

class AiWidgetInstance {
  const AiWidgetInstance({
    required this.id,
    required this.type,
    required this.size,
    required this.row,
    required this.col,
    required this.settings,
    this.schemaVersion = 1,
  });

  final String id;
  final AiWidgetType type;
  final AiWidgetSize size;
  final int row;
  final int col;
  final Map<String, dynamic> settings;
  final int schemaVersion;

  AiWidgetInstance copyWith({
    AiWidgetType? type,
    AiWidgetSize? size,
    int? row,
    int? col,
    Map<String, dynamic>? settings,
    int? schemaVersion,
  }) {
    return AiWidgetInstance(
      id: id,
      type: type ?? this.type,
      size: size ?? this.size,
      row: row ?? this.row,
      col: col ?? this.col,
      settings: settings ?? this.settings,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'size': size.name,
      'row': row,
      'col': col,
      'settings': settings,
      'schemaVersion': schemaVersion,
    };
  }

  factory AiWidgetInstance.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;
    final sizeName = json['size'] as String?;
    return AiWidgetInstance(
      id: json['id'] as String,
      type: AiWidgetType.values.firstWhere(
        (v) => v.name == typeName,
        orElse: () => AiWidgetType.quickPrompts,
      ),
      size: AiWidgetSize.values.firstWhere(
        (v) => v.name == sizeName,
        orElse: () => AiWidgetSize.small,
      ),
      row: (json['row'] as num).toInt(),
      col: (json['col'] as num).toInt(),
      settings: Map<String, dynamic>.from(json['settings'] as Map? ?? const {}),
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
    );
  }
}

class AiLayoutState {
  const AiLayoutState({
    required this.schemaVersion,
    required this.columns,
    required this.items,
  });

  final int schemaVersion;
  final int columns;
  final List<AiWidgetInstance> items;

  int get rowCount {
    if (items.isEmpty) return 0;
    return items
            .map((item) => item.row + item.size.heightUnits)
            .reduce((value, element) => max(value, element)) +
        2;
  }

  AiLayoutState copyWith({
    int? schemaVersion,
    int? columns,
    List<AiWidgetInstance>? items,
  }) {
    return AiLayoutState(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      columns: columns ?? this.columns,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'columns': columns,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory AiLayoutState.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    return AiLayoutState(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      columns: (json['columns'] as num?)?.toInt() ?? 3,
      items: itemsJson
          .map((e) =>
              AiWidgetInstance.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  static AiLayoutState defaults() {
    return const AiLayoutState(
      schemaVersion: 3,
      columns: 3,
      items: [
        AiWidgetInstance(
          id: 'quick-prompts',
          type: AiWidgetType.quickPrompts,
          size: AiWidgetSize.large,
          row: 0,
          col: 0,
          settings: {
            'title': 'Quick Prompts',
            'prompts': [
              {'label': 'Check in', 'target': 'doctor'},
              {'label': 'Need support', 'target': 'nurse'},
              {'label': 'Ask a peer', 'target': 'peer'},
              {'label': 'Group share', 'target': 'group'},
              {'label': 'Medication help', 'target': 'doctor'},
              {'label': 'Positive note', 'target': 'peer'},
            ],
          },
        ),
        AiWidgetInstance(
          id: 'daily-brief',
          type: AiWidgetType.dailyBrief,
          size: AiWidgetSize.large,
          row: 2,
          col: 0,
          settings: {
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
              {
                'icon': 'mood',
                'text': 'Mood is steady · 4/5',
                'target': 'peer'
              },
              {
                'icon': 'sleep',
                'text': 'Slept 7h 20m last night',
                'target': 'nurse'
              },
              {
                'icon': 'steps',
                'text': '4,200 steps so far',
                'target': 'group'
              },
              {
                'icon': 'hydration',
                'text': '5 of 8 cups recorded',
                'target': 'group'
              },
            ],
          },
        ),
        AiWidgetInstance(
          id: 'pinned-chats',
          type: AiWidgetType.pinnedChats,
          size: AiWidgetSize.medium,
          row: 4,
          col: 0,
          settings: {
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
          },
        ),
        AiWidgetInstance(
          id: 'trends-snapshot',
          type: AiWidgetType.trends,
          size: AiWidgetSize.small,
          row: 4,
          col: 2,
          settings: {
            'title': 'Trends Snapshot',
            'metrics': [
              {'label': 'Mood', 'value': '↑ 12%', 'target': 'doctor'},
              {'label': 'Sleep', 'value': '7.2h', 'target': 'nurse'},
              {'label': 'Steps', 'value': '5.8k', 'target': 'peer'},
              {'label': 'Hydration', 'value': '6/8', 'target': 'group'},
            ],
          },
        ),
      ],
    );
  }
}
