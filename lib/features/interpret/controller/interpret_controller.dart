// lib/features/interpret/controller/interpret_controller.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/interpret_models.dart';
import '../services/interpret_services.dart';

/// Coordinates the realtime mic -> STT -> MT -> TTS pipeline.
class InterpretController extends ChangeNotifier {
  InterpretController({
    required SttService stt,
    required MtService mt,
    required TtsService tts,
    SttService? demoStt,
    AudioPlayer? cuePlayer,
  })  : _stt = stt,
        _mt = mt,
        _tts = tts,
        _demoStt = demoStt ?? DemoSttService(),
        _cuePlayer = cuePlayer ?? AudioPlayer();

  final SttService _stt;
  final SttService _demoStt;
  final MtService _mt;
  final TtsService _tts;
  final AudioPlayer _cuePlayer;

  final List<Segment> source = <Segment>[];
  final List<Segment> target = <Segment>[];

  InterpState _state = InterpState.idle;
  String langIn = 'en-US';
  String langOut = 'zh-CN';
  bool ttsEnabled = true;
  bool handsFree = true;
  bool _micGranted = false;
  bool _demoMode = false;
  bool _translationPending = false;
  bool _ttsPending = false;
  double _inputLevel = 0;
  String? _errorMessage;
  String? _infoBanner;

  Segment? _activeSourceSegment;
  Segment? _activeTargetSegment;

  StreamSubscription<SttEvent>? _sttSubscription;
  StreamSubscription<String>? _mtSubscription;
  Timer? _waveformTimer;
  double ttsRate = 0.95;
  double ttsVolume = 1.0;

  InterpState get state => _state;
  bool get micGranted => _micGranted;
  bool get demoMode => _demoMode;
  bool get translationPending => _translationPending;
  bool get ttsPending => _ttsPending;
  double get inputLevel => _inputLevel;
  String? get errorMessage => _errorMessage;
  String? get infoBanner => _infoBanner;
  bool get hasCaptions => source.isNotEmpty || target.isNotEmpty;

