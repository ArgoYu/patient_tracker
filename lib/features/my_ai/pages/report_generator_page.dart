import 'package:flutter/material.dart';

import '../ai_care_bus.dart';
import '../ai_care_context.dart';
import '../ingest/scan_sheet.dart';

class ReportGeneratorPage extends StatefulWidget {
  const ReportGeneratorPage({super.key});

  @override
  State<ReportGeneratorPage> createState() => _ReportGeneratorPageState();
}

class _ReportGeneratorPageState extends State<ReportGeneratorPage> {
  AiCareContext? _ctx;

  @override
  void initState() {
    super.initState();
    _ctx = AiCareBus.I.latest;
    AiCareBus.I.addListener(_onBus);
  }

  void _onBus() {
    setState(() => _ctx = AiCareBus.I.latest);
  }

  @override
  void dispose() {
    AiCareBus.I.removeListener(_onBus);
    super.dispose();
  }

  Future<void> _showScanSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const ScanPaperReportSheet(),
    );
  }

  Future<void> _exportMock() async {
    final text = '''
# Consult Report (Mock)
Generated: ${DateTime.now()}
Highlights:
${(_ctx?.highlights ?? []).map((e) => '- $e').join('\n')}
Follow-ups:
${(_ctx?.followUps ?? []).map((e) => '- $e').join('\n')}

Summary:
${_ctx?.summaryMarkdown ?? '(empty)'}
''';
    debugPrint(text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exported draft (mock)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctx = _ctx;
    return Scaffold(
      appBar: AppBar(title: const Text('AI Report Generator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Generated ${DateTime.now()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _showScanSheet,
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('Scan paper report'),
          ),
          const SizedBox(height: 12),
          Text('Key highlights', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          if (ctx == null || ctx.highlights.isEmpty)
            const Text('No highlights yet. Generate a Co-Consult summary first.')
          else
            ...ctx.highlights.map(_bullet),
          const SizedBox(height: 16),
          Text('Plan / Follow-ups', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          if (ctx == null || ctx.followUps.isEmpty)
            const Text('No follow-ups yet.')
          else
            ...ctx.followUps.map(_bullet),
          const SizedBox(height: 16),
          Text('Full summary', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          SelectableText(ctx?.summaryMarkdown ?? '(no summary)'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _exportMock,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export (mock)'),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•  '),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
