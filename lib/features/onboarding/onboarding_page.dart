import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/routing/app_routes.dart';

const kOnboardingVersion = 2;

class OnboardingFlowArguments {
  const OnboardingFlowArguments({this.replay = false});
  final bool replay;
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static const routeName = '/onboarding';

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;
  bool micGranted = false;
  bool camGranted = false;
  bool notifGranted = false;
  bool consentChecked = false;
  String _exportFormat = 'pdf';
  bool _includePatientQuestions = true;
  bool _showScoreBar = true;
  bool _autoFollowUps = true;
  bool _highlightMeds = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isReplayFlow() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is OnboardingFlowArguments) {
      return args.replay;
    }
    if (args is Map) {
      final replay = args['replay'];
      if (replay is bool) {
        return replay;
      }
    }
    return false;
  }

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  Future<void> _grant(Permission permission, ValueSetter<bool> onResult) async {
    final status = await permission.request();
    onResult(status.isGranted);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _finish() async {
    final isReplay = _isReplayFlow();
    if (!consentChecked && !isReplay) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the consent to continue.'),
        ),
      );
      return;
    }
    if (isReplay) {
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setInt('onboarding_version', kOnboardingVersion);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _AnimatedOnboardingPane(
        index: 0,
        currentIndex: _index,
        reduceMotion: _reduceMotion,
        child: _Welcome(
          onGetStarted: () => _controller.nextPage(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
      _AnimatedOnboardingPane(
        index: 1,
        currentIndex: _index,
        reduceMotion: _reduceMotion,
        child: const _AppOverview(),
      ),
      _AnimatedOnboardingPane(
        index: 2,
        currentIndex: _index,
        reduceMotion: _reduceMotion,
        child: const _WorkflowOverview(),
      ),
      _AnimatedOnboardingPane(
        index: 3,
        currentIndex: _index,
        reduceMotion: _reduceMotion,
        child: _Permissions(
          micGranted: micGranted,
          camGranted: camGranted,
          notifGranted: notifGranted,
          onGrantMic: () =>
              _grant(Permission.microphone, (v) => micGranted = v),
          onGrantCam: () =>
              _grant(Permission.camera, (v) => camGranted = camGranted || v),
          onGrantPhotos: () =>
              _grant(Permission.photos, (v) => camGranted = camGranted || v),
          onGrantNotif: () =>
              _grant(Permission.notification, (v) => notifGranted = v),
        ),
      ),
      _AnimatedOnboardingPane(
        index: 4,
        currentIndex: _index,
        reduceMotion: _reduceMotion,
        child: _Consent(
          checked: consentChecked,
          onChanged: (value) => setState(() => consentChecked = value),
        ),
      ),
      _AnimatedOnboardingPane(
        index: 5,
        currentIndex: _index,
        reduceMotion: _reduceMotion,
        child: _Personalize(
          exportFormat: _exportFormat,
          includePatientQuestions: _includePatientQuestions,
          showScoreBar: _showScoreBar,
          autoFollowUps: _autoFollowUps,
          highlightMeds: _highlightMeds,
          onFormatChanged: (format) =>
              setState(() => _exportFormat = format),
          onIncludePatientQuestionsChanged: (value) =>
              setState(() => _includePatientQuestions = value),
          onShowScoreBarChanged: (value) =>
              setState(() => _showScoreBar = value),
          onAutoFollowUpsChanged: (value) =>
              setState(() => _autoFollowUps = value),
          onHighlightMedsChanged: (value) =>
              setState(() => _highlightMeds = value),
        ),
      ),
      _AnimatedOnboardingPane(
        index: 6,
        currentIndex: _index,
        reduceMotion: _reduceMotion,
        child: _Ready(
          onFinish: _finish,
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _Dots(index: _index, total: pages.length),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _index = value),
                children: pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Row(
                children: [
                  if (_index > 0)
                    TextButton(
                      onPressed: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                      ),
                      child: const Text('Previous'),
                    ),
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: _index == pages.length - 1
                        ? 'Finish onboarding'
                        : 'Next onboarding step',
                    child: ElevatedButton(
                      onPressed: () {
                        if (_index == pages.length - 1) {
                          _finish();
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                      child:
                          Text(_index == pages.length - 1 ? 'Finish' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedOnboardingPane extends StatelessWidget {
  const _AnimatedOnboardingPane({
    required this.child,
    required this.index,
    required this.currentIndex,
    required this.reduceMotion,
  });

  final Widget child;
  final int index;
  final int currentIndex;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) {
      return child;
    }
    final isActive = index == currentIndex;
    return AnimatedOpacity(
      opacity: isActive ? 1 : 0.4,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: Offset(0, isActive ? 0 : 0.05),
        child: child,
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return _OnboardingCard(
      title: 'Welcome to Patient Tracker',
      subtitle:
          'Track visits, coordinate with care teams, and keep AI support across the whole app.',
      illustration: Icons.favorite_outline,
      primary: _CardAction(label: 'Get started', onTap: onGetStarted),
    );
  }
}

class _AppOverview extends StatelessWidget {
  const _AppOverview();

  @override
  Widget build(BuildContext context) {
    const sections = [
      (
        label: 'Home',
        description: 'Glanceable stats, vitals, and upcoming follow-ups.',
        icon: Icons.home_outlined,
      ),
      (
        label: 'Chat',
        description: 'Securely message doctors, peers, or group spaces.',
        icon: Icons.chat_bubble_outline,
      ),
      (
        label: 'My AI',
        description: 'Co-Consult, AI Report, Scan, and Ask AI tools.',
        icon: Icons.smart_toy_outlined,
      ),
      (
        label: 'custom',
        description: 'Pin a shortcut to the widget or workflow you rely on.',
        icon: Icons.widgets_outlined,
      ),
      (
        label: 'More',
        description: 'Settings, privacy, help, and support resources.',
        icon: Icons.more_horiz,
      ),
    ];
    return _OnboardingCard(
      title: 'App overview',
      subtitle:
          'Navigate across five areas. Each section keeps the same data model so you never lose context.',
      children: [
        Column(
          children: sections
              .map(
                (section) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _OverviewRow(
                    icon: section.icon,
                    label: section.label,
                    description: section.description,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _WorkflowOverview extends StatelessWidget {
  const _WorkflowOverview();

  @override
  Widget build(BuildContext context) {
    const flows = [
      'Record → Co-Consult → Summary → Plan / Follow-ups → Export',
      'Scan paper report → Extract → Merge into Summary',
    ];
    return _OnboardingCard(
      title: 'Key workflows',
      subtitle:
          'AI stays aligned across intake, collaboration, and export steps.',
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: flows
              .map(
                (flow) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _WorkflowRow(text: flow),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _Permissions extends StatelessWidget {
  const _Permissions({
    required this.micGranted,
    required this.camGranted,
    required this.notifGranted,
    required this.onGrantMic,
    required this.onGrantCam,
    required this.onGrantPhotos,
    required this.onGrantNotif,
  });

  final bool micGranted;
  final bool camGranted;
  final bool notifGranted;
  final VoidCallback onGrantMic;
  final VoidCallback onGrantCam;
  final VoidCallback onGrantPhotos;
  final VoidCallback onGrantNotif;

  @override
  Widget build(BuildContext context) {
    return _OnboardingCard(
      title: 'Permissions',
      subtitle: 'Grant access when you are ready. You can skip for now.',
      children: [
        _PermissionTile(
          label: 'Microphone (Co-Consult)',
          description: 'Allow AI to listen for summaries during visits.',
          granted: micGranted,
          onGrant: onGrantMic,
        ),
        const Divider(),
        _PermissionTile(
          label: 'Camera / Photos (Scan)',
          description: 'Capture paper charts or add existing media.',
          granted: camGranted,
          onGrant: () {
            onGrantCam();
            onGrantPhotos();
          },
        ),
        const Divider(),
        _PermissionTile(
          label: 'Notifications (Follow-ups)',
          description: 'Send gentle reminders after rounds.',
          granted: notifGranted,
          onGrant: onGrantNotif,
        ),
      ],
    );
  }
}

class _Consent extends StatelessWidget {
  const _Consent({
    required this.checked,
    required this.onChanged,
  });

  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _OnboardingCard(
      title: 'Privacy & consent',
      subtitle:
          'We process audio, camera, and chat data only to keep your record current. You can delete it or turn permissions off at any time.',
      children: [
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.privacy_tip_outlined),
          title: Text('You stay in control'),
          subtitle: Text(
            'Data is encrypted in transit and at rest, and you can clear conversation history from Settings → Privacy.',
          ),
        ),
        CheckboxListTile(
          value: checked,
          onChanged: (value) => onChanged(value ?? false),
          title: const Text(
            'I agree to the AI drafting and data processing policy',
          ),
        ),
        Wrap(
          spacing: 16,
          children: [
            TextButton(
              onPressed: () {},
              child: const Text('Privacy Policy'),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Terms'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Personalize extends StatelessWidget {
  const _Personalize({
    required this.exportFormat,
    required this.includePatientQuestions,
    required this.showScoreBar,
    required this.autoFollowUps,
    required this.highlightMeds,
    required this.onFormatChanged,
    required this.onIncludePatientQuestionsChanged,
    required this.onShowScoreBarChanged,
    required this.onAutoFollowUpsChanged,
    required this.onHighlightMedsChanged,
  });

  final String exportFormat;
  final bool includePatientQuestions;
  final bool showScoreBar;
  final bool autoFollowUps;
  final bool highlightMeds;
  final ValueChanged<String> onFormatChanged;
  final ValueChanged<bool> onIncludePatientQuestionsChanged;
  final ValueChanged<bool> onShowScoreBarChanged;
  final ValueChanged<bool> onAutoFollowUpsChanged;
  final ValueChanged<bool> onHighlightMedsChanged;

  @override
  Widget build(BuildContext context) {
    final chips = ['PDF', 'TXT'];
    return _OnboardingCard(
      title: 'Personalize',
      subtitle: 'Configure defaults for exports and AI suggestions.',
      children: [
        Text(
          'Default export format',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: chips
              .map(
                (chip) => ChoiceChip(
                  label: Text(chip),
                  selected: exportFormat == chip.toLowerCase(),
                  onSelected: (_) => onFormatChanged(chip.toLowerCase()),
                ),
              )
              .toList(),
        ),
        const Divider(height: 32),
        _ToggleRow(
          label: 'Auto-create patient questions section',
          value: includePatientQuestions,
          onChanged: onIncludePatientQuestionsChanged,
        ),
        _ToggleRow(
          label: 'Show score bar on report page',
          value: showScoreBar,
          onChanged: onShowScoreBarChanged,
        ),
        _ToggleRow(
          label: 'Auto-generate follow-ups',
          value: autoFollowUps,
          onChanged: onAutoFollowUpsChanged,
        ),
        _ToggleRow(
          label: 'Highlight medication changes',
          value: highlightMeds,
          onChanged: onHighlightMedsChanged,
        ),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({
    required this.onFinish,
  });

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return _OnboardingCard(
      title: 'You’re all set',
      subtitle:
          'Personalization is saved. Head to Home to start exploring other tabs.',
      actions: [
        _CardAction(
          label: 'Go to Home',
          onTap: onFinish,
        ),
      ],
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.title,
    this.subtitle,
    this.children,
    this.actions,
    this.primary,
    this.illustration,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? children;
  final List<_CardAction>? actions;
  final _CardAction? primary;
  final IconData? illustration;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 16),
            color: Color(0x11000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (illustration != null)
            Align(
              alignment: Alignment.centerRight,
              child: Icon(
                illustration,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
              ),
            ),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.black54),
            ),
          ],
          if (children != null) ...[
            const SizedBox(height: 16),
            ...children!,
          ],
          if (primary != null || (actions?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (primary != null) primary!.build(context),
                ...(actions ?? []).map((a) => a.build(context)),
              ],
            ),
          ],
        ],
      ),
    );
    return Semantics(
      label: title,
      container: true,
      child: card,
    );
  }
}

class _CardAction {
  const _CardAction({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: FilledButton(
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.icon,
    required this.label,
    required this.description,
  });

  final IconData icon;
  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkflowRow extends StatelessWidget {
  const _WorkflowRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.bolt_outlined, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.label,
    required this.description,
    required this.granted,
    required this.onGrant,
  });

  final String label;
  final String description;
  final bool granted;
  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(description),
      trailing: granted
          ? const Chip(
              label: Text('Granted'),
              backgroundColor: Color(0xFFE4F5EC),
            )
          : OutlinedButton(
              onPressed: onGrant,
              child: const Text('Grant'),
            ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.total, required this.index});

  final int total;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
        (i) {
          final isActive = i == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
          );
        },
      ),
    );
  }
}
