// lib/core/routing/app_routes.dart
import 'package:flutter/material.dart';

import '../../app_modules.dart'
    show MessagesPage, RootShell, ChatHomePage, MyAiPage, MedicationHistoryPage;
import '../../features/onboarding/global_onboarding_screen.dart';
import '../../features/auth/auth_gate_page.dart';
import '../../features/auth/auth_service.dart';
import '../../features/voice_chat/voice_chat_page.dart';
import '../../features/interpret/view/interpret_page.dart';
import '../../features/ask_ai_doctor/chat_screen.dart';
import '../../features/timeline/timeline_page.dart';
import '../../features/auth/two_factor_screen.dart';
import '../../features/medications/medication_timeline_screen.dart';
import '../../data/models/rx_medication.dart';

/// Central place for route names and builders.
class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String globalOnboarding = GlobalOnboardingScreen.routeName;
  static const String auth = AuthGatePage.routeName;
  static const String trends = '/trends';
  static const String feelings = '/feelings';
  static const String profile = '/profile';
  static const String chat = '/chat';
  static const String myAi = '/my-ai';
  static const String chatHome = '/chatHome';
  static const String chatHomeDeepLink = '/chat/home';
  static const String voiceChat = VoiceChatPage.routeName;
  static const String interpret = InterpretPage.routeName;
  static const String askAiDoctorChat = AskAiDoctorChatScreen.routeName;
  static const String timelinePlanner = '/timeline-planner';
  static const String twoFactor = TwoFactorScreen.routeName;
  static const String medicationHistory = MedicationHistoryPage.routeName;
  static const String medicationTimeline = '/rx-timeline';

  static Map<String, WidgetBuilder> routes = {
    globalOnboarding: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final flowArgs = args is GlobalOnboardingFlowArguments
          ? args
          : const GlobalOnboardingFlowArguments();
      final userId = flowArgs.userId ?? AuthService.instance.currentUserId;
      if (userId == null) {
        return const AuthGatePage();
      }
      return GlobalOnboardingScreen(
        userId: userId,
        replay: flowArgs.replay,
        isNewlyRegistered: flowArgs.isNewlyRegistered,
      );
    },
    auth: (_) => const AuthGatePage(),
    home: (_) => const RootShell(),
    trends: (_) => const RootShell(initialIndex: 0),
    feelings: (_) => const RootShell(initialIndex: 0),
    profile: (_) => const RootShell(initialIndex: 0),
    chat: (_) => const MessagesPage(),
    myAi: (_) => const RootShell(initialIndex: 2),
    chatHome: (_) => const ChatHomePage(),
    chatHomeDeepLink: (_) => const ChatHomePage(),
    voiceChat: (_) => const VoiceChatPage(),
    interpret: (_) => const InterpretPage(),
    askAiDoctorChat: (_) => const AskAiDoctorChatScreen(),
    timelinePlanner: (_) => const TimelinePlannerPage(),
    medicationHistory: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is RxMedication) {
        return MedicationHistoryPage(medication: args);
      }
      return const RootShell();
    },
    medicationTimeline: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is MedicationTimelineArgs) {
        return MedicationTimelineScreen(
          medicationId: args.medicationId,
          medicationDisplayName: args.medicationDisplayName,
          checkIns: args.checkIns,
        );
      }
      return const MedicationTimelineScreen(medicationId: 'unknown');
    },
    ...MyAiPage.routes,
    twoFactor: (_) => const TwoFactorScreen(),
  };
}
