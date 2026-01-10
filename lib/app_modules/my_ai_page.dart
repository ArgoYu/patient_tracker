part of 'package:patient_tracker/app_modules.dart';

typedef _ContextAction = Future<void> Function(BuildContext context);
typedef _ContextBoolAction = Future<void> Function(
  BuildContext context,
  bool value,
);
typedef _ContextListAction = Future<void> Function(
  BuildContext context,
  List<String> values,
);

enum _AutoProcess {
  consent,
  asr,
  summary,
  timeline,
  patientQuestions,
  pdf,
}

enum _AutoProcessState { pending, inProgress, ready, completed }

enum _SummaryFocus {
  overview,
  timeline,
  transcript,
  consent,
  metadata,
  all,
}

enum _SummarySectionType {
  overview,
  chiefComplaint,
  history,
  diagnosis,
  recommendations,
  timeline,
  consent,
  transcript,
  metadata,
}

class MyAiPage extends StatefulWidget {
  const MyAiPage({super.key, this.autoShowSessionControls = false});

  static const String routeName = '/my_ai';
  final bool autoShowSessionControls;

  static final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
    routeName: (_) => const MyAiPage(),
    _AiCoConsultHubDetailPage.routeName: (_) =>
        const _AiCoConsultHubDetailPage(),
    _AiReportGeneratorHubPage.routeName: (_) =>
        const _AiReportGeneratorHubPage(),
    _AskAiDoctorHubPage.routeName: (_) => const _AskAiDoctorHubPage(),
    AiConsentPage.routeName: (_) => const AiConsentPage(),
    _TimelinePlannerHubPage.routeName: (_) => const _TimelinePlannerHubPage(),
    RiskAlertPage.routeName: (_) => const RiskAlertPage(),
    InterpretPage.routeName: (_) => const InterpretPage(),
  };

  @override
  State<MyAiPage> createState() => _MyAiPageState();
}

class _MyAiPageState extends State<MyAiPage> {
  late final AiCoConsultCoordinator _coCoordinator;
  final TextEditingController _sessionLabelController =
      TextEditingController(text: 'Consult Room A');
  final TextEditingController _clinicianController =
      TextEditingController(text: 'Dr. Chen');

  @override
  void initState() {
    super.initState();
    _coCoordinator = AiCoConsultCoordinator.instance;
  }

  Future<void> _handlePermissionChanged(
    BuildContext context,
    bool allowed,
  ) async {
    final confirmed = await _showClinicianConsentDialog(context, allowed);
    if (confirmed == null) return;
    _coCoordinator.updatePermission(confirmed);
    _showMyAiSnack(
      context,
      confirmed
          ? 'Clinician access to AI listening enabled'
          : 'Clinician listening access disabled',
    );
  }

  Future<void> _handleConsentChanged(
    BuildContext context,
    bool allowed,
  ) async {
    final confirmed = await _showPatientConsentDialog(context, allowed);
    if (confirmed == null) return;
    _coCoordinator.updateRecordingConsent(confirmed);
    _showMyAiSnack(
      context,
      confirmed
          ? 'Patient consent confirmed'
          : 'Patient consent missing; unable to start listening',
    );
  }

