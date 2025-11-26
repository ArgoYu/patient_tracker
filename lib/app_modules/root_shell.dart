part of 'package:patient_tracker/app_modules.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _CustomShortcutDefinition {
  const _CustomShortcutDefinition({
    required this.id,
    required this.navLabel,
    required this.settingsLabel,
    required this.description,
    required this.icon,
    required this.selectedIcon,
  });

  final int id;
  final String navLabel;
  final String settingsLabel;
  final String description;
  final IconData icon;
  final IconData selectedIcon;
}

const List<_CustomShortcutDefinition> _customShortcutOptions =
    <_CustomShortcutDefinition>[
  _CustomShortcutDefinition(
    id: 1,
    navLabel: 'Care',
    settingsLabel: 'My care plan',
    description: 'Review care plan details and safety resources.',
    icon: Icons.health_and_safety_outlined,
    selectedIcon: Icons.health_and_safety,
  ),
  _CustomShortcutDefinition(
    id: 2,
    navLabel: 'Calendar',
    settingsLabel: 'Calendar & visits',
    description: 'Open upcoming appointments and visit history.',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
  ),
  _CustomShortcutDefinition(
    id: 3,
    navLabel: 'Alerts',
    settingsLabel: 'Notifications center',
    description: 'See reminders, alerts, and mood tracking prompts.',
    icon: Icons.notifications_none,
    selectedIcon: Icons.notifications,
  ),
  _CustomShortcutDefinition(
    id: 4,
    navLabel: 'Meditate',
    settingsLabel: 'Mindfulness',
    description: 'Start a breathing and focus session right away.',
    icon: Icons.self_improvement_outlined,
    selectedIcon: Icons.self_improvement,
  ),
  _CustomShortcutDefinition(
    id: 5,
    navLabel: 'Games',
    settingsLabel: 'Mini games arcade',
    description: 'Jump into a calming mini game session.',
    icon: Icons.videogame_asset_outlined,
    selectedIcon: Icons.videogame_asset,
  ),
  _CustomShortcutDefinition(
    id: 6,
    navLabel: 'Learn',
    settingsLabel: 'Education hub',
    description: 'Read curated care articles and resources.',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book,
  ),
];

const int _kCustomNoneChoice = -1;

_CustomShortcutDefinition _shortcutById(int id) =>
    _customShortcutOptions.firstWhere(
      (opt) => opt.id == id,
      orElse: () => _customShortcutOptions.first,
    );

enum _CopingPlanShareAction { shareText, exportPdf }

const _kDiscoveryPrefKey = 'discovery_completed';
const String _kGuestAccountId = 'guest';

String _accountKeyFor(UserAccount? account) =>
    account?.id ?? _kGuestAccountId;

String _discoveryKeyFor(String accountId) =>
    '${_kDiscoveryPrefKey}_$accountId';

class _RootShellState extends State<RootShell> {
  static const int _kTabHome = 0;
  static const int _kTabChat = 1;
  static const int _kTabMyAi = 2;
  static const int _kTabCustom = 3;
  static const int _kTabMore = 4;

  late int idx;
  int? _customDestination;
  bool _customSelectionMade = false;
  bool _showFeatureDiscovery = false;
  late final AiCoConsultCoordinator _coConsultCoordinator =
      AiCoConsultCoordinator.instance;

  // Tabs: home, chat, My AI, custom, more
  final List<GlobalKey<NavigatorState>> _tabKeys =
      List.generate(5, (_) => GlobalKey<NavigatorState>());

  GlobalKey<NavigatorState> get _currentKey => _tabKeys[idx];

  // Push into the current tab's navigator
  Future<T?> _pushCurrent<T>(Widget page) {
    final navigatorState = _currentKey.currentState;
    final navigatorContext = _currentKey.currentContext;

    final route = MaterialPageRoute<T>(builder: (_) => page);

    if (navigatorState != null) {
      return navigatorState.push(route);
    }

    if (navigatorContext != null) {
      return Navigator.of(navigatorContext).push(route);
    }

    return Navigator.of(context).push(route);
  }

  late AccountData _accountData;
  late final ValueListenable<UserAccount?> _accountListenable;
  late final VoidCallback _accountListener;
  String _currentAccountId = _accountKeyFor(null);

  List<Goal> get goals => _accountData.goals;
  List<RxMedication> get meds => _accountData.meds;
  int get feelingsScore => _accountData.feelingsScore;
  set feelingsScore(int value) => _accountData.feelingsScore = value;
  List<FeelingEntry> get feelingHistory => _accountData.feelingHistory;
  CarePlan get carePlan => _accountData.carePlan;
  set carePlan(CarePlan value) => _accountData.carePlan = value;
  List<ScheduleItem> get schedule => _accountData.schedule;
  PatientProfile get profile => _accountData.profile;
  set profile(PatientProfile value) => _accountData.profile = value;
  List<HomePanel> get homeOrder => _accountData.homeOrder;
  List<VitalEntry> get vitalHistory => _accountData.vitalHistory;
  List<LabResult> get labResults => _accountData.labResults;
  NextVisit get nextVisit => _accountData.nextVisit;
  SafetyPlanData get safetyPlan => _accountData.safetyPlan;
  set safetyPlan(SafetyPlanData value) => _accountData.safetyPlan = value;
  List<AppNotification> get notifications => _accountData.notifications;
  List<CopingPlan> get copingPlans => _accountData.copingPlans;
  Map<MealSlot, List<MealOption>> get mealMenu => _accountData.mealMenu;
  Map<MealSlot, int> get mealSelections => _accountData.mealSelections;
  Map<MealSlot, TimeOfDay> get mealDeliveryWindows =>
      _accountData.mealDeliveryWindows;
  Set<MealSlot> get completedMeals => _accountData.completedMeals;
  String get mealNotes => _accountData.mealNotes;
  set mealNotes(String value) => _accountData.mealNotes = value;

