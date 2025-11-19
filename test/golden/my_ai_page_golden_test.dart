import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_tracker/app_modules.dart';
import 'package:patient_tracker/features/my_ai/controller/ai_co_consult_service.dart';

bool _shouldSkipGolden(String relativePath) {
  final file = File('test/$relativePath');
  final isDesktop = Platform.isMacOS || Platform.isLinux || Platform.isWindows;
  return !file.existsSync() || !isDesktop;
}

Future<void> _withConfiguredSurface(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final view = tester.view;
  final originalPhysicalSize = view.physicalSize;
  final originalPixelRatio = view.devicePixelRatio;

  view
    ..devicePixelRatio = 2.0
    ..physicalSize = const Size(1400, 2200);
  await tester.binding.setSurfaceSize(const Size(700, 1100));

  try {
    await body();
  } finally {
    view
      ..physicalSize = originalPhysicalSize
      ..devicePixelRatio = originalPixelRatio;
    await tester.binding.setSurfaceSize(
      Size(
        originalPhysicalSize.width / originalPixelRatio,
        originalPhysicalSize.height / originalPixelRatio,
      ),
    );
  }
}

Future<void> _pumpMyAiPage(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const MyAiPage(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('my_ai_page_default_golden', (tester) async {
    await _withConfiguredSurface(tester, () async {
      AiCoConsultCoordinator.instance.resetSessionState();

      await _pumpMyAiPage(tester);

      await expectLater(
        find.byType(MyAiPage),
        matchesGoldenFile('goldens/my_ai_page_default.png'),
        skip: _shouldSkipGolden('goldens/my_ai_page_default.png'),
      );
    });
  });
}
