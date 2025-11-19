import 'dart:async';
import 'dart:math';

import '../../my_ai/ai_care_bus.dart';
import '../../my_ai/ai_care_context.dart';
import '../models/consult_context.dart';

/// Repository surface for Ask-AI-Doctor chat flows.
class AiDoctorRepository {
  AiDoctorRepository({AiCareBus? bus, Duration? chunkDelay})
      : _bus = bus ?? AiCareBus.I,
        _chunkDelay = chunkDelay ?? const Duration(milliseconds: 120),
        _rand = Random();

  final AiCareBus _bus;
  final Duration _chunkDelay;
  final Random _rand;

  /// Simulates streaming text back from the AI service.
  Stream<String> streamReply(
      {required String prompt, String? consultId}) async* {
    final body = _composeMockResponse(prompt: prompt, consultId: consultId);
    final parts = body.split(' ');
    for (final word in parts) {
      await Future.delayed(_chunkDelay);
      yield '$word ';
    }
  }

  /// Retrieves the latest consult context (if any) from the bus.
  Future<ConsultContext> getLatestConsult() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final AiCareContext? ctx = _bus.latest;
    if (ctx == null) {
      return ConsultContext.empty;
    }
    return ConsultContext.fromAiCare(ctx);
  }

  String _composeMockResponse({required String prompt, String? consultId}) {
    final suggestion = _rxSuggestions[_rand.nextInt(_rxSuggestions.length)];
    final now = DateTime.now();
    final consultInfo = consultId == null || consultId.isEmpty
        ? 'general guidance'
        : 'consult $consultId';
    return '''
Thanks for sharing *"$prompt"*. Here's what I recommend based on $consultInfo:

1. **Symptom check** – monitor breathing rate every 2 hours today.
2. **Medication reminder** – ${suggestion.medication} (${suggestion.dosage}) with food.
3. **When to escalate** – reach out if fever > 38.3 C or chest tightness worsens.

> Key note: stay hydrated with ${suggestion.hydrationTip} every few hours.

```markdown
Vitals snapshot (${now.hour}:${now.minute.toString().padLeft(2, '0')}):
- Temp: 37.6 C
- O2 sat: 96%
- HR: 82 bpm
```

**Next steps**
- Gentle stretching routine (5–7 minutes)
- Schedule follow-up in 2 days
- Add questions to care journal tonight
''';
  }
}

class _RxSuggestion {
  const _RxSuggestion({
    required this.medication,
    required this.dosage,
    required this.hydrationTip,
  });

  final String medication;
  final String dosage;
  final String hydrationTip;
}

const List<_RxSuggestion> _rxSuggestions = <_RxSuggestion>[
  _RxSuggestion(
    medication: 'Budesonide inhaler',
    dosage: '2 puffs (180 mcg) every 12h',
    hydrationTip: '300 ml warm water with electrolytes',
  ),
  _RxSuggestion(
    medication: 'Azithromycin',
    dosage: '500 mg day 1, then 250 mg daily x4',
    hydrationTip: 'herbal tea or broth',
  ),
  _RxSuggestion(
    medication: 'Prednisone taper',
    dosage: '40 mg -> 10 mg across 5 days',
    hydrationTip: 'coconut water',
  ),
];
