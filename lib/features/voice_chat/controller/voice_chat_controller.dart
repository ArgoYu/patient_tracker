import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/voice_chat_models.dart';
import '../services/voice_ai_service.dart';

/// Mediates between the microphone, STT, mock backend, and UI.
class VoiceChatController extends ChangeNotifier {
  VoiceChatController({
    required VoiceAiService service,
    SpeechToText? speechToText,
    FlutterTts? flutterTts,
    Record? recorder,
    AudioPlayer? earconPlayer,
  })  : _service = service,
        _speechToText = speechToText ?? SpeechToText(),
        _tts = flutterTts ?? FlutterTts(),
        _recorder = recorder ?? Record(),
        _earconPlayer = earconPlayer ?? AudioPlayer() {
    _setupTtsHandlers();
  }

  final VoiceAiService _service;
  final SpeechToText _speechToText;
  final FlutterTts _tts;
  final Record _recorder;
  final AudioPlayer _earconPlayer;

  final List<ChatTurn> _turns = <ChatTurn>[];
  VoiceState _state = VoiceState.idle;
  bool _ttsEnabled = true;
  bool _micGranted = false;
  bool _micPermanentlyDenied = false;
  bool _isRequesting = false;
  String _partialTranscript = '';
  String? _error;
  double _inputLevel = 0;

  StreamSubscription<String>? _aiSubscription;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _silenceTimer;

  static const Duration _silenceTimeout = Duration(seconds: 2);

  List<ChatTurn> get turns => List.unmodifiable(_turns);
  VoiceState get state => _state;
  bool get ttsEnabled => _ttsEnabled;
  bool get isBusy =>
      _state == VoiceState.holding || _state == VoiceState.processing;
  bool get micGranted => _micGranted;
  bool get micPermanentlyDenied => _micPermanentlyDenied;
  String get partialTranscript => _partialTranscript;
  double get inputLevel => _inputLevel;
  String? get errorMessage => _error;
  bool get hasTranscript => _turns.isNotEmpty;
  bool get isStreaming =>
      _turns.isNotEmpty &&
      _turns.last.isStreaming &&
      _turns.last.role == ChatRole.ai;
  String languageCode = 'en-US';

  Future<void> requestPermissions() async {
    if (_isRequesting) return;
    _isRequesting = true;
    notifyListeners();
    final status = await Permission.microphone.request();
    _micGranted = status == PermissionStatus.granted;
    _micPermanentlyDenied = status == PermissionStatus.permanentlyDenied;
    if (!_micGranted && _micPermanentlyDenied) {
      _error = 'Microphone permission denied. Enable it in Settings.';
      _state = VoiceState.error;
    } else if (_micGranted) {
      _error = null;
      if (_state == VoiceState.error) {
        _state = VoiceState.idle;
      }
    }
    _isRequesting = false;
    notifyListeners();
  }

  Future<void> openPermissionSettings() async {
    await openAppSettings();
  }

