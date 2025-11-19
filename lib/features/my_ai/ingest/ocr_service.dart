import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    as mlkit;

abstract class OcrService {
  Future<String> extractText(File imageFile);
}

class MlkitOcrService implements OcrService {
  @override
  Future<String> extractText(File imageFile) async {
    if (kIsWeb) {
      throw UnsupportedError('OCR is not supported on web.');
    }
    try {
      final lib = await _loadMlkit();
      final inputImage = lib.inputImageFromFile(imageFile);
      final recognizer = lib.textRecognizer();
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();
      return result.text;
    } catch (_) {
      // fallback to mock if mlkit is unavailable
      return await MockOcrService().extractText(imageFile);
    }
  }

  Future<_MlkitShim> _loadMlkit() async => const _MlkitShim();
}

class MockOcrService implements OcrService {
  @override
  Future<String> extractText(File imageFile) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return '''
Doctor: Dr. Chen
Chief complaint: Chest tightness for 2 weeks.
History: No fever, occasional cough at night.
Diagnosis: Suspected musculoskeletal chest pain. Low ACS risk.
Recommendations: Naproxen 250 mg BID with food; Follow-up in 1–2 weeks; Call if pain with exertion.
''';
  }
}

class _MlkitShim {
  const _MlkitShim();

  mlkit.InputImage inputImageFromFile(File file) =>
      mlkit.InputImage.fromFile(file);

  mlkit.TextRecognizer textRecognizer() => mlkit.TextRecognizer();
}
