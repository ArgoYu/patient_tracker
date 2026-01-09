// lib/features/home/view/home_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:patient_tracker/core/theme/theme_tokens.dart';
import 'package:patient_tracker/shared/widgets/layout_cards.dart';

import '../../auth/auth_session_scope.dart';
import '../../../data/models/models.dart';

enum HomePanel { goals, meds, feelings, sud }

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({
    super.key,
    required this.profile,
    required this.onOpenProfile,
    required this.goals,
    required this.meds,
    required this.initialFeelingsScore,
    required this.feelingHistory,
    required this.vitalHistory,
    required this.labResults,
    required this.onMedicationCheckIn,
    required this.onFeelingsSaved,
    required this.scheduleItems,
    required this.onAddScheduleItem,
    required this.panelsOrder,
    required this.nextVisit,
    required this.mealMenu,
    required this.mealSelections,
    required this.mealDeliveryWindows,
    required this.completedMeals,
    required this.mealNotes,
    required this.onSelectMealOption,
    required this.onChangeMealTime,
    required this.onToggleMealCompleted,
    required this.onUpdateMealNotes,
    required this.onOpenNotifications,
    required this.onOpenGoals,
    required this.onOpenMeds,
    required this.onOpenTrends,
    required this.onOpenSchedule,
    required this.onOpenSud,
  });

  final PatientProfile profile;
  final VoidCallback onOpenProfile;
  final List<Goal> goals;
  final List<RxMedication> meds;
  final int initialFeelingsScore;
  final List<FeelingEntry> feelingHistory;
  final List<VitalEntry> vitalHistory;
  final List<LabResult> labResults;
  final void Function(int index, DateTime when) onMedicationCheckIn;
  final void Function(int score, DateTime when, String? note) onFeelingsSaved;
  final List<ScheduleItem> scheduleItems;
  final void Function(ScheduleItem item) onAddScheduleItem;
  final List<HomePanel> panelsOrder;
  final NextVisit nextVisit;
  final Map<MealSlot, List<MealOption>> mealMenu;
  final Map<MealSlot, int> mealSelections;
  final Map<MealSlot, TimeOfDay> mealDeliveryWindows;
  final Set<MealSlot> completedMeals;
  final String mealNotes;
  final void Function(MealSlot slot, int index) onSelectMealOption;
  final void Function(MealSlot slot, TimeOfDay time) onChangeMealTime;
  final void Function(MealSlot slot, bool value) onToggleMealCompleted;
  final ValueChanged<String> onUpdateMealNotes;
  final VoidCallback onOpenNotifications;
  final Future<void> Function() onOpenGoals;
  final Future<void> Function() onOpenMeds;
  final Future<void> Function() onOpenTrends;
  final Future<void> Function() onOpenSchedule;
  final Future<void> Function() onOpenSud;

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  late Timer _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  String _greeting() {
    final h = _now.hour;
    if (h < 5) return 'Good night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 22) return 'Good evening';
    return 'Good night';
  }

  Future<void> _handleGoalsTap() async {
    await widget.onOpenGoals();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleMedsTap() async {
    await widget.onOpenMeds();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleTrendsTap() async {
    await widget.onOpenTrends();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleScheduleTap() async {
    await widget.onOpenSchedule();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleSudTap() async {
    await widget.onOpenSud();
    if (!mounted) return;
    setState(() {});
  }

  DashboardCard _buildPanel(HomePanel panel) {
    switch (panel) {
      case HomePanel.goals:
        return DashboardCard(
          icon: Icons.flag,
          title: 'My Goals',
          status: _statusForPanel(panel),
          onTap: () => _handleGoalsTap(),
          isPrimary: true,
        );
      case HomePanel.meds:
        return DashboardCard(
          icon: Icons.medication,
          title: 'Rx Suggestions',
          status: _statusForPanel(panel),
          onTap: () => _handleMedsTap(),
        );
      case HomePanel.feelings:
        return DashboardCard(
          icon: Icons.show_chart,
          title: 'Trends',
          status: _statusForPanel(panel),
          onTap: () => _handleTrendsTap(),
        );
      case HomePanel.sud:
        return DashboardCard(
          icon: Icons.medical_services_outlined,
          title: 'Substance Use Disorder',
          status: _statusForPanel(panel),
          onTap: () => _handleSudTap(),
        );
    }
  }

  String _statusForPanel(HomePanel panel) {
    switch (panel) {
      case HomePanel.goals:
        if (widget.goals.isEmpty) return 'No goals yet';
        return '${widget.goals.length} goals in progress';
      case HomePanel.meds:
        if (widget.meds.isEmpty) return 'No new suggestions';
        return '${widget.meds.length} meds tracked';
      case HomePanel.feelings:
        final latestFeeling = _latestBy<FeelingEntry>(
          widget.feelingHistory,
          (entry) => entry.date,
        );
        if (latestFeeling != null) {
          return 'Mood logged ${_formatRelative(latestFeeling.date)}';
        }
        final latestVital = _latestBy<VitalEntry>(
          widget.vitalHistory,
          (entry) => entry.date,
        );
        if (latestVital != null) {
          return 'Vitals ${latestVital.label()}';
        }
        return 'Tap to view trends';
      case HomePanel.sud:
        return 'Tap to review your SUD care plan';
    }
  }

  T? _latestBy<T>(List<T> entries, DateTime Function(T) selector) {
    if (entries.isEmpty) return null;
    return entries.reduce((prev, next) {
      final prevDate = selector(prev);
      final nextDate = selector(next);
      return nextDate.isAfter(prevDate) ? next : prev;
    });
  }

  String _formatRelative(DateTime date) {
    final diff = _now.difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes;
      return '$minutes min${minutes == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return '$hours hr${hours == 1 ? '' : 's'} ago';
    }
    final days = diff.inDays;
    return '$days day${days == 1 ? '' : 's'} ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final userAccount = AuthSessionScope.of(context).currentUserAccount;
    final greetingName = userAccount?.displayName ?? 'Guest';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_greeting()}, $greetingName',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Schedule',
            onPressed: () => _handleScheduleTap(),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: widget.onOpenNotifications,
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppThemeTokens.pagePadding,
          AppThemeTokens.pagePadding,
          AppThemeTokens.pagePadding,
          AppThemeTokens.pagePadding,
        ),
        children: [
          Center(
            child: PatientInfoHeader(
              profile: widget.profile,
              onOpenProfile: widget.onOpenProfile,
              displayName: greetingName,
              symptoms: widget.profile.notes,
              primaryDoctor: widget.nextVisit.doctor,
            ),
          ),
          SizedBox(height: AppThemeTokens.gap + 6),
          _HomePanelsGrid(
            panels: widget.panelsOrder,
            buildPanel: (panel) => _buildPanel(panel),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class PatientInfoHeader extends StatefulWidget {
  const PatientInfoHeader({
    super.key,
    required this.profile,
    required this.onOpenProfile,
    this.symptoms,
    this.primaryDoctor,
    this.displayName,
  });

  final PatientProfile profile;
  final VoidCallback onOpenProfile;
  final String? symptoms;
  final String? primaryDoctor;
  final String? displayName;

  @override
  State<PatientInfoHeader> createState() => _PatientInfoHeaderState();
}

class _PatientInfoHeaderState extends State<PatientInfoHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  late final Animation<double> _opacity =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide =
      Tween(begin: const Offset(0, 0.2), end: Offset.zero)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.profile.avatarUrl?.trim() ?? '';
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final symptoms = () {
      final custom = widget.symptoms?.trim() ?? '';
      if (custom.isNotEmpty) return custom;
      return widget.profile.notes?.trim() ?? '';
    }();
    final doctor = widget.primaryDoctor?.trim() ?? '';
    final headerName = () {
      final override = widget.displayName?.trim();
      if (override?.isNotEmpty ?? false) {
        return override!;
      }
      return widget.profile.name;
    }();
    final infoParts = <String>[];
    if (symptoms.isNotEmpty) infoParts.add(symptoms);
    if (doctor.isNotEmpty) infoParts.add(doctor);
    final infoLine = infoParts.join(' · ');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.onOpenProfile,
          child: CircleAvatar(
            radius: 40,
            backgroundColor: colorScheme.surfaceVariant,
            foregroundColor: colorScheme.onSurface,
            backgroundImage:
                avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Icon(Icons.person, size: 40, color: colorScheme.onSurface)
                : null,
          ),
        ),
        SizedBox(height: AppThemeTokens.gap),
        FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _slide,
            child: GestureDetector(
              onTap: widget.onOpenProfile,
              child: Column(
                children: [
                  Text(
                    headerName,
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (infoLine.isNotEmpty) ...[
                    SizedBox(height: AppThemeTokens.gap / 2),
                    Text(
                      infoLine,
                      style: text.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class NextAppointmentRow extends StatelessWidget {
  const NextAppointmentRow({
    super.key,
    required this.title,
    required this.timeText,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String timeText;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('$timeText · $subtitle'),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _HomePanelsGrid extends StatelessWidget {
  const _HomePanelsGrid({required this.panels, required this.buildPanel});

  final List<HomePanel> panels;
  final Widget Function(HomePanel) buildPanel;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: panels.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppThemeTokens.gap - 4,
        crossAxisSpacing: AppThemeTokens.gap,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) => buildPanel(panels[index]),
    );
  }
}