  final Random _rand = Random();

  Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    _micGranted = status == PermissionStatus.granted;
    if (status == PermissionStatus.permanentlyDenied) {
      _errorMessage =
          'Microphone permission denied. Enable it in system Settings.';
      _state = InterpState.error;
      notifyListeners();
    }
    return _micGranted;
  }

  Future<void> start({bool pushToTalk = false}) async {
    if (_state.isActive && !pushToTalk) return;
    final granted = await requestMicPermission();
    if (!granted) {
      await _startDemoSession();
      return;
    }
    _demoMode = false;
    _infoBanner = null;
    await _playCue();
    await _attachSttStream(_stt);
  }

  Future<void> _startDemoSession() async {
    _demoMode = true;
    _infoBanner = 'Demo mode — captions will use scripted audio.';
    _errorMessage = null;
    await _playCue();
    await _attachSttStream(_demoStt);
  }

  Future<void> _attachSttStream(SttService service) async {
    await stop();
    _setState(InterpState.listening);
    _beginWaveform();
    _sttSubscription = service.startStream(
      langIn,
      onInputLevel: (level) {
        _inputLevel = level.clamp(0, 1);
        notifyListeners();
      },
    ).listen(
      _handleSttEvent,
      onError: (err) async {
        await _sttSubscription?.cancel();
        _sttSubscription = null;
        if (!demoMode) {
          await _startDemoSession();
          return;
        }
        _errorMessage = err.toString();
        _setState(InterpState.error);
        notifyListeners();
      },
      onDone: () {
        if (handsFree) {
          _setState(InterpState.idle);
          _stopWaveform();
        }
      },
    );
  }

  Future<void> stop() async {
    await _stt.stop();
    await _demoStt.stop();
    await _sttSubscription?.cancel();
    await _mtSubscription?.cancel();
    _sttSubscription = null;
    _mtSubscription = null;
    _activeSourceSegment = null;
    _activeTargetSegment = null;
    _translationPending = false;
    _ttsPending = false;
    _stopWaveform();
    _inputLevel = 0;
    if (_state != InterpState.error) {
      _setState(InterpState.idle);
    }
  }

  Future<void> pause() async {
    if (_state == InterpState.paused) return;
    await _stt.stop();
    await _tts.stop();
    _stopWaveform();
    _setState(InterpState.paused);
  }

  Future<void> resume() async {
    if (_state != InterpState.paused) {
      await start();
      return;
    }
    await start();
  }

  void swapLanguages() {
    final tmp = langIn;
    langIn = langOut;
    langOut = tmp;
    _infoBanner =
        'Now interpreting: ${describeLanguage(langIn)} → ${describeLanguage(langOut)}';
    clearCaptions();
    notifyListeners();
  }

  void toggleTts() {
    ttsEnabled = !ttsEnabled;
    if (!ttsEnabled) {
      _tts.stop();
    }
    notifyListeners();
  }

  void toggleHandsFree() {
    handsFree = !handsFree;
    notifyListeners();
  }

  void appendSourceCaption(String text) {
    final parsed = _normalizeCaption(text);
    source.add(
      Segment(
        text: parsed.$1,
        ts: DateTime.now(),
        isFinal: parsed.$2,
      ),
    );
    notifyListeners();
  }

  void appendTargetCaption(String text) {
    final parsed = _normalizeCaption(text);
    target.add(
      Segment(
        text: parsed.$1,
        ts: DateTime.now(),
        isFinal: parsed.$2,
      ),
    );
    notifyListeners();
  }

  Future<void> typeAndTranslate(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final segment = Segment(text: trimmed, ts: DateTime.now(), isFinal: true);
    source.add(segment);
    notifyListeners();
    await _translate(trimmed, finalize: true);
  }

  Future<void> copyTranscript() async {
    final buffer = StringBuffer();
    for (var i = 0; i < source.length; i++) {
      final s = source[i];
      final tgt = i < target.length ? target[i] : null;
      buffer.writeln(
          '[${s.ts.toIso8601String()}] Speaker: ${s.text.trim().isEmpty ? '…' : s.text}');
      if (tgt != null) {
        buffer.writeln('           Listener: ${tgt.text}');
      }
      buffer.writeln();
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
  }

  Future<File> exportTranscript(InterpretExportFormat format) async {
    final dir = await Directory.systemTemp.createTemp('interpret');
    final file = File(
        '${dir.path}/session_${DateTime.now().millisecondsSinceEpoch}.${format.extension}');
    final data = format == InterpretExportFormat.txt
        ? _buildTxtTranscript()
        : _buildSrtTranscript();
    await file.writeAsString(data);
    return file;
  }

  String _buildTxtTranscript() {
    final buffer = StringBuffer();
    for (var i = 0; i < source.length; i++) {
      final s = source[i];
      buffer.writeln(
          '${_formatTimestamp(s.ts)} | Speaker: ${s.text.isEmpty ? '…' : s.text}');
      if (i < target.length) {
        buffer.writeln(
            '                 Listener: ${target[i].text.trim().isEmpty ? '…' : target[i].text}');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  String _buildSrtTranscript() {
    final buffer = StringBuffer();
    for (var i = 0; i < source.length; i++) {
      buffer.writeln('${i + 1}');
      final begin = source[i].ts;
      final end = begin.add(const Duration(seconds: 2));
      buffer.writeln(
          '${_formatSrtTimestamp(begin)} --> ${_formatSrtTimestamp(end)}');
      buffer.writeln('Speaker: ${source[i].text}');
      if (i < target.length) {
        buffer.writeln('Listener: ${target[i].text}');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  Future<void> _handleSttEvent(SttEvent event) async {
    final segment = _ensureSourceSegment();
    segment.text = event.text;
    segment.isFinal = event.isFinal;
    notifyListeners();
    await _translate(event.text, finalize: event.isFinal);
  }

  Future<void> _translate(String text, {required bool finalize}) async {
    if (text.trim().isEmpty) return;
    _translationPending = true;
    _setState(InterpState.translating);
    _mtSubscription?.cancel();
    final segment = _ensureTargetSegment();
    segment.text = '';
    try {
      _mtSubscription =
          _mt.translateStream(text, from: langIn, to: langOut).listen(
        (token) {
          segment.text += token;
          segment.isFinal = false;
          notifyListeners();
        },
        onError: (err) {
          _errorMessage = err.toString();
          _translationPending = false;
          _setState(InterpState.error);
          notifyListeners();
        },
        onDone: () async {
          _translationPending = false;
          if (finalize) {
            segment.isFinal = true;
            _activeSourceSegment = null;
            _activeTargetSegment = null;
            notifyListeners();
            if (ttsEnabled && segment.text.trim().isNotEmpty) {
              _ttsPending = true;
              notifyListeners();
              await _speak(segment.text);
              _ttsPending = false;
            }
            if (!handsFree) {
              await stop();
            } else {
              _setState(InterpState.listening);
            }
          } else {
            _setState(InterpState.listening);
          }
        },
      );
    } catch (err) {
      _errorMessage = err.toString();
      _translationPending = false;
      _setState(InterpState.error);
      notifyListeners();
    }
  }

  Segment _ensureSourceSegment() {
    return _activeSourceSegment ??= () {
      final segment = Segment(text: '', ts: DateTime.now());
      source.add(segment);
      return segment;
    }();
  }

  Segment _ensureTargetSegment() {
    return _activeTargetSegment ??= () {
      final segment = Segment(text: '', ts: DateTime.now());
      target.add(segment);
      return segment;
    }();
  }

  Future<void> _speak(String text) async {
    _setState(InterpState.speaking);
    await _tts.speak(
      text,
      lang: langOut,
      rate: ttsRate,
      volume: ttsVolume,
    );
    if (_state == InterpState.speaking) {
      _setState(InterpState.listening);
    }
  }

  void clearCaptions() {
    source.clear();
    target.clear();
    _activeSourceSegment = null;
    _activeTargetSegment = null;
    notifyListeners();
  }

  void setTtsRate(double value) {
    ttsRate = value.clamp(0.5, 1.5);
    notifyListeners();
  }

  void setTtsVolume(double value) {
    ttsVolume = value.clamp(0.1, 1.0);
    notifyListeners();
  }

  Future<void> _playCue() async {
    try {
      await _cuePlayer.setAsset('assets/audio/voice_prompt.wav');
      await _cuePlayer.seek(Duration.zero);
      await _cuePlayer.play();
    } catch (_) {
      // Ignore cue failures.
    }
  }

  void _beginWaveform() {
    _waveformTimer?.cancel();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!_state.isActive) {
        _inputLevel = 0;
      } else {
        final baseline = demoMode ? 0.4 : 0.15;
        _inputLevel = (baseline + _rand.nextDouble() * 0.7).clamp(0, 1);
      }
      notifyListeners();
    });
  }

  void _stopWaveform() {
    _waveformTimer?.cancel();
    _waveformTimer = null;
    _inputLevel = 0;
  }

  String _formatTimestamp(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

  String _formatSrtTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ms = dt.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s,$ms';
  }

  void _setState(InterpState value) {
    _state = value;
    notifyListeners();
  }

  (String, bool) _normalizeCaption(String raw) {
    const prefix = '[partial] ';
    final isPartial = raw.startsWith(prefix);
    final clean = isPartial ? raw.substring(prefix.length) : raw;
    return (clean, !isPartial);
  }

  @override
  void dispose() {
    _waveformTimer?.cancel();
    _cuePlayer.dispose();
    _sttSubscription?.cancel();
    _mtSubscription?.cancel();
    super.dispose();
  }
}
