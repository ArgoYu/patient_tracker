// lib/core/routing/app_routes.dart
import 'package:flutter/material.dart';

import '../../app_modules.dart'
    show MessagesPage, RootShell, ChatHomePage, MyAiPage;
import '../../features/onboarding/onboarding_page.dart';
import '../../features/voice_chat/voice_chat_page.dart';
import '../../features/interpret/view/interpret_page.dart';
import '../../features/ask_ai_doctor/chat_screen.dart';
import '../../features/timeline/timeline_page.dart';
import '../../features/auth/auth_gate_page.dart';
import '../../features/auth/biometric_opt_in_page.dart';
import '../../features/auth/two_factor_screen.dart';

/// Central place for route names and builders.
class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String onboarding = OnboardingPage.routeName;
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
  static const String postLogin = BiometricOptInScreen.routeName;

  static Map<String, WidgetBuilder> routes = {
    onboarding: (_) => const OnboardingPage(),
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
    ...MyAiPage.routes,
    twoFactor: (_) => const TwoFactorScreen(),
    postLogin: (_) => const BiometricOptInScreen(),
  };
}