  Future<void> _handleStartListening(BuildContext context) async {
    if (!_coCoordinator.hasRecordingConsent) {
      await _showConsentAlert(context);
      return;
    }
    if (!_coCoordinator.hasPermission) {
      _showMyAiSnack(
        context,
        'Clinician listening permission is required to start',
      );
      return;
    }

    final label = _sessionLabelController.text.trim();
    final clinician = _clinicianController.text.trim().isEmpty
        ? 'Care Team'
        : _clinicianController.text.trim();
    final baseId = label.isEmpty ? clinician : label;
    final conversationId = _sanitizeConversationId(baseId);
    final session = _coCoordinator.startSession(
      conversationId: conversationId.isEmpty
          ? 'consult-${DateTime.now().millisecondsSinceEpoch}'
          : conversationId,
      contactName: clinician,
    );
    if (session == null) {
      _showMyAiSnack(
        context,
        'Confirm permissions and patient consent before starting listening',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    _showMyAiSnack(
      context,
      'AI listening started and monitoring the current consult',
    );
  }

  Future<void> _handlePauseListening(BuildContext context) async {
    if (_coCoordinator.status != AiCoConsultListeningStatus.listening) return;
    _coCoordinator.pauseListening();
    _showMyAiSnack(context, 'AI listening paused');
  }

  Future<void> _handleResumeListening(BuildContext context) async {
    if (_coCoordinator.status != AiCoConsultListeningStatus.paused) return;
    _coCoordinator.resumeListening();
    _showMyAiSnack(context, 'AI listening resumed');
  }

  Future<void> _handleSendFollowUps(
    BuildContext context,
    List<String> selections,
  ) async {
    if (selections.isEmpty) {
      _showMyAiSnack(
        context,
        'Select the follow-up prompts to send to the patient',
      );
      return;
    }
    _showMyAiSnack(
      context,
      'Prepared to send ${selections.length} automated follow-ups to the patient',
    );
  }

  Future<void> _handleSkipFollowUps(BuildContext context) async {
    _showMyAiSnack(context, 'Automated follow-ups skipped for now');
  }

  void _showMyAiSnack(BuildContext context, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showConsentAlert(BuildContext context) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Patient Consent Required'),
        content: const Text(
          'Record patient consent before starting AI co-consulting.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            isDefaultAction: true,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showClinicianConsentDialog(
    BuildContext context,
    bool allowed,
  ) {
    final title =
        allowed ? 'Confirm clinician access' : 'Revoke clinician access';
    final description = allowed
        ? 'Allow the clinician to initiate Echo AI listening for the current session.'
        : 'Revoking access prevents new Echo AI sessions until permissions are restored.';
    final confirmLabel = allowed ? 'Allow access' : 'Revoke access';
    return showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(description),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(allowed),
            isDefaultAction: allowed,
            isDestructiveAction: !allowed,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showPatientConsentDialog(
    BuildContext context,
    bool allowed,
  ) {
    final title =
        allowed ? 'Confirm patient consent' : 'Revoking patient consent';
    final description = allowed
        ? 'Confirm the patient understands that Echo AI will capture and analyze this conversation.'
        : 'Revoking patient consent prevents future Echo AI recordings until new consent is provided.';
    final confirmLabel = allowed ? 'Record consent' : 'Revoke consent';
    return showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(description),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(allowed),
            isDefaultAction: allowed,
            isDestructiveAction: !allowed,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  String _sanitizeConversationId(String input) {
    final sanitized = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
    return sanitized.startsWith('-')
        ? sanitized.replaceFirst(RegExp(r'^-+'), '')
        : sanitized;
  }

  @override
  void dispose() {
    _sessionLabelController.dispose();
    _clinicianController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MyAiDetailPage(
      autoShowSessionControls: widget.autoShowSessionControls,
      coordinator: _coCoordinator,
      onStart: _handleStartListening,
      onPause: _handlePauseListening,
      onResume: _handleResumeListening,
      onPermissionChanged: _handlePermissionChanged,
      onConsentChanged: _handleConsentChanged,
      onSendFollowUps: _handleSendFollowUps,
      onSkipFollowUps: _handleSkipFollowUps,
    );
  }
}

class _MyAiDetailPage extends StatefulWidget {
  const _MyAiDetailPage({
    required this.autoShowSessionControls,
    required this.coordinator,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onPermissionChanged,
    required this.onConsentChanged,
    required this.onSendFollowUps,
    required this.onSkipFollowUps,
  });

  final bool autoShowSessionControls;
  final AiCoConsultCoordinator coordinator;
  final _ContextAction onStart;
  final _ContextAction onPause;
  final _ContextAction onResume;
  final _ContextBoolAction onPermissionChanged;
  final _ContextBoolAction onConsentChanged;
  final _ContextListAction onSendFollowUps;
  final _ContextAction onSkipFollowUps;

  @override
  State<_MyAiDetailPage> createState() => _MyAiDetailPageState();
}

class _MyAiDetailPageState extends State<_MyAiDetailPage> {
  final Set<int> _selectedFollowUps = <int>{};
  bool _exportingPdf = false;
  bool _completingSession = false;
  final ScrollController _scrollController = ScrollController();
  late AiCoConsultListeningStatus _lastStatus;
  final Map<_AutoProcess, _AutoProcessState> _autoProcessStates = {
    for (final process in _AutoProcess.values)
      process: _AutoProcessState.pending,
  };
  bool _sessionControlsDialogShownAutomatically = false;
  bool _sessionControlsDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _lastStatus = widget.coordinator.status;
    widget.coordinator.addListener(_handleCoordinatorUpdate);
    _syncAutoProcesses();
    _triggerAutoShowSessionControls();
  }

  Future<void> _handleCompleteSession() async {
    if (_completingSession) return;
    final status = widget.coordinator.status;
    if (status == AiCoConsultListeningStatus.idle) {
      _showToast('Start recording before completing the session.');
      return;
    }
    setState(() {
      _completingSession = true;
    });
    try {
      final outcome = widget.coordinator.completeSession();
      if (!mounted) return;
      if (outcome == null) {
        _showToast('Unable to complete the session. Try again.');
        return;
      }
      _showToast('Consult summary ready.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_openSummarySheet(_SummaryFocus.overview));
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _completingSession = false;
        });
      }
    }
  }

  Future<void> _handleSendSelected(List<String> suggestions) async {
    if (_selectedFollowUps.isEmpty) return;
    final selected = _selectedFollowUps.map((i) => suggestions[i]).toList();
    await widget.onSendFollowUps(context, selected);
    setState(() {
      _selectedFollowUps.clear();
    });
  }

  Future<void> _openSummarySheet(_SummaryFocus focus) async {
    final outcome = widget.coordinator.latestOutcome;
    if (outcome == null) return;
    if (!widget.coordinator.canPatientViewReport) {
      _showToast('Doctor approval is required before viewing this summary.');
      return;
    }
    final visibleSections = _sectionsForFocus(focus);
    final approvalLabel = _approvalBadgeText();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _ConsultSummarySheet(
        outcome: outcome,
        approvalLabel: approvalLabel,
        onSave: () => _showToast('Summary saved to the patient record'),
        onExport: () => _exportPdf(outcome),
        exporting: _exportingPdf,
        initialFocus: focus,
        visibleSections: visibleSections,
      ),
    );
  }

  Set<_SummarySectionType>? _sectionsForFocus(_SummaryFocus focus) {
    switch (focus) {
      case _SummaryFocus.overview:
        return {
          _SummarySectionType.overview,
          _SummarySectionType.chiefComplaint,
          _SummarySectionType.history,
          _SummarySectionType.diagnosis,
          _SummarySectionType.recommendations,
        };
      case _SummaryFocus.timeline:
        return {_SummarySectionType.timeline};
      case _SummaryFocus.transcript:
        return {_SummarySectionType.transcript};
      case _SummaryFocus.consent:
        return {_SummarySectionType.consent};
      case _SummaryFocus.metadata:
        return {_SummarySectionType.metadata};
      case _SummaryFocus.all:
        return null;
    }
  }

  Future<void> _openPatientQuestionsSheet(List<String> suggestions) async {
    if (!widget.coordinator.canPatientViewReport) {
      _showToast(
          'Doctor approval is required before sending these follow-ups.');
      return;
    }
    if (suggestions.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _PatientQuestionsSheet(
        suggestions: suggestions,
        initialSelection: _selectedFollowUps,
        onSelectionChanged: (selection) {
          setState(() {
            _selectedFollowUps
              ..clear()
              ..addAll(selection);
          });
        },
        onSend: (selection) async {
          setState(() {
            _selectedFollowUps
              ..clear()
              ..addAll(selection);
          });
          await _handleSendSelected(suggestions);
        },
        onSkip: () async {
          await widget.onSkipFollowUps(context);
          setState(() {
            _selectedFollowUps.clear();
          });
        },
      ),
    );
  }

  void _handleCoordinatorUpdate() {
    final status = widget.coordinator.status;
    if (status != _lastStatus) {
      _lastStatus = status;
    }
    _syncAutoProcesses();
  }

  @override
  void dispose() {
    widget.coordinator.removeListener(_handleCoordinatorUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _handleShareButton(AiCoConsultOutcome? outcome) {
    if (outcome == null) {
      _showToast('Summary is not ready yet.');
      return;
    }
    if (!widget.coordinator.canPatientViewReport) {
      _showToast('This report unlocks after a clinician approves it.');
      return;
    }
    _showShareActions(outcome);
  }

  void _showShareActions(AiCoConsultOutcome outcome) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.32),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Share report',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.save_outlined),
                  title: const Text('Save report'),
                  subtitle:
                      const Text('Add this summary to the patient record.'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _handleSaveReport(outcome);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('Send to Chat…'),
                  subtitle: const Text('Attach the summary to a chat thread.'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openChatTargetPicker(outcome);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: const Text('Export as PDF'),
                  subtitle: const Text(
                      'Generate the PDF copy for download or sharing.'),
                  trailing: _exportingPdf
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _exportingPdf
                      ? null
                      : () {
                          Navigator.of(sheetContext).pop();
                          _exportPdf(outcome);
                        },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSaveReport(AiCoConsultOutcome outcome) {
    _showToast('Summary saved to the patient record');
  }

  Future<void> _openChatTargetPicker(AiCoConsultOutcome outcome) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.32),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Send report to chat',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              ...personalChatContacts.map(
                (contact) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: contact.color.withOpacity(0.16),
                    child: Icon(contact.icon, color: contact.color),
                  ),
                  title: Text(contact.name),
                  subtitle: Text(contact.subtitle),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _handleSendToChat(contact, outcome);
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSendToChat(
    PersonalChatContact contact,
    AiCoConsultOutcome outcome,
  ) {
    _showToast('Report attached to ${contact.name} chat.');
  }

  String? _approvalBadgeText() {
    if (!widget.coordinator.canPatientViewReport) return null;
    final doctorName = widget.coordinator.lastSession?.contactName ??
        widget.coordinator.latestOutcome?.contactName;
    final when = widget.coordinator.approvalTime ??
        widget.coordinator.latestOutcome?.generatedAt;
    if (doctorName == null || when == null) return null;
    final displayName = doctorName.toLowerCase().startsWith('dr.')
        ? doctorName
        : 'Dr. $doctorName';
    return 'Approved by $displayName on ${formatDateTime(when)}';
  }

  Future<void> _exportPdf(AiCoConsultOutcome outcome) async {
    if (_exportingPdf) return;
    setState(() {
      _exportingPdf = true;
      _autoProcessStates[_AutoProcess.pdf] = _AutoProcessState.inProgress;
    });
    var exported = false;
    try {
      final doc = pw.Document();
      final consent = outcome.consentRecord;
      final baseInfo = [
        'Session ID: ${outcome.sessionId}',
        'Conversation ID: ${outcome.conversationId}',
        'Clinician: ${outcome.contactName}',
        'Started: ${formatDateTime(outcome.startedAt)}',
        'Completed: ${formatDateTime(outcome.completedAt)}',
        'Generated: ${formatDateTime(outcome.generatedAt)}',
      ];
      final consentInfo = [
        'Status: ${consent.granted ? 'granted' : 'revoked'}',
        'Recorded at: ${formatDateTime(consent.recordedAt)}',
        'Method: ${consent.method}',
        if (consent.version != null) 'Version: ${consent.version}',
        if (consent.notes != null) 'Notes: ${consent.notes}',
      ];

      doc.addPage(
        pw.MultiPage(
          pageFormat: pdf.PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Echo AI Summary',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Paragraph(text: baseInfo.join('\n')),
            pw.SizedBox(height: 12),
            pw.Header(level: 1, text: 'Clinical Summary'),
            pw.Paragraph(text: outcome.summary),
            pw.Header(level: 2, text: 'Chief Complaint'),
            pw.Paragraph(text: outcome.chiefComplaint),
            pw.Header(level: 2, text: 'History'),
            pw.Paragraph(text: outcome.historySummary),
            pw.Header(level: 2, text: 'Diagnosis'),
            pw.Paragraph(text: outcome.diagnosisSummary),
            pw.Header(level: 2, text: 'Recommendations'),
            pw.Paragraph(text: outcome.recommendations),
            pw.Header(level: 1, text: 'Consent Record'),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children:
                  consentInfo.map((info) => pw.Bullet(text: info)).toList(),
            ),
            pw.Header(level: 1, text: 'Follow-up Timeline'),
            if (outcome.timeline.isEmpty)
              pw.Paragraph(text: 'No follow-up timeline items.')
            else
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: outcome.timeline
                    .map(
                      (item) => pw.Bullet(
                        text:
                            '${formatDateTime(item.when)} · ${item.title} — ${item.detail}${item.code != null ? ' (${item.code})' : ''}',
                      ),
                    )
                    .toList(),
              ),
            pw.Header(level: 1, text: 'Patient Question Suggestions'),
            if (outcome.followUpQuestions.isEmpty)
              pw.Paragraph(text: 'No patient questions suggested.')
            else
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: outcome.followUpQuestions
                    .map((q) => pw.Bullet(text: q))
                    .toList(),
              ),
            pw.Header(level: 1, text: 'Audio Transcript (ASR)'),
            pw.Paragraph(text: outcome.transcript),
            pw.Header(level: 1, text: 'Session Metadata'),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: outcome.metadata.entries
                  .map(
                    (entry) => pw.Bullet(
                      text: '${entry.key}: ${entry.value}',
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      final tempDir = await Directory.systemTemp.createTemp('ai_co_consult');
      final file = File(
        '${tempDir.path}/ai_co_consult_${outcome.sessionId}.pdf',
      );
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType: 'application/pdf',
            name: 'ai_co_consult_${outcome.sessionId}.pdf',
          ),
        ],
        text: 'Echo AI summary for ${outcome.contactName}',
      );
      exported = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF exported successfully')),
      );
      // Cleanup temp dir asynchronously.
      unawaited(
        Future<void>.delayed(const Duration(seconds: 5), () async {
          try {
            if (await tempDir.exists()) {
              await tempDir.delete(recursive: true);
            }
          } catch (_) {
            // Ignore cleanup errors.
          }
        }),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export PDF: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _exportingPdf = false;
          _autoProcessStates[_AutoProcess.pdf] =
              exported ? _AutoProcessState.completed : _AutoProcessState.ready;
        });
      }
    }
  }

  void _syncAutoProcesses() {
    final status = widget.coordinator.status;
    final consentGranted = widget.coordinator.hasRecordingConsent;
    final updated = Map<_AutoProcess, _AutoProcessState>.from(
      _autoProcessStates,
    );

    void setProcess(_AutoProcess process, _AutoProcessState state) {
      if (updated[process] != state) {
        updated[process] = state;
      }
    }

    setProcess(
      _AutoProcess.consent,
      consentGranted ? _AutoProcessState.completed : _AutoProcessState.pending,
    );

    switch (status) {
      case AiCoConsultListeningStatus.idle:
        setProcess(_AutoProcess.asr, _AutoProcessState.pending);
        setProcess(_AutoProcess.summary, _AutoProcessState.pending);
        setProcess(_AutoProcess.timeline, _AutoProcessState.pending);
        setProcess(_AutoProcess.patientQuestions, _AutoProcessState.pending);
        setProcess(_AutoProcess.pdf, _AutoProcessState.pending);
        break;
      case AiCoConsultListeningStatus.listening:
      case AiCoConsultListeningStatus.paused:
        setProcess(_AutoProcess.asr, _AutoProcessState.inProgress);
        setProcess(_AutoProcess.summary, _AutoProcessState.inProgress);
        setProcess(_AutoProcess.timeline, _AutoProcessState.inProgress);
        setProcess(
          _AutoProcess.patientQuestions,
          _AutoProcessState.inProgress,
        );
        break;
      case AiCoConsultListeningStatus.completed:
        setProcess(_AutoProcess.asr, _AutoProcessState.completed);
        setProcess(_AutoProcess.summary, _AutoProcessState.completed);
        setProcess(_AutoProcess.timeline, _AutoProcessState.completed);
        setProcess(
          _AutoProcess.patientQuestions,
          _AutoProcessState.completed,
        );
        if (!_exportingPdf &&
            _autoProcessStates[_AutoProcess.pdf] !=
                _AutoProcessState.completed) {
          setProcess(_AutoProcess.pdf, _AutoProcessState.ready);
        }
        break;
    }

    if (!mapEquals(_autoProcessStates, updated)) {
      setState(() {
        _autoProcessStates
          ..clear()
          ..addAll(updated);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final background =
        CupertinoColors.systemGroupedBackground.resolveFrom(context);
    return AnimatedBuilder(
      animation: widget.coordinator,
      builder: (context, _) {
        final theme = Theme.of(context);
        final outcome = widget.coordinator.latestOutcome;
        final followUps = outcome?.followUpQuestions ?? const <String>[];
        final cards = <Widget>[
          _CoConsultDetailHeader(
            coordinator: widget.coordinator,
            onStart: () => widget.onStart(context),
            onPause: () => widget.onPause(context),
            onResume: () => widget.onResume(context),
            onComplete: _handleCompleteSession,
            isCompleting: _completingSession,
            onViewSummary: null,
          ),
          const SizedBox(height: AppThemeTokens.gap),
          const AiGenerateReportButton(),
          const SizedBox(height: AppThemeTokens.gap),
          _ReportStatusNotice(status: widget.coordinator.reportStatus),
        ];

        final hasPatientAccess =
            widget.coordinator.canPatientViewReport && outcome != null;
        if (hasPatientAccess) {
          cards.add(const SizedBox(height: AppThemeTokens.gap));
          cards.add(
            _AutoProcessActionsCard(
              states: Map<_AutoProcess, _AutoProcessState>.unmodifiable(
                _autoProcessStates,
              ),
              onViewSummary: () => _openSummarySheet(_SummaryFocus.overview),
              onViewTimeline: () => _openSummarySheet(_SummaryFocus.timeline),
              onViewAll: () => _openSummarySheet(_SummaryFocus.all),
              onOpenPatientQuestions: followUps.isEmpty
                  ? null
                  : () => _openPatientQuestionsSheet(followUps),
            ),
          );
        } else {
          cards.add(const SizedBox(height: AppThemeTokens.gap));
          cards.add(
            _PatientViewLockedCard(
              status: widget.coordinator.reportStatus,
              onReview: widget.coordinator.isReportPendingReview
                  ? () async {
                      final sessionId =
                          widget.coordinator.pendingOutcome?.sessionId ??
                              widget.coordinator.lastSession?.id ??
                              'unknown';
                      final approved = await Navigator.of(context).push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (_) =>
                              DoctorReviewPage(sessionId: sessionId),
                        ),
                      );
                      if (approved == true) {
                        _showToast('Report signed and ready to share with the patient.');
                      }
                    }
                  : null,
            ),
          );
        }

        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: background,
            surfaceTintColor: Colors.transparent,
            centerTitle: false,
            title: Text(
              'Echo AI',
              style: AiTextStyles.title16(context),
            ),
            actions: [
              IconButton(
                iconSize: 22,
                padding: const EdgeInsets.all(10),
                constraints:
                    const BoxConstraints(minWidth: 40, minHeight: 40),
                color: theme.colorScheme.onSurfaceVariant,
                icon: const Icon(Icons.verified_user_outlined),
                tooltip: 'Consent & permissions',
                onPressed: () => _showSessionControlsDialog(),
              ),
              IconButton(
                iconSize: 22,
                padding: const EdgeInsets.all(10),
                constraints:
                    const BoxConstraints(minWidth: 40, minHeight: 40),
                color: theme.colorScheme.onSurfaceVariant,
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share report',
                onPressed: () => _handleShareButton(outcome),
              ),
            ],
          ),
          body: Stack(
            children: [
              ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppThemeTokens.pagePadding,
                  AppThemeTokens.pagePadding,
                  AppThemeTokens.pagePadding,
                  AppThemeTokens.pagePadding,
                ),
                itemBuilder: (context, index) => cards[index],
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppThemeTokens.gap),
                itemCount: cards.length,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSessionControlsDialog({bool autoTriggered = false}) {
    if (_sessionControlsDialogOpen) {
      return Future<void>.value();
    }
    _sessionControlsDialogOpen = true;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('Session controls'),
        content: _SessionControlsEditor(
          coordinator: widget.coordinator,
          onPermissionChanged: (value) =>
              widget.onPermissionChanged(dialogContext, value),
          onConsentChanged: (value) =>
              widget.onConsentChanged(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    ).whenComplete(() {
      _sessionControlsDialogOpen = false;
      if (autoTriggered) {
        _sessionControlsDialogShownAutomatically = true;
      }
    });
  }

  void _maybeAutoShowSessionControlsDialog() {
    if (!mounted ||
        _sessionControlsDialogShownAutomatically ||
        _sessionControlsDialogOpen) {
      return;
    }
    _showSessionControlsDialog(autoTriggered: true);
  }

  void _triggerAutoShowSessionControls() {
    if (!widget.autoShowSessionControls) return;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybeAutoShowSessionControlsDialog());
  }

  @override
  void didUpdateWidget(covariant _MyAiDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoShowSessionControls && !oldWidget.autoShowSessionControls) {
      _triggerAutoShowSessionControls();
    }
  }
}

class _CoConsultDetailHeader extends StatelessWidget {
  const _CoConsultDetailHeader({
    required this.coordinator,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    this.onComplete,
    this.onViewSummary,
    this.isCompleting = false,
  });

  final AiCoConsultCoordinator coordinator;
  final Future<void> Function() onStart;
  final Future<void> Function() onPause;
  final Future<void> Function() onResume;
  final Future<void> Function()? onComplete;
  final Future<void> Function()? onViewSummary;
  final bool isCompleting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = coordinator.status;
    final isCompleted = status == AiCoConsultListeningStatus.completed;
    final isActiveSession = status == AiCoConsultListeningStatus.listening ||
        status == AiCoConsultListeningStatus.paused;
    final timerStyle = theme.textTheme.titleMedium?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ) ??
        TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        );

    return PrimaryPanelCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _RecordControlButton(
            status: status,
            canStart: coordinator.canStartSession,
            hasConsent: coordinator.hasRecordingConsent,
            onStart: onStart,
            onPause: onPause,
            onResume: onResume,
            onBookmark: () =>
                coordinator.addBookmark(coordinator.activeListeningDuration),
            size: 64,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        'Echo AI',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ) ??
                            TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _LiveDurationText(
                      coordinator: coordinator,
                      style: timerStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _headerStatusText(status, coordinator.canStartSession),
                  style: AiTextStyles.body13(context).copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if ((onComplete != null && isActiveSession) ||
                    (isCompleted && onViewSummary != null))
                  const SizedBox(height: 12),
                if ((onComplete != null && isActiveSession) ||
                    (isCompleted && onViewSummary != null))
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (onComplete != null && isActiveSession)
                        FilledButton.tonal(
                          onPressed: isCompleting
                              ? null
                              : () async {
                                  await onComplete?.call();
                                },
                          child: isCompleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('End session'),
                        ),
                      if (isCompleted && onViewSummary != null)
                        OutlinedButton(
                          onPressed: () async {
                            await onViewSummary?.call();
                          },
                          child: const Text('View summary'),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _headerStatusText(
    AiCoConsultListeningStatus status,
    bool canStartSession,
  ) {
    switch (status) {
      case AiCoConsultListeningStatus.idle:
        return canStartSession ? 'Ready to begin' : 'Waiting for consent';
      case AiCoConsultListeningStatus.listening:
        return 'Listening';
      case AiCoConsultListeningStatus.paused:
        return 'Paused';
      case AiCoConsultListeningStatus.completed:
        return 'Completed';
    }
  }
}

class _SessionControlsEditor extends StatelessWidget {
  const _SessionControlsEditor({
    required this.coordinator,
    required this.onPermissionChanged,
    required this.onConsentChanged,
  });

  final AiCoConsultCoordinator coordinator;
  final ValueChanged<bool> onPermissionChanged;
  final ValueChanged<bool> onConsentChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: coordinator,
      builder: (context, _) {
        final theme = Theme.of(context);
        final canStart = coordinator.canStartSession;
        final needsConsent = !coordinator.hasRecordingConsent;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SettingToggle(
              label: 'Allow clinician start',
              value: coordinator.hasPermission,
              onChanged: onPermissionChanged,
            ),
            const SizedBox(height: 12),
            _SettingToggle(
              label: 'Patient consent',
              value: coordinator.hasRecordingConsent,
              onChanged: onConsentChanged,
            ),
            if (!canStart)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  needsConsent
                      ? 'Consent must be granted before recording starts.'
                      : 'Enable both toggles to allow recording.',
                  style: AiTextStyles.body13(context).copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CoConsultSummaryCard extends StatelessWidget {
  const _CoConsultSummaryCard({
    required this.outcome,
    required this.onExport,
    required this.onSave,
    required this.exporting,
    this.overviewKey,
    this.timelineKey,
    this.consentKey,
    this.transcriptKey,
    this.metadataKey,
    this.visibleSections,
  });

  final AiCoConsultOutcome outcome;
  final Future<void> Function() onExport;
  final VoidCallback onSave;
  final bool exporting;
  final GlobalKey? overviewKey;
  final GlobalKey? timelineKey;
  final GlobalKey? consentKey;
  final GlobalKey? transcriptKey;
  final GlobalKey? metadataKey;
  final Set<_SummarySectionType>? visibleSections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ) ??
        TextStyle(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Consult Summary',
                  style: titleStyle,
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  FilledButton(
                    onPressed: onSave,
                    child: const Text('Save'),
                  ),
                  OutlinedButton(
                    onPressed: exporting ? null : () => onExport(),
                    child: exporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Export'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SummarySections(
          outcome: outcome,
          overviewKey: overviewKey,
          timelineKey: timelineKey,
          consentKey: consentKey,
          transcriptKey: transcriptKey,
          metadataKey: metadataKey,
          visibleSections: visibleSections,
        ),
      ],
    );
  }
}

