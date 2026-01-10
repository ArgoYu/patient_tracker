import 'package:flutter/material.dart';
import 'package:patient_tracker/core/theme/theme_tokens.dart';
import 'package:patient_tracker/data/models/ai_co_consult_outcome.dart';
import 'package:patient_tracker/features/my_ai/ai_co_consult_coordinator.dart'
    show AiCoConsultCoordinator, AiCoConsultListeningStatus;
// ^ 如果 AiCoConsultCoordinator 不在 app_modules.dart，改成实际的 import，
// 例如： import 'package:patient_tracker/features/my_ai/ai_co_consult_coordinator.dart';

/// A floating, stateful button that generates the AI co-consult report.
/// - It observes AiCoConsultCoordinator for status changes
/// - Disabled when permission/consent missing or currently busy
/// - On tap: completes the session (if needed) and builds AiCoConsultOutcome
/// - Shows a preview dialog with the generated summary
class AiGenerateReportButton extends StatefulWidget {
  const AiGenerateReportButton({super.key});

  @override
  State<AiGenerateReportButton> createState() => _AiGenerateReportButtonState();
}

class _AiGenerateReportButtonState extends State<AiGenerateReportButton> {
  bool _busy = false;

  AiCoConsultCoordinator get _coordinator => AiCoConsultCoordinator.instance;

  Future<void> _handleGenerateReport(BuildContext context) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Ensure session is marked complete and outcome is generated.
      final AiCoConsultOutcome? outcome = _coordinator.completeSession();

      if (outcome == null) {
        messenger.showSnackBar(
          const SnackBar(
              content: Text(
                  'Failed to generate report: missing context or transcript.')),
        );
        return;
      }

      // Success feedback
      messenger.showSnackBar(
        const SnackBar(content: Text('Report ready for doctor review.')),
      );

      if (!context.mounted) return;

      // Optional: show a quick preview dialog of the summary (Markdown text rendered as plain for now).
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Consultation Summary'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: SelectableText(
                outcome
                    .summary, // This is Markdown text; render as plain text here.
                style: const TextStyle(fontSize: 14, height: 1.35),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to coordinator changes to keep the button enabled/disabled appropriately.
    return AnimatedBuilder(
      animation: _coordinator,
      builder: (context, _) {
        final canGenerate = _coordinator.hasPermission &&
            _coordinator.hasRecordingConsent &&
            !_busy;

        // Button label varies by status
        final status = _coordinator.status;
        String label;
        IconData icon;
        switch (status) {
          case AiCoConsultListeningStatus.listening:
            label = 'Generate Report (End Session)';
            icon = Icons.description_outlined;
            break;
          case AiCoConsultListeningStatus.paused:
            label = 'Generate Report';
            icon = Icons.description_outlined;
            break;
          case AiCoConsultListeningStatus.completed:
            label = 'Regenerate Report';
            icon = Icons.refresh;
            break;
          case AiCoConsultListeningStatus.idle:
            label = 'Generate Report';
            icon = Icons.description_outlined;
            break;
        }

        final theme = Theme.of(context);
        final buttonStyle = ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(WidgetState.disabled)) {
                return theme.colorScheme.onSurface.withOpacity(0.08);
              }
              return theme.colorScheme.primary.withOpacity(0.18);
            },
          ),
          foregroundColor:
              WidgetStateProperty.all(theme.colorScheme.onSurface),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppThemeTokens.smallRadius),
            ),
          ),
          elevation: WidgetStateProperty.all(0),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 14),
          ),
        );

        return SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            style: buttonStyle,
            onPressed:
                canGenerate ? () => _handleGenerateReport(context) : null,
            icon: _busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onSurface,
                    ),
                  )
                : Icon(icon, size: 20),
            label: Text(_busy ? 'Generating…' : label),
          ),
        );
      },
    );
  }
}
