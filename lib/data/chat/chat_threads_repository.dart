import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/user_account.dart';
import 'chat_threads.dart';

class ChatThreadsRepository {
  ChatThreadsRepository(this.accountListenable);

  static const List<String> _demoGroupIds = [
    'anxiety',
    'pain',
    'sleep',
  ];

  static const List<SavedPersonalChat> _demoPersonalChats = [
    SavedPersonalChat(
      type: 'aiCoach',
      handle: 'personal_care_ai',
      displayName: 'My Personal Care AI',
      subtitle: 'Ask your AI coach for next steps anytime.',
    ),
    SavedPersonalChat(
      type: 'maya',
      handle: 'maya.chen',
      displayName: 'Maya Chen',
      subtitle: 'Catch up on your daily reflection.',
    ),
    SavedPersonalChat(
      type: 'alex',
      handle: 'alex.rivera',
      displayName: 'Alex Rivera',
      subtitle: 'Shared a new playlist for your wind-down.',
    ),
    SavedPersonalChat(
      type: 'doctor',
      handle: 'dr.chen',
      displayName: 'Dr. Chen (Psychiatry)',
      subtitle: 'Telehealth follow-up · medication review.',
    ),
  ];

  static final ChatThreads _demoChatThreads = ChatThreads(
    personalChats: _demoPersonalChats,
    groupIds: _demoGroupIds,
  );

  final ValueListenable<UserAccount?> accountListenable;

  Future<ChatThreads> loadThreads() async {
    final account = accountListenable.value;
    if (account != null && account.isDemo) {
      return _demoChatThreads;
    }

    if (account == null) {
      return const ChatThreads.empty();
    }

    return await _loadThreadsFromStorage(account.id) ?? const ChatThreads.empty();
  }

  Future<void> saveThreads(ChatThreads threads) async {
    final account = accountListenable.value;
    if (account == null || account.isDemo) return;
    await _saveThreadsToStorage(account.id, threads);
  }

  Future<ChatThreads?> _loadThreadsFromStorage(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_threadsKeyFor(userId));
    if (json == null || json.isEmpty) return null;
    try {
      return ChatThreads.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveThreadsToStorage(String userId, ChatThreads threads) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_threadsKeyFor(userId), threads.toJson());
  }

  String _threadsKeyFor(String userId) => 'chat_threads_$userId';
}
