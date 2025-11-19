import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:patient_tracker/features/voice_chat/controller/voice_chat_controller.dart';
import 'package:patient_tracker/features/voice_chat/voice_chat_page.dart';
import '../../helpers/voice_chat_test_stubs.dart';

void main() {
  group('VoiceChatPage', () {
    late VoiceChatController controller;

    testWidgets('manual send streams AI reply bubbles', (tester) async {
      controller = buildTestVoiceController();
      await tester.pumpWidget(
        MaterialApp(
          home: VoiceChatPage(
            controllerBuilder: () => controller,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Hi AI');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Hi AI'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('Hello there!'), findsOneWidget);
    });

    testWidgets('mute toggle updates controller state', (tester) async {
      controller = buildTestVoiceController();
      await tester.pumpWidget(
        MaterialApp(
          home: VoiceChatPage(
            controllerBuilder: () => controller,
          ),
        ),
      );

      expect(controller.ttsEnabled, isTrue);
      final muteButton = find.byTooltip('Mute TTS');
      await tester.tap(muteButton);
      await tester.pump();
      expect(controller.ttsEnabled, isFalse);
      expect(find.byIcon(Icons.volume_off), findsOneWidget);
    });
  });
}
