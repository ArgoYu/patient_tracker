// lib/features/my_ai/services/risk_report_exporter.dart

import 'dart:io';

import '../controller/ai_co_consult_service.dart';
import '../models/risk_models.dart';

typedef _DirectoryFactory = Future<Directory> Function();

class RiskReportExporter {
  RiskReportExporter({
    DateTime Function()? clock,
    _DirectoryFactory? directoryFactory,
    this.patientIdentifierResolver,
  })  : _clock = clock ?? DateTime.now,
        _directoryFactory = directoryFactory ??
            (() async => Directory.systemTemp.createTemp('risk_report'));

  final DateTime Function() _clock;
  final _DirectoryFactory _directoryFactory;
  final String Function()? patientIdentifierResolver;

  String? lastExportPath;

  Future<void> exportRiskReport(RiskResult result) async {
    final buffer = StringBuffer()
      ..writeln('Risk Alert Report')
      ..writeln('Generated: ${_clock().toIso8601String()}')
      ..writeln('Patient identifier: ${_resolvePatientId()}')
      ..writeln(
          'Overall score: ${result.overallScore} (${result.overallLevel.name})')
      ..writeln('Summary: ${result.summary}')
      ..writeln('--- Findings ---');

    if (result.items.isEmpty) {
      buffer.writeln('No actionable risks detected.');
    } else {
      for (final item in result.items) {
        buffer
          ..writeln('* ${item.category} — ${item.level.name.toUpperCase()}')
          ..writeln('  Triggers: ${item.triggers.join(', ')}')
          ..writeln('  Recommendation: ${item.suggestion}');
      }
    }

    final directory = await _directoryFactory();
    final filename =
        'risk_alert_${_clock().millisecondsSinceEpoch.toString()}.txt';
    final file = File('${directory.path}/$filename');
    await file.writeAsString(buffer.toString());
    lastExportPath = file.path;
  }

  String _resolvePatientId() {
    if (patientIdentifierResolver != null) {
      final resolved = patientIdentifierResolver!().trim();
      if (resolved.isNotEmpty) return resolved;
    }
    final coordinator = AiCoConsultCoordinator.instance;
    return coordinator.latestOutcome?.conversationId ??
        coordinator.activeConversationId ??
        'MRN-UNKNOWN';
  }
}

Future<void> exportRiskReport(RiskResult result) {
  return RiskReportExporter().exportRiskReport(result);
}
