import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/routing/app_routes.dart';
import '../auth/auth_service.dart';
import '../auth/mock_auth_api.dart';
import '../auth/two_factor_setup_screen.dart';
import '../user/mock_user_api.dart';
import '../../shared/language_preferences.dart';
import '../../shared/prefs_keys.dart';

const _pronounOptions = [
  'She/her',
  'He/him',
  'They/them',
  'Prefer not to say',
];

const _genderOptions = [
  'Male',
  'Female',
  'Non-binary',
  'Prefer not to say',
];

const _raceOptions = [
  'Asian',
  'Black or African American',
  'White',
  'Hispanic or Latino',
  'Native American or Alaska Native',
  'Native Hawaiian or Other Pacific Islander',
  'Multiple races',
  'Prefer not to say',
];

const _accessibilityNeedOptions = [
  'Larger text or high contrast',
  'Screen reader support',
  'Reduced animations',
  'Captioning for audio / video',
  'Other',
];

class GlobalOnboardingFlowArguments {
  const GlobalOnboardingFlowArguments({
    this.replay = false,
    this.userId,
    this.isNewlyRegistered = false,
  });

  final bool replay;
  final String? userId;
  final bool isNewlyRegistered;
}

class GlobalOnboardingScreen extends StatefulWidget {
  const GlobalOnboardingScreen({
    super.key,
    required this.userId,
    this.replay = false,
    this.isNewlyRegistered = false,
  });

  static const routeName = '/global-onboarding';

  final String userId;
  final bool replay;
  final bool isNewlyRegistered;

  @override
  State<GlobalOnboardingScreen> createState() => _GlobalOnboardingScreenState();
}

class _GlobalOnboardingScreenState extends State<GlobalOnboardingScreen> {
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
  String _preferredLanguageCode =
      LanguagePreferences.fallbackLanguageCode;
  final TextEditingController _preferredNameController = TextEditingController();
  final TextEditingController _legalNameController = TextEditingController();
  String? _selectedPronouns;
  DateTime? _selectedDateOfBirth;
  String? _selectedGender;
  String? _selectedRaceEthnicity;
  final List<String> _selectedAccessibilityOptions = [];
  final TextEditingController _accessibilityNotesController = TextEditingController();
  bool _isSavingProfile = false;
  String? _personalInfoError;

  @override
  void initState() {
    super.initState();
    _loadAccountInfo();
    _preferredNameController.addListener(_onPreferredNameChanged);
    _legalNameController.addListener(_onLegalNameChanged);
    _loadPreferredLanguage();
  }

  @override
  void dispose() {
    _controller.dispose();
    _preferredNameController.removeListener(_onPreferredNameChanged);
    _preferredNameController.dispose();
    _legalNameController.removeListener(_onLegalNameChanged);
    _legalNameController.dispose();
    _accessibilityNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferredLanguage() async {
    final code = await LanguagePreferences.loadPreferredLanguageCode();
    if (!mounted) return;
    setState(() => _preferredLanguageCode = code);
  }

  void _loadAccountInfo() {
    final account = AuthService.instance.currentUserAccount;
    final legalName = account?.legalName?.trim();
    _legalNameController.text = legalName ?? '';
    final preferredName = account?.preferredName?.trim();
    if (preferredName != null && preferredName.isNotEmpty) {
      _preferredNameController.text = preferredName;
    }
  }

  void _onPreferredNameChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onLegalNameChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _toggleAccessibilityOption(String option) {
    setState(() {
      if (_selectedAccessibilityOptions.contains(option)) {
        _selectedAccessibilityOptions.remove(option);
      } else {
        _selectedAccessibilityOptions.add(option);
      }
    });
  }

  Future<void> _onLanguageChanged(String code) async {
    setState(() => _preferredLanguageCode = code);
    await LanguagePreferences.savePreferredLanguageCode(code);
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

  Future<String?> _persistOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      PrefsKeys.preferredLanguageCode,
      _preferredLanguageCode,
    );
    await MockAuthApi.instance.setGlobalOnboardingCompleted(userId: widget.userId);
    AuthService.instance.markGlobalOnboardingCompleted();
    return prefs.getString(PrefsKeys.authEmail);
  }

