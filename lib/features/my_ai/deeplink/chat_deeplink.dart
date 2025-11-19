import 'package:flutter/material.dart';

import 'package:patient_tracker/direct_chat_page.dart';

class ChatDeeplink {
  static const PersonalChatContact _personalCareAiContact = PersonalChatContact(
    contactId: 'personal_care_ai',
    type: PersonalChatType.aiCoach,
    name: 'My Personal Care AI',
    subtitle: 'Ask your AI coach for next steps anytime.',
    icon: Icons.support_agent_outlined,
    color: Color(0xFF2563EB),
  );

  /// Navigate to Chat home and focus the target conversation by id or title.
  static Future<void> focusThread({
    required BuildContext context,
    String? threadId,
    String? threadTitle, // e.g. "My Personal Care AI"
    String? flashColorHex, // optional highlight color
  }) async {
    final args = {
      'focusThreadId': threadId,
      'focusThreadTitle': threadTitle,
      'flashColor': flashColorHex ?? '#E6F0FF', // subtle blue
      'autoOpenIfDetailRouteExists': true,
    };

    // Preferred: your real chat home route
    const routeName = '/chat/home';

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    try {
      await rootNavigator.pushNamed(routeName, arguments: args);
      return;
    } catch (_) {
      // Fallback: shim page so the tap is never dead
      await rootNavigator.push(MaterialPageRoute(
        builder: (_) => const _ChatShimInfo(),
      ));
    }
  }

  static Future<void> openPersonalCareAi(
    BuildContext context, {
    String? seed, // optional: message to prefill in the composer
  }) async {
    final preparedSeed = seed?.trim();
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => DirectChatPage(
          contact: _personalCareAiContact,
          initialComposerText: preparedSeed?.isEmpty ?? true ? null : preparedSeed,
        ),
      ),
    );
  }
}

class _ChatShimInfo extends StatelessWidget {
  const _ChatShimInfo();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: const Center(
        child: Text('Chat route not wired yet.\n(Deeplink shim)'),
      ),
    );
  }
}
