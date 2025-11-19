const String _voiceEndpoint =
    String.fromEnvironment('VOICE_CHAT_ENDPOINT', defaultValue: '');
const String _voiceApiKey =
    String.fromEnvironment('VOICE_CHAT_API_KEY', defaultValue: '');

/// Build-time configuration for the Voice Chat feature.
class VoiceChatConfig {
  const VoiceChatConfig._();

  /// Endpoint for the real-time chat backend.
  static Uri? get endpoint =>
      _voiceEndpoint.isEmpty ? null : Uri.parse(_voiceEndpoint);

  /// Optional API key that will be sent as a Bearer token.
  static String? get apiKey => _voiceApiKey.isEmpty ? null : _voiceApiKey;

  static bool get isBackendEnabled => endpoint != null;
}
