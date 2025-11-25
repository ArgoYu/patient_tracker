part of 'package:patient_tracker/app_modules.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({
    super.key,
    required this.profile,
    this.onProfileChanged,
  });

  final PatientProfile profile;
  final ValueChanged<PatientProfile>? onProfileChanged;

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  late PatientProfile _profile;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  Future<void> _openChangePassword() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
    );
  }

  Future<void> _openContactInfo() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AccountContactInfoPage(profile: _profile),
      ),
    );
  }

  Future<void> _openLanguageRegion() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const LanguageRegionPage()),
    );
  }

  Future<void> _openNotificationPreferences() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const NotificationPreferencesPage()),
    );
  }

  Future<void> _openPrivacy() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const PrivacySecurityPage()),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This action will permanently remove your Echo AI account data. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthRepository.instance.deleteAccount();
        if (!mounted) return;
        showToast(context, 'Account deletion requested (demo).');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGatePage()),
          (route) => false,
        );
      } catch (_) {
        if (mounted) {
          showToast(context, 'Could not delete the account right now.');
        }
      }
    }
  }

  Future<void> _handleSignOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await AuthRepository.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGatePage()),
        (route) => false,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _signingOut = false);
        showToast(context, 'Unable to sign out. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final avatarUrl = _profile.avatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final mrn = _profile.patientId;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const _SectionLabel('Profile'),
          Glass(
            child: ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                child: hasAvatar ? null : const Icon(Icons.person, size: 28),
              ),
              title: Text(_profile.name, style: text.titleMedium),
              subtitle: Text(mrn),
              trailing: const Text('Read-only'),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Account management'),
          Glass(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openChangePassword,
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.alternate_email),
                  title: const Text('Email & phone'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openContactInfo,
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language & region'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openLanguageRegion,
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notification preferences'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openNotificationPreferences,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Privacy & security'),
          Glass(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Privacy & data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openPrivacy,
                ),
                const Divider(height: 0),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: colorScheme.error),
                  title: Text(
                    'Delete account',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  trailing: Icon(Icons.chevron_right, color: colorScheme.error),
                  onTap: _confirmDeleteAccount,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _signingOut ? null : _handleSignOut,
              icon: const Icon(Icons.logout),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              label: Text(_signingOut ? 'Signing out...' : 'Sign out'),
            ),
          ),
        ],
      ),
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentC = TextEditingController();
  final _newC = TextEditingController();
  final _confirmC = TextEditingController();

  bool _busy = false;

  @override
  void dispose() {
    _currentC.dispose();
    _newC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;
    setState(() => _busy = true);
    try {
      await AuthRepository.instance.changePassword(
        currentPassword: _currentC.text,
        newPassword: _newC.text,
      );
      if (!mounted) return;
      showToast(context, 'Password updated (demo).');
      Navigator.of(context).pop();
    } on AuthRepositoryException catch (e) {
      if (mounted) {
        showToast(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        showToast(context, 'Unable to change password right now.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Glass(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _currentC,
                      decoration: const InputDecoration(
                        labelText: 'Current password',
                      ),
                      obscureText: true,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newC,
                      decoration: const InputDecoration(
                        labelText: 'New password',
                      ),
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Required';
                        }
                        if (v.length < 8) {
                          return 'Use at least 8 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmC,
                      decoration: const InputDecoration(
                        labelText: 'Confirm new password',
                      ),
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Required';
                        }
                        if (v != _newC.text) {
                          return 'Passwords do not match.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Saving...' : 'Update password'),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountContactInfoPage extends StatefulWidget {
  const AccountContactInfoPage({super.key, required this.profile});

  final PatientProfile profile;

  @override
  State<AccountContactInfoPage> createState() => _AccountContactInfoPageState();
}

class _AccountContactInfoPageState extends State<AccountContactInfoPage> {
  String? _loginEmail;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final email = await AuthRepository.instance.currentEmail();
    if (!mounted) return;
    setState(() => _loginEmail = email);
  }

  @override
  Widget build(BuildContext context) {
    final email =
        _loginEmail ?? widget.profile.email ?? 'No login email on file';
    final phone = widget.profile.phoneNumber ?? 'Add a phone number later';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email & phone'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Glass(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text(email),
                  subtitle: const Text('Login email'),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(phone),
                  subtitle: const Text('Phone number'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Editing email and phone will be available soon.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class LanguageRegionPage extends StatefulWidget {
  const LanguageRegionPage({super.key});

  @override
  State<LanguageRegionPage> createState() => _LanguageRegionPageState();
}

class _LanguageRegionPageState extends State<LanguageRegionPage> {
  String _languageCode = LanguagePreferences.fallbackLanguageCode;
  String? _timeZone;
  bool _loading = true;
  bool _saving = false;

  List<String> get _timeZoneOptions {
    final current = DateTime.now().timeZoneName;
    final set = <String>{
      if (current.isNotEmpty) current,
      'UTC',
      'America/New_York',
      'America/Los_Angeles',
      'Europe/London',
      'Europe/Berlin',
      'Asia/Shanghai',
    }.toList()
      ..sort();
    if (current.isNotEmpty) {
      set.remove(current);
      set.insert(0, current);
    }
    return set;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final code = await LanguagePreferences.loadPreferredLanguageCode();
    final tz = await LanguagePreferences.loadPreferredTimeZone();
    if (!mounted) return;
    setState(() {
      _languageCode = code;
      _timeZone = tz ?? DateTime.now().timeZoneName;
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await LanguagePreferences.savePreferredLanguageCode(_languageCode);
    await LanguagePreferences.savePreferredTimeZone(_timeZone);
    if (!mounted) return;
    setState(() => _saving = false);
    showToast(context, 'Language & region updated');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language & region'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionLabel('Preferred language'),
          Glass(
            child: Column(
              children: [
                for (final lang in LanguagePreferences.supportedLanguages) ...[
                  RadioListTile<String>(
                    value: lang.code,
                    groupValue: _languageCode,
                    onChanged: (value) =>
                        setState(() => _languageCode = value ?? _languageCode),
                    title: Text(lang.label),
                  ),
                  if (lang != LanguagePreferences.supportedLanguages.last)
                    const Divider(height: 0),
                ]
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Time zone / region'),
          Glass(
            child: ListTile(
              leading: const Icon(Icons.public),
              title: DropdownButton<String>(
                value: _timeZone ?? _timeZoneOptions.first,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: _timeZoneOptions
                    .map(
                      (tz) => DropdownMenuItem<String>(
                        value: tz,
                        child: Text(tz),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _timeZone = value),
              ),
              subtitle: const Text('Used for reminders and translations'),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save preferences'),
          ),
        ],
      ),
    );
  }
}

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends State<NotificationPreferencesPage> {
  bool _reminders = true;
  bool _alerts = true;
  bool _productUpdates = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Glass(
            child: Column(
              children: [
                SwitchListTile(
                  value: _reminders,
                  title: const Text('Reminders'),
                  subtitle: const Text('Appointment and med reminders'),
                  onChanged: (v) => setState(() => _reminders = v),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  value: _alerts,
                  title: const Text('Alerts'),
                  subtitle: const Text('Critical updates and escalations'),
                  onChanged: (v) => setState(() => _alerts = v),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  value: _productUpdates,
                  title: const Text('Product updates'),
                  subtitle: const Text('Newsletters, tips, and new features'),
                  onChanged: (v) => setState(() => _productUpdates = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Preferences are local-only for now. Alerts will remain enabled '
            'for safety-related events.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & data'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Glass(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your data stays protected.',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We encrypt information in transit and at rest. '
                    'Data is never shared without your permission. '
                    'Export and deletion controls will live here soon.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () =>
                        showToast(context, 'Privacy content placeholder'),
                    child: const Text('Learn more'),
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
