import 'voice_ai_service.dart';

/// Simple service locator so the UI can resolve whichever VoiceAiService is configured.
class VoiceAiServiceRegistry {
  VoiceAiServiceRegistry._();

  static final VoiceAiServiceRegistry instance = VoiceAiServiceRegistry._();

  VoiceAiService _service = const MockVoiceAiService();

  VoiceAiService get service => _service;

  void register(VoiceAiService service) {
    _service = service;
  }
}