  void _selectMealOption(MealSlot slot, int index) {
    setState(() {
      mealSelections[slot] = index;
      completedMeals.remove(slot);
    });
  }

  void _updateMealDelivery(MealSlot slot, TimeOfDay time) {
    setState(() {
      mealDeliveryWindows[slot] = time;
    });
  }

  void _toggleMealCompleted(MealSlot slot, bool value) {
    setState(() {
      if (value) {
        completedMeals.add(slot);
      } else {
        completedMeals.remove(slot);
      }
    });
  }

  void _updateMealNotes(String notes) {
    setState(() {
      mealNotes = notes;
    });
  }

  void _addCopingPlan(CopingPlan plan) {
    setState(() {
      final pinned = plan.copyWith(pinnedAt: DateTime.now());
      copingPlans.removeWhere((existing) => existing.id == pinned.id);
      copingPlans.insert(0, pinned);
    });
  }

  void _replaceCopingPlan(CopingPlan plan) {
    setState(() {
      final index = copingPlans.indexWhere((element) => element.id == plan.id);
      if (index == -1) {
        copingPlans.insert(0, plan);
      } else {
        copingPlans[index] = plan;
      }
    });
  }

  Future<void> _launchCopingPlan(CopingPlan plan) {
    return _pushCurrent(
      CopingPlanExecutionPage(
        plan: plan,
        onShare: () => _shareCopingPlan(plan),
      ),
    );
  }

  Future<void> _shareCopingPlan(CopingPlan plan) async {
    final shareContext = _currentKey.currentContext ?? context;
    final planTitle = plan.title;
    final action = await showModalBottomSheet<_CopingPlanShareAction>(
      context: shareContext,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share "$planTitle"',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.sms_outlined),
                  title: const Text('Share summary'),
                  subtitle: const Text('Send a text version via chat or email'),
                  onTap: () => Navigator.of(sheetContext)
                      .pop(_CopingPlanShareAction.shareText),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: const Text('Export PDF'),
                  subtitle: const Text('Download or share a printable copy'),
                  onTap: () => Navigator.of(sheetContext)
                      .pop(_CopingPlanShareAction.exportPdf),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null) return;

    switch (action) {
      case _CopingPlanShareAction.shareText:
        await _shareCopingPlanAsText(plan);
        break;
      case _CopingPlanShareAction.exportPdf:
        await _exportCopingPlanPdf(plan);
        break;
    }
  }

  Future<void> _shareCopingPlanAsText(CopingPlan plan) async {
    final currentContext = _currentKey.currentContext ?? context;
    final summary = _buildCopingPlanSummary(plan, currentContext);
    await Share.share(
      summary,
      subject: plan.title,
    );
  }

  String _buildCopingPlanSummary(CopingPlan plan, BuildContext ctx) {
    final buffer = StringBuffer()
      ..writeln('Coping plan: ${plan.title}')
      ..writeln();

    if (plan.warningSigns.isNotEmpty) {
      buffer.writeln('Early warning signs:');
      for (final sign in plan.warningSigns) {
        buffer.writeln('• $sign');
      }
      buffer.writeln();
    }

    if (plan.steps.isNotEmpty) {
      buffer.writeln('Coping steps:');
      for (var i = 0; i < plan.steps.length; i++) {
        final step = plan.steps[i];
        final minutes = step.estimatedDuration.inMinutes;
        final durationLabel = minutes > 0 ? ' ($minutes min)' : '';
        buffer.writeln('${i + 1}. ${step.description}$durationLabel');
      }
      buffer.writeln();
    }

    if (plan.supportContacts.isNotEmpty) {
      buffer.writeln('Support contacts:');
      for (final contact in plan.supportContacts) {
        final phone = contact.phone.trim();
        final phoneLabel = phone.isEmpty ? '' : ' · $phone';
        buffer.writeln('- ${contact.name}$phoneLabel');
      }
      buffer.writeln();
    }

    if (plan.safeLocations.isNotEmpty) {
      buffer.writeln('Safe locations:');
      for (final location in plan.safeLocations) {
        buffer.writeln('- $location');
      }
      buffer.writeln();
    }

    if (plan.checkInTime != null) {
      final formattedTime = plan.checkInTime!.format(ctx);
      buffer.writeln('Preferred daily check-in: $formattedTime');
    }

    return buffer.toString();
  }

