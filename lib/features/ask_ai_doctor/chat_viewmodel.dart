import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'data/ai_doctor_repository.dart';
import 'models/chat_message.dart';
import 'models/consult_context.dart';

class AskAiDoctorChatVM extends ChangeNotifier {
  AskAiDoctorChatVM({
    AiDoctorRepository? repository,
    Uuid? uuid,
  })  : _repository = repository ?? AiDoctorRepository(),
        _uuid = uuid ?? const Uuid();

  final AiDoctorRepository _repository;
  final Uuid _uuid;

  final List<ChatMessage> _messages = <ChatMessage>[];
  StreamSubscription<String>? _streamSub;
  Timer? _recordingTimer;

  bool _isStreaming = false;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  double _waveformLevel = 0;

  ConsultContext? _latestConsult;
  bool _isLoadingConsult = false;
  bool _insertLatestConsult = true;

  String? _activeAssistantMessageId;
  String? _activeParentUserId;
  String? _errorMessage;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isStreaming => _isStreaming;
  bool get isRecording => _isRecording;
  Duration get recordingDuration => _recordingDuration;
  double get waveformLevel => _waveformLevel;
  ConsultContext? get latestConsult => _latestConsult;
  bool get insertLatestConsult => _insertLatestConsult;
  bool get isLoadingConsult => _isLoadingConsult;
  bool get isEmpty => _messages.isEmpty;
  String? get errorMessage => _errorMessage;

  Future<void> loadLatestConsult() async {
    if (_isLoadingConsult) return;
    _isLoadingConsult = true;
    notifyListeners();
    try {
      final ctx = await _repository.getLatestConsult();
      _latestConsult = ctx.hasContent ? ctx : null;
    } finally {
      _isLoadingConsult = false;
      notifyListeners();
    }
  }

  void toggleConsultContext(bool value) {
    _insertLatestConsult = value;
    notifyListeners();
  }

  Future<void> send(String text, {String? consultId}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final resolvedConsultId =
        consultId ?? (_insertLatestConsult ? _latestConsult?.consultId : null);
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      isUser: true,
      text: trimmed,
      createdAt: DateTime.now(),
      meta: {
        if (resolvedConsultId != null) 'consultId': resolvedConsultId,
      },
    );
    _messages.add(userMessage);
    notifyListeners();

    await _streamReply(
      prompt: trimmed,
      consultId: resolvedConsultId,
      parentId: userMessage.id,
    );
  }

  Future<void> regenerate(String messageId) async {
    ChatMessage? parent;
    int? aiIndex;
    for (var i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      if (message.id == messageId) {
        if (message.isUser) {
          parent = message;
          final nextIndex = i + 1;
          if (nextIndex < _messages.length && !_messages[nextIndex].isUser) {
            aiIndex = nextIndex;
          }
        } else {
          aiIndex = i;
          for (var j = i - 1; j >= 0; j--) {
            if (_messages[j].isUser) {
              parent = _messages[j];
              break;
            }
          }
        }
        break;
      }
    }
    parent ??= () {
      for (var i = _messages.length - 1; i >= 0; i--) {
        if (_messages[i].isUser) {
          return _messages[i];
        }
      }
      return null;
    }();
    if (parent == null) {
      return;
    }
    if (aiIndex != null) {
      _messages.removeAt(aiIndex);
    }
    notifyListeners();

    final consultId = parent.meta?['consultId'] as String? ??
        (_insertLatestConsult ? _latestConsult?.consultId : null);
    await _streamReply(
      prompt: parent.text,
      consultId: consultId,
      parentId: parent.id,
    );
  }

  void deleteMessage(String id) {
    final before = _messages.length;
    _messages.removeWhere((m) => m.id == id);
    if (_messages.length != before) {
      notifyListeners();
    }
  }

  void clear() {
    stopStreaming();
    if (_messages.isEmpty) return;
    _messages.clear();
    notifyListeners();
  }

  Future<void> _streamReply({
    required String prompt,
    String? consultId,
    required String parentId,
  }) async {
    await stopStreaming();
    _isStreaming = true;
    _errorMessage = null;
    _activeParentUserId = parentId;
    final assistantMessage = ChatMessage(
      id: _uuid.v4(),
      isUser: false,
      text: '',
      createdAt: DateTime.now(),
      meta: {
        'status': 'streaming',
        if (consultId != null) 'consultId': consultId,
      },
    );
    _activeAssistantMessageId = assistantMessage.id;
    _messages.add(assistantMessage);
    notifyListeners();

    _streamSub = _repository
        .streamReply(prompt: prompt, consultId: consultId)
        .listen((chunk) {
      final idx = _messages.indexWhere((m) => m.id == assistantMessage.id);
      if (idx == -1) return;
      final current = _messages[idx];
      _messages[idx] = current.copyWith(text: '${current.text}$chunk');
      notifyListeners();
    }, onError: (Object error, StackTrace stack) {
      _errorMessage = 'Unable to get an AI reply. Please try again.';
      _isStreaming = false;
      final idx = _messages.indexWhere((m) => m.id == assistantMessage.id);
      if (idx != -1) {
        final current = _messages[idx];
        _messages[idx] = current.copyWith(
          meta: {
            ...?current.meta,
            'status': 'error',
          },
        );
      }
      notifyListeners();
    }, onDone: () {
      final idx = _messages.indexWhere((m) => m.id == assistantMessage.id);
      if (idx != -1) {
        final current = _messages[idx];
        _messages[idx] =
            current.copyWith(meta: {...?current.meta}..remove('status'));
      }
      _isStreaming = false;
      _activeAssistantMessageId = null;
      _activeParentUserId = null;
      notifyListeners();
    });
  }

  Future<void> stopStreaming() async {
    if (_streamSub == null) return;
    await _streamSub?.cancel();
    _streamSub = null;
    _isStreaming = false;
    if (_activeAssistantMessageId != null) {
      final idx =
          _messages.indexWhere((m) => m.id == _activeAssistantMessageId);
      if (idx != -1) {
        final current = _messages[idx];
        _messages[idx] =
            current.copyWith(meta: {...?current.meta}..remove('status'));
      }
    }
    _activeAssistantMessageId = null;
    _activeParentUserId = null;
    notifyListeners();
  }

  void startRecording() {
    if (_isRecording) return;
    _isRecording = true;
    _recordingDuration = Duration.zero;
    _waveformLevel = 0;
    final rand = Random();
    _recordingTimer =
        Timer.periodic(const Duration(milliseconds: 200), (Timer timer) {
      _recordingDuration = Duration(milliseconds: timer.tick * 200);
      _waveformLevel = rand.nextDouble();
      notifyListeners();
    });
    notifyListeners();
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _isRecording = false;
    _waveformLevel = 0;
    final mock =
        'Transcribed text (sample), recording length ${_recordingDuration.inSeconds}s';
    _recordingDuration = Duration.zero;
    notifyListeners();
    return mock;
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }
}
