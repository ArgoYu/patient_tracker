import 'dart:convert';

/// Serialized representation of a personal chat that can be persisted per user.
class SavedPersonalChat {
  const SavedPersonalChat({
    required this.type,
    required this.handle,
    this.displayName,
    this.subtitle,
  });

  final String type;
  final String handle;
  final String? displayName;
  final String? subtitle;

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'handle': handle,
      'displayName': displayName,
      'subtitle': subtitle,
    };
  }

  factory SavedPersonalChat.fromMap(Map<String, dynamic> map) {
    return SavedPersonalChat(
      type: (map['type'] as String?)?.trim() ?? 'custom',
      handle: (map['handle'] as String?)?.trim() ?? '',
      displayName: (map['displayName'] as String?)?.trim(),
      subtitle: (map['subtitle'] as String?)?.trim(),
    );
  }
}

class ChatThreads {
  const ChatThreads({
    this.personalChats = const [],
    this.groupIds = const [],
  });

  const ChatThreads.empty()
      : personalChats = const [],
        groupIds = const [];

  final List<SavedPersonalChat> personalChats;
  final List<String> groupIds;

  ChatThreads copyWith({
    List<SavedPersonalChat>? personalChats,
    List<String>? groupIds,
  }) {
    return ChatThreads(
      personalChats: personalChats ?? this.personalChats,
      groupIds: groupIds ?? this.groupIds,
    );
  }

  bool get isEmpty => personalChats.isEmpty && groupIds.isEmpty;

  Map<String, dynamic> toMap() {
    return {
      'personalChats': personalChats.map((chat) => chat.toMap()).toList(),
      'groupIds': groupIds,
    };
  }

  factory ChatThreads.fromMap(Map<String, dynamic> map) {
    final personal = map['personalChats'];
    final groups = map['groupIds'];
    final personalChats = <SavedPersonalChat>[];
    if (personal is List) {
      for (final item in personal) {
        if (item is Map<String, dynamic>) {
          personalChats.add(SavedPersonalChat.fromMap(item));
        }
      }
    }

    final groupIds = <String>[];
    if (groups is List) {
      for (final value in groups) {
        if (value is String && value.isNotEmpty) {
          groupIds.add(value);
        }
      }
    }

    return ChatThreads(
      personalChats: personalChats,
      groupIds: groupIds,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ChatThreads.fromJson(String source) {
    final map = jsonDecode(source);
    if (map is! Map<String, dynamic>) {
      throw const FormatException('Invalid ChatThreads JSON');
    }
    return ChatThreads.fromMap(map);
  }
}
