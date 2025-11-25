import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/user_account.dart';
import 'care_team_member.dart';

class CareTeamRepository {
  CareTeamRepository(this.accountListenable);

  final ValueListenable<UserAccount?> accountListenable;

  Future<List<CareTeamMember>> loadMembers() async {
    final account = accountListenable.value;
    if (account != null && account.isDemo) {
      return demoCareTeamMembers;
    }

    if (account == null) {
      return const <CareTeamMember>[];
    }

    return await _loadMembersFromStorage(account.id) ?? const <CareTeamMember>[];
  }

  Future<void> saveMembers(List<CareTeamMember> members) async {
    final account = accountListenable.value;
    if (account == null || account.isDemo) return;
    await _saveMembersToStorage(account.id, members);
  }

  Future<List<CareTeamMember>?> _loadMembersFromStorage(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_careTeamKeyFor(userId));
    if (json == null || json.isEmpty) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return null;
      final members = <CareTeamMember>[];
      for (final entry in decoded) {
        if (entry is Map<String, dynamic>) {
          members.add(CareTeamMember.fromMap(entry));
        }
      }
      return members;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveMembersToStorage(
    String userId,
    List<CareTeamMember> members,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      members.map((member) => member.toMap()).toList(),
    );
    await prefs.setString(_careTeamKeyFor(userId), encoded);
  }

  String _careTeamKeyFor(String userId) => 'care_team_$userId';
}
