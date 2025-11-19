import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:patient_tracker/features/my_ai/my_ai_page.dart'
    as legacy_my_ai;
import 'package:patient_tracker/features/my_ai/widgets/ai_feature_card.dart';
import 'package:patient_tracker/features/voice_chat/voice_chat_page.dart';

import '../../helpers/voice_chat_test_stubs.dart';

void main() {
  testWidgets('Voice Chat AI card launches VoiceChatPage', (tester) async {
    final view = tester.view;
    view.physicalSize = const Size(1080, 1920);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: legacy_my_ai.MyAiPage.routeName,
        routes: {
          legacy_my_ai.MyAiPage.routeName: (_) => const legacy_my_ai.MyAiPage(),
          VoiceChatPage.routeName: (_) => VoiceChatPage(
                controllerBuilder: () => buildTestVoiceController(),
              ),
        },
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final voiceLabelFinder = find.text('Voice Chat AI');
    await tester.scrollUntilVisible(
      voiceLabelFinder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final voiceCardFinder =
        find.ancestor(of: voiceLabelFinder, matching: find.byType(AiFeatureCard))
            .first;
    await tester.tap(voiceCardFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(VoiceChatPage), findsOneWidget);
  });
}
