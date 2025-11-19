import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../../data/models/ai_co_consult_outcome.dart';
import '../controller/ai_co_consult_service.dart';

/// Provides the doctor review workflow for the AI Co-Consult summary.
class DoctorReviewPage extends StatefulWidget {
  const DoctorReviewPage({super.key, required this.sessionId});

  static const String routeName = '/my-ai/doctor-review';

  final String sessionId;

  @override
  State<DoctorReviewPage> createState() => _DoctorReviewPageState();
}

class _DoctorReviewPageState extends State<DoctorReviewPage> {
  final AiCoConsultCoordinator _coordinator = AiCoConsultCoordinator.instance;
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  bool _reviewConfirmed = false;
  bool _submitting = false;

  AiCoConsultOutcome? get _outcome {
    return _coordinator.pendingOutcome ?? _coordinator.latestOutcome;
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (!_reviewConfirmed) {
      _showMessage('请勾选确认框后再继续。');
      return;
    }
    if (_signatureController.isEmpty) {
      _showMessage('签名区域不能为空。');
      return;
    }
    setState(() => _submitting = true);
    try {
      final Uint8List? signatureBytes = await _signatureController.toPngBytes();
      if (signatureBytes == null || signatureBytes.isEmpty) {
        _showMessage('签名导出失败，请重试。');
        return;
      }
      final approvedOutcome = _coordinator.markDoctorReviewed(
        approved: true,
        signature: signatureBytes,
        timestamp: DateTime.now(),
      );
      if (approvedOutcome == null) {
        _showMessage('未找到待审核报告。');
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summaryText = _outcome?.summary ?? '报告尚未生成，请稍候。';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Review Page'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Session ID: ${widget.sessionId}',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text(
                    'Full AI Session Summary',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          summaryText,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          _buildReviewPanel(theme),
        ],
      ),
    );
  }

  Widget _buildReviewPanel(ThemeData theme) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Doctor Approval & Signature',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _reviewConfirmed,
              title: const Text('I confirm that I have reviewed this report and it is accurate.'),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _reviewConfirmed = value);
              },
            ),
            const SizedBox(height: 8),
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              margin: const EdgeInsets.only(bottom: 4),
              child: Signature(
                controller: _signatureController,
                backgroundColor: Colors.white,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _signatureController.clear();
                },
                child: const Text('Clear signature'),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _submitting ? null : _handleConfirm,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('确认签字并发布报告 (Confirm & Publish Report)'),
            ),
          ],
        ),
      ),
    );
  }
}
