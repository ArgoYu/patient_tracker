// ignore_for_file: deprecated_member_use, duplicate_ignore

part of 'package:patient_tracker/app_modules.dart';

class MorePage extends StatelessWidget {
  const MorePage(
      {super.key,
      required this.profile,
      required this.onProfileChanged,
      required this.customDestination,
      required this.customSelectionMade,
      required this.onCustomSettingsChanged,
      required this.scheduleItems,
      required this.onAddScheduleItem,
      required this.initialFeelingsScore,
      required this.feelingHistory,
      required this.onFeelingsSaved,
      required this.safetyPlan,
      required this.onSafetyPlanChanged});

  final PatientProfile profile;
  final ValueChanged<PatientProfile> onProfileChanged;
  final int? customDestination;
  final bool customSelectionMade;
  final void Function(int? destination, bool selectionMade)
      onCustomSettingsChanged;
  final List<ScheduleItem> scheduleItems;
  final void Function(ScheduleItem item) onAddScheduleItem;
  final int initialFeelingsScore;
  final List<FeelingEntry> feelingHistory;
  final void Function(int score, DateTime when, String? note) onFeelingsSaved;
  final SafetyPlanData safetyPlan;
  final ValueChanged<SafetyPlanData> onSafetyPlanChanged;
  @override
  Widget build(BuildContext context) {
    final items = <_MoreItem>[
      _MoreItem(
        Icons.calendar_month,
        'Calendar',
        () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CalendarPage(
              items: scheduleItems,
              onAdd: onAddScheduleItem,
            ),
          ),
        ),
      ),
      _MoreItem(
          Icons.menu_book,
          'Education',
          () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const EducationPage()))),
      _MoreItem(
          Icons.chat_bubble,
          'Chat',
          () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const MessagesPage()))),
      _MoreItem(
          Icons.videogame_asset,
          'Mini Games',
          () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const MiniGamesPage()))),
      _MoreItem(
          Icons.self_improvement,
          'Mindfulness',
          () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => MeditationModePage(
                  initialFeelingsScore: initialFeelingsScore,
                  feelingHistory: feelingHistory,
                  onFeelingsSaved: onFeelingsSaved,
                  safetyPlan: safetyPlan,
                  onSafetyPlanChanged: onSafetyPlanChanged,
                ),
              ))),
      _MoreItem(
          Icons.settings,
          'Settings',
          () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsPage(
                    profile: profile,
                    onProfileChanged: onProfileChanged,
                    customDestination: customDestination,
                    customSelectionMade: customSelectionMade,
                    onCustomSelectionChanged: onCustomSettingsChanged,
                  ),
                ),
              )),
    ];
    return Scaffold(
      appBar: AppBar(
          title: const Text('More'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => Glass(
            child: ListTile(
                leading: Icon(items[i].icon),
                title: Text(items[i].title),
                trailing: const Icon(Icons.chevron_right),
                onTap: items[i].onTap)),
      ),
    );
  }
}

