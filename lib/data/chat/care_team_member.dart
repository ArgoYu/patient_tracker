import 'dart:convert';

import 'conversation_type.dart';

class CareTeamMember {
  const CareTeamMember({
    required this.type,
    required this.name,
    required this.role,
  });

  final ConversationType type;
  final String name;
  final String role;

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'name': name,
      'role': role,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory CareTeamMember.fromMap(Map<String, dynamic> map) {
    final type = conversationTypeFromString(map['type'] as String?) ??
        ConversationType.coach;
    final name = (map['name'] as String?)?.trim() ?? '';
    final role = (map['role'] as String?)?.trim() ?? '';
    return CareTeamMember(
      type: type,
      name: name,
      role: role,
    );
  }

  factory CareTeamMember.fromJson(String source) {
    final map = jsonDecode(source);
    if (map is! Map<String, dynamic>) {
      throw const FormatException('Invalid CareTeamMember JSON');
    }
    return CareTeamMember.fromMap(map);
  }
}

const List<CareTeamMember> demoCareTeamMembers = [
  CareTeamMember(
    type: ConversationType.coach,
    name: 'my personal care AI',
    role: 'Care coach',
  ),
  CareTeamMember(
    type: ConversationType.peer,
    name: 'Peer supporter',
    role: 'Peer mentor',
  ),
  CareTeamMember(
    type: ConversationType.physician,
    name: 'Dr. Wang',
    role: 'Primary physician',
  ),
  CareTeamMember(
    type: ConversationType.nurse,
    name: 'Nurse Kim',
    role: 'Care nurse',
  ),
  CareTeamMember(
    type: ConversationType.group,
    name: 'Recovery circle',
    role: 'Support group',
  ),
];
