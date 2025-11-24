// lib/main.dart
import 'dart:io' show Platform;

import 'dart:ui' as ui show KeyData, KeyEventType;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/routing/app_routes.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/auth/auth_service.dart';
import 'features/voice_chat/services/voice_ai_http_service.dart';
import 'features/voice_chat/services/voice_ai_service.dart';
import 'features/voice_chat/services/voice_ai_service_registry.dart';
import 'features/voice_chat/services/voice_chat_config.dart';
import 'shared/prefs_keys.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installStrayKeyGuard();
  _configureVoiceChatService();

  await Hive.initFlutter();
  final sp = await SharedPreferences.getInstance();
  final done = sp.getBool(PrefsKeys.onboardingCompleted) ?? false;
  final version = sp.getInt(PrefsKeys.onboardingVersion) ?? 0;
  final needOnboarding = !done || version < kOnboardingVersion;
  final remembered = await AuthService.instance.tryAutoLogin();
  final initialRoute = needOnboarding
      ? AppRoutes.onboarding
      : (remembered ? AppRoutes.home : AppRoutes.auth);
  runApp(AppRoot(initialRoute: initialRoute));
}

void _configureVoiceChatService() {
  final endpoint = VoiceChatConfig.endpoint;
  if (endpoint != null) {
    final headers = <String, String>{
      if (VoiceChatConfig.apiKey != null)
        'Authorization': 'Bearer ${VoiceChatConfig.apiKey}',
    };
    VoiceAiServiceRegistry.instance.register(
      HttpVoiceAiService(
        endpoint: endpoint,
        headers: headers.isEmpty ? null : headers,
      ),
    );
  } else {
    VoiceAiServiceRegistry.instance.register(const MockVoiceAiService());
  }
}

void _installStrayKeyGuard() {
  final dispatcher =
      WidgetsFlutterBinding.ensureInitialized().platformDispatcher;
  final originalOnKeyData = dispatcher.onKeyData;
  dispatcher.onKeyData = (ui.KeyData data) {
    if (_shouldSwallowKeyData(data)) {
      return true;
    }
    if (originalOnKeyData != null) {
      return originalOnKeyData(data);
    }
    return false;
  };
}

bool _shouldSwallowKeyData(ui.KeyData data) {
  if (data.type != ui.KeyEventType.up) {
    return false;
  }
  final physicalKey = PhysicalKeyboardKey(data.physical);
  final bool isPressed =
      HardwareKeyboard.instance.isPhysicalKeyPressed(physicalKey);
  final bool isCapsLockOnMac =
      Platform.isMacOS && data.logical == LogicalKeyboardKey.capsLock.keyId;
  return !isPressed || isCapsLockOnMac;
}
