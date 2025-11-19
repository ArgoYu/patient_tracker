import 'package:flutter/material.dart';
import 'package:patient_tracker/core/utils/date_formats.dart';
import 'package:patient_tracker/data/models/ai_co_consult_outcome.dart';
import 'package:patient_tracker/features/my_ai/controller/ai_co_consult_service.dart';

/// Doctor-facing workflow for approving AI-generated consult notes.
class AiConsentPage extends StatefulWidget {
  const AiConsentPage({super.key});

  static const String routeName = '/my-ai/consent';

  @override
  State<AiConsentPage> createState() => _AiConsentPageState();
}

class _AiConsentPageState extends State<AiConsentPage> {
  final AiCoConsultCoordinator _coordinator = AiCoConsultCoordinator.instance;
  final TextEditingController _signatureController = TextEditingController();
  bool _approving = false;
  bool _confirmedAccuracy = false;

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _handleApprove() async {
    final signature = _signatureController.text.trim();
    if (signature.isEmpty ||
        !_coordinator.isReportPendingReview ||
        !_confirmedAccuracy) {
      return;
    }
    setState(() => _approving = true);
    try {
      final outcome = _coordinator.markDoctorReviewed(
        approved: true,
        signature: null,
        timestamp: DateTime.now(),
        signatureLabel: signature,
      );
      if (!mounted) return;
      setState(() {
        _signatureController.clear();
        _confirmedAccuracy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report approved by your doctor.')),
      );
      if (outcome != null) {
        await _handleShowToPatient(outcome);
      }
    } finally {
      if (mounted) {
        setState(() => _approving = false);
      }
    }
  }

  void _handleReject() {
    if (_coordinator.pendingOutcome == null) return;
    _coordinator.rejectPendingReport();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report marked for regeneration.')),
    );
  }

  Future<void> _handleShowToPatient(AiCoConsultOutcome outcome) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Patient-ready report'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _approvedByLabel(outcome),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              const Text('Summary'),
              const SizedBox(height: 4),
              SelectableText(
                outcome.summary,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Consent')),
      body: AnimatedBuilder(
        animation: _coordinator,
        builder: (context, _) {
          final status = _coordinator.reportStatus;
          final outcome = _coordinator.pendingOutcome;
          final showPatientPreview = _coordinator.canPatientViewReport
              ? _coordinator.latestOutcome
              : null;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatusCard(status),
              const SizedBox(height: 16),
              if (outcome != null) ...[
                _buildDoctorSummary(outcome),
                const SizedBox(height: 16),
              ] else
                _buildPlaceholder(),
              _buildSignatureField(status),
              const SizedBox(height: 12),
              _buildActionButtons(status, outcome, showPatientPreview),
              if (showPatientPreview != null) ...[
                const SizedBox(height: 16),
                _buildApprovedStamp(showPatientPreview),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(ConsultReportStatus status) {
    final title = _statusTitle(status);
    final subtitle = _statusHint(status);
    final icon = _statusIcon(status);
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _buildDoctorSummary(AiCoConsultOutcome outcome) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doctor Review & Confirmation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Text('Summary'),
            const SizedBox(height: 4),
            SelectableText(
              outcome.summary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (outcome.planUpdates.isNotEmpty)
              _buildBulletList('Plan highlights', outcome.planUpdates),
            if (outcome.followUpQuestions.isNotEmpty)
              _buildBulletList('Follow-up prompts', outcome.followUpQuestions),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletList(String title, List<String> entries) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: Theme.of(context).textTheme.bodySmall),
                  Expanded(
                    child: Text(
                      entry,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No AI report is pending review. Generate a consult summary to begin the workflow.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildSignatureField(ConsultReportStatus status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digital signature',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _signatureController,
              decoration: const InputDecoration(
                labelText: 'Type your name as signature',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            CheckboxListTile(
              value: _confirmedAccuracy,
              onChanged: status == ConsultReportStatus.reportPendingReview
                  ? (value) {
                      setState(() => _confirmedAccuracy = value ?? false);
                    }
                  : null,
              title: const Text('确认报告准确无误'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            Text(
              'Doctors must sign to confirm the summary is accurate before patients can view it.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    ConsultReportStatus status,
    AiCoConsultOutcome? pending,
    AiCoConsultOutcome? patientView,
  ) {
    final signatureNotEmpty = _signatureController.text.trim().isNotEmpty;
    final canApprove = status == ConsultReportStatus.reportPendingReview &&
        signatureNotEmpty &&
        _confirmedAccuracy &&
        !_approving;
    final canShowPatient =
        patientView != null && _coordinator.canPatientViewReport;
    final canRegenerate =
        pending != null && status != ConsultReportStatus.recordingDeleted;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        ElevatedButton(
          onPressed: canApprove ? _handleApprove : null,
          child: _approving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Approve & Sign'),
        ),
        OutlinedButton(
          onPressed: canRegenerate ? _handleReject : null,
          child: const Text('Regenerate Report'),
        ),
        OutlinedButton(
          onPressed:
              canShowPatient ? () => _handleShowToPatient(patientView) : null,
          child: const Text('Show Report to Patient'),
        ),
      ],
    );
  }

  Widget _buildApprovedStamp(AiCoConsultOutcome outcome) {
    final label = _approvedByLabel(outcome);
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  String _statusTitle(ConsultReportStatus status) {
    switch (status) {
      case ConsultReportStatus.idle:
        return 'Awaiting AI report';
      case ConsultReportStatus.reportPendingReview:
        return 'Pending doctor review';
      case ConsultReportStatus.reportRejected:
        return 'Report flagged for regeneration';
      case ConsultReportStatus.reportApproved:
        return 'Report approved';
      case ConsultReportStatus.recordingDeleted:
        return 'Recording deleted';
    }
  }

  String _statusHint(ConsultReportStatus status) {
    switch (status) {
      case ConsultReportStatus.idle:
        return 'Generate a consult summary to begin the clinical approval workflow.';
      case ConsultReportStatus.reportPendingReview:
        return 'Review the AI draft, confirm accuracy, and sign before sharing with the patient.';
      case ConsultReportStatus.reportRejected:
        return 'Request a new AI pass once you have clarified or expanded the notes.';
      case ConsultReportStatus.reportApproved:
        return 'Patient access is enabled; recording will be deleted for compliance.';
      case ConsultReportStatus.recordingDeleted:
        return 'Audio was removed after approval. The report is visible to the patient.';
    }
  }

  IconData _statusIcon(ConsultReportStatus status) {
    switch (status) {
      case ConsultReportStatus.idle:
        return Icons.hourglass_empty_outlined;
      case ConsultReportStatus.reportPendingReview:
        return Icons.rate_review_outlined;
      case ConsultReportStatus.reportRejected:
        return Icons.refresh_outlined;
      case ConsultReportStatus.reportApproved:
        return Icons.verified_outlined;
      case ConsultReportStatus.recordingDeleted:
        return Icons.delete_forever_outlined;
    }
  }

  String _approvedByLabel(AiCoConsultOutcome outcome) {
    final doctorName =
        _coordinator.lastSession?.contactName ?? outcome.contactName;
    final formattedTime =
        formatDateTime(_coordinator.approvalTime ?? outcome.generatedAt);
    final displayName = doctorName.toLowerCase().startsWith('dr.')
        ? doctorName
        : 'Dr. $doctorName';
    return 'Approved by $displayName on $formattedTime';
  }
}