class _SummarySections extends StatelessWidget {
  const _SummarySections({
    required this.outcome,
    this.overviewKey,
    this.timelineKey,
    this.consentKey,
    this.transcriptKey,
    this.metadataKey,
    // ignore: unused_element_parameter
    this.visibleSections,
    // ignore: unused_element_parameter
    this.bodyStyle,
  });

  final AiCoConsultOutcome outcome;
  final TextStyle? bodyStyle;
  final GlobalKey? overviewKey;
  final GlobalKey? timelineKey;
  final GlobalKey? consentKey;
  final GlobalKey? transcriptKey;
  final GlobalKey? metadataKey;
  final Set<_SummarySectionType>? visibleSections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseBodyStyle = Theme.of(context).textTheme.bodyMedium ??
        DefaultTextStyle.of(context).style;
    final defaultStyle = baseBodyStyle.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.5,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: DefaultTextStyle(
        style: defaultStyle,
        textAlign: TextAlign.start,
        child: _ConsultSummaryBody(
          outcome: outcome,
          bodyStyle: bodyStyle ?? defaultStyle,
          overviewKey: overviewKey,
          timelineKey: timelineKey,
          consentKey: consentKey,
          transcriptKey: transcriptKey,
          metadataKey: metadataKey,
          visibleSections: visibleSections,
        ),
      ),
    );
  }
}

class _ConsultSummaryBody extends StatelessWidget {
  const _ConsultSummaryBody({
    required this.outcome,
    required this.bodyStyle,
    this.overviewKey,
    this.timelineKey,
    this.consentKey,
    this.transcriptKey,
    this.metadataKey,
    this.visibleSections,
  });

  final AiCoConsultOutcome outcome;
  final TextStyle bodyStyle;
  final GlobalKey? overviewKey;
  final GlobalKey? timelineKey;
  final GlobalKey? consentKey;
  final GlobalKey? transcriptKey;
  final GlobalKey? metadataKey;
  final Set<_SummarySectionType>? visibleSections;

  bool _shouldShow(_SummarySectionType type) {
    if (visibleSections == null) return true;
    return visibleSections!.contains(type);
  }

  Widget _wrapWithKey(GlobalKey? key, Widget child) {
    if (key == null) return child;
    return KeyedSubtree(key: key, child: child);
  }

  List<String> _splitLines(String value) {
    return value
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final headingStyle = textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.3,
        ) ??
        bodyStyle.copyWith(fontWeight: FontWeight.w600);
    final captionStyle = textTheme.bodySmall?.copyWith(height: 1.3);
    final children = <Widget>[];

