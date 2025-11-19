import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:patient_tracker/features/voice_chat/controller/voice_chat_controller.dart';
import 'package:patient_tracker/features/voice_chat/models/voice_chat_models.dart';
import 'package:patient_tracker/features/voice_chat/services/voice_ai_service.dart';

VoiceChatController buildTestVoiceController({
  List<String> replyTokens = const ['Hello there!'],
}) {
  return VoiceChatController(
    service: TestVoiceAiService(replyTokens),
    flutterTts: StubFlutterTts(),
  );
}

class TestVoiceAiService extends VoiceAiService {
  TestVoiceAiService(this.tokens);

  final List<String> tokens;

  @override
  Future<Stream<String>> chatStream(
    List<VoiceMessage> history,
    String userText,
  ) async {
    final controller = StreamController<String>();
    Future<void>.microtask(() async {
      for (final token in tokens) {
        controller.add(token);
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
      await controller.close();
    });
    return controller.stream;
  }
}

class StubFlutterTts extends FlutterTts {
  VoidCallback? _completion;

  @override
  Future<dynamic> setLanguage(String language) async {}

  @override
  Future<dynamic> stop() async {}

  @override
  Future<dynamic> speak(String text) async {
    _completion?.call();
  }

  @override
  void setCompletionHandler(VoidCallback callback) {
    _completion = callback;
  }

  @override
  void setErrorHandler(ErrorHandler handler) {}
}