  Future<void> _exportCopingPlanPdf(CopingPlan plan) async {
    final doc = pw.Document();
    final ctx = _currentKey.currentContext ?? context;
    final sectionTitle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
    );

    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context pdfContext) => [
          pw.Text(
            plan.title,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          if (plan.warningSigns.isNotEmpty) ...[
            pw.Text('Early warning signs', style: sectionTitle),
            pw.SizedBox(height: 6),
            for (final sign in plan.warningSigns) pw.Bullet(text: sign),
            pw.SizedBox(height: 12),
          ],
          if (plan.steps.isNotEmpty) ...[
            pw.Text('Coping steps', style: sectionTitle),
            pw.SizedBox(height: 6),
            for (var i = 0; i < plan.steps.length; i++)
              pw.Bullet(
                text:
                    '${i + 1}. ${plan.steps[i].description} (${_pdfStepMinutes(plan.steps[i])} min)',
              ),
            pw.SizedBox(height: 12),
          ],
          if (plan.supportContacts.isNotEmpty) ...[
            pw.Text('Support contacts', style: sectionTitle),
            pw.SizedBox(height: 6),
            for (final contact in plan.supportContacts)
              pw.Bullet(
                text: contact.phone.trim().isEmpty
                    ? contact.name
                    : '${contact.name} · ${contact.phone}',
              ),
            pw.SizedBox(height: 12),
          ],
          if (plan.safeLocations.isNotEmpty) ...[
            pw.Text('Safe locations', style: sectionTitle),
            pw.SizedBox(height: 6),
            for (final location in plan.safeLocations)
              pw.Bullet(text: location),
            pw.SizedBox(height: 12),
          ],
          if (plan.checkInTime != null)
            pw.Text(
              'Preferred daily check-in: ${plan.checkInTime!.format(ctx)}',
              style: const pw.TextStyle(fontSize: 12),
            ),
        ],
      ),
    );

    final data = await doc.save();
    final fileName = _copingPlanFileName(plan.title);
    await Share.shareXFiles(
      [
        XFile.fromData(
          data,
          name: fileName,
          mimeType: 'application/pdf',
        ),
      ],
      subject: plan.title,
      text: 'Coping plan: ${plan.title}',
    );
  }

  int _pdfStepMinutes(CopingPlanStep step) {
    final minutes = step.estimatedDuration.inMinutes;
    return minutes <= 0 ? 1 : minutes;
  }

  String _copingPlanFileName(String title) {
    final sanitized = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
    if (sanitized.isEmpty) return 'coping_plan.pdf';
    return '${sanitized}_coping_plan.pdf';
  }

  void _applyCoConsultOutcome(AiCoConsultOutcome outcome) {
    final existingPlan = List<String>.from(carePlan.plan);
    final seen = existingPlan.map((e) => e.toLowerCase()).toSet();
    for (final update in outcome.planUpdates) {
      final normalized = update.toLowerCase();
      if (seen.contains(normalized)) continue;
      existingPlan.insert(0, update);
      seen.add(normalized);
    }
    carePlan = CarePlan(
      physician: carePlan.physician,
      insurance: carePlan.insurance,
      medsEffects: carePlan.medsEffects,
      plan: existingPlan,
      expectedOutcomes: carePlan.expectedOutcomes,
    );

    for (final proposal in outcome.goalProposals) {
      final index = goals.indexWhere(
        (goal) => goal.title.toLowerCase() == proposal.title.toLowerCase(),
      );
      if (index == -1) {
        goals.insert(0, buildGoalFromProposal(proposal));
        continue;
      }
      final goal = goals[index];
      if (proposal.instructions != null) {
        goal.instructions = proposal.instructions;
      }
      if (proposal.category != null) {
        goal.category = proposal.category!;
        if (proposal.category == GoalCategory.custom) {
          goal.customCategoryName = proposal.title;
        }
      }
      if (proposal.frequency != null) {
        goal.frequency = proposal.frequency!;
      }
      if (proposal.timesPerPeriod != null) {
        goal.timesPerPeriod = proposal.timesPerPeriod!;
      }
      if (proposal.importance != null) {
        goal.importance = proposal.importance!;
      }
    }

    for (final change in outcome.medicationChanges) {
      final index = meds.indexWhere(
        (med) => med.name.toLowerCase() == change.name.toLowerCase(),
      );
      switch (change.action) {
        case AiMedicationAction.add:
          if (index == -1) {
            meds.insert(0, buildMedicationFromChange(change));
          } else {
            final existing = meds[index];
            meds[index] = RxMedication(
              name: existing.name,
              dose: change.dose ?? existing.dose,
              effect: change.effect ?? existing.effect,
              sideEffects: change.sideEffects ?? existing.sideEffects,
              intakeLog: existing.intakeLog,
            );
          }
          break;
        case AiMedicationAction.update:
          if (index != -1) {
            final existing = meds[index];
            meds[index] = RxMedication(
              name: existing.name,
              dose: change.dose ?? existing.dose,
              effect: change.effect ?? existing.effect,
              sideEffects: change.sideEffects ?? existing.sideEffects,
              intakeLog: existing.intakeLog,
            );
          } else {
            meds.insert(0, buildMedicationFromChange(change));
          }
          break;
        case AiMedicationAction.discontinue:
          if (index != -1) {
            meds.removeAt(index);
          }
          break;
      }
    }
  }

  void _saveFeeling(int score, DateTime when, String? note) {
    setState(() {
      feelingsScore = score;
      final trimmedNote = note?.trim();
      feelingHistory.add(
        FeelingEntry(
          date: when,
          score: score,
          note: trimmedNote?.isEmpty ?? true ? null : trimmedNote,
          comments: <FeelingComment>[],
        ),
      );
    });
  }

  void _logMedicationIntake(int medIndex, DateTime when) {
    setState(() {
      final log = meds[medIndex].intakeLog;
      log.add(when);
      log.sort((a, b) => b.compareTo(a));
    });
  }

  _CustomShortcutDefinition? get _activeShortcut {
    final id = _customDestination;
    return id == null ? null : _shortcutById(id);
  }

  @override
  void initState() {
    super.initState();
    idx = widget.initialIndex;
    _coConsultCoordinator.addListener(_onCoConsultUpdated);

    _accountListenable = AuthService.instance.currentUserAccountListenable;
    final initialAccount = _accountListenable.value;
    _currentAccountId = _accountKeyFor(initialAccount);
    _accountData = _accountDataRepository.forAccount(initialAccount);
    _accountListener = _handleAccountChanged;
    _accountListenable.addListener(_accountListener);
    _loadFeatureDiscoveryFlag(_currentAccountId);
  }

  void _onCoConsultUpdated() {
    final outcome = _coConsultCoordinator.latestOutcome;
    if (outcome == null) return;
    setState(() {
      _applyCoConsultOutcome(outcome);
    });
  }

  void _handleAccountChanged() {
    final account = _accountListenable.value;
    final key = _accountKeyFor(account);
    if (key != _currentAccountId) {
      final data = _accountDataRepository.forAccount(account);
      if (!mounted) return;
      setState(() {
        _accountData = data;
        _currentAccountId = key;
        _showFeatureDiscovery = false;
      });
      _loadFeatureDiscoveryFlag(key);
      return;
    }
    if (account != null && _accountData.profile.name != account.displayName) {
      if (!mounted) return;
      setState(() {
        _accountData.profile =
            _accountData.profile.copyWith(name: account.displayName);
      });
    }
  }

  Future<void> _loadFeatureDiscoveryFlag(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_discoveryKeyFor(accountId)) ?? false;
    if (!mounted) return;
    setState(() => _showFeatureDiscovery = !completed);
  }

  void _completeFeatureDiscovery() {
    if (!_showFeatureDiscovery) return;
    setState(() => _showFeatureDiscovery = false);
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool(_discoveryKeyFor(_currentAccountId), true),
    );
  }

  @override
  void didUpdateWidget(covariant RootShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      idx = widget.initialIndex;
    }
  }

  @override
  void dispose() {
    _coConsultCoordinator.removeListener(_onCoConsultUpdated);
    _accountListenable.removeListener(_accountListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      PatientHomePage(
        profile: profile,
        onOpenProfile: _openMePage,
        goals: goals,
        meds: meds,
        initialFeelingsScore: feelingsScore,
        feelingHistory: feelingHistory,
        vitalHistory: vitalHistory,
        labResults: labResults,
        onMedicationCheckIn: _logMedicationIntake,
        onFeelingsSaved: _saveFeeling,
        scheduleItems: schedule,
        onAddScheduleItem: (item) => setState(() => schedule.add(item)),
        panelsOrder: homeOrder,
        nextVisit: nextVisit,
        mealMenu: mealMenu,
        mealSelections: mealSelections,
        mealDeliveryWindows: mealDeliveryWindows,
        completedMeals: completedMeals,
        mealNotes: mealNotes,
        onSelectMealOption: _selectMealOption,
        onChangeMealTime: _updateMealDelivery,
        onToggleMealCompleted: _toggleMealCompleted,
        onUpdateMealNotes: _updateMealNotes,
        onOpenNotifications: _openNotificationsPage,
        onOpenGoals: _openGoalsPage,
        onOpenMeds: _openMedsPage,
        onOpenTrends: _openTrendsPage,
        onOpenSchedule: _openSchedulePage,
        onOpenSud: _openSudPage,
      ),
      const MessagesPage(),
      MyAiPage(autoShowSessionControls: idx == _kTabMyAi),
      _buildCustomPage(),
      MorePage(
        profile: profile,
        onProfileChanged: (updated) => setState(() => profile = updated),
        customDestination: _customDestination,
        customSelectionMade: _customSelectionMade,
        onCustomSettingsChanged: (destination, selectionMade) => setState(() {
          _customSelectionMade = selectionMade;
          _customDestination = destination;
          if (selectionMade && destination == null && idx == _kTabCustom) {
            idx = _kTabHome;
          }
          _tabKeys[_kTabCustom] = GlobalKey<NavigatorState>();
        }),
        scheduleItems: schedule,
        onAddScheduleItem: (item) => setState(() => schedule.add(item)),
        initialFeelingsScore: feelingsScore,
        feelingHistory: feelingHistory,
        onFeelingsSaved: _saveFeeling,
        safetyPlan: safetyPlan,
        onSafetyPlanChanged: (plan) => setState(() => safetyPlan = plan),
      ),
    ];

    final showCustomTab = !_customSelectionMade || _customDestination != null;
    final visibleSlots = <int>[_kTabHome, _kTabChat, _kTabMyAi];
    if (showCustomTab) visibleSlots.add(_kTabCustom);
    visibleSlots.add(_kTabMore);

    if (!showCustomTab && idx == _kTabCustom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => idx = _kTabHome);
      });
    }

    NavigationDestination destinationForSlot(int slot) {
      switch (slot) {
        case _kTabHome:
          return const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home');
        case _kTabChat:
          return const NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Chat');
        case _kTabMyAi:
          return const NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy),
              label: 'Echo AI');
        case _kTabCustom:
          final shortcut = _activeShortcut;
          return NavigationDestination(
              icon: Icon(shortcut?.icon ?? Icons.add_circle_outline),
              selectedIcon: Icon(shortcut?.selectedIcon ?? Icons.add_circle),
              label: shortcut?.navLabel ?? 'custom');
        case _kTabMore:
          return const NavigationDestination(
              icon: Icon(Icons.more_horiz),
              selectedIcon: Icon(Icons.more),
              label: 'More');
        default:
          return const NavigationDestination(
              icon: Icon(Icons.help_outline),
              selectedIcon: Icon(Icons.help),
              label: '');
      }
    }

    final navSelectedIndexRaw = visibleSlots.indexOf(idx);
    final navSelectedIndex =
        navSelectedIndexRaw == -1 ? 0 : navSelectedIndexRaw;

    final navState = _currentKey.currentState;
    final canPopRoot =
        idx == _kTabHome && (navState == null || !navState.canPop());

    final scaffold = Scaffold(
      body: IndexedStack(
        index: navSelectedIndex,
        children: [
          for (final slot in visibleSlots)
            _buildTabNavigator(slot, pages[slot]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navSelectedIndex,
        onDestinationSelected: (selected) => _switchTab(visibleSlots[selected]),
        destinations: [
          for (final slot in visibleSlots) destinationForSlot(slot),
        ],
      ),
    );

    return PopScope(
      canPop: canPopRoot,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_showFeatureDiscovery) {
          _completeFeatureDiscovery();
          return;
        }
        final nav = _currentKey.currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
          return;
        }
        if (idx != _kTabHome) {
          setState(() => idx = _kTabHome);
        }
      },
      child: Stack(
        children: [
          scaffold,
          if (_showFeatureDiscovery)
            _FeatureDiscoveryOverlay(onDismiss: _completeFeatureDiscovery),
        ],
      ),
    );
  }

  Widget _buildCustomPage() {
    final option = _activeShortcut;
    if (option == null) {
      if (_customSelectionMade) {
        return const SizedBox.shrink();
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('Custom button'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Set up your custom tab shortcut to jump to a favorite feature.',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openCustomButtonSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Customize now'),
              ),
            ],
          ),
        ),
      );
    }
    switch (option.id) {
      case 1:
        return MePage(
          carePlan: carePlan,
          safetyPlan: safetyPlan,
          onSafetyPlanChanged: (plan) => setState(() => safetyPlan = plan),
        );
      case 2:
        return CalendarPage(
          items: schedule,
          onAdd: (item) => setState(() => schedule.add(item)),
        );
      case 3:
        return NotificationCenterPage(
          list: notifications,
          initialFeelingsScore: feelingsScore,
          feelingHistory: feelingHistory,
          onFeelingsSaved: _saveFeeling,
          nextVisit: nextVisit,
          safetyPlan: safetyPlan,
          onSafetyPlanChanged: (plan) => setState(() => safetyPlan = plan),
        );
      case 4:
        return MeditationModePage(
          initialFeelingsScore: feelingsScore,
          feelingHistory: feelingHistory,
          onFeelingsSaved: _saveFeeling,
          safetyPlan: safetyPlan,
          onSafetyPlanChanged: (plan) => setState(() => safetyPlan = plan),
        );
      case 5:
        return const MiniGamesPage();
      case 6:
        return const EducationPage();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTabNavigator(int index, Widget root) {
    return Offstage(
      offstage: idx != index,
      child: Navigator(
        key: _tabKeys[index],
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => root,
            settings: const RouteSettings(name: '/'),
          );
        },
      ),
    );
  }

  void _switchTab(int v) {
    if (v == idx) {
      final nav = _currentKey.currentState;
      if (nav != null) nav.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => idx = v);
  }

  void _openCustomButtonSettings() {
    _pushCurrent<void>(
      SettingsPage(
        profile: profile,
        onProfileChanged: (updated) => setState(() => profile = updated),
        customDestination: _customDestination,
        customSelectionMade: _customSelectionMade,
        onCustomSelectionChanged: (destination, selectionMade) => setState(() {
          _customSelectionMade = selectionMade;
          _customDestination = destination;
          if (selectionMade && destination == null && idx == _kTabCustom) {
            idx = _kTabHome;
          }
          _tabKeys[_kTabCustom] = GlobalKey<NavigatorState>();
        }),
      ),
    );
  }

  void _openMePage() {
    _pushCurrent<void>(
      MePage(
        carePlan: carePlan,
        safetyPlan: safetyPlan,
        onSafetyPlanChanged: (plan) => setState(() => safetyPlan = plan),
      ),
    );
  }

  Future<void> _openGoalsPage() async {
    await _pushCurrent(
      GoalsPage(
        goals: goals,
        mealMenu: mealMenu,
        mealSelections: mealSelections,
        mealDeliveryWindows: mealDeliveryWindows,
        completedMeals: completedMeals,
        mealNotes: mealNotes,
        onSelectMealOption: _selectMealOption,
        onChangeMealTime: _updateMealDelivery,
        onToggleMealCompleted: _toggleMealCompleted,
        onUpdateMealNotes: _updateMealNotes,
      ),
    );
    setState(() {});
  }

  Future<void> _openMedsPage() async {
    await _pushCurrent(
      RxSuggestionsPage(
        meds: meds,
        onCheckIn: (index, when) {
          _logMedicationIntake(index, when);
          setState(() {});
        },
      ),
    );
    setState(() {});
  }

  Future<void> _openTrendsPage() async {
    await _pushCurrent(
      TrendsPage(
        history: feelingHistory,
        vitals: vitalHistory,
        labs: labResults,
      ),
    );
  }

  Future<void> _openSchedulePage() async {
    await _pushCurrent(
      CalendarPage(
        items: schedule,
        onAdd: (item) => setState(() => schedule.add(item)),
      ),
    );
    setState(() {});
  }

  Future<void> _openSudPage() async {
    await _pushCurrent(
      SubstanceUseDisorderPage(
        profile: profile,
        medications: meds,
        vitals: vitalHistory,
        nextVisit: nextVisit,
        safetyPlan: safetyPlan,
        carePlan: carePlan,
        labs: labResults,
        copingPlans: List<CopingPlan>.from(copingPlans),
        onCreatePlan: _addCopingPlan,
        onUpdatePlan: _replaceCopingPlan,
        onLaunchPlan: _launchCopingPlan,
        onSharePlan: _shareCopingPlan,
      ),
    );
  }

  Future<void> _openNotificationsPage() async {
    await _pushCurrent(
      NotificationCenterPage(
        list: notifications,
        initialFeelingsScore: feelingsScore,
        feelingHistory: feelingHistory,
        onFeelingsSaved: _saveFeeling,
        nextVisit: nextVisit,
        safetyPlan: safetyPlan,
        onSafetyPlanChanged: (plan) => setState(() => safetyPlan = plan),
      ),
    );
  }
}