  Future<void> startListening({bool ptt = false}) async {
    if (_state == VoiceState.holding) return;
    await requestPermissions();
    if (!_micGranted) return;
    final available = await _speechToText.initialize(
      onStatus: _handleSttStatus,
      onError: (details) {
        _error = details.errorMsg;
        _setState(VoiceState.error);
      },
    );
    if (!available) {
      _error = 'Speech recognition unavailable on this device.';
      _setState(VoiceState.error);
      return;
    }
    await _playEarcon();
    _partialTranscript = '';
    _setState(VoiceState.holding);
    await _startAmplitudeMeter();
    await _speechToText.listen(
      onResult: _handleSpeechResult,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
      ),
      localeId: languageCode,
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 5),
      onSoundLevelChange: (level) {
        _inputLevel = _normalizeLevel(level);
        notifyListeners();
      },
    );
    if (!ptt) {
      _scheduleSilenceTimeout();
    }
    HapticFeedback.mediumImpact();
  }

  Future<void> stopListening() async {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    await _stopAmplitudeMeter();
    if (_state == VoiceState.holding) {
      _setState(VoiceState.processing);
    }
  }

  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _appendUserTurn(trimmed);
    await _emitAiResponse(trimmed);
  }

  Stream<String> streamAiReply(String userText) {
    final controller = StreamController<String>();
    _service.chatStream(_historyMessages(), userText).then(
      (stream) {
        stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onError: controller.addError,
    );
    return controller.stream;
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    if (!_ttsEnabled) return;
    await _tts.setLanguage(languageCode);
    await _tts.stop();
    _setState(VoiceState.speaking);
    await _tts.speak(text);
  }

  void stopSpeaking() {
    _tts.stop();
    if (_state == VoiceState.speaking) {
      _setState(VoiceState.idle);
    }
  }

  void toggleTts() {
    _ttsEnabled = !_ttsEnabled;
    if (!_ttsEnabled) {
      stopSpeaking();
    }
    notifyListeners();
  }

  Future<void> endSession() async {
    await stopListening();
    _aiSubscription?.cancel();
    _turns.clear();
    _partialTranscript = '';
    _error = null;
    _setState(VoiceState.idle);
    notifyListeners();
  }

  void setLanguage(String code) {
    languageCode = code;
    notifyListeners();
  }

  void syncUiState(VoiceState state) {
    _setState(state);
  }

  Future<String> generateMockHoldToTalkExchange() async {
    const userStub = '[voice] Captured a quick check-in.';
    _appendUserTurn(userStub);
    await Future.delayed(const Duration(milliseconds: 650));
    const reply =
        'Got it. This is a mock response while the voice stack finishes wiring up.';
    _appendAiTurn(reply);
    return reply;
  }

  void _appendUserTurn(String text) {
    _turns.add(
      ChatTurn(
        role: ChatRole.user,
        text: text,
        timestamp: DateTime.now(),
        isStreaming: false,
      ),
    );
    notifyListeners();
  }

  void _appendAiTurn(String text) {
    _turns.add(
      ChatTurn(
        role: ChatRole.ai,
        text: text,
        timestamp: DateTime.now(),
        isStreaming: false,
      ),
    );
    notifyListeners();
  }

  Future<void> _emitAiResponse(String userText) async {
    _error = null;
    _setState(VoiceState.processing);
    final aiTurnIndex = _turns.length;
    _turns.add(
      ChatTurn(
        role: ChatRole.ai,
        text: '',
        timestamp: DateTime.now(),
        isStreaming: true,
      ),
    );
    notifyListeners();

    _aiSubscription?.cancel();
    final stream = streamAiReply(userText);
    _aiSubscription = stream.listen(
      (token) {
        final aiTurn = _turns[aiTurnIndex];
        _turns[aiTurnIndex] = aiTurn.copyWith(
            text: '${aiTurn.text}$token', timestamp: DateTime.now());
        notifyListeners();
      },
      onError: (Object error) {
        final aiTurn = _turns[aiTurnIndex];
        _turns[aiTurnIndex] = aiTurn.copyWith(
          text: 'Something went wrong. Please try again.',
          isStreaming: false,
          isError: true,
        );
        _error = error.toString();
        _setState(VoiceState.error);
      },
      onDone: () {
        final aiTurn = _turns[aiTurnIndex];
        _turns[aiTurnIndex] = aiTurn.copyWith(isStreaming: false);
        notifyListeners();
        if (_ttsEnabled) {
          unawaited(speak(_turns[aiTurnIndex].text));
        } else {
          _setState(VoiceState.idle);
        }
      },
    );
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    _partialTranscript = result.recognizedWords;
    notifyListeners();
    if (result.finalResult) {
      _silenceTimer?.cancel();
      stopListening();
      unawaited(sendText(_partialTranscript));
    } else {
      _scheduleSilenceTimeout();
    }
  }

  void _handleSttStatus(String status) {
    if (status == 'done' && _state == VoiceState.holding) {
      stopListening();
    }
  }

  Future<void> _startAmplitudeMeter() async {
    try {
      if (!await _recorder.hasPermission()) return;
      await _recorder.start(
        encoder: AudioEncoder.wav,
        samplingRate: 16000,
        numChannels: 1,
        bitRate: 128000,
      );
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 80))
          .listen((event) {
        _inputLevel = _normalizeLevel(event.current);
        notifyListeners();
      });
    } catch (_) {
      _inputLevel = 0;
    }
  }

  Future<void> _stopAmplitudeMeter() async {
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    _inputLevel = 0;
    notifyListeners();
  }

  void _scheduleSilenceTimeout() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(_silenceTimeout, () {
      if (_state == VoiceState.holding) {
        stopListening();
      }
    });
  }

  void _setupTtsHandlers() {
    _tts.setCompletionHandler(() {
      _setState(VoiceState.idle);
      notifyListeners();
    });
    _tts.setErrorHandler((message) {
      _error = message;
      _setState(VoiceState.error);
      notifyListeners();
    });
  }

  Future<void> _playEarcon() async {
    try {
      await _earconPlayer.stop();
      await _earconPlayer.setAudioSource(
        AudioSource.asset('assets/audio/voice_prompt.wav'),
      );
      await _earconPlayer.play();
    } catch (_) {
      // ignore missing asset errors in dev
    }
  }

  void _setState(VoiceState newState) {
    if (_state == newState) return;
    _state = newState;
    switch (newState) {
      case VoiceState.holding:
      case VoiceState.processing:
        HapticFeedback.selectionClick();
        break;
      case VoiceState.speaking:
      case VoiceState.idle:
      case VoiceState.error:
        break;
    }
    notifyListeners();
  }

  List<VoiceMessage> _historyMessages() {
    return _turns
        .map(
          (turn) => VoiceMessage(
            role: turn.role,
            content: turn.text,
          ),
        )
        .toList(growable: false);
  }

  double _normalizeLevel(double level) {
    // speech_to_text and record emit decibels in roughly -60..0 range
    final normalized = (level + 60) / 60;
    return normalized.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _aiSubscription?.cancel();
    _amplitudeSubscription?.cancel();
    _silenceTimer?.cancel();
    _speechToText.stop();
    _recorder.dispose();
    _earconPlayer.dispose();
    _tts.stop();
    super.dispose();
  }
}