  Future<void> _completeOnboarding({
    Future<void> Function(String? authEmail)? onComplete,
  }) async {
    final isReplay = widget.replay;
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
    final authEmail = await _persistOnboardingState();
    if (!mounted) return;
    if (onComplete != null) {
      await onComplete(authEmail);
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  bool get _isPersonalInfoValid =>
      _legalNameController.text.trim().isNotEmpty &&
      _preferredNameController.text.trim().isNotEmpty &&
      _selectedDateOfBirth != null;

  Future<void> _savePersonalInfo() async {
    final legalName = _legalNameController.text.trim();
    if (legalName.isEmpty) {
      setState(() {
        _personalInfoError = 'Enter your legal name to continue.';
      });
      return;
    }
    final preferredName = _preferredNameController.text.trim();
    if (preferredName.isEmpty) {
      setState(() {
        _personalInfoError = 'Enter a preferred name to continue.';
      });
      return;
    }
    if (_selectedDateOfBirth == null) {
      setState(() {
        _personalInfoError = 'Enter your date of birth to continue.';
      });
      return;
    }
    setState(() {
      _isSavingProfile = true;
      _personalInfoError = null;
    });
    try {
      final dobValue =
          DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!);
      final accessibilityOptions =
          _selectedAccessibilityOptions.isNotEmpty
              ? List<String>.from(_selectedAccessibilityOptions)
              : null;
      final accessibilityNotes =
          _accessibilityNotesController.text.trim();
      await MockUserApi.instance.updateProfile(
        userId: widget.userId,
        legalName: legalName,
        preferredName: preferredName,
        preferredLanguage: _preferredLanguageCode,
        pronouns: _selectedPronouns,
        dob: dobValue,
        gender: _selectedGender,
        raceEthnicity: _selectedRaceEthnicity,
        accessibilityOptions: accessibilityOptions,
        accessibilityNotes:
            accessibilityNotes.isEmpty ? null : accessibilityNotes,
      );
      await AuthService.instance.refreshCurrentUserAccount();
      await _completeOnboarding(
        onComplete: (authEmail) async {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => TwoFactorSetupScreen(
                userId: widget.userId,
                email: authEmail,
              ),
            ),
          );
        },
      );
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _personalInfoError =
            'Unable to save your personal info. Please try again.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSavingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pages = <Widget>[
      _AnimatedOnboardingPane(
        index: 0,
        currentIndex: _index,
        reduceMotion: _reduceMotion,
        child: _Welcome(
          selectedLanguage: _preferredLanguageCode,
          onLanguageChanged: _onLanguageChanged,
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
          onFormatChanged: (format) => setState(() => _exportFormat = format),
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
    ];
    final finalIndex = pages.length;
    pages.add(
      _AnimatedOnboardingPane(
        index: finalIndex,
        currentIndex: _index,
        reduceMotion: _reduceMotion,
            child: widget.replay
                ? _Ready(onFinish: _completeOnboarding)
                : _PersonalInformation(
                    legalNameController: _legalNameController,
                    preferredNameController: _preferredNameController,
                selectedLanguage: _preferredLanguageCode,
                onLanguageChanged: _onLanguageChanged,
                selectedPronouns: _selectedPronouns,
                onPronounsChanged: (value) =>
                    setState(() => _selectedPronouns = value),
                selectedDateOfBirth: _selectedDateOfBirth,
                onDateOfBirthChanged: (value) =>
                    setState(() => _selectedDateOfBirth = value),
                selectedGender: _selectedGender,
                onGenderChanged: (value) => setState(() => _selectedGender = value),
                selectedRaceEthnicity: _selectedRaceEthnicity,
                onRaceEthnicityChanged: (value) =>
                    setState(() => _selectedRaceEthnicity = value),
                selectedAccessibilityOptions: _selectedAccessibilityOptions,
                onToggleAccessibilityOption: _toggleAccessibilityOption,
                accessibilityNotesController: _accessibilityNotesController,
                isSaving: _isSavingProfile,
                errorMessage: _personalInfoError,
              ),
      ),
    );
    final isPersonalInfoPage = _index == pages.length - 1;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                  if (isPersonalInfoPage)
                    Semantics(
                      button: true,
                      label: 'Save and continue',
                      child: FilledButton(
                        onPressed: (_isSavingProfile || !_isPersonalInfoValid)
                            ? null
                            : _savePersonalInfo,
                        child: _isSavingProfile
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save and continue'),
                      ),
                    )
                  else
                    Semantics(
                      button: true,
                      label: 'Next onboarding step',
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        onPressed: () => _controller.nextPage(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                        ),
                        child: const Text('Next'),
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
  const _Welcome({
    required this.onGetStarted,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  final VoidCallback onGetStarted;
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return _OnboardingCard(
      title: 'Welcome to Patient Tracker',
      subtitle:
          'Track visits, coordinate with care teams, and keep AI support across the whole app.',
      illustration: Icons.favorite_outline,
      primary: _CardAction(label: 'Get started', onTap: onGetStarted),
      children: [
        Text(
          'Choose your language',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: LanguagePreferences.supportedLanguages
              .map(
                (lang) => ChoiceChip(
                  label: Text(lang.label),
                  selected: lang.code == selectedLanguage,
                  selectedColor: colorScheme.primary,
                  onSelected: (_) => onLanguageChanged(lang.code),
                  labelStyle: TextStyle(
                    color: lang.code == selectedLanguage
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: lang.code == selectedLanguage
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        Text(
          'Used for bilingual translation and onboarding text.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
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
        label: 'Echo AI',
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

class _PersonalInformation extends StatelessWidget {
  const _PersonalInformation({
    required this.legalNameController,
    required this.preferredNameController,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.selectedPronouns,
    required this.onPronounsChanged,
    required this.selectedDateOfBirth,
    required this.onDateOfBirthChanged,
    required this.selectedGender,
    required this.onGenderChanged,
    required this.selectedRaceEthnicity,
    required this.onRaceEthnicityChanged,
    required this.selectedAccessibilityOptions,
    required this.onToggleAccessibilityOption,
    required this.accessibilityNotesController,
    required this.isSaving,
    this.errorMessage,
  });

  final TextEditingController legalNameController;
  final TextEditingController preferredNameController;
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;
  final String? selectedPronouns;
  final ValueChanged<String?> onPronounsChanged;
  final DateTime? selectedDateOfBirth;
  final ValueChanged<DateTime?> onDateOfBirthChanged;
  final String? selectedGender;
  final ValueChanged<String?> onGenderChanged;
  final String? selectedRaceEthnicity;
  final ValueChanged<String?> onRaceEthnicityChanged;
  final List<String> selectedAccessibilityOptions;
  final ValueChanged<String> onToggleAccessibilityOption;
  final TextEditingController accessibilityNotesController;
  final bool isSaving;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OnboardingCard(
            title: 'Tell us a bit about you',
            subtitle: 'This helps us personalize messages and defaults.',
            children: [
              TextFormField(
                controller: legalNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Legal name',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: preferredNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Preferred name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedLanguage,
                decoration: const InputDecoration(
                  labelText: 'Preferred language',
                ),
                isExpanded: true,
                items: LanguagePreferences.supportedLanguages
                    .map(
                      (lang) => DropdownMenuItem(
                        value: lang.code,
                        child: Text(lang.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    onLanguageChanged(value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedPronouns,
                decoration: const InputDecoration(
                  labelText: 'Pronouns (optional)',
                  border: OutlineInputBorder(),
                ),
                isExpanded: true,
                hint: const Text('Select'),
                items: _pronounOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      ),
                    )
                    .toList(),
                onChanged: onPronounsChanged,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final firstDate = DateTime(1900);
                  final lastDate = DateTime.now();
                  final initialDate = selectedDateOfBirth ??
                      DateTime.now().subtract(const Duration(days: 365 * 25));
                  final safeInitial = initialDate.isAfter(lastDate)
                      ? lastDate
                      : initialDate;
                  final clampedInitial = safeInitial.isBefore(firstDate)
                      ? firstDate
                      : safeInitial;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: clampedInitial,
                    firstDate: firstDate,
                    lastDate: lastDate,
                  );
                  if (picked != null) {
                    onDateOfBirthChanged(picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of birth',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  isEmpty: selectedDateOfBirth == null,
                  child: Text(
                    selectedDateOfBirth != null
                        ? DateFormat('yyyy-MM-dd').format(selectedDateOfBirth!)
                        : 'Select',
                    style: selectedDateOfBirth == null
                        ? Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).hintColor,
                                )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender (optional)',
                  border: OutlineInputBorder(),
                ),
                isExpanded: true,
                hint: const Text('Select'),
                items: _genderOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      ),
                    )
                    .toList(),
                onChanged: onGenderChanged,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRaceEthnicity,
                decoration: const InputDecoration(
                  labelText: 'Race / ethnicity (optional)',
                  border: OutlineInputBorder(),
                ),
                isExpanded: true,
                hint: const Text('Select'),
                items: _raceOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      ),
                    )
                    .toList(),
                onChanged: onRaceEthnicityChanged,
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Accessibility needs (optional)',
                  border: OutlineInputBorder(),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _accessibilityNeedOptions
                        .map(
                          (option) => FilterChip(
                            label: Text(option),
                            selected: selectedAccessibilityOptions.contains(option),
                            onSelected: (_) => onToggleAccessibilityOption(option),
                            selectedColor:
                                colorScheme.primary.withOpacity(0.12),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: accessibilityNotesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Tell us about any other accessibility needs',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  style: TextStyle(color: colorScheme.error),
                ),
              ],
            ],
          ),
        ],
      ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final card = Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 16),
            color: colorScheme.shadow.withValues(alpha: 0.08),
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
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
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
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(description),
      trailing: granted
          ? Chip(
              label: Text(
                'Granted',
                style: TextStyle(color: colorScheme.onPrimaryContainer),
              ),
              backgroundColor: colorScheme.primaryContainer,
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
