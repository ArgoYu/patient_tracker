// lib/features/interpret/services/interpret_services.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// STT event representing either a partial or final hypothesis.
class SttEvent {
  SttEvent(this.text, this.isFinal);
  final String text;
  final bool isFinal;
}

/// Contract for microphone streaming speech recognition.
abstract class SttService {
  Stream<SttEvent> startStream(
    String lang, {
    void Function(double level)? onInputLevel,
  });

  Future<void> stop();
}

/// Contract for realtime MT streaming.
abstract class MtService {
  Stream<String> translateStream(
    String text, {
    required String from,
    required String to,
  });
}

/// Contract for TTS playback.
abstract class TtsService {
  Future<void> speak(
    String text, {
    required String lang,
    double? rate,
    double? volume,
  });

  Future<void> stop();
}

/// Speech-to-text backed by the `speech_to_text` plugin.
class SpeechToTextSttService implements SttService {
  SpeechToTextSttService({SpeechToText? speechToText})
      : _speech = speechToText ?? SpeechToText();

  final SpeechToText _speech;
  StreamController<SttEvent>? _controller;

  @override
  Stream<SttEvent> startStream(
    String lang, {
    void Function(double level)? onInputLevel,
  }) {
    _controller?.close();
    final controller = StreamController<SttEvent>();
    _controller = controller;
    () async {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done') {
            controller.close();
          }
        },
        onError: (details) {
          if (!controller.isClosed) {
            controller.addError(details.errorMsg);
          }
        },
      );
      if (!available) {
        controller.addError(StateError('Speech recognition unavailable.'));
        await controller.close();
        return;
      }
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          if (!controller.isClosed) {
            controller
                .add(SttEvent(result.recognizedWords, result.finalResult));
          }
        },
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 6),
        localeId: lang,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
        onSoundLevelChange: onInputLevel,
      );
    }();
    return controller.stream;
  }

  @override
  Future<void> stop() async {
    await _speech.stop();
    await _controller?.close();
    _controller = null;
  }
}

/// Simple mock MT that streams pseudo tokens for UX demoing.
class MockMtService implements MtService {
  const MockMtService();

  static const Map<String, String> _sampleLexicon = {
    'hello': '你好',
    'patient': '病人',
    'take': '服用',
    'medication': '药物',
    'stay': '保持',
    'hydrated': '水分充足',
    'please': '请',
    'thank': '谢谢',
    'follow': '遵循',
    'up': '后续',
    'tomorrow': '明天',
  };

  @override
  Stream<String> translateStream(
    String text, {
    required String from,
    required String to,
  }) {
    final controller = StreamController<String>();
    final words = text.split(RegExp(r'(\s+)'));
    var index = 0;
    Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (index >= words.length) {
        timer.cancel();
        controller.close();
        return;
      }
      final token = words[index];
      if (token.trim().isEmpty) {
        controller.add(token);
      } else {
        final translated = _sampleLexicon[token.toLowerCase()] ?? '$token($to)';
        controller.add('$translated ');
      }
      index++;
    });
    return controller.stream;
  }
}

/// Flutter TTS wrapper that takes care of rate/volume adjustments.
class FlutterTtsService implements TtsService {
  FlutterTtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  @override
  Future<void> speak(
    String text, {
    required String lang,
    double? rate,
    double? volume,
  }) async {
    await _tts.stop();
    await _tts.setLanguage(lang);
    if (rate != null) {
      await _tts.setSpeechRate(rate);
    }
    if (volume != null) {
      await _tts.setVolume(volume);
    }
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}

/// Deterministic script-driven STT for demo mode or offline QA.
class DemoSttService implements SttService {
  DemoSttService({List<String>? script}) : _script = script ?? _defaultScript;

  final List<String> _script;
  int _cursor = 0;

  static const List<String> _defaultScript = [
    'Good morning, we are starting the consultation now.',
    'Please describe how you have been feeling since the last visit.',
    'Remember to take your medication after breakfast and stay hydrated.',
  ];

  @override
  Stream<SttEvent> startStream(
    String lang, {
    void Function(double level)? onInputLevel,
  }) {
    final controller = StreamController<SttEvent>();
    final sentence = _script[_cursor % _script.length];
    _cursor++;
    final words = sentence.split(' ');
    var idx = 0;
    var partial = '';
    final rand = Random();
    Timer.periodic(const Duration(milliseconds: 320), (timer) {
      if (idx >= words.length) {
        timer.cancel();
        controller.add(SttEvent(partial.trim(), true));
        controller.close();
        return;
      }
      onInputLevel?.call(rand.nextDouble());
      partial = '$partial ${words[idx]}'.trim();
      final isFinal = idx == words.length - 1;
      controller.add(SttEvent(partial, isFinal));
      idx++;
    });
    return controller.stream;
  }

  @override
  Future<void> stop() async {}
}
