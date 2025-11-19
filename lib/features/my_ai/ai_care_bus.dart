import 'package:flutter/foundation.dart';

import 'ai_care_context.dart';

class AiCareBus extends ChangeNotifier {
  AiCareBus._();

  static final AiCareBus I = AiCareBus._();

  AiCareContext? _latest;
  AiCareContext? get latest => _latest;

  void publish(AiCareContext ctx) {
    _latest = ctx;
    notifyListeners();
  }
}
