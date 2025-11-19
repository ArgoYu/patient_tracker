import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

Future<void> testExecutable(Future<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final tempDir = await Directory.systemTemp.createTemp('patient_tracker_hive');
  Hive.init(tempDir.path);
  await testMain();
  await Hive.close();
  if (tempDir.existsSync()) {
    await tempDir.delete(recursive: true);
  }
}
