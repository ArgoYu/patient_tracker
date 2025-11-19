// lib/features/home/view/home_page.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/models/models.dart';
import '../../../shared/app_settings.dart';
import '../../../shared/widgets/glass.dart';

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

  @override
  Widget build(BuildContext context) {
    final name = widget.profile.name.split(' ').first;
    return Scaffold(
      appBar: AppBar(
        title: Text('${_greeting()}, $name'),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Center(
            child: PatientInfoHeader(
              profile: widget.profile,
              onOpenProfile: widget.onOpenProfile,
              symptoms: widget.profile.notes,
              primaryDoctor: widget.nextVisit.doctor,
            ),
          ),
          const SizedBox(height: 16),
          _HomePanelsGrid(
            panels: widget.panelsOrder,
            buildPanel: (panel) {
              switch (panel) {
                case HomePanel.goals:
                  return GlassSmallPanel(
                    icon: Icons.flag,
                    label: 'My Goals',
                    onTap: () => _handleGoalsTap(),
                  );
                case HomePanel.meds:
                  return GlassSmallPanel(
                    icon: Icons.medication,
                    label: 'Rx Suggestions',
                    onTap: () => _handleMedsTap(),
                  );
                case HomePanel.feelings:
                  return GlassSmallPanel(
                    icon: Icons.show_chart,
                    label: 'Trends',
                    onTap: () => _handleTrendsTap(),
                  );
                case HomePanel.sud:
                  return GlassSmallPanel(
                    icon: Icons.medical_services_outlined,
                    label: 'Substance Use Disorder',
                    onTap: () => _handleSudTap(),
                  );
              }
            },
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
  });

  final PatientProfile profile;
  final VoidCallback onOpenProfile;
  final String? symptoms;
  final String? primaryDoctor;

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
    final text = Theme.of(context).textTheme;
    final symptoms = () {
      final custom = widget.symptoms?.trim() ?? '';
      if (custom.isNotEmpty) return custom;
      return widget.profile.notes?.trim() ?? '';
    }();
    final doctor = widget.primaryDoctor?.trim() ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.onOpenProfile,
          child: CircleAvatar(
            radius: 40,
            backgroundImage:
                avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child:
                avatarUrl.isEmpty ? const Icon(Icons.person, size: 40) : null,
          ),
        ),
        const SizedBox(height: 10),
        FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _slide,
            child: GestureDetector(
              onTap: widget.onOpenProfile,
              child: Column(
                children: [
                  Text(
                    widget.profile.name,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (symptoms.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Symptoms: $symptoms',
                      style: text.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (doctor.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Primary doctor: $doctor',
                      style: text.bodySmall?.copyWith(
                        color: text.bodySmall?.color?.withValues(alpha: 0.85),
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
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) => buildPanel(panels[index]),
    );
  }
}

class GlassSmallPanel extends StatefulWidget {
  const GlassSmallPanel(
      {super.key, required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  State<GlassSmallPanel> createState() => _GlassSmallPanelState();
}

class _GlassSmallPanelState extends State<GlassSmallPanel> {
  bool _pressed = false;

  Color _accent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final palette = <Color>[
      cs.primary,
      cs.tertiary,
      const Color(0xFF22C55E),
      const Color(0xFF06B6D4),
      const Color(0xFFA855F7),
    ];
    return palette[widget.label.hashCode.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = AppSettings.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: accent.withValues(alpha: 0.07),
        highlightColor: accent.withValues(alpha: 0.035),
        onHighlightChanged: (value) => setState(() => _pressed = value),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          scale: _pressed ? 0.98 : 1.0,
          child: Glass(
            radius: 18,
            padding: const EdgeInsets.all(14),
            lightOpacity: (settings.lightOpacity - 0.005).clamp(0.0, 1.0),
            darkOpacity: (settings.darkOpacity - 0.005).clamp(0.0, 1.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.withValues(alpha: 0.20)),
                  ),
                  child: Icon(widget.icon, color: accent, size: 26),
                ),
                const Spacer(),
                Text(
                  widget.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.arrow_outward,
                    size: 16,
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: isDark ? 0.30 : 0.22),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