class _MoreItem {
  _MoreItem(this.icon, this.title, this.onTap);
  final IconData icon;
  final String title;
  final VoidCallback onTap;
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.profile,
    required this.onProfileChanged,
    required this.customDestination,
    required this.customSelectionMade,
    required this.onCustomSelectionChanged,
  });

  final PatientProfile profile;
  final ValueChanged<PatientProfile> onProfileChanged;
  final int? customDestination;
  final bool customSelectionMade;
  final void Function(int? destination, bool selectionMade)
      onCustomSelectionChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late PatientProfile _profile;
  int? _customDestination;
  late bool _customSelectionMade;
  bool _notificationsEnabled = true;
  bool _medReminders = true;
  bool _appointmentReminders = true;
  bool _newsletterOptIn = false;
  String _measurementUnit = 'Metric (kg, cm)';
  String _preferredLanguageCode = LanguagePreferences.fallbackLanguageCode;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _customDestination = widget.customDestination;
    _customSelectionMade = widget.customSelectionMade;
    _loadPreferredLanguage();
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      setState(() => _profile = widget.profile);
    }
    if (oldWidget.customDestination != widget.customDestination) {
      setState(() => _customDestination = widget.customDestination);
    }
    if (oldWidget.customSelectionMade != widget.customSelectionMade) {
      setState(() => _customSelectionMade = widget.customSelectionMade);
    }
  }

  Future<void> _openAccountSettings() async {
    final updated = await Navigator.of(context).push<PatientProfile>(
      MaterialPageRoute(
        builder: (_) => AccountSettingsPage(
          profile: _profile,
          onProfileChanged: (p) {
            setState(() => _profile = p);
            widget.onProfileChanged(p);
          },
        ),
      ),
    );
    if (updated != null) {
      setState(() => _profile = updated);
      widget.onProfileChanged(updated);
    }
  }

  void _onCustomDestinationChanged(int? value) {
    if (value == null) return;
    setState(() {
      _customSelectionMade = true;
      _customDestination = value == _kCustomNoneChoice ? null : value;
    });
    widget.onCustomSelectionChanged(
      value == _kCustomNoneChoice ? null : value,
      true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.of(context);
    final text = Theme.of(context).textTheme;
    final selectedCustomValue = _customSelectionMade
        ? (_customDestination ?? _kCustomNoneChoice)
        : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          const _SectionLabel('Account'),
          Glass(
            child: Builder(builder: (context) {
              final hasAvatar = _profile.avatarUrl?.trim().isNotEmpty ?? false;
              return ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: hasAvatar
                      ? NetworkImage(_profile.avatarUrl!.trim())
                      : null,
                  child: hasAvatar ? null : const Icon(Icons.person, size: 28),
                ),
                title: Text(_profile.name),
                subtitle: Text(_profile.patientId),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openAccountSettings,
              );
            }),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Custom tab'),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Choose which feature the shortcut opens',
                    style: text.titleMedium,
                  ),
                ),
                const Divider(height: 0),
                RadioListTile<int?>(
                  value: _kCustomNoneChoice,
                  groupValue: selectedCustomValue,
                  onChanged: _onCustomDestinationChanged,
                  title: const Text('None'),
                  subtitle:
                      const Text('Hide the custom button from the nav bar.'),
                  secondary: const Icon(Icons.block),
                ),
                const Divider(height: 0),
                for (final option in _customShortcutOptions) ...[
                  RadioListTile<int?>(
                    value: option.id,
                    groupValue: selectedCustomValue,
                    onChanged: _onCustomDestinationChanged,
                    title: Text(option.settingsLabel),
                    subtitle: Text(option.description),
                    secondary: Icon(option.icon),
                  ),
                  if (option != _customShortcutOptions.last)
                    const Divider(height: 0),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Appearance'),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Theme mode', style: text.titleMedium),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: s.themeMode,
                  onChanged: (v) => s.onChangeThemeMode(v!),
                  title: const Text('System'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  // ignore: deprecated_member_use
                  groupValue: s.themeMode,
                  // ignore: deprecated_member_use
                  onChanged: (v) => s.onChangeThemeMode(v!),
                  title: const Text('Light'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  // ignore: deprecated_member_use
                  groupValue: s.themeMode,
                  // ignore: deprecated_member_use
                  onChanged: (v) => s.onChangeThemeMode(v!),
                  title: const Text('Dark'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Glass(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Accent palette', style: text.titleMedium),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: palettes.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.3,
                    ),
                    itemBuilder: (_, i) {
                      final p = palettes[i];
                      final selected = i == s.paletteIndex;
                      return GestureDetector(
                        onTap: () => s.onChangePalette(i),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white24,
                              width: selected ? 2 : 1,
                            ),
                            gradient: LinearGradient(colors: p.lightGradient),
                          ),
                          child: Center(
                            child: Text(
                              p.name.split(' ').last,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Glass(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Primary color', style: text.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final c in [
                        palettes[s.paletteIndex].seed,
                        const Color(0xFF2563EB),
                        const Color(0xFF22C55E),
                        const Color(0xFFF59E0B),
                        const Color(0xFFEF4444),
                        const Color(0xFFA855F7),
                        const Color(0xFF06B6D4),
                        const Color(0xFF111827),
                      ])
                        _SeedSwatch(
                          color: c,
                          selected: s.seedColor == c,
                          onTap: () => s.onChangeSeed(c),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Notifications'),
          Glass(
            child: Column(
              children: [
                SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: (v) => setState(() => _notificationsEnabled = v),
                  title: const Text('Enable notifications'),
                  subtitle: const Text('Receive reminders and status updates'),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  value: _medReminders,
                  onChanged: _notificationsEnabled
                      ? (v) => setState(() => _medReminders = v)
                      : null,
                  title: const Text('Medication reminders'),
                  subtitle: const Text('Doses, refills, interactions'),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  value: _appointmentReminders,
                  onChanged: _notificationsEnabled
                      ? (v) => setState(() => _appointmentReminders = v)
                      : null,
                  title: const Text('Appointment reminders'),
                  subtitle: const Text('24 hr & 1 hr before visits'),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  value: _newsletterOptIn,
                  onChanged: (v) => setState(() => _newsletterOptIn = v),
                  title: const Text('Wellness newsletter'),
                  subtitle: const Text('Weekly progress stories & tips'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Preferences'),
          Glass(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.stacked_bar_chart),
                  title: const Text('Measurement unit'),
                  subtitle: Text(_measurementUnit),
                  onTap: _pickUnits,
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Interface language'),
                  subtitle: Text(
                      LanguagePreferences.labelFor(_preferredLanguageCode)),
                  trailing: FilledButton.tonal(
                    onPressed: _pickLanguage,
                    child: const Text('Change'),
                  ),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Privacy controls'),
                  subtitle: const Text('Manage data sharing & export logs'),
                  trailing: FilledButton.tonal(
                    onPressed: () =>
                        showToast(context, 'Privacy controls coming soon'),
                    child: const Text('Open'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Support'),
          Glass(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.slideshow),
                  title: const Text('Replay onboarding'),
                  subtitle: const Text('Show the app-wide intro again'),
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.onboarding,
                    arguments: {'replay': true},
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help center'),
                  onTap: () => showToast(context, 'Help center coming soon'),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.contact_mail_outlined),
                  title: const Text('Contact support'),
                  subtitle: const Text('support@patienttracker.app'),
                  onTap: () => showToast(context, 'Opening mail composer...'),
                  trailing: const Icon(Icons.open_in_new),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms & privacy policy'),
                  onTap: () =>
                      showToast(context, 'Viewing policies (placeholder)'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickUnits() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        final options = [
          'Metric (kg, cm)',
          'Imperial (lb, ft)',
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Select measurement unit',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...options.map(
                (opt) => ListTile(
                  title: Text(opt),
                  trailing: opt == _measurementUnit
                      ? Icon(Icons.check,
                          color: Theme.of(ctx).colorScheme.primary)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(opt),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() => _measurementUnit = result);
    }
  }

  Future<void> _loadPreferredLanguage() async {
    final code = await LanguagePreferences.loadPreferredLanguageCode();
    if (!mounted) return;
    setState(() => _preferredLanguageCode = code);
  }

  Future<void> _pickLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Choose language',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
          ),
          ...LanguagePreferences.supportedLanguages.map(
            (lang) => RadioListTile<String>(
              value: lang.code,
              groupValue: _preferredLanguageCode,
              title: Text(lang.label),
              onChanged: (value) => Navigator.of(ctx).pop(value),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );

    if (selected != null && selected != _preferredLanguageCode) {
      setState(() => _preferredLanguageCode = selected);
      await LanguagePreferences.savePreferredLanguageCode(selected);
      if (mounted) {
        showToast(context,
            'Language updated to ${LanguagePreferences.labelFor(selected)}');
      }
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
      ),
    );
  }
}

class _SeedSwatch extends StatelessWidget {
  const _SeedSwatch(
      {required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.white.withValues(alpha: 0.4),
            width: selected ? 3 : 1.6,
          ),
          gradient: SweepGradient(
            colors: [
              color.withValues(alpha: 0.9),
              color.withValues(alpha: 0.5),
              color
            ],
          ),
        ),
      ),
    );
  }
}