class _FeatureDiscoveryOverlay extends StatelessWidget {
  const _FeatureDiscoveryOverlay({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const hints = <({IconData icon, String title, String detail})>[
      (
        icon: Icons.home_outlined,
        title: 'Home',
        detail: 'Vitals, schedule, and quick actions at a glance.'
      ),
      (
        icon: Icons.chat_bubble_outline,
        title: 'Chat',
        detail: 'One-on-one, peer, and group conversations.'
      ),
      (
        icon: Icons.smart_toy_outlined,
        title: 'Echo AI',
        detail: 'Co-Consult, Scan, Report Generator, and Ask AI.'
      ),
      (
        icon: Icons.widgets_outlined,
        title: 'custom & More',
        detail: 'Pin your shortcut and reach settings, privacy, and help.'
      ),
    ];
    return Positioned.fill(
      child: Material(
        color: Colors.black54,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDismiss,
                  child: const SizedBox.shrink(),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Semantics(
                    label: 'Navigation tips overlay',
                    container: true,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick tour',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'These tabs stay fixed so you can jump between Home, Chat, Echo AI, custom, and More anytime.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            ...hints.map(
                              (hint) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(hint.icon, size: 22),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            hint.title,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            hint.detail,
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: onDismiss,
                                child: const Text('Got it'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

final AccountDataRepository _accountDataRepository = AccountDataRepository();

class AccountDataRepository {
  final Map<String, AccountData> _cache = {};

  AccountData forAccount(UserAccount? account) {
    final key = _accountKeyFor(account);
    return _cache.putIfAbsent(
      key,
      () => (account?.isDemo ?? false)
          ? AccountData.demo()
          : AccountData.empty(account),
    );
  }
}

class AccountData {
  AccountData._({
    required this.goals,
    required this.meds,
    required this.feelingsScore,
    required this.feelingHistory,
    required this.carePlan,
    required this.schedule,
    required this.profile,
    required this.homeOrder,
    required this.vitalHistory,
    required this.labResults,
    required this.nextVisit,
    required this.safetyPlan,
    required this.notifications,
    required this.copingPlans,
    required this.mealMenu,
    required this.mealSelections,
    required this.mealDeliveryWindows,
    required this.completedMeals,
    required this.mealNotes,
  });

  final List<Goal> goals;
  final List<RxMedication> meds;
  int feelingsScore;
  final List<FeelingEntry> feelingHistory;
  CarePlan carePlan;
  final List<ScheduleItem> schedule;
  PatientProfile profile;
  final List<HomePanel> homeOrder;
  final List<VitalEntry> vitalHistory;
  final List<LabResult> labResults;
  final NextVisit nextVisit;
  SafetyPlanData safetyPlan;
  final List<AppNotification> notifications;
  final List<CopingPlan> copingPlans;
  final Map<MealSlot, List<MealOption>> mealMenu;
  final Map<MealSlot, int> mealSelections;
  final Map<MealSlot, TimeOfDay> mealDeliveryWindows;
  final Set<MealSlot> completedMeals;
  String mealNotes;

  factory AccountData.demo() => AccountData._(
        goals: _buildDemoGoals(),
        meds: _buildDemoMeds(),
        feelingsScore: 4,
        feelingHistory: [],
        carePlan: _buildDemoCarePlan(),
        schedule: _buildDemoSchedule(),
        profile: _buildDemoProfile(),
        homeOrder: _defaultHomePanels(),
        vitalHistory: _buildDemoVitals(),
        labResults: _buildDemoLabResults(),
        nextVisit: _buildDemoNextVisit(),
        safetyPlan: SafetyPlanData.defaults(),
        notifications: _buildDemoNotifications(),
        copingPlans: _buildDemoCopingPlans(),
        mealMenu: kDefaultMealMenu,
        mealSelections: _defaultMealSelections(),
        mealDeliveryWindows: _defaultMealWindows(),
        completedMeals: _defaultCompletedMeals(),
        mealNotes: kDefaultMealNotes,
      );

  factory AccountData.empty(UserAccount? account) => AccountData._(
        goals: [],
        meds: [],
        feelingsScore: 3,
        feelingHistory: [],
        carePlan: _emptyCarePlan(),
        schedule: [],
        profile: _profileFor(account),
        homeOrder: _defaultHomePanels(),
        vitalHistory: [],
        labResults: [],
        nextVisit: _fallbackNextVisit(),
        safetyPlan: SafetyPlanData(),
        notifications: [],
        copingPlans: [],
        mealMenu: kDefaultMealMenu,
        mealSelections: _defaultMealSelections(),
        mealDeliveryWindows: _defaultMealWindows(),
        completedMeals: _defaultCompletedMeals(),
        mealNotes: kDefaultMealNotes,
      );
}

List<HomePanel> _defaultHomePanels() => [
      HomePanel.goals,
      HomePanel.meds,
      HomePanel.feelings,
      HomePanel.sud
    ];

CarePlan _emptyCarePlan() => CarePlan(
      physician: '',
      insurance: InsuranceSummary(totalCost: 0, covered: 0),
      medsEffects: const [],
      plan: const [],
      expectedOutcomes: const [],
    );

PatientProfile _profileFor(UserAccount? account) {
  return PatientProfile(
    name: account?.displayName ?? 'Guest',
    patientId: account?.id ?? _kGuestAccountId,
    email: account?.email,
  );
}

NextVisit _fallbackNextVisit() => NextVisit(
      title: 'No upcoming visits',
      when: DateTime.now(),
      location: 'TBD',
      doctor: 'TBD',
      notes: 'Schedule a visit to receive reminders.',
    );

Map<MealSlot, int> _defaultMealSelections() => {
      for (final slot in MealSlot.values) slot: 0,
    };

Map<MealSlot, TimeOfDay> _defaultMealWindows() =>
    Map<MealSlot, TimeOfDay>.from(kDefaultMealWindows);

Set<MealSlot> _defaultCompletedMeals() => <MealSlot>{};

List<Goal> _buildDemoGoals() {
  return [
    Goal(
        title: 'Walk 30 minutes',
        progress: 0.6,
        instructions:
            'Warm up for 5 minutes, walk at a brisk pace, cool down and stretch.',
        category: GoalCategory.exercises,
        frequency: GoalFrequency.daily,
        timesPerPeriod: 1,
        startDate: DateUtils.dateOnly(
            DateTime.now().subtract(const Duration(days: 7))),
        endDate:
            DateUtils.dateOnly(DateTime.now().add(const Duration(days: 21))),
        reminder: const TimeOfDay(hour: 9, minute: 0),
        importance: GoalImportance.medium),
    Goal(
        title: 'Take meds on time (AM/PM)',
        progress: 0.9,
        instructions: 'Lay out pill organizer each night and log after doses.',
        category: GoalCategory.treatment,
        frequency: GoalFrequency.daily,
        timesPerPeriod: 2,
        startDate: DateUtils.dateOnly(
            DateTime.now().subtract(const Duration(days: 3))),
        endDate:
            DateUtils.dateOnly(DateTime.now().add(const Duration(days: 27))),
        reminder: const TimeOfDay(hour: 8, minute: 0),
        importance: GoalImportance.high),
    Goal(
        title: 'Meditate 10 minutes',
        progress: 0.2,
        instructions:
            'Use the breathing app after dinner and note reflections.',
        category: GoalCategory.meditation,
        frequency: GoalFrequency.weekly,
        timesPerPeriod: 4,
        startDate: DateUtils.dateOnly(
            DateTime.now().subtract(const Duration(days: 1))),
        endDate:
            DateUtils.dateOnly(DateTime.now().add(const Duration(days: 60))),
        reminder: const TimeOfDay(hour: 21, minute: 0),
        importance: GoalImportance.low),
    Goal(
        title: 'Lights out by 11 PM',
        progress: 0.4,
        instructions: 'Wind down with reading and avoid screens after 10:30.',
        category: GoalCategory.sleep,
        frequency: GoalFrequency.daily,
        timesPerPeriod: 1,
        startDate: DateUtils.dateOnly(
            DateTime.now().subtract(const Duration(days: 5))),
        endDate:
            DateUtils.dateOnly(DateTime.now().add(const Duration(days: 25))),
        reminder: const TimeOfDay(hour: 22, minute: 30),
        importance: GoalImportance.medium),
    Goal(
        title: 'Drink 8 cups of water',
        progress: 0.5,
        instructions:
            'Use the hydration tracker app and keep a water bottle nearby.',
        category: GoalCategory.hydration,
        frequency: GoalFrequency.daily,
        timesPerPeriod: 8,
        startDate: DateUtils.dateOnly(
            DateTime.now().subtract(const Duration(days: 2))),
        endDate:
            DateUtils.dateOnly(DateTime.now().add(const Duration(days: 30))),
        reminder: const TimeOfDay(hour: 10, minute: 0),
        importance: GoalImportance.medium),
    Goal(
        title: 'Check in with a friend',
        progress: 0.3,
        instructions:
            'Send a thoughtful message or schedule a video call each week.',
        category: GoalCategory.social,
        frequency: GoalFrequency.weekly,
        timesPerPeriod: 2,
        startDate: DateUtils.dateOnly(
            DateTime.now().subtract(const Duration(days: 10))),
        endDate:
            DateUtils.dateOnly(DateTime.now().add(const Duration(days: 40))),
        reminder: const TimeOfDay(hour: 19, minute: 0),
        importance: GoalImportance.high),
    Goal(
        title: 'Meal prep Sundays',
        progress: 0.7,
        instructions:
            'Plan a balanced menu, grocery shop Saturday, cook Sunday afternoon.',
        category: GoalCategory.diet,
        frequency: GoalFrequency.weekly,
        timesPerPeriod: 1,
        startDate: DateUtils.dateOnly(
            DateTime.now().subtract(const Duration(days: 21))),
        endDate:
            DateUtils.dateOnly(DateTime.now().add(const Duration(days: 14))),
        reminder: const TimeOfDay(hour: 15, minute: 0),
        importance: GoalImportance.medium),
  ];
}

List<RxMedication> _buildDemoMeds() {
  return [
    RxMedication(
      name: 'Sertraline',
      dose: '50 mg · morning',
      effect: 'Helps balance serotonin to reduce anxiety and stabilize mood.',
      sideEffects: 'Mild nausea, vivid dreams during first week.',
      intakeLog: [
        DateTime.now().subtract(const Duration(days: 2, hours: 3)),
        DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ],
    ),
    RxMedication(
      name: 'Quetiapine',
      dose: '25 mg · evening',
      effect: 'Supports sleep onset and reduces nighttime racing thoughts.',
      sideEffects: 'Possible morning grogginess; stay hydrated.',
      intakeLog: [
        DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      ],
    ),
  ];
}

CarePlan _buildDemoCarePlan() => CarePlan(
      physician: 'Dr. Wang (Psychiatry)',
      insurance: InsuranceSummary(totalCost: 12430.00, covered: 9850.00),
      medsEffects: const [
        MedEffect(
            name: 'Sertraline 50 mg',
            effect: 'Mood stabilization; fewer panic spikes',
            sideEffects: 'Mild nausea (first week)'),
        MedEffect(
            name: 'Quetiapine 25 mg',
            effect: 'Better sleep onset',
            sideEffects: 'Morning grogginess'),
      ],
      plan: const [
        'CBT weekly (8 sessions)',
        'Sleep hygiene routine',
        'Daily walk 30 minutes',
        'Meds review after 4 weeks'
      ],
      expectedOutcomes: const [
        'PHQ-9 ↓ by 5–8 points in 4–6 weeks',
        'Sleep latency < 30 min in 2–3 weeks'
      ],
    );

List<ScheduleItem> _buildDemoSchedule() => [
      ScheduleItem(
          title: 'Surgery (arthroscopy)',
          date: DateTime.now().add(const Duration(days: 7)),
          notes:
              'Arrive fasting; bring insurance card. Check in at Building A, Room 203.',
          kind: ScheduleKind.surgery,
          location: 'Springfield General Hospital, Wing C',
          link: 'https://example.com/surgery-prep',
          doctor: 'Dr. Smith',
          attendees: const ['Nurse Allen', 'Physio lead: Jamie G.']),
    ];

PatientProfile _buildDemoProfile() => PatientProfile(
      name: 'Argo',
      patientId: 'MRN 2025-001',
      avatarUrl: null,
      notes: 'Anxiety · Insomnia',
      email: 'argo@example.com',
      phoneNumber: '(415) 555-0135',
    );

List<VitalEntry> _buildDemoVitals() => [
      VitalEntry(
          date: DateTime.now().subtract(const Duration(days: 2)),
          systolic: 122,
          diastolic: 78,
          heartRate: 72),
      VitalEntry(
          date: DateTime.now().subtract(const Duration(days: 1)),
          systolic: 118,
          diastolic: 76,
          heartRate: 70),
      VitalEntry(
          date: DateTime.now(), systolic: 125, diastolic: 80, heartRate: 74),
    ];

List<LabResult> _buildDemoLabResults() => [
      LabResult(
          name: 'Complete Blood Count',
          value: 'Normal',
          unit: '',
          collectedOn: DateTime.now().subtract(const Duration(days: 10)),
          notes: 'All markers within range.'),
      LabResult(
          name: 'TSH',
          value: '2.1',
          unit: 'µIU/mL',
          collectedOn: DateTime.now().subtract(const Duration(days: 20)),
          notes: 'Within reference 0.4–4.0.'),
      LabResult(
          name: 'Vitamin D',
          value: '28',
          unit: 'ng/mL',
          collectedOn: DateTime.now().subtract(const Duration(days: 35)),
          notes: 'Slightly low · supplement recommended.'),
    ];

NextVisit _buildDemoNextVisit() => NextVisit(
      title: 'Review meds & sleep',
      when: DateTime.now().add(const Duration(days: 3, hours: 2, minutes: 30)),
      location: 'Telehealth (Zoom link)',
      doctor: 'Dr. Wang',
      mode: 'Online',
      notes: 'Prepare PHQ-9 and sleep diary.',
    );

List<AppNotification> _buildDemoNotifications() => [
      AppNotification('Welcome', 'Thanks for using Patient Tracker.',
          DateTime.now().subtract(const Duration(hours: 2))),
      AppNotification('Meds Reminder', 'Evening dose due at 8:00 PM.',
          DateTime.now().subtract(const Duration(hours: 1))),
    ];

List<CopingPlan> _buildDemoCopingPlans() => [
      CopingPlan(
        id: 'plan-1',
        title: 'My coping plan #1',
        warningSigns: [
          'Sleeping poorly',
          'Feeling on edge',
          'Thinking about old triggers',
        ],
        steps: [
          const CopingPlanStep(
            description: 'Box breathing for 2 minutes',
            estimatedDuration: Duration(minutes: 2),
          ),
          const CopingPlanStep(
            description: 'Step outside for fresh air',
            estimatedDuration: Duration(minutes: 5),
          ),
          const CopingPlanStep(
            description: 'Call my support contact and share how I feel',
            estimatedDuration: Duration(minutes: 5),
          ),
        ],
        supportContacts: [
          const SupportContact(name: 'Coach Riley', phone: '+1-555-201-8842'),
          const SupportContact(name: 'Sponsor June', phone: '+1-555-433-0098'),
        ],
        safeLocations: ['Dorm common area', 'Campus wellness lounge'],
        checkInTime: const TimeOfDay(hour: 21, minute: 0),
        pinnedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

/// ===================== Goals / Meds / Feelings / Me / Calendar =====================
