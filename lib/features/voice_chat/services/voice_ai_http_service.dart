import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/voice_chat_models.dart';
import 'voice_ai_service.dart';

/// Voice service backed by a streaming HTTP endpoint.
class HttpVoiceAiService extends VoiceAiService {
  HttpVoiceAiService({
    required this.endpoint,
    Map<String, String>? headers,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  })  : _client = client ?? http.Client(),
        _headers = {
          'Content-Type': 'application/json',
          if (headers != null) ...headers,
        };

  final Uri endpoint;
  final Map<String, String> _headers;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<Stream<String>> chatStream(
    List<VoiceMessage> history,
    String userText,
  ) async {
    final request = http.Request('POST', endpoint)
      ..headers.addAll(_headers)
      ..body = jsonEncode({
        'history': history
            .map(
              (e) => {
                'role': e.role.name,
                'content': e.content,
              },
            )
            .toList(),
        'message': userText,
      });

    final response = await _client.send(request).timeout(timeout);
    if (response.statusCode >= 400) {
      final errorBody = await response.stream.bytesToString();
      throw HttpException(
        'Voice chat failed (${response.statusCode}): $errorBody',
        uri: endpoint,
      );
    }
    final controller = StreamController<String>();
    response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) {
        if (line.trim().isEmpty) return;
        controller.add(line);
      },
      onError: controller.addError,
      onDone: controller.close,
    );
    return controller.stream;
  }
}
