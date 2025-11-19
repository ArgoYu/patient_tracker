import 'package:flutter/foundation.dart';

import 'ai_care_bus.dart';
import 'ai_care_context.dart';

/// Read-only view model the Report screen can listen to.
class ReportGeneratorVM extends ChangeNotifier {
  AiCareContext? _ctx;
  AiCareContext? get ctx => _ctx;

  ReportGeneratorVM() {
    _ctx = AiCareBus.I.latest;
    AiCareBus.I.addListener(_onBus);
  }

  void _onBus() {
    _ctx = AiCareBus.I.latest;
    notifyListeners();
  }

  @override
  void dispose() {
    AiCareBus.I.removeListener(_onBus);
    super.dispose();
  }
}
