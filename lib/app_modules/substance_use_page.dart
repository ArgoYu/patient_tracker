part of 'package:patient_tracker/app_modules.dart';

class SubstanceUseDisorderPage extends StatefulWidget {
  const SubstanceUseDisorderPage({
    super.key,
    this.profile,
    this.medications,
    this.vitals,
    this.nextVisit,
    this.safetyPlan,
    this.carePlan,
    this.labs,
    this.copingPlans = const <CopingPlan>[],
    required this.onCreatePlan,
    required this.onUpdatePlan,
    required this.onLaunchPlan,
    required this.onSharePlan,
  });

  final PatientProfile? profile;
  final List<RxMedication>? medications;
  final List<VitalEntry>? vitals;
  final NextVisit? nextVisit;
  final SafetyPlanData? safetyPlan;
  final CarePlan? carePlan;
  final List<LabResult>? labs;
  final List<CopingPlan> copingPlans;
  final ValueChanged<CopingPlan> onCreatePlan;
  final ValueChanged<CopingPlan> onUpdatePlan;
  final Future<void> Function(CopingPlan plan) onLaunchPlan;
  final Future<void> Function(CopingPlan plan) onSharePlan;

  @override
  State<SubstanceUseDisorderPage> createState() =>
      _SubstanceUseDisorderPageState();
}

class _SubstanceUseDisorderPageState extends State<SubstanceUseDisorderPage> {
  late List<CopingPlan> _plans;

  static PatientProfile _fallbackProfile() => PatientProfile(
        name: 'Argo (Demo)',
        patientId: 'MRN-2025-001',
        notes: 'Recovery plan active · monitor cravings and vitals',
      );

  static List<RxMedication> _fallbackMedications() => [
        RxMedication(
          name: 'Buprenorphine/Naloxone',
          dose: '8 mg SL · twice daily',
          effect: 'Prevents withdrawal while supporting recovery stability.',
          sideEffects: 'May cause dry mouth or mild headache.',
          intakeLog: [
            DateTime.now().subtract(const Duration(hours: 6)),
            DateTime.now().subtract(const Duration(hours: 18)),
          ],
        ),
        RxMedication(
          name: 'Sertraline',
          dose: '50 mg PO · morning',
          effect: 'Supports mood stabilization and reduces anxiety.',
          sideEffects: 'Occasional nausea during first two weeks.',
          intakeLog: [
            DateTime.now().subtract(const Duration(hours: 4)),
            DateTime.now().subtract(const Duration(days: 1, hours: 3)),
          ],
        ),
      ];

  static List<VitalEntry> _fallbackVitals() => [
        VitalEntry(
          date: DateTime.now().subtract(const Duration(hours: 2)),
          systolic: 116,
          diastolic: 74,
          heartRate: 68,
        ),
        VitalEntry(
          date: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
          systolic: 118,
          diastolic: 76,
          heartRate: 70,
        ),
      ];

  static NextVisit _fallbackNextVisit() => NextVisit(
        title: 'Recovery follow-up',
        when: DateTime.now().add(const Duration(days: 3, hours: 2)),
        location: 'Telehealth (secure video link)',
        doctor: 'Dr. Chen',
        mode: 'Online',
        notes: 'Review cravings journal and coping strategies.',
      );

  static CarePlan _fallbackCarePlan() => CarePlan(
        physician: 'Dr. Chen (Addiction Medicine)',
        insurance: InsuranceSummary(totalCost: 1280, covered: 980),
        medsEffects: const [
          MedEffect(
            name: 'Buprenorphine/Naloxone',
            effect: 'Reduces cravings and stabilises recovery.',
            sideEffects: 'Dry mouth, mild fatigue.',
          ),
          MedEffect(
            name: 'Sertraline 50 mg',
            effect: 'Improves baseline mood regulation.',
            sideEffects: 'Initial nausea (monitor hydration).',
          ),
        ],
        plan: const [
          'Daily cravings check-in before dinner',
          'Attend peer support call on Tuesdays',
          'Practice grounding exercise twice daily',
        ],
        expectedOutcomes: const [
          'Maintain >14 day substance-free streak',
          'Self-reported cravings intensity <4/10',
        ],
      );

  static List<LabResult> _fallbackLabs() => [
        LabResult(
          name: 'Liver function panel',
          value: 'Stable',
          unit: '',
          collectedOn: DateTime.now().subtract(const Duration(days: 12)),
          notes: 'AST / ALT within range.',
        ),
        LabResult(
          name: 'Urine toxicology',
          value: 'Negative',
          unit: '',
          collectedOn: DateTime.now().subtract(const Duration(days: 5)),
          notes: 'No opioids detected · continue monitoring.',
        ),
      ];

  @override
  void initState() {
    super.initState();
    _plans = List<CopingPlan>.from(widget.copingPlans);
  }

  String _generatePlanId() =>
      'plan-${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}';