    void addSection({
      GlobalKey? key,
      required String title,
      required Widget body,
    }) {
      final section = _SummarySection(
        title: title,
        body: body,
        headingStyle: headingStyle,
        bodyStyle: bodyStyle,
      );
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 16));
      }
      children.add(_wrapWithKey(key, section));
    }

    if (_shouldShow(_SummarySectionType.overview)) {
      addSection(
        key: overviewKey,
        title: 'Overview',
        body: SelectableText(
          outcome.summary,
          textAlign: TextAlign.start,
          style: bodyStyle,
        ),
      );
    }

    if (_shouldShow(_SummarySectionType.chiefComplaint)) {
      addSection(
        title: 'Chief complaint',
        body: SelectableText(
          outcome.chiefComplaint.isEmpty ? '—' : outcome.chiefComplaint,
          textAlign: TextAlign.start,
          style: bodyStyle,
        ),
      );
    }
    if (_shouldShow(_SummarySectionType.history)) {
      addSection(
        title: 'History',
        body: SelectableText(
          outcome.historySummary.isEmpty ? '—' : outcome.historySummary,
          textAlign: TextAlign.start,
          style: bodyStyle,
        ),
      );
    }
    if (_shouldShow(_SummarySectionType.diagnosis)) {
      addSection(
        title: 'Diagnosis',
        body: SelectableText(
          outcome.diagnosisSummary.isEmpty ? '—' : outcome.diagnosisSummary,
          textAlign: TextAlign.start,
          style: bodyStyle,
        ),
      );
    }
    if (_shouldShow(_SummarySectionType.recommendations)) {
      addSection(
        title: 'Recommendations',
        body: _BulletList(
          entries: _splitLines(outcome.recommendations),
          bodyStyle: bodyStyle,
        ),
      );
    }

    if (_shouldShow(_SummarySectionType.timeline)) {
      addSection(
        key: timelineKey,
        title: 'Follow-up Timeline',
        body: outcome.timeline.isEmpty
            ? Text(
                'No follow-up timeline items.',
                textAlign: TextAlign.start,
                style: bodyStyle,
              )
            : _TimelineList(
                items: outcome.timeline,
                bodyStyle: bodyStyle,
              ),
      );
    }

    if (_shouldShow(_SummarySectionType.consent)) {
      final consentEntries = <String, String>{
        'Status': outcome.consentRecord.granted ? 'Granted' : 'Revoked',
        'Recorded': formatDateTime(outcome.consentRecord.recordedAt),
        'Method': outcome.consentRecord.method,
        if (outcome.consentRecord.version != null)
          'Version': outcome.consentRecord.version!,
        if (outcome.consentRecord.notes != null)
          'Notes': outcome.consentRecord.notes!,
      };
      addSection(
        key: consentKey,
        title: 'Patient Consent',
        body: _DefinitionTable(
          entries: consentEntries,
          bodyStyle: bodyStyle,
        ),
      );
    }

    if (_shouldShow(_SummarySectionType.transcript)) {
      addSection(
        key: transcriptKey,
        title: 'Audio Transcript (ASR)',
        body: outcome.transcript.isEmpty
            ? Text(
                'No transcript available.',
                textAlign: TextAlign.start,
                style: bodyStyle,
              )
            : SelectableText(
                outcome.transcript,
                textAlign: TextAlign.start,
                style: bodyStyle,
              ),
      );
    }

    if (_shouldShow(_SummarySectionType.metadata)) {
      final metadataEntries = <String, String>{
        'Duration (seconds)':
            outcome.metadata['session_duration_seconds'] ?? 'n/a',
        'Clinician statements':
            outcome.metadata['clinician_statement_count'] ?? '0',
        'Patient statements':
            outcome.metadata['patient_statement_count'] ?? '0',
        'Transcript length': outcome.metadata['transcript_length'] ?? '0',
        if (outcome.metadata.containsKey('bookmark_count'))
          'Bookmarks': outcome.metadata['bookmark_count']!,
        if (outcome.metadata.containsKey('paused_seconds'))
          'Paused (seconds)': outcome.metadata['paused_seconds']!,
      };
      addSection(
        key: metadataKey,
        title: 'Session Metadata',
        body: _DefinitionTable(
          entries: metadataEntries,
          emptyPlaceholder: 'No additional metadata captured.',
          bodyStyle: bodyStyle,
        ),
      );
    }

    if (outcome.doctorReviewed) {
      addSection(
        title: 'Doctor Approval',
        body: _buildDoctorApprovalSection(outcome, bodyStyle),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    children.add(const SizedBox(height: 12));
    children.add(
      Text(
        'Generated ${formatDateTime(outcome.generatedAt)}',
        style: captionStyle,
        textAlign: TextAlign.start,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildDoctorApprovalSection(
    AiCoConsultOutcome outcome,
    TextStyle bodyStyle,
  ) {
    final approvalTime = outcome.doctorApprovalTime ?? outcome.generatedAt;
    final doctorName =
        outcome.doctorName ?? outcome.contactName ?? 'Dr. Clinician';
    final signature = outcome.doctorSignature;
    final signatureLabel = outcome.doctorSignatureLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reviewed and approved by: $doctorName', style: bodyStyle),
        const SizedBox(height: 4),
        Text('Approval time: ${formatDateTime(approvalTime)}',
            style: bodyStyle),
        if (signature != null && signature.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Signature:',
              style: bodyStyle.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              signature,
              height: 140,
              fit: BoxFit.fitWidth,
            ),
          ),
        ] else if (signatureLabel != null && signatureLabel.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Signature: $signatureLabel', style: bodyStyle),
        ],
      ],
    );
  }
}

class _DefinitionTable extends StatelessWidget {
  const _DefinitionTable({
    required this.entries,
    required this.bodyStyle,
    this.emptyPlaceholder,
  });

  final Map<String, String> entries;
  final TextStyle bodyStyle;
  final String? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final labelStyle = bodyStyle.copyWith(fontWeight: FontWeight.w600);
    final filtered = entries.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .toList();

    if (filtered.isEmpty) {
      if (emptyPlaceholder == null) {
        return const SizedBox.shrink();
      }
      return Text(
        emptyPlaceholder!,
        textAlign: TextAlign.start,
        style: bodyStyle,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < filtered.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == filtered.length - 1 ? 0 : 8),
            child: RichText(
              textAlign: TextAlign.start,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${filtered[i].key}: ',
                    style: labelStyle,
                  ),
                  TextSpan(
                    text: filtered[i].value,
                    style: bodyStyle,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.title,
    required this.body,
    required this.headingStyle,
    required this.bodyStyle,
  });

