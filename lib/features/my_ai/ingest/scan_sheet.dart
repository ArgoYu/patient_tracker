import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../ai_care_facade.dart';
import 'ocr_service.dart';
import 'report_parser.dart';

class ScanPaperReportSheet extends StatefulWidget {
  const ScanPaperReportSheet({super.key});

  @override
  State<ScanPaperReportSheet> createState() => _ScanPaperReportSheetState();
}

class _ScanPaperReportSheetState extends State<ScanPaperReportSheet> {
  File? _image;
  String _raw = '';
  ParsedReport? _parsed;
  bool _busy = false;

  final _picker = ImagePicker();
  final OcrService _ocr = MlkitOcrService();

  Future<void> _pick(bool camera) async {
    final x = await (camera
        ? _picker.pickImage(source: ImageSource.camera)
        : _picker.pickImage(source: ImageSource.gallery));
    if (x == null) return;
    setState(() {
      _image = File(x.path);
      _parsed = null;
      _raw = '';
    });
  }

  Future<void> _runOcr() async {
    final f = _image;
    if (f == null) return;
    setState(() => _busy = true);
    final text = await _ocr.extractText(f);
    final parsed = parseReportText(text);
    if (!mounted) return;
    setState(() {
      _raw = text;
      _parsed = parsed;
      _busy = false;
    });
  }

  Future<void> _useAsReport() async {
    final p = _parsed;
    if (p == null) return;
    await aiCare_onCoConsultSummary(
      consultId: 'scanned_${DateTime.now().millisecondsSinceEpoch}',
      summaryMarkdown: '''
**Overview**  
${p.overview}

**Chief complaint**  
${p.chiefComplaint}

**History**  
${p.history}

**Diagnosis**  
${p.diagnosis}

**Recommendations**  
${p.recommendations.map((e) => '• $e').join('\n')}
''',
      highlights: p.highlights,
      followUps: p.followUps,
      rawTranscript: _raw,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report applied to current session.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scan paper report',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pick(true),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Take photo'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _pick(false),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose image'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: (_image != null && !_busy) ? _runOcr : null,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.document_scanner_outlined),
                  label: const Text('Scan'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 140, fit: BoxFit.cover),
              ),
            if (_parsed != null) ...[
              const SizedBox(height: 12),
              Text('Preview', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              _previewLine('Chief complaint', _parsed!.chiefComplaint),
              _previewLine('History', _parsed!.history),
              _previewLine('Diagnosis', _parsed!.diagnosis),
              _previewBullets('Recommendations', _parsed!.recommendations),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _useAsReport,
                icon: const Icon(Icons.check_circle),
                label: const Text('Use as Report'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _previewLine(String h, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(h, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(v),
          ],
        ),
      );

  Widget _previewBullets(String h, List<String> items) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(h, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            if (items.isEmpty)
              const Text('—')
            else
              ...items.map(
                (s) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(s)),
                  ],
                ),
              ),
          ],
        ),
      );
}