  void _openCareChat(BuildContext context,
      {ConversationType? initialConversation}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CareTeamMessagesPage(
          initialConversation: initialConversation,
        ),
      ),
    );
  }

  Future<void> _openAskQuestionPage(BuildContext context) async {
    final selection = await showModalBottomSheet<ConversationType>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        const tiles = <_AskQuestionDestination>[
          _AskQuestionDestination(
            emoji: '💬',
            title: 'Chat with peer',
            subtitle: 'Connect anonymously with a peer supporter',
            color: Colors.blueAccent,
            conversation: ConversationType.peer,
          ),
          _AskQuestionDestination(
            emoji: '👨‍⚕️',
            title: 'Chat with doctor',
            subtitle: 'Send a note to your care physician',
            color: Colors.greenAccent,
            conversation: ConversationType.physician,
          ),
          _AskQuestionDestination(
            emoji: '👩‍⚕️',
            title: 'Chat with nurse',
            subtitle: 'Ask the nursing team for guidance',
            color: Colors.pinkAccent,
            conversation: ConversationType.nurse,
          ),
          _AskQuestionDestination(
            emoji: '👥',
            title: 'Chat with group',
            subtitle: 'Join the support circle discussion',
            color: Colors.purpleAccent,
            conversation: ConversationType.group,
          ),
        ];

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask a question',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose who you want to chat with.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 20),
                for (final destination in tiles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AskQuestionOptionTile(
                      destination: destination,
                      onTap: () => Navigator.of(sheetContext)
                          .pop(destination.conversation),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selection == null) return;
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MessagesPage(
          highlightConversation: selection,
        ),
      ),
    );
  }

  Future<void> _openAddConditionPage(BuildContext context) async {
    final condition = await Navigator.of(context).push<_ConditionDraft>(
      MaterialPageRoute(
        builder: (_) => const SubstanceAddConditionPage(),
      ),
    );
    if (!context.mounted) return;
    if (condition == null) return;
    showToast(context, 'Condition added successfully');
  }

  Future<void> _openCravingLogPage(BuildContext context) async {
    final log = await Navigator.of(context).push<_CravingLogEntry>(
      MaterialPageRoute(
        builder: (_) => const SubstanceCravingLogPage(),
      ),
    );
    if (!context.mounted) return;
    if (log == null) return;
    final triggers =
        log.triggers.isEmpty ? 'No triggers noted' : log.triggers.join(', ');
    showToast(
      context,
      'Logged craving (${log.intensity}/10 · $triggers)',
    );
  }

  Future<void> _openCopingPlanPage(BuildContext context) async {
    final planId = _generatePlanId();
    final plan = await Navigator.of(context).push<CopingPlan>(
      MaterialPageRoute(
        builder: (_) => SubstanceCopingPlanPage(
          planId: planId,
          initialTitle: 'My coping plan #${(_plans.length + 1).toString()}',
        ),
      ),
    );
    if (!context.mounted) return;
    if (plan == null) return;
    final resolvedPlan = plan.id.isEmpty
        ? plan.copyWith(id: planId, pinnedAt: DateTime.now())
        : plan.copyWith(pinnedAt: DateTime.now());
    setState(() {
      _plans.removeWhere((existing) => existing.id == resolvedPlan.id);
      _plans.insert(0, resolvedPlan);
    });
    widget.onCreatePlan(resolvedPlan);
    showToast(context, 'Coping plan "${resolvedPlan.title}" saved & pinned.');
  }

  Future<void> _editCopingPlan(BuildContext context, CopingPlan plan) async {
    final updatedPlan = await Navigator.of(context).push<CopingPlan>(
      MaterialPageRoute(
        builder: (_) => SubstanceCopingPlanPage(
          planId: plan.id,
          initialTitle: plan.title,
          initialWarningSigns: plan.warningSigns,
          initialSteps: plan.steps,
          initialContacts: plan.supportContacts,
          initialSafeLocations: plan.safeLocations,
          initialCheckInTime: plan.checkInTime,
          initialPinnedAt: plan.pinnedAt,
        ),
      ),
    );
    if (!context.mounted) return;
    if (updatedPlan == null) return;
    final resolvedPlan = updatedPlan.copyWith(
      id: plan.id,
      pinnedAt: updatedPlan.pinnedAt ?? plan.pinnedAt ?? DateTime.now(),
    );
    setState(() {
      final index =
          _plans.indexWhere((element) => element.id == resolvedPlan.id);
      if (index == -1) {
        _plans.insert(0, resolvedPlan);
      } else {
        _plans[index] = resolvedPlan;
      }
    });
    widget.onUpdatePlan(resolvedPlan);
    showToast(context, 'Coping plan "${resolvedPlan.title}" updated.');
  }

  Future<void> _showCopingSkillsSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final cs = theme.colorScheme;

        String planSummary(CopingPlan plan) {
          final parts = <String>[];
          if (plan.steps.isNotEmpty) {
            parts.add(
              '${plan.steps.length} step${plan.steps.length == 1 ? '' : 's'}',
            );
          }
          if (plan.supportContacts.isNotEmpty) {
            parts.add(
              '${plan.supportContacts.length} contact${plan.supportContacts.length == 1 ? '' : 's'}',
            );
          }
          if (plan.safeLocations.isNotEmpty) {
            parts.add(
              '${plan.safeLocations.length} safe location${plan.safeLocations.length == 1 ? '' : 's'}',
            );
          }
          return parts.isEmpty ? 'No details yet' : parts.join(' · ');
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coping skills',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start, share, or update a coping plan whenever cravings peak.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 16),
                if (_plans.isEmpty) ...[
                  Text(
                    'No coping plans yet. Create one to stay ready with your go-to skills.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    primary: false,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: cs.primary.withValues(alpha: 0.12),
                          child: const Icon(Icons.sticky_note_2_outlined),
                        ),
                        title: Text(plan.title),
                        subtitle: Text(
                          planSummary(plan),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.72),
                          ),
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          widget.onLaunchPlan(plan);
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Share plan',
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                widget.onSharePlan(plan);
                              },
                              icon: const Icon(Icons.ios_share_outlined),
                            ),
                            IconButton(
                              tooltip: 'Edit plan',
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                _editCopingPlan(context, plan);
                              },
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (context, _) =>
                        const Divider(height: 1, thickness: 0.5),
                    itemCount: _plans.length,
                  ),
                  const SizedBox(height: 20),
                ],
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _openCopingPlanPage(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create coping plan'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final patientProfile = widget.profile ?? _fallbackProfile();
    final patientMeds = widget.medications ?? _fallbackMedications();
    final patientVitals = widget.vitals ?? _fallbackVitals();
    final upcomingVisit = widget.nextVisit ?? _fallbackNextVisit();
    final activeSafetyPlan = widget.safetyPlan ?? SafetyPlanData.defaults();
    final activeCarePlan = widget.carePlan ?? _fallbackCarePlan();
    final recentLabs = widget.labs ?? _fallbackLabs();

    final quickActions = [
      {
        'icon': Icons.help_outline,
        'label': 'Ask a question',
        'onTap': () => _openAskQuestionPage(context),
      },
      {
        'icon': Icons.playlist_add,
        'label': 'Add condition',
        'onTap': () => _openAddConditionPage(context),
      },
      {
        'icon': Icons.note_add_outlined,
        'label': 'Log craving',
        'onTap': () => _openCravingLogPage(context),
      },
      {
        'icon': Icons.self_improvement_outlined,
        'label': 'Coping skills',
        'onTap': () => _showCopingSkillsSheet(context),
      },
    ];

    final metrics = [
      {
        'icon': Icons.flag_outlined,
        'title': 'Current streak',
        'subtitle': '12 days substance-free',
      },
      {
        'icon': Icons.task_alt_outlined,
        'title': "Today's focus",
        'subtitle': 'Log cravings after lunch and review coping plan',
      },
      {
        'icon': Icons.groups_3_outlined,
        'title': 'Next support circle',
        'subtitle': 'Tuesday 6:00 PM (virtual check-in)',
      },
    ];

    final contacts = [
      {
        'icon': Icons.support_agent,
        'title': 'Care coach AI',
        'subtitle': 'Check-in prompts and personalized goals',
        'color': cs.primary,
        'conversation': ConversationType.coach,
      },
      {
        'icon': Icons.local_hospital,
        'title': activeCarePlan.physician,
        'subtitle': '${upcomingVisit.doctor} · replies within 1 business day',
        'color': cs.secondary,
        'conversation': ConversationType.physician,
      },
      {
        'icon': Icons.volunteer_activism,
        'title': activeSafetyPlan.emergencyContactName.isNotEmpty
            ? activeSafetyPlan.emergencyContactName
            : 'Nursing support team',
        'subtitle': activeSafetyPlan.emergencyContactPhone.isNotEmpty
            ? 'Emergency contact · ${activeSafetyPlan.emergencyContactPhone}'
            : 'Nursing care team · weekdays 08:00-18:00',
        'color': cs.tertiary,
        'conversation': ConversationType.nurse,
      },
    ];

    final resources = [
      {
        'icon': Icons.note_alt_outlined,
        'title': 'Cravings journal',
        'subtitle': 'Capture triggers, intensity, and what you tried.',
        'action': 'Open log',
      },
      {
        'icon': Icons.lightbulb_outline,
        'title': 'Relapse prevention toolkit',
        'subtitle': 'Download worksheets to plan for challenging moments.',
        'action': 'Download',
      },
      {
        'icon': Icons.location_on_outlined,
        'title': 'Local recovery meetings',
        'subtitle': 'Find mutual support groups in your area.',
        'action': 'Browse',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Substance Use Disorder'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final tiles = <Widget>[
            for (final metric in metrics)
              _SubstanceFeatureTile(
                icon: metric['icon'] as IconData,
                title: metric['title'] as String,
                subtitle: metric['subtitle'] as String,
                accentColor: cs.primary,
              ),
            _SubstanceFeatureTile(
              icon: Icons.favorite_outline,
              title: 'Daily recovery check-in',
              subtitle:
                  'Log cravings, mood, and triggers to keep your plan up to date.',
              accentColor: cs.tertiary,
              actions: [
                FilledButton.tonal(
                  onPressed: () => showToast(
                    context,
                    'Opening daily check-in (placeholder)',
                  ),
                  child: const Text('Start check-in'),
                ),
              ],
            ),
            for (final contact in contacts)
              _SubstanceFeatureTile(
                icon: contact['icon'] as IconData,
                title: contact['title'] as String,
                subtitle: contact['subtitle'] as String,
                accentColor: (contact['color'] as Color?) ?? cs.primary,
                actions: [
                  FilledButton.tonal(
                    onPressed: () => _openCareChat(
                      context,
                      initialConversation:
                          contact['conversation'] as ConversationType?,
                    ),
                    child: const Text('Chat now'),
                  ),
                ],
              ),
            _SubstanceFeatureTile(
              icon: Icons.chat_bubble_outline,
              title: 'Care team inbox',
              subtitle: 'Catch up on replies or start a new message thread.',
              accentColor: cs.primary,
              actions: [
                FilledButton.icon(
                  onPressed: () => _openCareChat(context),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open inbox'),
                ),
              ],
            ),
            _SubstanceFeatureTile(
              icon: Icons.groups_outlined,
              title: 'Community support circles',
              subtitle:
                  'Join moderated peer conversations and share progress ideas.',
              accentColor: cs.secondary,
              actions: [
                FilledButton.tonal(
                  onPressed: () => showToast(
                    context,
                    'Opening community support circles (placeholder)',
                  ),
                  child: const Text('Browse sessions'),
                ),
              ],
            ),
            for (final res in resources)
              _SubstanceFeatureTile(
                icon: res['icon'] as IconData,
                title: res['title'] as String,
                subtitle: res['subtitle'] as String,
                accentColor: cs.primary,
                actions: [
                  FilledButton.tonal(
                    onPressed: () => showToast(
                      context,
                      'Opening ${(res['title'] as String).toLowerCase()} (placeholder)',
                    ),
                    child: Text(res['action'] as String),
                  ),
                ],
              ),
          ];

          const spacing = 20.0;
          final width = constraints.maxWidth;
          final crossAxisCount = width >= 1120
              ? 3
              : width >= 720
                  ? 2
                  : 1;
          final tileWidth = crossAxisCount == 1
              ? width
              : (width - spacing * (crossAxisCount - 1)) / crossAxisCount;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EmergencyAssistPanel(
                  onEmergencyConfirmed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EmergencyAssistPage(
                        profile: patientProfile,
                        medications: patientMeds,
                        vitals: patientVitals,
                        nextVisit: upcomingVisit,
                        safetyPlan: activeSafetyPlan,
                        carePlan: activeCarePlan,
                        labs: recentLabs,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: spacing),
                _QuickActionsStrip(actions: quickActions),
                if (_plans.isNotEmpty) ...[
                  const SizedBox(height: spacing),
                  _CopingPlansBoard(
                    plans: _plans,
                    onAddPlan: () => _openCopingPlanPage(context),
                    onLaunchPlan: (plan) => widget.onLaunchPlan(plan),
                    onSharePlan: (plan) => widget.onSharePlan(plan),
                    onEditPlan: (plan) => _editCopingPlan(context, plan),
                  ),
                ],
                const SizedBox(height: spacing),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final tile in tiles)
                      SizedBox(
                        width: crossAxisCount == 1 ? width : tileWidth,
                        child: tile,
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SubstanceAskQuestionPage extends StatefulWidget {
  const SubstanceAskQuestionPage({super.key});

  @override
  State<SubstanceAskQuestionPage> createState() =>
      _SubstanceAskQuestionPageState();
}

class _AskQuestionDestination {
  const _AskQuestionDestination({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.conversation,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final ConversationType conversation;
}

class _AskQuestionOptionTile extends StatelessWidget {
  const _AskQuestionOptionTile({
    required this.destination,
    required this.onTap,
  });

  final _AskQuestionDestination destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: destination.color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: destination.color.withValues(alpha: 0.18),
                child: Text(
                  destination.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachMessage {
  const _CoachMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;
}

class _SubstanceAskQuestionPageState extends State<SubstanceAskQuestionPage> {
  late final List<_CoachMessage> _messages;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _pendingResponse = false;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _messages = [
      _CoachMessage(
        text:
            'Hi Argo! I\'m your care coach AI. Share what you need support with today.',
        isUser: false,
        timestamp: now,
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendUserMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        _CoachMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _pendingResponse = true;
    });
    _controller.clear();
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final reply = _composeReply(text);
      setState(() {
        _messages.add(
          _CoachMessage(
            text: reply,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _pendingResponse = false;
      });
      _scrollToBottom();
    });
  }

  String _composeReply(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('craving')) {
      return 'Cravings ebb and flow. Try rating the craving from 1-10 and notice what helped last time. Breathing with a slow 4-7-8 pattern for one minute often lowers intensity.';
    }
    if (lower.contains('sleep')) {
      return 'Sleep can be a powerful stabilizer. Consider dimming lights 60 minutes before bed and review your coping plan for a calming activity.';
    }
    if (lower.contains('med') || lower.contains('side effect')) {
      return 'I noted your concern about medications. Capture the symptoms and timing, then message Dr. Chen via the care team inbox so they can review promptly.';
    }
    if (lower.contains('support') || lower.contains('alone')) {
      return 'You’re not alone. Reach out to your support contact or schedule a quick check-in. I can also help you plan a coping activity if you’d like.';
    }
    const generic = [
      'Thanks for sharing. What is one small action you can take in the next 15 minutes to support your recovery?',
      'I hear you. Let’s summarize: note your trigger, pick a coping action, and log how you feel after. I’m here for follow-up.',
      'Take a slow breath. Progress is built on small, consistent steps. Want a suggestion for a coping activity?',
    ];
    return generic[_random.nextInt(generic.length)];
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildMessageBubble(_CoachMessage message) {
    final theme = Theme.of(context);
    final alignment =
        message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final cs = theme.colorScheme;
    final bubbleColor =
        message.isUser ? cs.primary : cs.surfaceContainerHighest;
    final textColor =
        message.isUser ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.9);
    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomLeft:
                message.isUser ? const Radius.circular(18) : Radius.zero,
            bottomRight:
                message.isUser ? Radius.zero : const Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
            ),
            const SizedBox(height: 6),
            Text(
              formatTime(message.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Care coach AI'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (_, index) => _buildMessageBubble(_messages[index]),
            ),
          ),
          if (_pendingResponse)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendUserMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Ask anything about your recovery plan…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _pendingResponse ? null : _sendUserMessage,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: cs.primary,
                    ),
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionDraft {
  const _ConditionDraft({
    required this.triggerType,
    required this.description,
    required this.tags,
    required this.timestamp,
    required this.location,
    required this.riskLevel,
  });

  final String triggerType;
  final String description;
  final List<String> tags;
  final DateTime timestamp;
  final String? location;
  final double riskLevel;
}

class SubstanceAddConditionPage extends StatefulWidget {
  const SubstanceAddConditionPage({super.key});

  @override
  State<SubstanceAddConditionPage> createState() =>
      _SubstanceAddConditionPageState();
}

class _SubstanceAddConditionPageState extends State<SubstanceAddConditionPage> {
  static const List<String> _triggerTypes = [
    'Person',
    'Location',
    'Event',
    'Emotion',
    'Other',
  ];

  static const List<String> _suggestedTags = [
    'Lonely',
    'Stressed',
    'Nighttime'
  ];

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _tagInputController = TextEditingController();

  String _selectedTriggerType = _triggerTypes.first;
  final List<String> _tags = [];
  DateTime _timestamp = DateTime.now();
  double _riskLevel = 0;

  @override
  void initState() {
    super.initState();
    _prefillContext();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _prefillContext() {
    _timestamp = DateTime.now();
  }

  bool _tagExists(String value) {
    final normalized = value.toLowerCase();
    return _tags.any((tag) => tag.toLowerCase() == normalized);
  }

  void _addTag(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _tagInputController.clear();
      return;
    }
    if (_tagExists(trimmed)) {
      _tagInputController.clear();
      return;
    }
    setState(() => _tags.add(trimmed));
    _tagInputController.clear();
  }

  void _removeTag(String value) {
    setState(() => _tags.removeWhere(
          (tag) => tag.toLowerCase() == value.toLowerCase(),
        ));
  }

  Future<void> _pickDateTime() async {
    final initialDate = _timestamp;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(initialDate.year - 5),
      lastDate: DateTime(initialDate.year + 1),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return;

    setState(
      () => _timestamp = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  void _useCurrentLocation() {
    setState(() {
      _locationController.text = 'Current location';
    });
  }

  String _formatRiskLabel(double value) => value.round().toString();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final bottomPadding = 20 + media.viewInsets.bottom;
    final canSubmit = _descriptionController.text.trim().isNotEmpty;

    const sectionSpacing = 28.0;

    Widget sectionTitle(String text) => Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        );

    Widget cardSection({
      required String title,
      required List<Widget> content,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle(title),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < content.length; index++) ...[
                    if (index != 0) const SizedBox(height: 12),
                    content[index],
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    void submit() {
      final description = _descriptionController.text.trim();
      if (description.isEmpty) {
        showToast(context, 'Please describe what happened.');
        return;
      }
      Navigator.of(context).pop(
        _ConditionDraft(
          triggerType: _selectedTriggerType,
          description: description,
          tags: List<String>.from(_tags),
          timestamp: _timestamp,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          riskLevel: _riskLevel,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add condition'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log the context to better understand relapse triggers.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: sectionSpacing),
              cardSection(
                title: 'Trigger type',
                content: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final type in _triggerTypes)
                        ChoiceChip(
                          label: Text(type),
                          selected: _selectedTriggerType == type,
                          onSelected: (_) =>
                              setState(() => _selectedTriggerType = type),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: sectionSpacing),
              sectionTitle('Description'),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: TextField(
                    controller: _descriptionController,
                    autofocus: true,
                    minLines: 5,
                    maxLines: 8,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Describe what happened',
                      hintText: 'What were you doing or feeling?',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: sectionSpacing),
              cardSection(
                title: 'Tags (optional)',
                content: [
                  if (_tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in _tags)
                          InputChip(
                            label: Text(tag),
                            onDeleted: () => _removeTag(tag),
                          ),
                      ],
                    )
                  else
                    Text(
                      'No tags yet. Try the suggestions below or create your own.',
                      style: theme.textTheme.bodySmall,
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final suggestion in _suggestedTags)
                        FilterChip(
                          label: Text(suggestion),
                          selected: _tagExists(suggestion),
                          onSelected: (_) {
                            if (_tagExists(suggestion)) {
                              _removeTag(suggestion);
                            } else {
                              _addTag(suggestion);
                            }
                          },
                        ),
                    ],
                  ),
                  TextField(
                    controller: _tagInputController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: _addTag,
                    decoration: const InputDecoration(
                      labelText: 'Add a custom tag',
                      hintText: 'Press enter to add',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: sectionSpacing),
              cardSection(
                title: 'Time & location (optional)',
                content: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('When did this happen?'),
                    subtitle: Text(formatDateTime(_timestamp)),
                    trailing: const Icon(Icons.schedule_outlined),
                    onTap: _pickDateTime,
                  ),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Where did it take place?',
                      hintText: 'Add a location',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.my_location_outlined),
                        onPressed: _useCurrentLocation,
                        tooltip: 'Use current location',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: sectionSpacing),
              cardSection(
                title: 'Risk level',
                content: [
                  Text(
                    'Rate how risky this situation felt (0 = no risk, 10 = very high).',
                    style: theme.textTheme.bodySmall,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _riskLevel,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: _formatRiskLabel(_riskLevel),
                          onChanged: (value) =>
                              setState(() => _riskLevel = value),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.colorScheme.primaryContainer,
                        ),
                        child: Text(
                          _formatRiskLabel(_riskLevel),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: sectionSpacing),
              FilledButton(
                onPressed: canSubmit ? submit : null,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CravingLogEntry {
  const _CravingLogEntry({
    required this.intensity,
    required this.triggers,
    required this.note,
    required this.reachedOut,
  });

  final int intensity;
  final List<String> triggers;
  final String note;
  final bool reachedOut;
}

class SubstanceCravingLogPage extends StatefulWidget {
  const SubstanceCravingLogPage({super.key});

  @override
  State<SubstanceCravingLogPage> createState() =>
      _SubstanceCravingLogPageState();
}

class _SubstanceCravingLogPageState extends State<SubstanceCravingLogPage> {
  static const List<String> _triggerOptions = [
    'Stress',
    'Loneliness',
    'Habit',
    'Environment',
    'Physical pain',
    'Celebration',
    'Sleep issues',
  ];

  double _intensity = 4;
  final Set<String> _selectedTriggers = <String>{};
  final TextEditingController _noteController = TextEditingController();
  bool _reachedOut = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final bottomPadding = 20 + media.viewInsets.bottom;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log craving'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Intensity'),
                  Expanded(
                    child: Slider(
                      value: _intensity,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: _intensity.round().toString(),
                      onChanged: (value) => setState(() => _intensity = value),
                    ),
                  ),
                  Text(
                    _intensity.round().toString(),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Triggers',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final trigger in _triggerOptions)
                    FilterChip(
                      label: Text(trigger),
                      selected: _selectedTriggers.contains(trigger),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTriggers.add(trigger);
                          } else {
                            _selectedTriggers.remove(trigger);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'What helped or what do you need?',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reached out for support'),
                subtitle: const Text('Coach, peer, or loved one'),
                value: _reachedOut,
                onChanged: (value) => setState(() => _reachedOut = value),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  _CravingLogEntry(
                    intensity: _intensity.round(),
                    triggers: _selectedTriggers.toList(),
                    note: _noteController.text.trim(),
                    reachedOut: _reachedOut,
                  ),
                ),
                child: const Text('Save log'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubstanceCopingPlanPage extends StatefulWidget {
  const SubstanceCopingPlanPage({
    super.key,
    required this.planId,
    this.initialTitle,
    this.initialWarningSigns,
    this.initialSteps,
    this.initialContacts,
    this.initialSafeLocations,
    this.initialCheckInTime,
    this.initialPinnedAt,
  });

  final String planId;
  final String? initialTitle;
  final List<String>? initialWarningSigns;
  final List<CopingPlanStep>? initialSteps;
  final List<SupportContact>? initialContacts;
  final List<String>? initialSafeLocations;
  final TimeOfDay? initialCheckInTime;
  final DateTime? initialPinnedAt;

  @override
  State<SubstanceCopingPlanPage> createState() =>
      _SubstanceCopingPlanPageState();
}

class _SubstanceCopingPlanPageState extends State<SubstanceCopingPlanPage> {
  static const List<String> _warningSuggestions = [
    'Sleeping poorly',
    'Feeling restless or irritable',
    'Skipping meals',
    'Isolating from friends',
    'Thinking about past triggers',
  ];

  static const List<String> _stepSuggestions = [
    'Box breathing for 2 minutes',
    'Drink water and stretch',
    'Step outside for fresh air',
    'Text a support contact',
    'Journal how I feel for 5 minutes',
  ];

  static const List<String> _locationSuggestions = [
    'Dorm common area',
    'Friend’s apartment',
    'Campus wellness lounge',
    'Library quiet room',
  ];

  final TextEditingController _titleController = TextEditingController();
  final List<_WarningFieldData> _warningFields = [];
  final List<_StepFieldData> _stepFields = [];
  final List<_ContactFieldData> _contactFields = [];
  final List<_SafeLocationFieldData> _locationFields = [];
  TimeOfDay? _checkInTime;
  int _fieldCounter = 0;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle?.trim().isNotEmpty == true
        ? widget.initialTitle!.trim()
        : 'My coping plan #1';
    _checkInTime = widget.initialCheckInTime;
    final initialWarnings = widget.initialWarningSigns ?? const <String>[];
    if (initialWarnings.isEmpty) {
      _addWarningField();
    } else {
      for (final warning in initialWarnings) {
        _addWarningField(initialValue: warning);
      }
    }

    final initialSteps = widget.initialSteps ?? const <CopingPlanStep>[];
    if (initialSteps.isEmpty) {
      _addStepField(
        initialValue: _stepSuggestions.first,
        minutes: 2,
      );
      _addStepField(
        initialValue: 'Reach out to someone I trust',
        minutes: 5,
      );
    } else {
      for (final step in initialSteps) {
        final minutes = step.estimatedDuration.inMinutes.clamp(1, 30);
        _addStepField(
          initialValue: step.description,
          minutes: minutes,
        );
      }
    }

    final initialContacts = widget.initialContacts ?? const <SupportContact>[];
    if (initialContacts.isEmpty) {
      _addContactField();
    } else {
      for (final contact in initialContacts) {
        _addContactField(
          name: contact.name,
          phone: contact.phone,
        );
      }
    }

    final initialLocations = widget.initialSafeLocations ?? const <String>[];
    if (initialLocations.isEmpty) {
      _addLocationField();
    } else {
      for (final location in initialLocations) {
        _addLocationField(initialValue: location);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final warning in _warningFields) {
      warning.dispose();
    }
    for (final step in _stepFields) {
      step.dispose();
    }
    for (final contact in _contactFields) {
      contact.dispose();
    }
    for (final location in _locationFields) {
      location.dispose();
    }
    super.dispose();
  }

  String _nextFieldId() => 'field-${_fieldCounter++}';

  void _addWarningField({String initialValue = ''}) {
    _warningFields.add(
      _WarningFieldData(
        id: _nextFieldId(),
        initialValue: initialValue,
      ),
    );
  }

  void _addStepField({String initialValue = '', int minutes = 2}) {
    _stepFields.add(
      _StepFieldData(
        id: _nextFieldId(),
        initialValue: initialValue,
        minutes: minutes,
      ),
    );
  }

  void _addContactField({String name = '', String phone = ''}) {
    _contactFields.add(
      _ContactFieldData(
        id: _nextFieldId(),
        name: name,
        phone: phone,
      ),
    );
  }

  void _addLocationField({String initialValue = ''}) {
    _locationFields.add(
      _SafeLocationFieldData(
        id: _nextFieldId(),
        initialValue: initialValue,
      ),
    );
  }

  void _removeWarningAt(int index) {
    if (index < 0 || index >= _warningFields.length) return;
    if (_warningFields.length == 1) {
      _warningFields[index].controller.clear();
      return;
    }
    final removed = _warningFields.removeAt(index);
    removed.dispose();
  }

  void _removeStepAt(int index) {
    if (index < 0 || index >= _stepFields.length) return;
    if (_stepFields.length == 1) {
      _stepFields[index].controller.clear();
      _stepFields[index].minutes = 2;
      return;
    }
    final removed = _stepFields.removeAt(index);
    removed.dispose();
  }

  void _removeContactAt(int index) {
    if (index < 0 || index >= _contactFields.length) return;
    if (_contactFields.length == 1) {
      _contactFields[index].nameController.clear();
      _contactFields[index].phoneController.clear();
      return;
    }
    final removed = _contactFields.removeAt(index);
    removed.dispose();
  }

  void _removeLocationAt(int index) {
    if (index < 0 || index >= _locationFields.length) return;
    if (_locationFields.length == 1) {
      _locationFields[index].controller.clear();
      return;
    }
    final removed = _locationFields.removeAt(index);
    removed.dispose();
  }

  void _addWarningFromSuggestion(String suggestion) {
    final trimmed = suggestion.trim();
    if (trimmed.isEmpty) return;
    final exists = _warningFields.any(
      (field) =>
          field.controller.text.trim().toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) return;
    setState(() {
      _addWarningField(initialValue: trimmed);
    });
  }

  void _addStepFromSuggestion(String suggestion) {
    final trimmed = suggestion.trim();
    if (trimmed.isEmpty) return;
    final exists = _stepFields.any(
      (field) =>
          field.controller.text.trim().toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) return;
    setState(() {
      _addStepField(initialValue: trimmed, minutes: 3);
    });
  }

  void _addLocationFromSuggestion(String suggestion) {
    final trimmed = suggestion.trim();
    if (trimmed.isEmpty) return;
    final exists = _locationFields.any(
      (field) =>
          field.controller.text.trim().toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) return;
    setState(() {
      _addLocationField(initialValue: trimmed);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _checkInTime ?? const TimeOfDay(hour: 21, minute: 0),
    );
    if (picked != null) {
      setState(() => _checkInTime = picked);
    }
  }

  void _handleSave() {
    final title = _titleController.text.trim().isEmpty
        ? (widget.initialTitle?.trim().isNotEmpty == true
            ? widget.initialTitle!.trim()
            : 'My coping plan #1')
        : _titleController.text.trim();
    final warnings = _warningFields
        .map((field) => field.controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final steps = _stepFields
        .map((field) => (
              description: field.controller.text.trim(),
              minutes: field.minutes.clamp(1, 30),
            ))
        .where((entry) => entry.description.isNotEmpty)
        .map(
          (entry) => CopingPlanStep(
            description: entry.description,
            estimatedDuration: Duration(minutes: entry.minutes),
          ),
        )
        .toList();

    if (steps.isEmpty) {
      showToast(context, 'Add at least one coping step.');
      return;
    }

    final contacts = _contactFields
        .map(
          (field) => SupportContact(
            name: field.nameController.text.trim(),
            phone: field.phoneController.text.trim(),
          ),
        )
        .where((contact) => contact.name.isNotEmpty || contact.phone.isNotEmpty)
        .toList();

    final safeLocations = _locationFields
        .map((field) => field.controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    Navigator.of(context).pop(
      CopingPlan(
        id: widget.planId,
        title: title,
        warningSigns: warnings,
        steps: steps,
        supportContacts: contacts,
        safeLocations: safeLocations,
        checkInTime: _checkInTime,
        pinnedAt: widget.initialPinnedAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final bottomPadding = 20 + media.viewInsets.bottom;
    final isEditing = (widget.initialSteps?.isNotEmpty ?? false) ||
        (widget.initialWarningSigns?.isNotEmpty ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit coping plan' : 'Add coping plan'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Plan title',
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Early warning signs',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _warningFields.length; i++) ...[
                _CopingTextFieldRow(
                  key: ValueKey(_warningFields[i].id),
                  controller: _warningFields[i].controller,
                  label: 'Warning ${i + 1}',
                  onRemove: () => setState(() => _removeWarningAt(i)),
                ),
                const SizedBox(height: 12),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _addWarningField()),
                  icon: const Icon(Icons.add),
                  label: const Text('Add warning sign'),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final suggestion in _warningSuggestions)
                    ActionChip(
                      label: Text(suggestion),
                      onPressed: () => _addWarningFromSuggestion(suggestion),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Coping steps',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ReorderableListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _stepFields.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _stepFields.removeAt(oldIndex);
                    _stepFields.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final field = _stepFields[index];
                  return Card(
                    key: ValueKey(field.id),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ReorderableDragStartListener(
                                index: index,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 4),
                                  child: Icon(Icons.drag_handle),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: field.controller,
                                  decoration: InputDecoration(
                                    labelText: 'Step ${index + 1}',
                                  ),
                                  minLines: 1,
                                  maxLines: 3,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remove step',
                                onPressed: () =>
                                    setState(() => _removeStepAt(index)),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                'Estimated duration',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Slider(
                                  value: field.minutes.toDouble(),
                                  min: 1,
                                  max: 15,
                                  divisions: 14,
                                  label: '${field.minutes} min',
                                  onChanged: (value) => setState(
                                    () => field.minutes = value.round(),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '${field.minutes} min',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _addStepField()),
                  icon: const Icon(Icons.add),
                  label: const Text('Add step'),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final suggestion in _stepSuggestions)
                    ActionChip(
                      label: Text(suggestion),
                      onPressed: () => _addStepFromSuggestion(suggestion),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Support contacts',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _contactFields.length; i++) ...[
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Contact ${i + 1}',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove contact',
                              onPressed: () =>
                                  setState(() => _removeContactAt(i)),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _contactFields[i].nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _contactFields[i].phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            hintText: '+1 555 010 8899',
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            final number =
                                _contactFields[i].phoneController.text.trim();
                            if (number.isEmpty) {
                              showToast(context, 'Add a phone number first.');
                              return;
                            }
                            launchUrl(Uri(scheme: 'tel', path: number));
                          },
                          icon: const Icon(Icons.call_outlined),
                          label: const Text('Test call'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _addContactField()),
                  icon: const Icon(Icons.add),
                  label: const Text('Add contact'),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Safe spaces',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _locationFields.length; i++) ...[
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _locationFields[i].controller,
                            decoration: InputDecoration(
                              labelText: 'Location ${i + 1}',
                              hintText: 'Dormitory, clinic, or trusted home',
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Open in Maps',
                          onPressed: _locationFields[i]
                                  .controller
                                  .text
                                  .trim()
                                  .isEmpty
                              ? null
                              : () {
                                  final query = Uri.encodeComponent(
                                    _locationFields[i].controller.text.trim(),
                                  );
                                  launchUrl(
                                    Uri.parse(
                                      'https://www.google.com/maps/search/?api=1&query=$query',
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.map_outlined),
                        ),
                        IconButton(
                          tooltip: 'Remove location',
                          onPressed: () => setState(() => _removeLocationAt(i)),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _addLocationField()),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Add safe space'),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final suggestion in _locationSuggestions)
                    ActionChip(
                      label: Text(suggestion),
                      onPressed: () => _addLocationFromSuggestion(suggestion),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Daily check-in time'),
                subtitle: Text(
                  _checkInTime == null
                      ? 'Optional reminder to review your plan'
                      : _checkInTime!.format(context),
                ),
                trailing: const Icon(Icons.schedule_outlined),
                onTap: _pickTime,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _handleSave,
                icon: const Icon(Icons.push_pin_outlined),
                label: const Text('Save & Pin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CopingTextFieldRow extends StatelessWidget {
  const _CopingTextFieldRow({
    super.key,
    required this.controller,
    required this.label,
    required this.onRemove,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: label),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Remove',
          onPressed: onRemove,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class _WarningFieldData {
  _WarningFieldData({required this.id, String? initialValue})
      : controller = TextEditingController(text: initialValue ?? '');

  final String id;
  final TextEditingController controller;

  void dispose() => controller.dispose();
}

class _StepFieldData {
  _StepFieldData({
    required this.id,
    String? initialValue,
    this.minutes = 2,
  }) : controller = TextEditingController(text: initialValue ?? '');

  final String id;
  final TextEditingController controller;
  int minutes;

  void dispose() => controller.dispose();
}

class _ContactFieldData {
  _ContactFieldData({
    required this.id,
    String? name,
    String? phone,
  })  : nameController = TextEditingController(text: name ?? ''),
        phoneController = TextEditingController(text: phone ?? '');

  final String id;
  final TextEditingController nameController;
  final TextEditingController phoneController;

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
  }
}

class _SafeLocationFieldData {
  _SafeLocationFieldData({required this.id, String? initialValue})
      : controller = TextEditingController(text: initialValue ?? '');

  final String id;
  final TextEditingController controller;

  void dispose() => controller.dispose();
}

class CopingPlanExecutionPage extends StatefulWidget {
  const CopingPlanExecutionPage({
    super.key,
    required this.plan,
    this.onShare,
  });

  final CopingPlan plan;
  final Future<void> Function()? onShare;

  @override
  State<CopingPlanExecutionPage> createState() =>
      _CopingPlanExecutionPageState();
}

class _CopingPlanExecutionPageState extends State<CopingPlanExecutionPage> {
  Timer? _timer;
  int _currentStepIndex = 0;
  late Duration _remaining;
  bool _isRunning = false;

  List<CopingPlanStep> get _steps => widget.plan.steps;

  @override
  void initState() {
    super.initState();
    _remaining = _steps.isEmpty
        ? Duration.zero
        : _normalizedDuration(_steps.first.estimatedDuration);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _normalizedDuration(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds <= 0) {
      return const Duration(minutes: 1);
    }
    return Duration(seconds: seconds);
  }

  bool get _isPlanComplete {
    if (_steps.isEmpty) return true;
    return _currentStepIndex == _steps.length - 1 &&
        _remaining == Duration.zero &&
        !_isRunning;
  }

  double get _progress {
    if (_steps.isEmpty) return 1;
    final totalSteps = _steps.length;
    final currentDuration =
        _normalizedDuration(_steps[_currentStepIndex].estimatedDuration)
            .inSeconds
            .toDouble();
    final completedSteps = _currentStepIndex;
    final stepProgress = currentDuration <= 0
        ? 1.0
        : 1 - (_remaining.inSeconds / currentDuration);
    return ((completedSteps + stepProgress.clamp(0.0, 1.0)) / totalSteps)
        .clamp(0.0, 1.0);
  }

  void _startTimer() {
    if (_steps.isEmpty || _isRunning) return;
    setState(() => _isRunning = true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remaining.inSeconds <= 1) {
        timer.cancel();
        _completeCurrentStep();
        return;
      }
      setState(() {
        _remaining -= const Duration(seconds: 1);
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _completeCurrentStep() {
    if (_currentStepIndex >= _steps.length - 1) {
      setState(() {
        _remaining = Duration.zero;
        _isRunning = false;
      });
      if (mounted) {
        showToast(context, 'Nice work! You completed the plan.');
      }
      return;
    }
    setState(() {
      _currentStepIndex += 1;
      _remaining = _normalizedDuration(
        _steps[_currentStepIndex].estimatedDuration,
      );
      _isRunning = false;
    });
    _startTimer();
  }

  void _nextStep() {
    if (_steps.isEmpty) return;
    _timer?.cancel();
    if (_currentStepIndex >= _steps.length - 1) {
      _completeCurrentStep();
      return;
    }
    setState(() {
      _currentStepIndex += 1;
      _remaining = _normalizedDuration(
        _steps[_currentStepIndex].estimatedDuration,
      );
      _isRunning = false;
    });
  }

  void _previousStep() {
    if (_steps.isEmpty) return;
    _timer?.cancel();
    if (_currentStepIndex == 0) {
      setState(() {
        _remaining = _normalizedDuration(_steps.first.estimatedDuration);
        _isRunning = false;
      });
      return;
    }
    setState(() {
      _currentStepIndex -= 1;
      _remaining = _normalizedDuration(
        _steps[_currentStepIndex].estimatedDuration,
      );
      _isRunning = false;
    });
  }

  void _restartPlan() {
    if (_steps.isEmpty) return;
    _timer?.cancel();
    setState(() {
      _currentStepIndex = 0;
      _remaining = _normalizedDuration(_steps.first.estimatedDuration);
      _isRunning = false;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = widget.plan;
    final steps = _steps;

    return Scaffold(
      appBar: AppBar(
        title: Text(plan.title),
        actions: [
          if (widget.onShare != null)
            IconButton(
              tooltip: 'Share or export',
              onPressed: () => widget.onShare!(),
              icon: const Icon(Icons.ios_share_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 24),
              if (steps.isEmpty)
                _EmptyPlanMessage(onShare: widget.onShare)
              else
                _CurrentStepCard(
                  step: steps[_currentStepIndex],
                  stepIndex: _currentStepIndex,
                  totalSteps: steps.length,
                  remaining: _remaining,
                  formatDuration: _formatDuration,
                ),
              const SizedBox(height: 24),
              if (steps.isNotEmpty)
                _ControlRow(
                  isRunning: _isRunning,
                  isComplete: _isPlanComplete,
                  onStart: _startTimer,
                  onPause: _pauseTimer,
                  onNext: _nextStep,
                  onPrevious: _previousStep,
                  onRestart: _restartPlan,
                ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (plan.warningSigns.isNotEmpty)
                        _PlanSection(
                          title: 'Early warning signs',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final sign in plan.warningSigns)
                                Chip(label: Text(sign)),
                            ],
                          ),
                        ),
                      if (plan.supportContacts.isNotEmpty)
                        _PlanSection(
                          title: 'Support contacts',
                          child: Column(
                            children: [
                              for (final contact in plan.supportContacts)
                                Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: const Icon(Icons.phone_outlined),
                                    title: Text(contact.name.isEmpty
                                        ? 'Support contact'
                                        : contact.name),
                                    subtitle: Text(
                                      contact.phone.isEmpty
                                          ? 'No phone number provided'
                                          : contact.phone,
                                    ),
                                    trailing: contact.phone.trim().isEmpty
                                        ? null
                                        : IconButton(
                                            tooltip: 'Call now',
                                            onPressed: () => launchUrl(
                                              Uri(
                                                scheme: 'tel',
                                                path: contact.phone,
                                              ),
                                            ),
                                            icon: const Icon(Icons.call),
                                          ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (plan.safeLocations.isNotEmpty)
                        _PlanSection(
                          title: 'Safe spaces',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final location in plan.safeLocations)
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.map_outlined,
                                    size: 16,
                                  ),
                                  label: Text(location),
                                  onPressed: () {
                                    final query = Uri.encodeComponent(location);
                                    launchUrl(
                                      Uri.parse(
                                        'https://www.google.com/maps/search/?api=1&query=$query',
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      if (steps.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Up next',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              for (final entry in steps.asMap().entries.where(
                                    (entry) => entry.key > _currentStepIndex,
                                  ))
                                Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      radius: 14,
                                      child: Text('${entry.key + 1}'),
                                    ),
                                    title: Text(entry.value.description),
                                    subtitle: Text(
                                      '${entry.value.estimatedDuration.inMinutes} min',
                                    ),
                                    onTap: () {
                                      _timer?.cancel();
                                      setState(() {
                                        _currentStepIndex = entry.key;
                                        _remaining = _normalizedDuration(
                                          entry.value.estimatedDuration,
                                        );
                                        _isRunning = false;
                                      });
                                    },
                                  ),
                                ),
                              if (_currentStepIndex >= steps.length - 1)
                                Text(
                                  'You are on the final step.',
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentStepCard extends StatelessWidget {
  const _CurrentStepCard({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.remaining,
    required this.formatDuration,
  });

  final CopingPlanStep step;
  final int stepIndex;
  final int totalSteps;
  final Duration remaining;
  final String Function(Duration) formatDuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step ${stepIndex + 1} of $totalSteps',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                step.description,
                key: ValueKey(step.description),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.timer_outlined),
                const SizedBox(width: 8),
                Text(
                  '${formatDuration(remaining)} remaining',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.isRunning,
    required this.isComplete,
    required this.onStart,
    required this.onPause,
    required this.onNext,
    required this.onPrevious,
    required this.onRestart,
  });

  final bool isRunning;
  final bool isComplete;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton.icon(
          onPressed: isComplete ? onRestart : (isRunning ? onPause : onStart),
          icon: Icon(isComplete
              ? Icons.refresh
              : (isRunning ? Icons.pause : Icons.play_arrow)),
          label: Text(isComplete ? 'Restart' : (isRunning ? 'Pause' : 'Start')),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: onPrevious,
          icon: const Icon(Icons.navigate_before),
          label: const Text('Back'),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: onNext,
          icon: const Icon(Icons.navigate_next),
          label: const Text('Next'),
        ),
      ],
    );
  }
}

class _PlanSection extends StatelessWidget {
  const _PlanSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EmptyPlanMessage extends StatelessWidget {
  const _EmptyPlanMessage({this.onShare});

  final Future<void> Function()? onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No steps in this coping plan yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Add steps so you can launch the guided mode.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (onShare != null)
              OutlinedButton.icon(
                onPressed: () => onShare!(),
                icon: const Icon(Icons.ios_share_outlined),
                label: const Text('Share plan details'),
              ),
          ],
        ),
      ),
    );
  }
}

class _CopingPlansBoard extends StatelessWidget {
  const _CopingPlansBoard({
    required this.plans,
    required this.onAddPlan,
    required this.onLaunchPlan,
    required this.onSharePlan,
    required this.onEditPlan,
  });

  final List<CopingPlan> plans;
  final Future<void> Function() onAddPlan;
  final Future<void> Function(CopingPlan plan) onLaunchPlan;
  final Future<void> Function(CopingPlan plan) onSharePlan;
  final Future<void> Function(CopingPlan plan) onEditPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Glass(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My coping plans',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap a plan to launch the guided mode or edit and share details.',
                      style: textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => onAddPlan(),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < plans.length; index++) ...[
            _CopingPlanTile(
              plan: plans[index],
              onLaunch: () => onLaunchPlan(plans[index]),
              onShare: () => onSharePlan(plans[index]),
              onEdit: () => onEditPlan(plans[index]),
            ),
            if (index != plans.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Divider(
                  height: 1,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CopingPlanTile extends StatelessWidget {
  const _CopingPlanTile({
    required this.plan,
    required this.onLaunch,
    required this.onShare,
    required this.onEdit,
  });

  final CopingPlan plan;
  final Future<void> Function() onLaunch;
  final Future<void> Function() onShare;
  final Future<void> Function() onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final timeOfDay = plan.checkInTime == null
        ? null
        : MaterialLocalizations.of(context).formatTimeOfDay(
            plan.checkInTime!,
            alwaysUse24HourFormat: false,
          );
    final warningPreview = plan.warningSigns.take(2).toList();
    final contactsPreview = plan.supportContacts.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onLaunch(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.push_pin_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (timeOfDay != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Daily check-in at $timeOfDay',
                          style: textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                      if (plan.warningSigns.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final sign in warningPreview)
                              Chip(
                                label: Text(sign),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                              ),
                            if (plan.warningSigns.length >
                                warningPreview.length)
                              Chip(
                                label: Text(
                                  '+${plan.warningSigns.length - warningPreview.length} more',
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                              ),
                          ],
                        ),
                      ],
                      if (plan.supportContacts.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Support contacts',
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final contact in contactsPreview)
                              contact.phone.trim().isEmpty
                                  ? Chip(
                                      label: Text(contact.name),
                                    )
                                  : ActionChip(
                                      avatar: const Icon(
                                        Icons.phone_forwarded_outlined,
                                        size: 16,
                                      ),
                                      onPressed: () => launchUrl(
                                        Uri(
                                          scheme: 'tel',
                                          path: contact.phone,
                                        ),
                                      ),
                                      label: Text(contact.name),
                                    ),
                            if (plan.supportContacts.length >
                                contactsPreview.length)
                              Chip(
                                label: Text(
                                  '+${plan.supportContacts.length - contactsPreview.length} more',
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (plan.safeLocations.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Safe spaces',
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final location in plan.safeLocations.take(3))
                              ActionChip(
                                avatar: const Icon(
                                  Icons.map_outlined,
                                  size: 16,
                                ),
                                onPressed: () {
                                  final query = Uri.encodeComponent(location);
                                  launchUrl(
                                    Uri.parse(
                                      'https://www.google.com/maps/search/?api=1&query=$query',
                                    ),
                                  );
                                },
                                label: Text(location),
                              ),
                            if (plan.safeLocations.length > 3)
                              Chip(
                                label: Text(
                                  '+${plan.safeLocations.length - 3} more',
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton(
              onPressed: () => onLaunch(),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
              ),
              child: const Text('Launch'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => onEdit(),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Share or export',
              onPressed: () => onShare(),
              icon: const Icon(Icons.ios_share_outlined),
            ),
          ],
        ),
      ],
    );
  }
}

/// ===================== Calendar =====================

class _QuickActionsStrip extends StatelessWidget {
  const _QuickActionsStrip({
    required this.actions,
  });

  final List<Map<String, Object>> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 12.0;
            const minTileWidth = 160.0;
            var maxWidth = constraints.maxWidth;
            if (!maxWidth.isFinite) {
              final size = MediaQuery.of(context).size;
              maxWidth = size.width - 32;
            }
            int perRow = math.max(
              1,
              ((maxWidth + spacing) / (minTileWidth + spacing)).floor(),
            );
            double tileWidth = perRow == 1
                ? maxWidth
                : (maxWidth - spacing * (perRow - 1)) / perRow;
            if (!tileWidth.isFinite || tileWidth <= 0) {
              tileWidth = minTileWidth;
            }
            if (maxWidth.isFinite && maxWidth > 0) {
              tileWidth = tileWidth.clamp(0.0, maxWidth);
            }

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (var index = 0; index < actions.length; index++)
                  _QuickActionButton(
                    icon: actions[index]['icon'] as IconData,
                    label: actions[index]['label'] as String,
                    onTap: actions[index]['onTap'] as VoidCallback?,
                    color: Color.lerp(
                          cs.primary,
                          cs.secondary,
                          actions.length <= 1
                              ? 0.0
                              : index / (actions.length - 1),
                        ) ??
                        cs.primary,
                    width: tileWidth,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SubstanceFeatureTile extends StatelessWidget {
  const _SubstanceFeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accentColor,
    this.actions,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? accentColor;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = accentColor ?? cs.primary;

    return Glass(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.16),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.72),
              ),
            ),
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.width,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Ink(
          width: width,
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.65),
                color.withValues(alpha: 0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                child: Icon(icon, color: Colors.white, size: 15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyAssistPanel extends StatefulWidget {
  const _EmergencyAssistPanel({
    required this.onEmergencyConfirmed,
  });

  final VoidCallback onEmergencyConfirmed;

  @override
  State<_EmergencyAssistPanel> createState() => _EmergencyAssistPanelState();
}

class _EmergencyAssistPanelState extends State<_EmergencyAssistPanel>
    with SingleTickerProviderStateMixin {
  static const Duration _holdDuration = Duration(seconds: 5);

  double _sliderValue = 0;
  bool _triggered = false;
  bool _isHolding = false;
  Timer? _holdTimer;
  Timer? _alarmTimer;
  OverlayEntry? _overlayEntry;
  late final AnimationController _holdController;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: _holdDuration,
    );
  }

  @override
  void dispose() {
    _cancelHoldSequence(updateState: false);
    _holdController.dispose();
    super.dispose();
  }

  void _handleSlide(double value) {
    final clamped = value.clamp(0.0, 1.0);
    if (!_triggered) {
      setState(() => _sliderValue = clamped);
    }
    if (clamped >= 0.99) {
      if (!_isHolding && _holdTimer == null) {
        _startHoldSequence();
      }
    } else {
      if (_isHolding || _holdTimer != null) {
        _cancelHoldSequence();
      }
    }
  }

  void _handleSlideEnd(double value) {
    if (_isHolding || _holdTimer != null) {
      _cancelHoldSequence();
    } else if (mounted) {
      setState(() => _sliderValue = 0);
    }
  }

  void _startHoldSequence() {
    final overlayState = Overlay.of(context, rootOverlay: true);
    setState(() {
      _sliderValue = 1;
      _isHolding = true;
    });
    _holdController.forward(from: 0);
    _insertOverlay(overlayState);
    _alarmTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      SystemSound.play(SystemSoundType.alert);
    });
    _holdTimer = Timer(_holdDuration, _completeEmergency);
  }

  void _completeEmergency() {
    _alarmTimer?.cancel();
    _alarmTimer = null;
    _holdController.stop();
    _holdController.value = 1;
    _removeOverlay();
    _holdTimer?.cancel();
    _holdTimer = null;
    setState(() {
      _triggered = true;
      _isHolding = false;
      _sliderValue = 0;
    });
    widget.onEmergencyConfirmed();
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _triggered = false);
      }
    });
  }

  void _cancelHoldSequence({bool updateState = true}) {
    _holdTimer?.cancel();
    _holdTimer = null;
    _alarmTimer?.cancel();
    _alarmTimer = null;
    _holdController.stop();
    _holdController.value = 0;
    _removeOverlay();
    if (updateState && mounted) {
      setState(() {
        _isHolding = false;
        _sliderValue = 0;
      });
    }
  }

  void _insertOverlay(OverlayState overlay) {
    _removeOverlay();
    final entry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        return Positioned.fill(
          child: AnimatedBuilder(
            animation: _holdController,
            builder: (_, __) {
              final remainingSeconds =
                  (_holdDuration.inSeconds * (1 - _holdController.value))
                      .clamp(0.0, _holdDuration.inSeconds.toDouble());
              return Container(
                color: cs.error.withValues(alpha: 0.92),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emergency, color: cs.onError, size: 76),
                      const SizedBox(height: 20),
                      Text(
                        'Emergency mode starting soon',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: cs.onError,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 220,
                        child: LinearProgressIndicator(
                          value: _holdController.value.clamp(0.0, 1.0),
                          backgroundColor: cs.onError.withValues(alpha: 0.25),
                          valueColor: AlwaysStoppedAnimation<Color>(cs.onError),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Keep holding for ${remainingSeconds.ceil()}s',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: cs.onError,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    overlay.insert(entry);
    _overlayEntry = entry;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final remainingSeconds =
        (_holdDuration.inSeconds * (1 - _holdController.value)).ceil();

    final statusText = _triggered
        ? 'Emergency activated'
        : _isHolding
            ? 'Keep holding for ${remainingSeconds}s to trigger assistance'
            : 'Slide and hold for 5 seconds to enter emergency assist';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            cs.error.withValues(alpha: 0.92),
            cs.error.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.error.withValues(alpha: 0.24),
            offset: const Offset(0, 18),
            blurRadius: 28,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: cs.onError.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.emergency,
                  color: cs.onError,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Emergency assist',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: cs.onError,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.swipe_right_alt,
                color: cs.onError,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: cs.onError,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              decoration: BoxDecoration(
                color: cs.onError.withValues(alpha: 0.12),
              ),
              height: 58,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 58,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 24,
                    pressedElevation: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                  inactiveTrackColor: Colors.transparent,
                  activeTrackColor: cs.onError.withValues(alpha: 0.2),
                  thumbColor: cs.onError,
                ),
                child: Slider(
                  value: _sliderValue,
                  min: 0,
                  max: 1,
                  onChanged: _handleSlide,
                  onChangeEnd: _handleSlideEnd,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