  final String title;
  final Widget body;
  final TextStyle headingStyle;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: headingStyle,
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 8),
        DefaultTextStyle(
          style: bodyStyle,
          textAlign: TextAlign.start,
          child: body,
        ),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({
    required this.entries,
    required this.bodyStyle,
  });

  final List<String> entries;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    final values = entries.isEmpty ? const ['—'] : entries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < values.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == values.length - 1 ? 0 : 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '•',
                    style: bodyStyle,
                    textAlign: TextAlign.start,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    values[i],
                    textAlign: TextAlign.start,
                    style: bodyStyle,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({
    required this.items,
    required this.bodyStyle,
  });

  final List<TimelineItem> items;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•',
                  style: bodyStyle,
                  textAlign: TextAlign.start,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    '${formatDateTime(item.when)} · ${item.title} — ${item.detail}${item.code != null ? ' (${item.code})' : ''}',
                    textAlign: TextAlign.start,
                    style: bodyStyle,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AutoProcessActionsCard extends StatelessWidget {
  const _AutoProcessActionsCard({
    required this.states,
    required this.onViewSummary,
    required this.onViewTimeline,
    required this.onOpenPatientQuestions,
    required this.onViewAll,
  });

  final Map<_AutoProcess, _AutoProcessState> states;
  final VoidCallback onViewSummary;
  final VoidCallback onViewTimeline;
  final VoidCallback? onOpenPatientQuestions;
  final VoidCallback onViewAll;

  bool _isEnabled(_AutoProcessState? state) {
    if (state == null) return false;
    return state == _AutoProcessState.ready ||
        state == _AutoProcessState.completed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ) ??
        TextStyle(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        );

    final summaryState = states[_AutoProcess.summary];
    final timelineState = states[_AutoProcess.timeline];
    final patientState = states[_AutoProcess.patientQuestions];

    final summaryHandler = _isEnabled(summaryState) ? onViewSummary : null;
    final timelineHandler = _isEnabled(timelineState) ? onViewTimeline : null;
    final patientHandler =
        _isEnabled(patientState) && onOpenPatientQuestions != null
            ? onOpenPatientQuestions
            : null;
    final viewAllHandler = _isEnabled(summaryState) ? onViewAll : null;

    final sessionItems = [
      _SessionOutputItem(
        label: 'Clinical Summary',
        icon: Icons.description_outlined,
        state: summaryState ?? _AutoProcessState.pending,
        onTap: summaryHandler,
      ),
      _SessionOutputItem(
        label: 'Follow-up Timeline',
        icon: Icons.timeline_outlined,
        state: timelineState ?? _AutoProcessState.pending,
        onTap: timelineHandler,
      ),
      _SessionOutputItem(
        label: 'Patient Qs',
        icon: Icons.chat_bubble_outline,
        state: patientState ?? _AutoProcessState.pending,
        onTap: patientHandler,
      ),
      _SessionOutputItem(
        label: 'View All',
        icon: Icons.view_comfy_alt_outlined,
        state: summaryState ?? _AutoProcessState.pending,
        onTap: viewAllHandler,
      ),
    ];

    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session outputs',
            style: titleStyle,
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              for (var i = 0; i < sessionItems.length; i++) ...[
                sessionItems[i],
                if (i < sessionItems.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionOutputItem extends StatelessWidget {
  const _SessionOutputItem({
    required this.label,
    required this.icon,
    required this.state,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final _AutoProcessState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool enabled = onTap != null;

    late final String statusText;
    late final IconData statusIcon;
    late final Color statusColor;

    switch (state) {
      case _AutoProcessState.pending:
        statusText = 'Pending';
        statusIcon = Icons.watch_later_outlined;
        statusColor = colorScheme.onSurfaceVariant;
        break;
      case _AutoProcessState.inProgress:
        statusText = 'Processing';
        statusIcon = Icons.autorenew;
        statusColor = colorScheme.primary;
        break;
      case _AutoProcessState.ready:
        statusText = 'Ready';
        statusIcon = Icons.play_circle_outline;
        statusColor = colorScheme.secondary;
        break;
      case _AutoProcessState.completed:
        statusText = 'Completed';
        statusIcon = Icons.check_circle_outline;
        statusColor = colorScheme.primary;
        break;
    }

    final iconColor =
        enabled ? colorScheme.primary : colorScheme.onSurfaceVariant;
    final arrowColor =
        enabled ? colorScheme.primary : colorScheme.onSurfaceVariant;
    final backgroundColor = colorScheme.surfaceContainerHighest;
    final borderColor = colorScheme.outlineVariant.withOpacity(0.4);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: iconColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ) ??
                              TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              statusIcon,
                              size: 14,
                              color: statusColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                  ) ??
                                  TextStyle(
                                    color: statusColor,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: arrowColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsultSummarySheet extends StatefulWidget {
  const _ConsultSummarySheet({
    required this.outcome,
    required this.onSave,
    required this.onExport,
    required this.exporting,
    required this.initialFocus,
    required this.visibleSections,
    this.approvalLabel,
  });

  final AiCoConsultOutcome outcome;
  final VoidCallback onSave;
  final Future<void> Function() onExport;
  final bool exporting;
  final _SummaryFocus initialFocus;
  final Set<_SummarySectionType>? visibleSections;
  final String? approvalLabel;

  @override
  State<_ConsultSummarySheet> createState() => _ConsultSummarySheetState();
}

class _ConsultSummarySheetState extends State<_ConsultSummarySheet> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _overviewKey = GlobalKey();
  final GlobalKey _timelineKey = GlobalKey();
  final GlobalKey _consentKey = GlobalKey();
  final GlobalKey _transcriptKey = GlobalKey();
  final GlobalKey _metadataKey = GlobalKey();
  bool _localExporting = false;

  @override
  void initState() {
    super.initState();
    _localExporting = widget.exporting;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToFocus(widget.initialFocus);
    });
  }

  Future<void> _scrollToFocus(_SummaryFocus focus) async {
    if (focus == _SummaryFocus.all) return;
    final target = switch (focus) {
      _SummaryFocus.overview => _overviewKey,
      _SummaryFocus.timeline => _timelineKey,
      _SummaryFocus.consent => _consentKey,
      _SummaryFocus.transcript => _transcriptKey,
      _SummaryFocus.metadata => _metadataKey,
      _SummaryFocus.all => null,
    };
    final context = target?.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      alignment: 0.08,
    );
  }

  Future<void> _handleExport() async {
    if (_localExporting) return;
    setState(() {
      _localExporting = true;
    });
    try {
      await widget.onExport();
    } finally {
      if (mounted) {
        setState(() {
          _localExporting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final handleColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.approvalLabel != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        widget.approvalLabel!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  _CoConsultSummaryCard(
                    outcome: widget.outcome,
                    onExport: _handleExport,
                    onSave: widget.onSave,
                    exporting: widget.exporting || _localExporting,
                    overviewKey: _overviewKey,
                    timelineKey: _timelineKey,
                    consentKey: _consentKey,
                    transcriptKey: _transcriptKey,
                    metadataKey: _metadataKey,
                    visibleSections: widget.visibleSections,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _PatientQuestionsSheet extends StatefulWidget {
  const _PatientQuestionsSheet({
    required this.suggestions,
    required this.initialSelection,
    required this.onSelectionChanged,
    required this.onSend,
    required this.onSkip,
  });

  final List<String> suggestions;
  final Set<int> initialSelection;
  final void Function(Set<int>) onSelectionChanged;
  final Future<void> Function(Set<int>) onSend;
  final Future<void> Function() onSkip;

  @override
  State<_PatientQuestionsSheet> createState() => _PatientQuestionsSheetState();
}

class _PatientQuestionsSheetState extends State<_PatientQuestionsSheet> {
  late final Set<int> _selected = Set<int>.from(widget.initialSelection);
  bool _submitting = false;

  void _toggle(int index, bool selected) {
    setState(() {
      if (selected) {
        _selected.add(index);
      } else {
        _selected.remove(index);
      }
    });
    widget.onSelectionChanged(Set<int>.from(_selected));
  }

  Future<void> _handleSend() async {
    if (_selected.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onSend(Set<int>.from(_selected));
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _handleSkip() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onSkip();
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final handleColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Patient Questions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ) ??
                    TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _FollowUpSuggestionsCard(
                suggestions: widget.suggestions,
                selectedIndexes: _selected,
                onToggle: _toggle,
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _FollowUpActionBar(
                hasSelection: _selected.isNotEmpty,
                onSend: () async => _handleSend(),
                onSkip: () async => _handleSkip(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowUpSuggestionsCard extends StatelessWidget {
  const _FollowUpSuggestionsCard({
    required this.suggestions,
    required this.selectedIndexes,
    required this.onToggle,
  });

  final List<String> suggestions;
  final Set<int> selectedIndexes;
  final void Function(int index, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Follow-up Suggestions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ) ??
                TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 12),
          ...List.generate(suggestions.length, (index) {
            final selected = selectedIndexes.contains(index);
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == suggestions.length - 1 ? 0 : 8,
              ),
              child: CheckboxListTile(
                value: selected,
                onChanged: (value) => onToggle(index, value ?? false),
                activeColor: Theme.of(context).colorScheme.primary,
                title: Text(
                  suggestions[index],
                  style: AiTextStyles.body13(context).copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RecordControlButton extends StatefulWidget {
  const _RecordControlButton({
    required this.status,
    required this.canStart,
    required this.hasConsent,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    this.onBookmark,
    this.size = 64,
  });

  final AiCoConsultListeningStatus status;
  final bool canStart;
  final bool hasConsent;
  final Future<void> Function() onStart;
  final Future<void> Function() onPause;
  final Future<void> Function() onResume;
  final bool Function()? onBookmark;
  final double size;

  @override
  State<_RecordControlButton> createState() => _RecordControlButtonState();
}

class _RecordControlButtonState extends State<_RecordControlButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 1.06).animate(_pulseAnimation);
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _RecordControlButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    if (widget.status == AiCoConsultListeningStatus.listening) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleLongPress() {
    final bookmark = widget.onBookmark;
    if (bookmark == null) return;
    final shouldTrigger =
        widget.status == AiCoConsultListeningStatus.listening ||
            widget.status == AiCoConsultListeningStatus.paused;
    if (!shouldTrigger) return;
    if (bookmark()) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    IconData icon;
    Widget? iconWidget;
    Color background;
    Color foreground = CupertinoColors.white;
    VoidCallback? handler;

    switch (widget.status) {
      case AiCoConsultListeningStatus.idle:
        icon = Icons.fiber_manual_record;
        background = (widget.canStart && widget.hasConsent)
            ? CupertinoColors.systemRed.resolveFrom(context)
            : theme.colorScheme.surfaceContainerHighest;
        foreground = (widget.canStart && widget.hasConsent)
            ? CupertinoColors.white
            : theme.colorScheme.onSurfaceVariant;
        handler = () => _handleStart(context);
        break;
      case AiCoConsultListeningStatus.listening:
        icon = Icons.pause;
        background = CupertinoColors.systemRed.resolveFrom(context);
        handler = () => widget.onPause();
        break;
      case AiCoConsultListeningStatus.paused:
        icon = Icons.fiber_manual_record;
        background = CupertinoColors.systemRed.resolveFrom(context);
        handler = () => widget.onResume();
        break;
      case AiCoConsultListeningStatus.completed:
        icon = Icons.stop;
        background = CupertinoColors.systemRed.resolveFrom(context);
        handler = () => _handleStart(context);
        break;
    }

    final enableBookmark = widget.onBookmark != null &&
        (widget.status == AiCoConsultListeningStatus.listening ||
            widget.status == AiCoConsultListeningStatus.paused);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final glowStrength =
              widget.status == AiCoConsultListeningStatus.listening
                  ? (0.25 + 0.35 * _pulseAnimation.value)
                  : 0.0;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: glowStrength > 0
                  ? [
                      BoxShadow(
                        color: CupertinoColors.systemRed
                            .resolveFrom(context)
                            .withValues(alpha: glowStrength * 0.35),
                        blurRadius: 18 + 6 * _pulseAnimation.value,
                      ),
                    ]
                  : null,
            ),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Material(
                color: background,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: handler,
                  onLongPress: enableBookmark ? _handleLongPress : null,
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: iconWidget ??
                        Icon(
                          icon,
                          color: foreground,
                          size: widget.size * 0.43,
                        ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleStart(BuildContext context) {
    if (!widget.hasConsent) {
      _showConsentDialog(context);
      return;
    }
    if (!widget.canStart) {
      HapticFeedback.selectionClick();
      return;
    }
    widget.onStart();
  }

  void _showConsentDialog(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Patient Consent Required'),
        content: const Text(
          'Record patient consent before starting AI co-consulting.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            isDefaultAction: true,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _LiveDurationText extends StatefulWidget {
  const _LiveDurationText({
    required this.coordinator,
    this.style,
  });

  final AiCoConsultCoordinator coordinator;
  final TextStyle? style;

  @override
  State<_LiveDurationText> createState() => _LiveDurationTextState();
}

class _LiveDurationTextState extends State<_LiveDurationText>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _duration = Duration.zero;
  late AiCoConsultListeningStatus _lastStatus;

  @override
  void initState() {
    super.initState();
    _duration = widget.coordinator.activeListeningDuration;
    _lastStatus = widget.coordinator.status;
    _ticker = createTicker(_handleTick);
    widget.coordinator.addListener(_handleCoordinatorChanged);
    _syncTicker(_lastStatus, updateDisplay: true);
  }

  void _handleTick(Duration elapsed) {
    _updateDuration();
  }

  void _handleCoordinatorChanged() {
    final status = widget.coordinator.status;
    if (status != _lastStatus) {
      _lastStatus = status;
      _syncTicker(status, updateDisplay: true);
    } else if (!_ticker.isActive) {
      _updateDuration(force: true);
    }
  }

  void _syncTicker(
    AiCoConsultListeningStatus status, {
    bool updateDisplay = false,
  }) {
    if (status == AiCoConsultListeningStatus.listening) {
      if (!_ticker.isActive) {
        _ticker.start();
      }
    } else {
      if (_ticker.isActive) {
        _ticker.stop();
      }
    }
    if (updateDisplay) {
      _updateDuration(force: true);
    }
  }

  void _updateDuration({bool force = false}) {
    final next = widget.coordinator.activeListeningDuration;
    final diff = (next.inMilliseconds - _duration.inMilliseconds).abs();
    if (force || diff >= 100) {
      if (!mounted) return;
      setState(() {
        _duration = next;
      });
    }
  }

  @override
  void didUpdateWidget(covariant _LiveDurationText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coordinator != widget.coordinator) {
      oldWidget.coordinator.removeListener(_handleCoordinatorChanged);
      _lastStatus = widget.coordinator.status;
      widget.coordinator.addListener(_handleCoordinatorChanged);
      _syncTicker(_lastStatus, updateDisplay: true);
    }
  }

  @override
  void dispose() {
    widget.coordinator.removeListener(_handleCoordinatorChanged);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDurationLabel(_duration),
      style: widget.style,
    );
  }
}

class _SettingToggle extends StatelessWidget {
  const _SettingToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AiTextStyles.body13(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        CupertinoSwitch(
          value: value,
          activeTrackColor: theme.colorScheme.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

class _FollowUpActionBar extends StatelessWidget {
  const _FollowUpActionBar({
    required this.hasSelection,
    required this.onSend,
    required this.onSkip,
  });

  final bool hasSelection;
  final Future<void> Function() onSend;
  final Future<void> Function() onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: hasSelection
                  ? () async {
                      await onSend();
                    }
                  : null,
              child: const Text('Send Selected'),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () async {
              await onSkip();
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}

String _formatDurationLabel(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

/// Mocked AI service used by the My AI tiles.
class _MockAiService {
  _MockAiService._();

  static final _MockAiService instance = _MockAiService._();

  Future<String> startListening() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return 'Listening started. Capturing consultation highlights in real time.';
  }

  Future<String> stopListening() async {
    await Future.delayed(const Duration(milliseconds: 320));
    return 'Listening stopped. Session transcript saved for analysis.';
  }

  Future<String> generateCoConsultSummary() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return '''
Co-Consult Summary
- Chief concern: Persistent shortness of breath with exertion.
- Key vitals: BP 126/82, HR 84, SpO₂ 97% on room air.
- Impression: Mild asthma flare.
- Plan: Resume daily Symbicort, schedule pulmonary follow-up in 2 weeks.
''';
  }

  Future<String> generateReport() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return '''
Visit Report
Patient: Alex Johnson

Diagnosis
- Mild intermittent asthma flare
- Seasonal allergic rhinitis

Treatment Plan
- Resume Symbicort 160/4.5 BID
- PRN Albuterol rescue inhaler
- Daily cetirizine during pollen season

Follow Up
- Pulmonary consult in 2 weeks
- Telehealth check-in in 7 days
''';
  }

  Future<String> askQuestion(String question) async {
    await Future.delayed(const Duration(milliseconds: 450));
    return '''
You asked: "$question"

AI Doctor Response
Based on the most recent consultation, the patient responded well to the adjusted inhaler regimen. Continue monitoring peak flows. Seek urgent care if nighttime symptoms worsen or rescue inhaler use exceeds twice per day.
''';
  }

  Future<List<_TimelineEntry>> buildTimeline({
    List<String> aiFollowUps = const [],
  }) async {
    await Future.delayed(const Duration(milliseconds: 380));
    final planner = PlannerService();
    final items = await planner.buildTodayPlan(aiFollowUps: aiFollowUps);
    return items
        .map(
          (item) => _TimelineEntry(
            when: item.when,
            task: item.text,
            source: item.source,
          ),
        )
        .toList();
  }

  Future<String> voiceChatStart() async {
    await Future.delayed(const Duration(milliseconds: 420));
    return 'Voice channel opened. AI is actively listening for spoken updates.';
  }

  Future<String> translateSample() async {
    await Future.delayed(const Duration(milliseconds: 500));
      return '''
Multi-language Output
- English: "Continue the inhaler twice daily."
- Español: "Continúa con el inhalador dos veces al día."
- Chinese: "Continue using the inhaler twice daily."
''';
  }

  Future<String> riskScanLastConsult() async {
    await Future.delayed(const Duration(milliseconds: 520));
    return '''
Risk Scan
- Adherence risk: Low — patient reports high medication compliance.
- Warning signs: Monitor nighttime cough frequency.
- Suggested action: Send weekly symptom survey via portal.
''';
  }
}

class _TimelineEntry {
  const _TimelineEntry({
    required this.when,
    required this.task,
    required this.source,
  });

  final DateTime when;
  final String task;
  final PlanSource source;
}

class _MyAiToolsSection extends StatelessWidget {
  const _MyAiToolsSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const primaryTiles = <_MyAiHubTileData>[
          _MyAiHubTileData(
            label: 'AI Report Generator',
            description:
                'Produce a draft clinical summary and share via mock PDF export.',
            icon: Icons.description,
            routeName: _AiReportGeneratorHubPage.routeName,
          ),
          _MyAiHubTileData(
            label: 'AI Consent',
            description:
                'Review, sign, and approve AI consult reports before sharing with patients.',
            icon: Icons.verified_user,
            routeName: AiConsentPage.routeName,
          ),
          _MyAiHubTileData(
            label: 'Ask-AI-Doctor',
            description:
                'Ask follow-up questions and get answers grounded in the last consult.',
            icon: Icons.question_answer,
            routeName: _AskAiDoctorHubPage.routeName,
          ),
          _MyAiHubTileData(
            label: 'Timeline Planner',
            description:
                'Preview medication reminders and upcoming follow-up tasks.',
            icon: Icons.schedule,
            routeName: _TimelinePlannerHubPage.routeName,
          ),
        ];

        const advancedTiles = <_MyAiHubTileData>[
          _MyAiHubTileData(
            label: 'Voice Chat AI',
            description: 'Quickly open a conversational voice channel.',
            icon: Icons.mic,
            routeName: VoiceChatPage.routeName,
          ),
          _MyAiHubTileData(
            label: 'Multi-language Support',
            description: 'Preview translations for clinician instructions.',
            icon: Icons.translate,
            routeName: InterpretPage.routeName,
          ),
          _MyAiHubTileData(
            label: 'Risk Alert',
            description:
                'Run a mock risk scan on the latest consultation notes.',
            icon: Icons.warning_amber,
            routeName: RiskAlertPage.routeName,
          ),
        ];

        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                for (final tile in primaryTiles)
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: tile == primaryTiles.last ? 0 : 12),
                    child: _MyAiHubTile(
                      data: tile,
                      onTap: () => _handleMyAiHubTap(context, tile.routeName),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Advanced tools',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                for (final tile in advancedTiles)
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: tile == advancedTiles.last ? 0 : 12),
                    child: _MyAiHubTile(
                      data: tile,
                      compact: true,
                      onTap: () => _handleMyAiHubTap(context, tile.routeName),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MyAiHubTileData {
  const _MyAiHubTileData({
    required this.label,
    required this.description,
    required this.icon,
    required this.routeName,
  });

  final String label;
  final String description;
  final IconData icon;
  final String routeName;
}

class _MyAiHubTile extends StatelessWidget {
  const _MyAiHubTile({
    required this.data,
    required this.onTap,
    this.compact = false,
  });

  final _MyAiHubTileData data;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double iconSize = compact ? 46 : 54;
    final double padding = compact ? 14 : 18;
    final Color containerColor =
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.75);
    final TextStyle? statusStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: padding - 2,
        ),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  data.icon,
                  size: compact ? 20 : 24,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.description,
                    style: statusStyle,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportStatusNotice extends StatelessWidget {
  const _ReportStatusNotice({required this.status});

  final ConsultReportStatus status;

  @override
  Widget build(BuildContext context) {
    final title = _statusTitle(status);
    final description = _statusDescription(status);
    final icon = _statusIcon(status);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppThemeTokens.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppThemeTokens.cardRadius),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.16),
              borderRadius: BorderRadius.circular(AppThemeTokens.smallRadius),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusTitle(ConsultReportStatus status) {
    switch (status) {
      case ConsultReportStatus.idle:
        return 'Awaiting AI summary';
      case ConsultReportStatus.reportPendingReview:
        return 'Doctor review required';
      case ConsultReportStatus.reportRejected:
        return 'Report flagged';
      case ConsultReportStatus.reportApproved:
        return 'Report approved';
      case ConsultReportStatus.recordingDeleted:
        return 'Recording removed';
    }
  }

  String _statusDescription(ConsultReportStatus status) {
    switch (status) {
      case ConsultReportStatus.idle:
        return 'Generate a consult summary to start the consent workflow.';
      case ConsultReportStatus.reportPendingReview:
        return 'A clinician must confirm accuracy before the patient can view this report.';
      case ConsultReportStatus.reportRejected:
        return 'Regenerate the summary once the necessary clarifications are captured.';
      case ConsultReportStatus.reportApproved:
        return 'Patients can view the report; the audio is queued for deletion.';
      case ConsultReportStatus.recordingDeleted:
        return 'Audio has already been deleted. The report is available to the patient.';
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
}

class _PatientViewLockedCard extends StatelessWidget {
  const _PatientViewLockedCard({
    required this.status,
    this.onReview,
  });

  final ConsultReportStatus status;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final message = status == ConsultReportStatus.reportPendingReview
        ? 'The report is awaiting doctor review before patients can access it.'
        : status == ConsultReportStatus.reportRejected
            ? 'This report was flagged for regeneration. Capture more context and try again.'
            : 'The report will unlock once a clinician signs off on it.';
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppThemeTokens.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppThemeTokens.cardRadius),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (status == ConsultReportStatus.reportPendingReview &&
              onReview != null) ...[
            const SizedBox(height: AppThemeTokens.gap),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                backgroundColor: theme.colorScheme.primary.withOpacity(0.16),
                foregroundColor: theme.colorScheme.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppThemeTokens.smallRadius),
                ),
              ),
              onPressed: onReview,
              icon: const Icon(Icons.visibility, size: 20),
              label: const Text('Doctor preview and sign'),
            ),
            const SizedBox(height: AppThemeTokens.gap / 2),
            Text(
              'Open the AI Consent page to review and sign the report before sharing it with the patient.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AiCoConsultHubDetailPage extends StatefulWidget {
  const _AiCoConsultHubDetailPage();

  static const String routeName = '${MyAiPage.routeName}/co_consult';

  @override
  State<_AiCoConsultHubDetailPage> createState() =>
      _AiCoConsultHubDetailPageState();
}

class _AiCoConsultHubDetailPageState extends State<_AiCoConsultHubDetailPage> {
  final _MockAiService _service = _MockAiService.instance;
  final List<String> _logs = <String>[];
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isListening = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      final result = await _service.stopListening();
      _timer?.cancel();
      setState(() {
        _isListening = false;
        _logs.insert(0, '[${_hubTimestamp()}] $result');
      });
      return;
    }
    final result = await _service.startListening();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
    setState(() {
      _elapsed = Duration.zero;
      _isListening = true;
      _logs.insert(0, '[${_hubTimestamp()}] $result');
    });
  }

  Future<void> _generateSummary() async {
    final summary = await _service.generateCoConsultSummary();
    final outcome = AiCoConsultCoordinator.instance.latestOutcome;
    if (outcome != null) {
      await aiCare_onCoConsultSummary(
        consultId: outcome.sessionId,
        summaryMarkdown: outcome.summary,
        highlights: outcome.planUpdates,
        followUps: outcome.followUpQuestions,
        rawTranscript: outcome.transcript,
        generatedAt: outcome.generatedAt,
      );
    } else {
      const fallbackHighlights = [
        'Persistent shortness of breath is stable on current inhaler.',
        'Vitals remain within normal range during consult.',
        'Reinforce nighttime symptom logging.',
      ];
      const fallbackFollowUps = [
        'Schedule spirometry within 2 weeks.',
        'Continue Symbicort twice daily.',
      ];
      await aiCare_onCoConsultSummary(
        consultId: 'mock-consult',
        summaryMarkdown: summary,
        highlights: fallbackHighlights,
        followUps: fallbackFollowUps,
      );
    }
    setState(() {
      _logs.insert(0, '[${_hubTimestamp()}] $summary');
    });
  }

  void _shareSummary() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Summary shared with care team (mock).'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _MyAiHubDetailScaffold(
      title: 'Echo AI',
      subtitle:
          'Start or stop listening to a consult and generate real-time insights.',
      actionLabel: _isListening ? 'Stop Listening' : 'Start Listening',
      onActionPressed: _toggleListening,
      secondaryActionLabel: 'Share Summary',
      onSecondaryActionPressed: _shareSummary,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Timer: ${_hubFormatDuration(_elapsed)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _generateSummary,
            icon: const Icon(Icons.summarize),
            label: const Text('Generate Summary'),
          ),
        ],
      ),
      resultChildren: _logs
          .map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SelectableText(log),
            ),
          )
          .toList(),
    );
  }
}

class _AiReportGeneratorHubPage extends StatefulWidget {
  const _AiReportGeneratorHubPage();

  static const String routeName = '${MyAiPage.routeName}/report';

  @override
  State<_AiReportGeneratorHubPage> createState() =>
      _AiReportGeneratorHubPageState();
}

class _AiReportGeneratorHubPageState extends State<_AiReportGeneratorHubPage> {
  final _MockAiService _service = _MockAiService.instance;
  late final ReportGeneratorVM _vm;
  String? _report;

  @override
  void initState() {
    super.initState();
    _vm = ReportGeneratorVM()..addListener(_handleVmChanged);
  }

  void _handleVmChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _vm
      ..removeListener(_handleVmChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _generateReport() async {
    final value = await _service.generateReport();
    setState(() => _report = value);
  }

  void _exportPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting PDF (mock).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _MyAiHubDetailScaffold(
      title: 'AI Report Generator',
      subtitle:
          'Create a draft visit summary with treatment suggestions and follow-ups.',
      actionLabel: 'Generate Report',
      onActionPressed: _generateReport,
      secondaryActionLabel: 'Export PDF',
      onSecondaryActionPressed: _exportPdf,
      resultChildren: [
        _buildReportContextPanel(context),
        const SizedBox(height: 16),
        if (_report == null)
          const Text('Tap "Generate Report" to see the latest summary.'),
        if (_report != null) SelectableText(_report!),
      ],
    );
  }

  Widget _buildReportContextPanel(BuildContext context) {
    final ctx = _vm.ctx;
    if (ctx == null || ctx.isEmpty) {
      return const Text('Generate a Co-Consult summary first.');
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SelectableText(ctx.summaryMarkdown),
        const SizedBox(height: 20),
        Text(
          'Key highlights',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildBulletList(
          ctx.highlights,
          emptyLabel: 'No highlights yet.',
        ),
        const SizedBox(height: 20),
        Text(
          'Plan / Follow-ups',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildBulletList(
          ctx.followUps,
          emptyLabel: 'No follow-ups generated yet.',
        ),
        const SizedBox(height: 16),
        Text(
          'Updated ${MaterialLocalizations.of(context).formatMediumDate(ctx.generatedAt)} '
          '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(ctx.generatedAt))}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildBulletList(
    List<String> items, {
    required String emptyLabel,
  }) {
    if (items.isEmpty) {
      return Text(emptyLabel);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AskAiDoctorHubPage extends StatefulWidget {
  const _AskAiDoctorHubPage();

  static const String routeName = '${MyAiPage.routeName}/ask';

  @override
  State<_AskAiDoctorHubPage> createState() => _AskAiDoctorHubPageState();
}

class _AskAiDoctorHubPageState extends State<_AskAiDoctorHubPage> {
  final TextEditingController _controller = TextEditingController();
  final Set<String> _selectedReferenceIds = <String>{};
  String? _response;

  @override
  void initState() {
    super.initState();
    AiCareBus.I.addListener(_handleCareContextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    AiCareBus.I.removeListener(_handleCareContextChanged);
    super.dispose();
  }

  void _handleCareContextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _askQuestion() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a question to ask the AI.')),
      );
      return;
    }

    final options = _buildReferenceOptions();
    final selected = _selectedReferencesFrom(options);
    final seed = _composeSeed(query, selected);

    setState(() {
      final contextNote = selected.isEmpty
          ? ''
          : ' with ${selected.length} context snippet${selected.length == 1 ? '' : 's'}';
      _response = 'Opening chat$contextNote with My Personal Care AI...';
    });

    await ChatDeeplink.openPersonalCareAi(context, seed: seed);
    if (!mounted) return;
    setState(
      () => _response =
          'Chat closed. Ask another question anytime to reopen the AI assistant.',
    );
  }

  void _shareAnswer() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Answer sent to patient portal (mock).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final referenceOptions = _buildReferenceOptions();
    final selectedReferences = _selectedReferencesFrom(referenceOptions);
    return _MyAiHubDetailScaffold(
      title: 'Ask-AI-Doctor',
      subtitle:
          'Submit follow-up questions and review the AI’s recommendation instantly.',
      actionLabel: 'Ask Question',
      onActionPressed: _askQuestion,
      secondaryActionLabel: 'Share Answer',
      onSecondaryActionPressed: _shareAnswer,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Type your question',
              hintText:
                  'e.g., Should the patient adjust inhaler dosage tonight?',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          _ReferenceSummary(
            references: selectedReferences,
            onRemove: (id) => setState(() => _selectedReferenceIds.remove(id)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: referenceOptions.isEmpty
                  ? null
                  : () => _openReferencePicker(referenceOptions),
              icon: const Icon(Icons.attach_file),
              label: Text(
                referenceOptions.isEmpty
                    ? 'No context available yet'
                    : 'Attach context',
              ),
            ),
          ),
        ],
      ),
      resultChildren: [
        if (_response == null)
          const Text('Chat status will appear here after you ask a question.'),
        if (_response != null) SelectableText(_response!),
      ],
    );
  }

  List<_AskReference> _buildReferenceOptions() {
    final refs = <_AskReference>[];
    final ctx = AiCareBus.I.latest;
    if (ctx != null && ctx.summaryMarkdown.trim().isNotEmpty) {
      refs.add(
        _AskReference(
          id: 'summary_${ctx.consultId}',
          title: 'Co-Consult summary',
          body: ctx.summaryMarkdown.trim(),
          source: _AskReferenceSource.summary,
          icon: Icons.receipt_long_outlined,
        ),
      );
      final highlights = ctx.highlights.take(4).toList();
      for (var i = 0; i < highlights.length; i++) {
        refs.add(
          _AskReference(
            id: 'highlight_${ctx.consultId}_$i',
            title: 'Highlight ${i + 1}',
            body: highlights[i],
            source: _AskReferenceSource.highlight,
            icon: Icons.lightbulb_outline,
          ),
        );
      }
      final followUps = ctx.followUps.take(4).toList();
      for (var i = 0; i < followUps.length; i++) {
        refs.add(
          _AskReference(
            id: 'plan_${ctx.consultId}_$i',
            title: 'Plan item ${i + 1}',
            body: followUps[i],
            source: _AskReferenceSource.plan,
            icon: Icons.task_alt_outlined,
          ),
        );
      }
      if (ctx.rawTranscript.trim().isNotEmpty) {
        refs.add(
          _AskReference(
            id: 'transcript_${ctx.consultId}',
            title: 'Transcript excerpt',
            body: ctx.rawTranscript.trim(),
            source: _AskReferenceSource.transcript,
            icon: Icons.chat_bubble_outline,
          ),
        );
      }
    }

    const chatSnippets = _ChatReferenceLibrary.aiCoachSnippets;
    for (var i = 0; i < chatSnippets.length; i++) {
      final snippet = chatSnippets[i];
      refs.add(
        _AskReference(
          id: 'chat_ai_$i',
          title: snippet.title,
          body: snippet.body,
          source: _AskReferenceSource.chat,
          icon: Icons.support_agent,
        ),
      );
    }

    return refs;
  }

  List<_AskReference> _selectedReferencesFrom(List<_AskReference> options) {
    final optionIds = options.map((ref) => ref.id).toSet();
    final missingIds =
        _selectedReferenceIds.where((id) => !optionIds.contains(id)).toList();
    if (missingIds.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() =>
            _selectedReferenceIds.removeWhere((id) => !optionIds.contains(id)));
      });
    }
    return options
        .where((ref) => _selectedReferenceIds.contains(ref.id))
        .toList();
  }

  Future<void> _openReferencePicker(List<_AskReference> options) async {
    if (options.isEmpty) return;
    final existing = Set<String>.from(_selectedReferenceIds);
    final grouped = _groupReferences(options);
    final selection = await showModalBottomSheet<Set<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final tempSelection = Set<String>.from(existing);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: Row(
                        children: [
                          Text(
                            'Reference context',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: tempSelection.isEmpty
                                ? null
                                : () {
                                    setSheetState(() => tempSelection.clear());
                                  },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          for (final entry in grouped.entries) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                              child: Text(
                                entry.key.label,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                            ...entry.value.map(
                              (ref) => Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: CheckboxListTile(
                                  value: tempSelection.contains(ref.id),
                                  onChanged: (checked) {
                                    setSheetState(() {
                                      if (checked == true) {
                                        tempSelection.add(ref.id);
                                      } else {
                                        tempSelection.remove(ref.id);
                                      }
                                    });
                                  },
                                  title: Text(ref.title),
                                  subtitle: Text(_truncate(ref.body)),
                                  secondary: Icon(ref.icon),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: FilledButton.icon(
                        onPressed: () =>
                            Navigator.of(context).pop(tempSelection),
                        icon: const Icon(Icons.check),
                        label: Text(
                          'Use ${tempSelection.length} snippet${tempSelection.length == 1 ? '' : 's'}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selection == null) return;
    setState(() {
      _selectedReferenceIds
        ..clear()
        ..addAll(selection);
    });
  }

  Map<_AskReferenceSource, List<_AskReference>> _groupReferences(
    List<_AskReference> options,
  ) {
    final grouped = <_AskReferenceSource, List<_AskReference>>{};
    for (final ref in options) {
      grouped.putIfAbsent(ref.source, () => []).add(ref);
    }
    return grouped;
  }

  String _composeSeed(String query, List<_AskReference> references) {
    if (references.isEmpty) return query;
    final buffer = StringBuffer(query);
    buffer
      ..writeln('\n\n---')
      ..writeln('Context to ground this follow-up:');
    for (final ref in references) {
      buffer.writeln('- ${ref.title}: ${ref.body}');
    }
    return buffer.toString();
  }
}

class _ReferenceSummary extends StatelessWidget {
  const _ReferenceSummary({
    required this.references,
    required this.onRemove,
  });

  final List<_AskReference> references;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (references.isEmpty) {
      return Text(
        'No context attached yet. Add a Co-Consult summary, report snippet, or chat quote so the AI knows what you are referring to.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: references
              .map(
                (ref) => InputChip(
                  avatar: Icon(ref.icon, size: 18),
                  label: Text(ref.title),
                  onDeleted: () => onRemove(ref.id),
                  tooltip: ref.body,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        ...references.map(
          (ref) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.title,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  _truncate(ref.body),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AskReference {
  const _AskReference({
    required this.id,
    required this.title,
    required this.body,
    required this.source,
    required this.icon,
  });

  final String id;
  final String title;
  final String body;
  final _AskReferenceSource source;
  final IconData icon;
}

enum _AskReferenceSource { summary, highlight, plan, transcript, chat }

extension on _AskReferenceSource {
  String get label => switch (this) {
        _AskReferenceSource.summary => 'Co-Consult summary',
        _AskReferenceSource.highlight => 'Key highlights',
        _AskReferenceSource.plan => 'Plans & follow-ups',
        _AskReferenceSource.transcript => 'Transcript excerpts',
        _AskReferenceSource.chat => 'Chat quotes',
      };
}

class _ChatReferenceLibrary {
  static const List<_ChatSnippet> aiCoachSnippets = [
    _ChatSnippet(
      title: 'Chat · Medication timing',
      body:
          'Patient: “Still waking up groggy after the evening dose.”\nAI Coach: “Let’s log energy for three mornings and shift the medication to 8:30 PM if dizziness returns.”',
    ),
    _ChatSnippet(
      title: 'Chat · Symptom recap',
      body:
          'Patient: “Night cough spiked twice this week.”\nAI Coach: “Noted. I’ll flag this in your care plan and remind you to use the spacer tonight.”',
    ),
    _ChatSnippet(
      title: 'Chat · Follow-up reminder',
      body:
          'AI Coach: “Thursday 8 PM check-in scheduled. Please share if the new inhaler routine reduced wheezing by then.”',
    ),
  ];
}

class _ChatSnippet {
  const _ChatSnippet({required this.title, required this.body});
  final String title;
  final String body;
}

String _truncate(String value, {int maxChars = 260}) {
  final trimmed = value.trim();
  if (trimmed.length <= maxChars) return trimmed;
  return '${trimmed.substring(0, maxChars)}…';
}

class _TimelinePlannerHubPage extends StatefulWidget {
  const _TimelinePlannerHubPage();

  static const String routeName = '${MyAiPage.routeName}/timeline';

  @override
  State<_TimelinePlannerHubPage> createState() =>
      _TimelinePlannerHubPageState();
}

class _TimelinePlannerHubPageState extends State<_TimelinePlannerHubPage> {
  final _MockAiService _service = _MockAiService.instance;
  List<_TimelineEntry>? _entries;
  bool _loading = false;

  Future<void> _loadTimeline() async {
    setState(() {
      _loading = true;
    });
    final aiFollowUps = AiCareBus.I.latest?.followUps ?? const <String>[];
    try {
      final items = await _service.buildTimeline(aiFollowUps: aiFollowUps);
      if (!mounted) return;
      setState(() {
        _entries = items;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _addToCalendar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Timeline events added to calendar (mock).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _MyAiHubDetailScaffold(
      title: 'Timeline Planner',
      subtitle:
          'Review suggested medication reminders and upcoming care milestones.',
      actionLabel: 'Refresh Timeline',
      onActionPressed: _loadTimeline,
      secondaryActionLabel: 'Add to Calendar',
      onSecondaryActionPressed: _addToCalendar,
      resultChildren: [
        if (_entries == null)
          const Text('Tap "Refresh Timeline" to fetch the latest schedule.'),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
        if (_entries != null && _entries!.isNotEmpty)
          ..._entries!.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(item.task),
              subtitle: Text(
                MaterialLocalizations.of(context).formatTimeOfDay(
                  TimeOfDay.fromDateTime(item.when),
                ),
              ),
              trailing: Chip(
                label: Text(_sourceLabel(item.source)),
              ),
            ),
          ),
        if (_entries != null && _entries!.isEmpty)
          const Text('No tasks found for today.'),
      ],
    );
  }

  String _sourceLabel(PlanSource source) {
    switch (source) {
      case PlanSource.goals:
        return 'goals';
      case PlanSource.prescription:
        return 'rx';
      case PlanSource.mood:
        return 'mood';
      case PlanSource.trends:
        return 'trends';
      case PlanSource.sud:
        return 'sud';
      case PlanSource.ai:
        return 'ai';
    }
  }
}

const riskInfoBannerText =
    'Risk Alert explains your risk score and what was scanned. Learn more';
const riskIntroHelpTooltip = 'About Risk Alert';
const riskIntroLearnMore = 'Learn more';
const riskIntroDismissTooltip = 'Dismiss';

class RiskAlertPage extends StatefulWidget {
  const RiskAlertPage({
    super.key,
    this.fetchNotes = fetchLatestConsultationNotes,
    this.runScan = runRiskScan,
    this.exportReport = exportRiskReport,
  });

  static const String routeName = '${MyAiPage.routeName}/risk';

  final Future<String?> Function() fetchNotes;
  final Future<RiskResult> Function(String notes) runScan;
  final Future<void> Function(RiskResult result) exportReport;

  @override
  State<RiskAlertPage> createState() => _RiskAlertPageState();
}

enum _RiskAlertViewState { loading, success, empty, error }

class _RiskAlertPageState extends State<RiskAlertPage> {
  _RiskAlertViewState _state = _RiskAlertViewState.loading;
  RiskResult? _result;
  String? _errorMessage;
  bool _isProcessing = false;
  bool _introSeen = false;
  bool _bannerDismissed = false;
  bool _introPrefsReady = false;

  @override
  void initState() {
    super.initState();
    _initIntroFlags();
    _runScan();
  }

  Future<void> _initIntroFlags() async {
    final prefs = await SharedPreferences.getInstance();
    final introSeen = prefs.getBool(kRiskIntroSeenKey) ?? false;
    final bannerDismissed =
        prefs.getBool(kRiskIntroBannerDismissedKey) ?? false;
    if (!mounted) return;
    setState(() {
      _introSeen = introSeen;
      _bannerDismissed = bannerDismissed;
      _introPrefsReady = true;
    });
    if (!_introSeen && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showRiskIntroFlow();
        }
      });
    }
  }

  Future<void> _dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kRiskIntroBannerDismissedKey, true);
    if (!mounted) return;
    setState(() {
      _bannerDismissed = true;
    });
  }

  Future<void> _runScan() async {
    setState(() {
      _state = _RiskAlertViewState.loading;
      _errorMessage = null;
      _isProcessing = true;
    });
    try {
      final notes = await widget.fetchNotes();
      if (!mounted) return;
      if (notes == null || notes.trim().isEmpty) {
        setState(() {
          _state = _RiskAlertViewState.empty;
          _result = null;
        });
        return;
      }
      final result = await widget.runScan(notes);
      if (!mounted) return;
      setState(() {
        _result = result;
        _state = _RiskAlertViewState.success;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _state = _RiskAlertViewState.error;
        _errorMessage = err.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleExport() async {
    final result = _result;
    if (result == null) return;
    try {
      await widget.exportReport(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Risk report exported.')),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export report: $err')),
      );
    }
  }

  void _openNotes() {
    Navigator.of(context).pushNamed(_AiCoConsultHubDetailPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Alert'),
        actions: [
          IconButton(
            tooltip: riskIntroHelpTooltip,
            icon: const Icon(Icons.help_outline),
            onPressed: _showRiskIntroFlow,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Evaluate the latest consult for potential risk patterns and follow-ups.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(context)),
              const SizedBox(height: 16),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_state) {
      case _RiskAlertViewState.loading:
        return _buildLoadingState(context);
      case _RiskAlertViewState.success:
        return _buildSuccessState(context);
      case _RiskAlertViewState.empty:
        return _buildEmptyState(context);
      case _RiskAlertViewState.error:
        return _buildErrorState(context);
    }
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Scanning latest consultation notes…'),
        ],
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    final result = _result!;
    final theme = Theme.of(context);
    return ListView(
      children: [
        if (_introPrefsReady && !_bannerDismissed)
          _InfoBanner(
            text: riskInfoBannerText,
            onLearnMore: _showRiskIntroFlow,
            onClose: _dismissBanner,
          ),
        Semantics(
          label:
              'Overall score ${result.overallScore} of ${result.maxScore} indicating ${result.overallLevel.name} risk',
          child: _OverallScore(
            score: result.overallScore,
            maxScore: result.maxScore,
            summary: result.summary,
            levelChip: _buildLevelChip(result.overallLevel),
            generatedLabel: 'Generated ${_formatTimestamp(result.generatedAt)}',
          ),
        ),
        const SizedBox(height: 16),
        if (result.items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No risk items were flagged in the latest scan.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else ...[
          Text(
            'Risk findings',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...result.items.map((item) => _buildRiskItemCard(context, item)),
        ],
        _ScanDetailsPanel(
          details: result.details,
          maxScore: result.maxScore,
        ),
      ],
    );
  }

  Widget _buildRiskItemCard(BuildContext context, RiskItem item) {
    final theme = Theme.of(context);
    final color = _colorForLevel(item.level);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.category,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                _buildLevelChip(item.level),
              ],
            ),
            if (item.hasTriggers) ...[
              const SizedBox(height: 8),
              Text(
                'Detected: ${item.triggers.join(', ')}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              item.suggestion,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined,
                  size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'No consultation notes found',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Create or import consult notes to enable risk scanning.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _openNotes,
                child: const Text('Go to Notes & Recordings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'Unable to complete scan',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Something went wrong. Please try again.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isProcessing ? null : _runScan,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final canExport = _state == _RiskAlertViewState.success &&
        !_isProcessing &&
        _result != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: _isProcessing ? null : _runScan,
          icon: _isProcessing
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          label: Text(_isProcessing ? 'Scanning…' : 'Re-run Scan'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: canExport ? _handleExport : null,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Export Report (PDF)'),
        ),
      ],
    );
  }

  Widget _buildLevelChip(RiskLevel level) {
    final label = switch (level) {
      RiskLevel.low => 'LOW',
      RiskLevel.medium => 'MEDIUM',
      RiskLevel.high => 'HIGH',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _colorForLevel(level).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _colorForLevel(level),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _colorForLevel(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.orangeAccent;
      case RiskLevel.high:
        return Colors.redAccent;
    }
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inMinutes < 1) return 'just now';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showRiskIntroFlow() async {
    if (!mounted) return;
    await showRiskAlertIntroFlow(
      context,
      maxScore: _result?.maxScore ?? 100,
    );
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _introSeen = prefs.getBool(kRiskIntroSeenKey) ?? false;
    });
  }
}

class _OverallScore extends StatelessWidget {
  const _OverallScore({
    required this.score,
    required this.maxScore,
    required this.summary,
    required this.levelChip,
    required this.generatedLabel,
  });

  final int score;
  final int maxScore;
  final String summary;
  final Widget levelChip;
  final String generatedLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Overall risk score',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                levelChip,
                const Spacer(),
                Tooltip(
                  message:
                      'Score $score of max $maxScore.\n0–39: Low | 40–69: Medium | 70–$maxScore: High',
                  child: const Icon(Icons.info_outline, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SegmentedBar(score: score, maxScore: maxScore),
            const SizedBox(height: 12),
            Text(
              summary,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              generatedLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.text,
    required this.onLearnMore,
    required this.onClose,
  });

  final String text;
  final VoidCallback onLearnMore;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: onLearnMore,
              child: const Text(riskIntroLearnMore),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: riskIntroDismissTooltip,
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedBar extends StatelessWidget {
  const _SegmentedBar({required this.score, required this.maxScore});

  final int score;
  final int maxScore;

  @override
  Widget build(BuildContext context) {
    final safeMax = maxScore <= 0 ? 1 : maxScore;
    final lowEnd = (39 / safeMax).clamp(0.0, 1.0);
    final medEnd = (69 / safeMax).clamp(lowEnd, 1.0);
    final pos = (score / safeMax).clamp(0.0, 1.0);

    return SizedBox(
      height: 20,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final left = (width * pos) - 6;
          final indicatorLeft = left.clamp(0.0, width <= 12 ? 0.0 : width - 12);
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Row(
                children: [
                  Container(
                    width: width * lowEnd,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.25),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(4),
                      ),
                    ),
                  ),
                  Container(
                    width: width * (medEnd - lowEnd),
                    height: 8,
                    color: Colors.orange.withOpacity(0.25),
                  ),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.25),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                left: indicatorLeft,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScanDetailsPanel extends StatelessWidget {
  const _ScanDetailsPanel({
    required this.details,
    required this.maxScore,
  });

  final List<RiskRuleDetail> details;
  final int maxScore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final earned = details
        .where((d) => d.matched)
        .fold<int>(0, (sum, d) => sum + d.weight);
    final inactiveColor = theme.colorScheme.onSurface.withOpacity(0.38);
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: ExpansionTile(
        title: const Text('Scan details'),
        subtitle: Text('Rules evaluated • $earned / $maxScore pts'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          for (final detail in details)
            ListTile(
              dense: true,
              leading: Icon(
                detail.matched
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: detail.matched ? Colors.green : inactiveColor,
              ),
              title: Text('${detail.category} (+${detail.weight})'),
              subtitle: Text(
                'Rule: ${detail.rule}\nEvidence: '
                '${detail.evidence.isEmpty ? '—' : detail.evidence.join(', ')}',
              ),
              trailing: detail.matched
                  ? const Chip(label: Text('Matched'))
                  : const Chip(label: Text('Not matched')),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Scoring scale: 0–39 Low • 40–69 Medium • 70–Max High',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyAiHubDetailScaffold extends StatelessWidget {
  const _MyAiHubDetailScaffold({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onActionPressed,
    required this.secondaryActionLabel,
    required this.onSecondaryActionPressed,
    required this.resultChildren,
    this.header,
    this.footer,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final Future<void> Function() onActionPressed;
  final String secondaryActionLabel;
  final VoidCallback onSecondaryActionPressed;
  final List<Widget> resultChildren;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (header != null) ...[
              header!,
              const SizedBox(height: 16),
            ],
            FilledButton(
              onPressed: () async {
                await onActionPressed();
              },
              child: Text(actionLabel),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: resultChildren.isEmpty
                    ? const SizedBox.shrink()
                    : ListView(
                        children: resultChildren,
                      ),
              ),
            ),
            if (footer != null) ...[
              const SizedBox(height: 16),
              footer!,
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onSecondaryActionPressed,
                child: Text(secondaryActionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _hubTimestamp() {
  final now = TimeOfDay.now();
  final hour = now.hourOfPeriod.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  final suffix = now.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $suffix';
}

void _handleMyAiHubTap(BuildContext context, String routeName) {
  switch (routeName) {
    case _AiReportGeneratorHubPage.routeName:
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ReportGeneratorPage()),
      );
      return;
    case _AskAiDoctorHubPage.routeName:
      Navigator.of(context, rootNavigator: true)
          .pushNamed(AskAiDoctorChatScreen.routeName);
      return;
    case _TimelinePlannerHubPage.routeName:
      Navigator.of(context, rootNavigator: true).pushNamed('/timeline-planner');
      return;
  }
  Navigator.of(context, rootNavigator: true).pushNamed(routeName);
}

String _hubFormatDuration(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
