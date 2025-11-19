// ignore_for_file: use_build_context_synchronously

part of 'package:patient_tracker/app_modules.dart';

class EducationPage extends StatefulWidget {
  const EducationPage({super.key});

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationModule {
  const _EducationModule({
    required this.title,
    required this.summary,
    required this.duration,
    required this.topics,
  });

  final String title;
  final String summary;
  final String duration;
  final List<String> topics;
}

class _EducationResource {
  const _EducationResource({
    required this.title,
    required this.description,
    required this.actionLabel,
  });

  final String title;
  final String description;
  final String actionLabel;
}

class _EducationPageState extends State<EducationPage> {
  final List<_EducationModule> _modules = const [
    _EducationModule(
      title: 'Understanding Your Medications',
      summary:
          'Learn how each prescription supports your recovery and how to stay on schedule.',
      duration: '7 min video',
      topics: [
        'Why adherence matters',
        'Handling missed doses safely',
        'Tracking side effects & improvements',
      ],
    ),
    _EducationModule(
      title: 'Sleep & Recovery Foundations',
      summary:
          'Reset your sleep routine with habits that complement your treatment plan.',
      duration: '5 min guide',
      topics: [
        'Wind-down rituals that work',
        'Screens & blue-light exposure',
        'Morning routines that stick',
      ],
    ),
    _EducationModule(
      title: 'Navigating Mood Changes',
      summary: 'Spot triggers early and use proven tools to steady daily mood.',
      duration: 'Interactive checklist',
      topics: [
        'Recognising early warning signs',
        'Creating a coping plan',
        'When to message your care team',
      ],
    ),
  ];

  final List<_EducationResource> _resources = const [
    _EducationResource(
      title: 'Mindfulness micro-exercises',
      description:
          'Three 60-second resets you can try during the day to ground yourself.',
      actionLabel: 'View exercises',
    ),
    _EducationResource(
      title: 'Preparing for appointments',
      description:
          'Checklist to capture symptoms, questions, and wins before you meet your clinician.',
      actionLabel: 'Download checklist',
    ),
    _EducationResource(
      title: 'Community stories',
      description:
          'Read how other patients built sustainable habits during recovery.',
      actionLabel: 'Read stories',
    ),
  ];

  final Set<int> _completedModules = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Education'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Glass(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.16),
                    child: const Icon(Icons.school_outlined, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Build knowledge in small steps',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 6),
                        Text(
                            'Save modules for later or tap to mark them complete when you feel confident.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Recommended modules'),
          ...List.generate(_modules.length, (index) {
            final module = _modules[index];
            final completed = _completedModules.contains(index);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Glass(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  module.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(module.summary),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Chip(
                                label: Text(module.duration),
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(height: 6),
                              FilterChip(
                                selected: completed,
                                label:
                                    Text(completed ? 'Completed' : 'Mark done'),
                                onSelected: (value) {
                                  setState(() {
                                    if (value) {
                                      _completedModules.add(index);
                                    } else {
                                      _completedModules.remove(index);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: module.topics
                            .map(
                              (topic) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline,
                                        size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(topic)),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          const _SectionLabel('Quick tips'),
          const Glass(
            child: Column(
              children: [
                _TipTile(
                  icon: Icons.lightbulb_outline,
                  title: '5-7-8 breathing reset',
                  body:
                      'Breathe in for 5, hold 7, exhale 8. Repeat three rounds to dampen fight-or-flight.',
                ),
                Divider(height: 0),
                _TipTile(
                  icon: Icons.schedule_outlined,
                  title: 'Habit stacking',
                  body:
                      'Anchor new routines to existing habits—e.g. meds immediately after brushing teeth.',
                ),
                Divider(height: 0),
                _TipTile(
                  icon: Icons.people_outline,
                  title: 'Care circle check-in',
                  body:
                      'Pick one person each week to update on how you’re doing. Shared progress keeps momentum.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Helpful resources'),
          ..._resources.map(
            (res) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Glass(
                child: ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(res.title),
                  subtitle: Text(res.description),
                  trailing: FilledButton.tonal(
                    onPressed: () => showToast(
                        context, 'Opening ${res.title} (placeholder)'),
                    child: Text(res.actionLabel),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  const _TipTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(body),
    );
  }
}

class CommunityChatPage extends StatefulWidget {
  const CommunityChatPage({super.key, this.initialCommunity});

  final PeerCommunity? initialCommunity;

  @override
  State<CommunityChatPage> createState() => _CommunityChatPageState();
}

enum PeerCommunity { anxiety, pain, sleep }

enum _GroupResourceType { link, video, pdf }

class _GroupResource {
  const _GroupResource({
    required this.title,
    required this.description,
    required this.type,
    required this.sourceLabel,
  });

  final String title;
  final String description;
  final _GroupResourceType type;
  final String sourceLabel;
}

class _PeerGroup {
  const _PeerGroup({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onlineCount,
    required this.resources,
  });

  final PeerCommunity id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int onlineCount;
  final List<_GroupResource> resources;
}

const List<_PeerGroup> _peerGroups = [
  _PeerGroup(
    id: PeerCommunity.anxiety,
    title: 'Anxiety & Panic Circle',
    subtitle: 'Swap grounding routines, morning check-ins, and small wins.',
    icon: Icons.self_improvement,
    color: Color(0xFF3B82F6),
    onlineCount: 42,
    resources: [
      _GroupResource(
        title: '4-7-8 Breathing Routine',
        description: 'Guided video to help reset your nervous system.',
        type: _GroupResourceType.video,
        sourceLabel: 'Watch tutorial',
      ),
      _GroupResource(
        title: 'Racing Thoughts Toolkit',
        description: 'Quick worksheet with grounding prompts and scripts.',
        type: _GroupResourceType.pdf,
        sourceLabel: 'Download PDF',
      ),
      _GroupResource(
        title: 'Daily Check-in Template',
        description: 'Link to our shared journal doc for nightly updates.',
        type: _GroupResourceType.link,
        sourceLabel: 'Open document',
      ),
    ],
  ),
  _PeerGroup(
    id: PeerCommunity.pain,
    title: 'Chronic Pain Support',
    subtitle: 'Compare pacing strategies, PT wins, and flare plans.',
    icon: Icons.favorite_outline,
    color: Color(0xFFF97316),
    onlineCount: 28,
    resources: [
      _GroupResource(
        title: 'Pacing Planner Spreadsheet',
        description: 'Track activity bursts and recovery windows.',
        type: _GroupResourceType.link,
        sourceLabel: 'Open sheet',
      ),
      _GroupResource(
        title: 'Medication Sync Checklist',
        description: 'Printable PDF for coordinating doses with providers.',
        type: _GroupResourceType.pdf,
        sourceLabel: 'Download PDF',
      ),
      _GroupResource(
        title: 'Stretch Ideas Library',
        description: 'Video playlist curated by our PT moderators.',
        type: _GroupResourceType.video,
        sourceLabel: 'View playlist',
      ),
    ],
  ),
  _PeerGroup(
    id: PeerCommunity.sleep,
    title: 'Sleep & Recovery Crew',
    subtitle: 'Build wind-down rituals and better mornings together.',
    icon: Icons.bedtime,
    color: Color(0xFF6366F1),
    onlineCount: 35,
    resources: [
      _GroupResource(
        title: 'Wind-down Routine Builder',
        description: 'Interactive doc to design a 30-minute wind-down plan.',
        type: _GroupResourceType.link,
        sourceLabel: 'Start planning',
      ),
      _GroupResource(
        title: 'Middle-of-Night Rescue Audio',
        description: 'Calming narration to help settle back to sleep.',
        type: _GroupResourceType.video,
        sourceLabel: 'Play audio',
      ),
      _GroupResource(
        title: 'Morning Energy Checklist',
        description: 'PDF cheat sheet for consistent wake-up cues.',
        type: _GroupResourceType.pdf,
        sourceLabel: 'Download PDF',
      ),
    ],
  ),
];

const List<PersonalChatContact> _initialPersonalChats = personalChatContacts;

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key, this.highlightConversation});

  final ConversationType? highlightConversation;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  bool _personalExpanded = true;
  bool _groupExpanded = true;
  bool _careExpanded = true;
  late List<PersonalChatContact> _personalChats;
  final ScrollController _scrollController = ScrollController();
  late final Map<ConversationType, GlobalKey> _careContactKeys;
  late final Map<PeerCommunity, GlobalKey> _groupTileKeys;
  ConversationType? _highlightedConversation;
  PeerCommunity? _highlightedGroup;
  ConversationType? _pendingHighlight;
  bool _routeArgsHandled = false;
  Timer? _highlightTimer;

  static const String _myInviteCode = 'argo-connect-2025';
  static const String _myInviteLink =
      'https://patient-tracker.example/invite/argo-connect-2025';

  @override
  void initState() {
    super.initState();
    _personalChats = List<PersonalChatContact>.of(_initialPersonalChats);
    _careContactKeys = {
      for (final contact in _careTeamContacts) contact.type: GlobalKey()
    };
    _groupTileKeys = {for (final group in _peerGroups) group.id: GlobalKey()};
    final initialTarget = widget.highlightConversation;
    _highlightedConversation =
        initialTarget == ConversationType.peer ? null : initialTarget;
    _highlightedGroup =
        initialTarget == ConversationType.peer ? _peerGroups.first.id : null;
    _pendingHighlight = initialTarget;
    if (_pendingHighlight != null) {
      if (_pendingHighlight == ConversationType.peer) {
        _groupExpanded = true;
      } else {
        _careExpanded = true;
      }
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _maybeTriggerHighlight());
    }
  }

  @override
  void didUpdateWidget(covariant MessagesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightConversation != oldWidget.highlightConversation &&
        widget.highlightConversation != null) {
      _pendingHighlight = widget.highlightConversation;
      if (_pendingHighlight == ConversationType.peer) {
        _groupExpanded = true;
      } else {
        _careExpanded = true;
      }
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _maybeTriggerHighlight());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgsHandled) return;
    _routeArgsHandled = true;
    final route = ModalRoute.of(context);
    if (route == null) return;
    final target = _conversationFromArguments(route.settings.arguments);
    if (target == null) return;
    _pendingHighlight ??= target;
    if (target == ConversationType.peer) {
      _groupExpanded = true;
    } else {
      _careExpanded = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeTriggerHighlight();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _highlightTimer?.cancel();
    super.dispose();
  }

  String _normalizeHandle(String input) => input.trim().toLowerCase();

  String _displayNameFromHandle(String handle) {
    final trimmed = handle.trim();
    if (trimmed.isEmpty) return 'New friend';
    final cleaned = trimmed.replaceAll(RegExp(r'^@'), '');
    final tokens = cleaned
        .split(RegExp(r'[._\s@]+'))
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return trimmed;
    return tokens
        .map((token) =>
            '${token.substring(0, 1).toUpperCase()}${token.substring(1).toLowerCase()}')
        .join(' ');
  }

  Color _colorForHandle(String handle) {
    final normalized = _normalizeHandle(handle);
    if (normalized.isEmpty) {
      return Theme.of(context).colorScheme.primary;
    }
    const palette = Colors.primaries;
    final sum =
        normalized.codeUnits.fold<int>(0, (acc, codeUnit) => acc + codeUnit);
    final swatch = palette[sum % palette.length];
    return swatch.shade400;
  }

  PersonalChatContact _createPersonalChatFromHandle(
    String handle, {
    String? displayName,
    String? subtitle,
  }) {
    final normalizedHandle = _normalizeHandle(handle);
    final name = displayName ?? _displayNameFromHandle(handle);
    final resolvedSubtitle = subtitle ??
        (normalizedHandle.contains('@')
            ? 'Invited via email'
            : 'Connected via username');
    return PersonalChatContact(
      contactId: normalizedHandle.isEmpty ? null : normalizedHandle,
      type: PersonalChatType.custom,
      name: name,
      subtitle: resolvedSubtitle,
      icon: Icons.person_outline,
      color: _colorForHandle(handle),
    );
  }

  void _addPersonalChat(PersonalChatContact contact) {
    final uniqueKey = (contact.contactId ?? contact.name).trim().toLowerCase();
    final alreadyExists = _personalChats.any((existing) {
      final key = (existing.contactId ?? existing.name).trim().toLowerCase();
      return key == uniqueKey;
    });
    if (alreadyExists) {
      showToast(context, '${contact.name} is already in your chats.');
      return;
    }
    setState(() => _personalChats.insert(0, contact));
    showToast(context, '${contact.name} added to personal chats.');
  }

  void _maybeTriggerHighlight() {
    final target = _pendingHighlight;
    if (target == null) return;
    _pendingHighlight = null;
    _focusConversation(target);
  }

  void _focusConversation(ConversationType type) {
    _highlightTimer?.cancel();
    GlobalKey? key;
    setState(() {
      if (type == ConversationType.peer) {
        _groupExpanded = true;
        final group = _peerGroups.first.id;
        _highlightedGroup = group;
        _highlightedConversation = null;
        key = _groupTileKeys[group];
      } else {
        _careExpanded = true;
        _highlightedConversation = type;
        _highlightedGroup = null;
        key = _careContactKeys[type];
      }
    });
    if (key == null) return;
    final targetKey = key as GlobalKey;
    void ensureVisible() {
      if (!mounted) return;
      final targetContext = targetKey.currentContext;
      if (targetContext == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => ensureVisible());
        return;
      }
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 460),
        curve: Curves.easeInOutCubic,
        alignment: 0.12,
      );
      _scheduleHighlightClear();
      _announceFocus(type);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => ensureVisible());
  }

  void _scheduleHighlightClear() {
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      setState(() {
        _highlightedConversation = null;
        _highlightedGroup = null;
      });
    });
  }

  void _announceFocus(ConversationType type) {
    final message = _highlightMessage(type);
    if (message == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 0),
            duration: const Duration(seconds: 2),
          ),
        );
    });
  }

  Color _highlightAccent(ConversationType type) {
    switch (type) {
      case ConversationType.peer:
        return Colors.blueAccent;
      case ConversationType.physician:
        return Colors.greenAccent;
      case ConversationType.nurse:
        return Colors.pinkAccent;
      case ConversationType.group:
        return Colors.purpleAccent;
      case ConversationType.coach:
        return Colors.blueAccent;
    }
  }

  String? _highlightMessage(ConversationType type) => switch (type) {
        ConversationType.peer => "Here’s your peer chat 👋",
        ConversationType.physician =>
          "You’re now chatting with your doctor 👨‍⚕️",
        ConversationType.nurse => "You’re now chatting with your nurse 👩‍⚕️",
        ConversationType.group => "Here’s your recovery group 👥",
        ConversationType.coach => null,
      };

  ConversationType? _conversationFromArguments(Object? arguments) {
    if (arguments == null) return null;
    if (arguments is ConversationType) return arguments;
    if (arguments is Map) {
      final target = arguments['target'] ??
          arguments['conversation'] ??
          arguments['chat'] ??
          arguments['type'];
      if (target is ConversationType) return target;
      if (target is String) return _conversationFromString(target);
    }
    if (arguments is String) {
      return _conversationFromString(arguments);
    }
    return null;
  }

  ConversationType? _conversationFromString(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'peer':
      case 'volunteer':
      case 'supporter':
        return ConversationType.peer;
      case 'doctor':
      case 'physician':
      case 'provider':
        return ConversationType.physician;
      case 'nurse':
      case 'care_nurse':
        return ConversationType.nurse;
      case 'group':
      case 'support':
      case 'community':
        return ConversationType.group;
      case 'coach':
      case 'ai':
      case 'assistant':
        return ConversationType.coach;
    }
    return null;
  }

  Future<void> _showQuickActionsSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: _QuickActionsPanel(
              onAddFriend: () {
                Navigator.of(sheetContext).pop();
                Future.microtask(() => _showAddFriendSheet(context));
              },
              onJoinGroup: () {
                Navigator.of(sheetContext).pop();
                Future.microtask(() => _showJoinGroupSheet(context));
              },
              onCreateGroup: () {
                Navigator.of(sheetContext).pop();
                Future.microtask(() => _showCreateGroupSheet(context));
              },
              onScanQr: () {
                Navigator.of(sheetContext).pop();
                Future.microtask(() => _showScanQrSheet(context));
              },
              onMyQr: () {
                Navigator.of(sheetContext).pop();
                Future.microtask(() => _showMyQrSheet(context));
              },
            ),
          ),
        );
      },
    );
  }

  void _openCommunityChat(BuildContext context, PeerCommunity community) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommunityChatPage(initialCommunity: community),
      ),
    );
  }

  Future<void> _showAddFriendSheet(BuildContext parentContext) async {
    final handle = await showModalBottomSheet<String>(
      context: parentContext,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddFriendSheet(),
    );
    if (!mounted) return;
    if (handle == null || handle.trim().isEmpty) return;
    final contact = _createPersonalChatFromHandle(handle);
    _addPersonalChat(contact);
  }

  void _showJoinGroupSheet(BuildContext parentContext) {
    final navigator = Navigator.of(parentContext);
    showModalBottomSheet<void>(
      context: parentContext,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join a group chat',
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _peerGroups.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final group = _peerGroups[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: group.color.withValues(alpha: 0.14),
                          child: Icon(group.icon, color: group.color),
                        ),
                        title: Text(group.title),
                        subtitle: Text(
                          group.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.add),
                        onTap: () {
                          navigator.pop();
                          showToast(
                            parentContext,
                            'Joined ${group.title}',
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreateGroupSheet(BuildContext parentContext) async {
    await showModalBottomSheet<void>(
      context: parentContext,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CreateGroupSheet(parentContext: parentContext),
    );
  }

  Future<void> _showScanQrSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_ScannedContact>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _QrScannerSheet(),
    );
    if (!mounted || result == null) return;
    final contact = _createPersonalChatFromHandle(
      result.handle,
      displayName: result.displayName,
      subtitle: result.subtitle,
    );
    _addPersonalChat(contact);
  }

  Future<void> _showMyQrSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _MyQrSheet(
        inviteCode: _myInviteCode,
        inviteLink: _myInviteLink,
      ),
    );
  }

  void _openCareTeamChat(BuildContext context, ConversationType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CareTeamMessagesPage(initialConversation: type),
      ),
    );
  }

  void _openPersonalChat(PersonalChatContact chat) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DirectChatPage(contact: chat),
      ),
    );
  }

  Widget _buildPersonalChatsSection(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _personalExpanded,
          onExpansionChanged: (value) =>
              setState(() => _personalExpanded = value),
          leading: Icon(Icons.person_outline, color: theme.colorScheme.primary),
          title: const Text('Personal chats'),
          subtitle: Text('${_personalChats.length} conversations'),
          children: [
            for (final chat in _personalChats)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ChatTile(
                  icon: chat.icon,
                  iconBackgroundColor: chat.color.withValues(alpha: 0.18),
                  iconColor: chat.color,
                  title: chat.name,
                  subtitle: chat.subtitle,
                  onTap: () => _openPersonalChat(chat),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupChatsSection(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _groupExpanded,
          onExpansionChanged: (value) => setState(() => _groupExpanded = value),
          leading:
              Icon(Icons.groups_outlined, color: theme.colorScheme.primary),
          title: const Text('Group chats'),
          subtitle: Text('${_peerGroups.length} active groups'),
          children: [
            for (final group in _peerGroups)
              _buildGroupTile(context, theme, group),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupTile(
    BuildContext context,
    ThemeData theme,
    _PeerGroup group,
  ) {
    final key = _groupTileKeys[group.id];
    final isHighlighted = _highlightedGroup == group.id;
    final highlightColor = _highlightAccent(ConversationType.peer);
    final gradient = isHighlighted
        ? LinearGradient(
            colors: [
              highlightColor.withValues(alpha: 0.3),
              highlightColor.withValues(alpha: 0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;
    final outerPadding =
        isHighlighted ? const EdgeInsets.all(2) : EdgeInsets.zero;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: AnimatedContainer(
        key: key,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        padding: outerPadding,
        decoration: BoxDecoration(
          gradient: gradient,
          color: isHighlighted ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isHighlighted
                ? highlightColor.withValues(alpha: 0.6)
                : Colors.transparent,
            width: isHighlighted ? 1.6 : 1,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: highlightColor.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: ChatTile(
          icon: group.icon,
          iconBackgroundColor: group.color.withValues(alpha: 0.14),
          iconColor: group.color,
          title: group.title,
          subtitle: group.subtitle,
          trailingInfo: '${group.onlineCount} online',
          onTap: () => _openCommunityChat(context, group.id),
          backgroundColor: theme.colorScheme.surface,
          boxShadow: isHighlighted
              ? const []
              : [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildCareTeamTile(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    _ChatContact contact,
  ) {
    final key = _careContactKeys[contact.type];
    final isHighlighted = _highlightedConversation == contact.type;
    final highlightColor = _highlightAccent(contact.type);
    final gradient = isHighlighted
        ? LinearGradient(
            colors: [
              highlightColor.withValues(alpha: 0.32),
              highlightColor.withValues(alpha: 0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;
    final outerPadding =
        isHighlighted ? const EdgeInsets.all(2) : EdgeInsets.zero;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: AnimatedContainer(
        key: key,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        padding: outerPadding,
        decoration: BoxDecoration(
          gradient: gradient,
          color: isHighlighted ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isHighlighted
                ? highlightColor.withValues(alpha: 0.62)
                : Colors.transparent,
            width: isHighlighted ? 1.6 : 1,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: highlightColor.withValues(alpha: 0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: ChatTile(
          icon: contact.icon,
          iconBackgroundColor:
              contact.color.withValues(alpha: isDark ? 0.28 : 0.14),
          iconColor: contact.color,
          title: contact.name,
          subtitle: contact.role,
          onTap: () => _openCareTeamChat(context, contact.type),
          backgroundColor: theme.colorScheme.surface,
          boxShadow: isHighlighted
              ? const []
              : [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildCareTeamSection(ThemeData theme, bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _careExpanded,
          onExpansionChanged: (value) => setState(() => _careExpanded = value),
          leading: Icon(Icons.medical_services_outlined,
              color: theme.colorScheme.primary),
          title: const Text('Care team'),
          subtitle: Text('${_careTeamContacts.length} members'),
          children: [
            for (final contact in _careTeamContacts)
              _buildCareTeamTile(context, theme, isDark, contact),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Messages'),
        actions: [
          IconButton(
            tooltip: 'Quick actions',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showQuickActionsSheet,
          ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: isDark ? 0.25 : 0.7),
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: const TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                icon: Icon(Icons.search),
                hintText: 'Search conversations',
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildPersonalChatsSection(theme),
          const SizedBox(height: 16),
          _buildGroupChatsSection(theme),
          const SizedBox(height: 16),
          _buildCareTeamSection(theme, isDark),
        ],
      ),
    );
  }
}

class _CommunityResponse {
  const _CommunityResponse({required this.sender, required this.text});

  final String sender;
  final String text;
}

class _CommunityChatPageState extends State<CommunityChatPage> {
  late final Map<PeerCommunity, List<_Msg>> _threads;
  late final Map<PeerCommunity, List<_CommunityResponse>> _autoReplies;
  late final Map<PeerCommunity, int> _replyCursor;
  late final Map<PeerCommunity, bool> _replyPending;
  late PeerCommunity _activeCommunity;
  late final Map<PeerCommunity, bool> _resourcesExpanded;
  late final Map<PeerCommunity, bool> _muted;
  bool _readReceiptsEnabled = true;
  bool _autoDownloadMedia = true;
  bool _smartRepliesEnabled = true;

  final TextEditingController _composer = TextEditingController();
  final FocusNode _composerFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _threads = {
      for (final group in _peerGroups) group.id: <_Msg>[],
    };
    _autoReplies = {
      PeerCommunity.anxiety: [
        const _CommunityResponse(
          sender: 'Leah - peer guide',
          text:
              'Box breathing slowed me down yesterday. I can share the steps.',
        ),
        const _CommunityResponse(
          sender: 'Marco',
          text:
              'I keep a pocket card with grounding prompts. Happy to post it.',
        ),
        const _CommunityResponse(
          sender: 'Kayla - moderator',
          text: 'Love these ideas. Remember to tag any resources you try.',
        ),
      ],
      PeerCommunity.pain: [
        const _CommunityResponse(
          sender: 'Amir',
          text:
              'My PT calls it the movement sandwich: stretch, activity, stretch.',
        ),
        const _CommunityResponse(
          sender: 'Naomi',
          text:
              'Warm compress before chores keeps my back calmer. Can walk through it.',
        ),
        const _CommunityResponse(
          sender: 'Drew - peer guide',
          text: 'Log what you tried today so we can spot patterns together.',
        ),
      ],
      PeerCommunity.sleep: [
        const _CommunityResponse(
          sender: 'Ivy',
          text:
              'I swap to low light and a lavender spray 30 minutes before bed.',
        ),
        const _CommunityResponse(
          sender: 'Jordan',
          text:
              'If I wake up, I do a body scan with slow counting. Usually works.',
        ),
        const _CommunityResponse(
          sender: 'Mae - moderator',
          text:
              'Gentle reminder: keep chats supportive. Reach out if you need urgent care.',
        ),
      ],
    };
    _replyCursor = {
      for (final group in _peerGroups) group.id: 0,
    };
    _replyPending = {
      for (final group in _peerGroups) group.id: false,
    };
    _resourcesExpanded = {
      for (final group in _peerGroups) group.id: false,
    };
    _muted = {
      for (final group in _peerGroups) group.id: false,
    };
    final initial = widget.initialCommunity;
    final allowed = _peerGroups.map((g) => g.id).toSet();
    _activeCommunity = initial != null && allowed.contains(initial)
        ? initial
        : _peerGroups.first.id;
    _seedConversations();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _composer.dispose();
    _composerFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _seedConversations() {
    final now = DateTime.now();
    _threads[PeerCommunity.anxiety]!.addAll([
      _Msg(
        sender: 'Kayla - moderator',
        text: 'Welcome to tonight\'s check-in. Share one small calming win.',
        isUser: false,
        time: now.subtract(const Duration(minutes: 42)),
      ),
      _Msg(
        sender: 'Leah - peer guide',
        text: 'I tried the 5-4-3-2-1 grounding sequence on the train. Helped.',
        isUser: false,
        time: now.subtract(const Duration(minutes: 26)),
      ),
      _Msg(
        sender: 'Marco',
        text: 'Morning walk with music slowed my racing thoughts before work.',
        isUser: false,
        time: now.subtract(const Duration(minutes: 18)),
      ),
    ]);

    _threads[PeerCommunity.pain]!.addAll([
      _Msg(
        sender: 'Amir',
        text: 'Breaking chores into 10 minute blocks meant no flare yesterday.',
        isUser: false,
        time: now.subtract(const Duration(minutes: 50)),
      ),
      _Msg(
        sender: 'Naomi',
        text: 'Heat wrap plus gentle twists loosened my shoulders tonight.',
        isUser: false,
        time: now.subtract(const Duration(minutes: 33)),
      ),
      _Msg(
        sender: 'Drew - peer guide',
        text:
            'Remember the color scale tracker? Mine flagged a flare early today.',
        isUser: false,
        time: now.subtract(const Duration(minutes: 12)),
      ),
    ]);

    _threads[PeerCommunity.sleep]!.addAll([
      _Msg(
        sender: 'Mae - moderator',
        text: 'Tonight we are trading wind-down playlists. Drop yours here.',
        isUser: false,
        time: now.subtract(const Duration(minutes: 58)),
      ),
      _Msg(
        sender: 'Jordan',
        text:
            'Setting phone to grayscale after 8 PM keeps me off social media.',
        isUser: false,
        time: now.subtract(const Duration(minutes: 36)),
      ),
      _Msg(
        sender: 'Ivy',
        text:
            'I journal what I want tomorrow to feel like. Unloads my thoughts.',
        isUser: false,
        time: now.subtract(const Duration(minutes: 19)),
      ),
    ]);
  }

  IconData _iconForResource(_GroupResource resource) {
    switch (resource.type) {
      case _GroupResourceType.link:
        return Icons.link_outlined;
      case _GroupResourceType.video:
        return Icons.play_circle_outline;
      case _GroupResourceType.pdf:
        return Icons.picture_as_pdf_outlined;
    }
  }

  IconData _actionIconFor(_GroupResource resource) {
    switch (resource.type) {
      case _GroupResourceType.link:
        return Icons.open_in_new;
      case _GroupResourceType.video:
        return Icons.play_arrow_rounded;
      case _GroupResourceType.pdf:
        return Icons.download;
    }
  }

  void _openResource(_GroupResource resource) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.16),
                      child: Icon(
                        _iconForResource(resource),
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        resource.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  resource.description,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showToast(
                      context,
                      '${resource.sourceLabel} (placeholder)',
                    );
                  },
                  icon: Icon(_actionIconFor(resource)),
                  label: Text(resource.sourceLabel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _PeerGroup _groupFor(PeerCommunity id) =>
      _peerGroups.firstWhere((group) => group.id == id);


  void _sendMessage() {
    final text = _composer.text.trim();
    if (text.isEmpty) return;

    final community = _activeCommunity;
    final now = DateTime.now();
    setState(() {
      _threads[community]!.add(
        _Msg(
          sender: 'You',
          text: text,
          isUser: true,
          time: now,
        ),
      );
    });
    _composer.clear();
    _scrollToBottom();
    _scheduleAutoReply(community);
  }

  void _scheduleAutoReply(PeerCommunity community) {
    final responses = _autoReplies[community];
    if (responses == null || responses.isEmpty) return;
    if (_replyPending[community] == true) return;

    _replyPending[community] = true;
    final index = _replyCursor[community]!;
    final response = responses[index % responses.length];
    _replyCursor[community] = index + 1;

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _threads[community]!.add(
          _Msg(
            sender: response.sender,
            text: response.text,
            isUser: false,
            time: DateTime.now(),
          ),
        );
      });
      _replyPending[community] = false;
      if (_activeCommunity == community) {
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _showGroupDetails(_PeerGroup group) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: group.color
                              .withValues(alpha: isDark ? 0.25 : 0.15),
                          child: Icon(group.icon, color: group.color, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.title,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${group.onlineCount} online',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  group.subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
                if (group.resources.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Group files',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ...group.resources.map(
                    (resource) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _iconForResource(resource),
                        color: group.color,
                      ),
                      title: Text(resource.title),
                      subtitle: Text(resource.description),
                      onTap: () {
                        Navigator.of(context).pop();
                        _openResource(resource);
                      },
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _showGuidelines() {
    final guidelines = [
      'Share lived experience, not medical advice.',
      'Protect privacy. No identifying details about others.',
      'If you are worried about someone\'s safety, flag a moderator.',
    ];
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community guidelines',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                for (final rule in guidelines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            rule,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openGroupSettings(_PeerGroup group) async {
    final selection = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ChatSettingsPage(
          title: '${group.title} settings',
          entries: [
            const ChatSettingEntry(
              key: 'guidelines',
              icon: Icons.info_outline,
              title: 'Community guidelines',
              subtitle: 'Pinned',
            ),
            const ChatSettingEntry(
              key: 'search',
              icon: Icons.search,
              title: 'Search chat',
            ),
            ChatSettingEntry(
              key: 'mute',
              icon: _muted[group.id] ?? false
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              title: (_muted[group.id] ?? false)
                  ? 'Unmute notifications'
                  : 'Mute notifications',
            ),
            const ChatSettingEntry(
              key: 'media',
              icon: Icons.photo_library_outlined,
              title: 'Shared media',
            ),
            const ChatSettingEntry(
              key: 'preferences',
              icon: Icons.settings_suggest_outlined,
              title: 'Chat preferences',
            ),
          ],
          footer: (_muted[group.id] ?? false)
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Notifications are muted for this group.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).hintColor),
                  ),
                )
              : null,
        ),
      ),
    );
    if (!mounted || selection == null) return;
    switch (selection) {
      case 'guidelines':
        _showGuidelines();
        break;
      case 'search':
        await _openGroupSearch(group.id);
        break;
      case 'mute':
        _toggleGroupMute(group.id);
        break;
      case 'media':
        _openGroupSharedMedia(group);
        break;
      case 'preferences':
        await _openGroupPreferences();
        break;
    }
  }

  Future<void> _openGroupSearch(PeerCommunity community) async {
    if (!mounted) return;
    final messages = List<_Msg>.from(_threads[community] ?? []);
    final result = await showSearch<_Msg?>(
      context: context,
      delegate: _GroupChatSearchDelegate(messages),
    );
    if (!mounted || result == null) return;
    final list = _threads[community] ?? [];
    final index = list.indexOf(result);
    if (index == -1 || !_scrollController.hasClients) return;
    _scrollController.animateTo(
      (_scrollController.position.maxScrollExtent /
              (list.isEmpty ? 1 : list.length)) *
          index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _toggleGroupMute(PeerCommunity community) {
    setState(() {
      _muted[community] = !(_muted[community] ?? false);
    });
    showToast(
      context,
      (_muted[community] ?? false)
          ? 'Group notifications muted'
          : 'Group notifications unmuted',
    );
  }

  void _openGroupSharedMedia(_PeerGroup group) {
    final list = _threads[group.id] ?? [];
    final items = list
        .where((msg) => msg.text.contains('http'))
        .map((msg) => ChatMediaItem(
              title: msg.text,
              subtitle: '${msg.sender} • ${_formatTime(msg.time)}',
              icon: msg.text.contains('video')
                  ? Icons.play_circle_outline
                  : Icons.link,
            ))
        .toList();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatMediaGalleryPage(
          title: '${group.title} shared media',
          items: items,
        ),
      ),
    );
  }

  Future<void> _openGroupPreferences() async {
    final result = await Navigator.of(context).push<Map<String, bool>>(
      MaterialPageRoute(
        builder: (_) => ChatPreferencesPage(
          title: 'Group chat preferences',
          options: [
            ChatPreferenceOption(
              key: 'receipts',
              title: 'Read receipts',
              subtitle: 'Show when your messages are read.',
              icon: Icons.visibility_outlined,
              value: _readReceiptsEnabled,
            ),
            ChatPreferenceOption(
              key: 'download',
              title: 'Auto-download media',
              subtitle: 'Automatically download group photos & videos.',
              icon: Icons.download_outlined,
              value: _autoDownloadMedia,
            ),
            ChatPreferenceOption(
              key: 'smartReplies',
              title: 'Smart replies',
              subtitle: 'Show suggested responses in chat composer.',
              icon: Icons.smart_toy_outlined,
              value: _smartRepliesEnabled,
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _readReceiptsEnabled = result['receipts'] ?? _readReceiptsEnabled;
        _autoDownloadMedia = result['download'] ?? _autoDownloadMedia;
        _smartRepliesEnabled = result['smartReplies'] ?? _smartRepliesEnabled;
      });
      showToast(context, 'Preferences updated');
    }
  }

  Widget _buildMessageBubble(
    _Msg message,
    _PeerGroup group,
    bool showReadReceipt,
  ) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final isDark = theme.brightness == Brightness.dark;
    final background = theme.colorScheme.surfaceContainerHighest
        .withValues(alpha: isDark ? 0.35 : 0.75);
    const userGradient = LinearGradient(
      colors: [
        Color(0xFF5B8CFF),
        Color(0xFF377DFF),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final textColor = isUser
        ? Colors.white
        : theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.9 : 0.82);
    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: group.color.withValues(alpha: 0.18),
              child: Icon(
                group.icon,
                size: 16,
                color: group.color,
              ),
            ),
          ),
        Flexible(
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isUser)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    message.sender,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: group.color.withValues(alpha: isDark ? 0.95 : 0.8),
                    ),
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 260),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isUser ? userGradient : null,
                      color: isUser ? null : background,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 6),
                        bottomRight: Radius.circular(isUser ? 6 : 18),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                      ),
                    ),
                  ),
                  if (isUser)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, size: 16),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(message.time),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor.withValues(alpha: 0.65),
                ),
              ),
              if (isUser && showReadReceipt)
                Text(
                  'Read',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: textColor.withValues(alpha: 0.65),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = _groupFor(_activeCommunity);
    final messages = _threads[_activeCommunity]!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leadingWidth: 98,
        leading: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
            GestureDetector(
              onTap: () => _showGroupDetails(group),
              child: CircleAvatar(
                backgroundColor: group.color.withValues(alpha: 0.2),
                child: Icon(group.icon, color: group.color),
              ),
            ),
          ],
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${group.onlineCount} online',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Video chat',
            onPressed: () => showToast(context, 'Video chat coming soon'),
            icon: const Icon(Icons.videocam_outlined),
          ),
          IconButton(
            tooltip: 'Call',
            onPressed: () => showToast(context, 'Voice call coming soon'),
            icon: const Icon(Icons.call_outlined),
          ),
          IconButton(
            tooltip: 'Community guidelines',
            onPressed: _showGuidelines,
            icon: const Icon(Icons.info_outline),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openGroupSettings(group),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          if (group.resources.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                elevation: 0,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    initiallyExpanded:
                        _resourcesExpanded[_activeCommunity] ?? false,
                    onExpansionChanged: (expanded) {
                      setState(() =>
                          _resourcesExpanded[_activeCommunity] = expanded);
                    },
                    leading: Icon(Icons.folder_outlined,
                        color: theme.colorScheme.primary),
                    title: const Text('Group files'),
                    subtitle:
                        Text('${group.resources.length} shared resources'),
                    children: [
                      for (final resource in group.resources)
                        ListTile(
                          leading: Icon(
                            _iconForResource(resource),
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(resource.title),
                          subtitle: Text(resource.description),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openResource(resource),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          if (group.resources.isNotEmpty) const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final lastUserIndex = messages.lastIndexWhere((m) => m.isUser);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _buildMessageBubble(
                    msg,
                    group,
                    _readReceiptsEnabled &&
                        index == lastUserIndex &&
                        msg.isUser,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Camera / gallery',
                  onPressed: () =>
                      showToast(context, 'Camera and gallery coming soon'),
                  icon: const Icon(Icons.camera_alt_outlined),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: isDark ? 0.28 : 0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color:
                            theme.colorScheme.outline.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _composer,
                            focusNode: _composerFocus,
                            decoration: const InputDecoration(
                              hintText: 'Chat message...',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Stickers',
                  onPressed: () => showToast(context, 'Stickers coming soon'),
                  icon: const Icon(Icons.emoji_emotions_outlined),
                ),
                IconButton(
                  tooltip: 'Voice message',
                  onPressed: () =>
                      showToast(context, 'Voice clips coming soon'),
                  icon: const Icon(Icons.mic_none_outlined),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                  ),
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupChatSearchDelegate extends SearchDelegate<_Msg?> {
  _GroupChatSearchDelegate(this.messages);

  final List<_Msg> messages;

  List<_Msg> _results(String query) => messages
      .where((msg) => msg.text.toLowerCase().contains(query.toLowerCase()))
      .toList();

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Search messages'));
    }
    return _buildList();
  }

  @override
  Widget buildResults(BuildContext context) => _buildList();

  Widget _buildList() {
    final filtered = _results(query);
    if (filtered.isEmpty) {
      return const Center(child: Text('No results'));
    }
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final msg = filtered[index];
        return ListTile(
          leading: Icon(msg.isUser ? Icons.person : Icons.chat_bubble_outline),
          title: Text(msg.text),
          subtitle: Text(
              '${msg.sender} • ${msg.time.hour}:${msg.time.minute.toString().padLeft(2, '0')}'),
          onTap: () => close(context, msg),
        );
      },
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );
}

class _AddFriendSheet extends StatefulWidget {
  const _AddFriendSheet();

  @override
  State<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<_AddFriendSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheetNavigator = Navigator.of(context);
    final bottomPadding = 20 + MediaQuery.of(context).viewInsets.bottom;
    final canSubmit = _controller.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a friend',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Username or email',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => sheetNavigator.pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: canSubmit
                    ? () {
                        final target = _controller.text.trim();
                        sheetNavigator.pop(target);
                      }
                    : null,
                child: const Text('Send request'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateGroupSheet extends StatefulWidget {
  const _CreateGroupSheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _membersController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _membersController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _membersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheetNavigator = Navigator.of(context);
    final bottomPadding = 20 + MediaQuery.of(context).viewInsets.bottom;
    final hasName = _nameController.text.trim().isNotEmpty;
    final hasMembers = _membersController.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create a group chat',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Group name',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _membersController,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Invite members (comma separated)',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => sheetNavigator.pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: hasName && hasMembers
                    ? () {
                        final groupName = _nameController.text.trim();
                        sheetNavigator.pop();
                        showToast(
                          widget.parentContext,
                          'Group "$groupName" created',
                        );
                      }
                    : null,
                child: const Text('Create'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScannedContact {
  const _ScannedContact({
    required this.handle,
    required this.displayName,
    required this.subtitle,
  });

  final String handle;
  final String displayName;
  final String subtitle;
}

class _QrScannerSheet extends StatefulWidget {
  const _QrScannerSheet();

  @override
  State<_QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<_QrScannerSheet> {
  bool _isScanning = false;
  _ScannedContact? _detected;
  int _nextSampleIndex = 0;

  static const List<_ScannedContact> _samples = [
    _ScannedContact(
      handle: 'lucas.recovery',
      displayName: 'Lucas Diaz',
      subtitle: 'Connected via QR scan',
    ),
    _ScannedContact(
      handle: 'jen.support',
      displayName: 'Jen Park',
      subtitle: 'Shared daily mood check-ins',
    ),
    _ScannedContact(
      handle: 'calm-circle',
      displayName: 'Calm Circle',
      subtitle: 'Peer support group invite',
    ),
  ];

  void _startScan() {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _detected = null;
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _detected = _samples[_nextSampleIndex];
        _nextSampleIndex = (_nextSampleIndex + 1) % _samples.length;
      });
    });
  }

  void _confirmContact() {
    final contact = _detected;
    if (contact == null) return;
    Navigator.of(context).pop(contact);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, size: 64, color: cs.primary),
            const SizedBox(height: 16),
            Text(
              'Scan a QR code',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'Align the QR code inside the frame to connect instantly.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isScanning ? null : _startScan,
              icon: Icon(
                  _isScanning ? Icons.hourglass_top : Icons.qr_code_scanner),
              label: Text(_isScanning ? 'Scanning...' : 'Start scanning'),
            ),
            if (_isScanning) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Looking for QR codes...',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (_detected != null) ...[
              const SizedBox(height: 28),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.secondary.withValues(alpha: 0.14),
                    child: Text(
                      _detected!.displayName.characters.first.toUpperCase(),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: cs.secondary),
                    ),
                  ),
                  title: Text(_detected!.displayName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_detected!.subtitle),
                      const SizedBox(height: 2),
                      Text(
                        '@${_detected!.handle}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _confirmContact,
                child: const Text('Add to chats'),
              ),
              TextButton(
                onPressed: _isScanning ? null : _startScan,
                child: const Text('Scan another code'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MyQrSheet extends StatelessWidget {
  const _MyQrSheet({
    required this.inviteCode,
    required this.inviteLink,
  });

  final String inviteCode;
  final String inviteLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final size = media.size;
    final cs = theme.colorScheme;
    final qrSide = math.min(size.width * 0.78, (size.height * 0.6));

    Future<void> copyLink() async {
      await Clipboard.setData(ClipboardData(text: inviteLink));
      showToast(context, 'Invite link copied to clipboard');
    }

    Future<void> shareInvite() async {
      await Share.share(
        'Add me on Patient Tracker: $inviteLink',
        subject: 'Join me on Patient Tracker',
      );
    }

    return SizedBox(
      height: size.height,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_2, size: 80, color: cs.primary),
              const SizedBox(height: 16),
              Text(
                'My QR code',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'Share this QR code or link to let friends add you quickly.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Container(
                width: qrSide,
                height: qrSide,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    width: 4,
                    color: cs.primary.withValues(alpha: 0.6),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code, size: 220),
                ),
              ),
              const SizedBox(height: 24),
              SelectableText(
                inviteLink,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Invite code: $inviteCode',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: copyLink,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy link'),
                  ),
                  OutlinedButton.icon(
                    onPressed: shareInvite,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatTile extends StatelessWidget {
  const ChatTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingInfo,
    this.onTap,
    this.iconBackgroundColor,
    this.iconColor,
    this.backgroundColor,
    this.boxShadow,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingInfo;
  final VoidCallback? onTap;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceColor = backgroundColor ?? theme.colorScheme.surface;
    final effectiveBoxShadow = boxShadow ??
        [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ];
    final subtitleColor = theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: effectiveBoxShadow.isEmpty ? null : effectiveBoxShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: iconBackgroundColor ??
                    theme.colorScheme.primary.withValues(alpha: 0.16),
                child: Icon(
                  icon,
                  size: 22,
                  color: iconColor ?? theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingInfo != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    trailingInfo!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              const Icon(Icons.chevron_right, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel({
    required this.onAddFriend,
    required this.onJoinGroup,
    required this.onCreateGroup,
    required this.onScanQr,
    required this.onMyQr,
  });

  final VoidCallback onAddFriend;
  final VoidCallback onJoinGroup;
  final VoidCallback onCreateGroup;
  final VoidCallback onScanQr;
  final VoidCallback onMyQr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick actions',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _QuickActionTile(
              icon: Icons.person_add_alt_1,
              title: 'Add friend',
              subtitle: 'Send a request by username or email.',
              onTap: onAddFriend,
            ),
            _QuickActionTile(
              icon: Icons.group_add_outlined,
              title: 'Join group chat',
              subtitle: 'Browse available community groups.',
              onTap: onJoinGroup,
            ),
            _QuickActionTile(
              icon: Icons.groups_2,
              title: 'Create group chat',
              subtitle: 'Start a shared conversation.',
              onTap: onCreateGroup,
            ),
            _QuickActionTile(
              icon: Icons.qr_code_scanner,
              title: 'Scan QR code',
              subtitle: 'Add friends or groups instantly.',
              onTap: onScanQr,
            ),
            _QuickActionTile(
              icon: Icons.qr_code_2,
              title: 'My QR code',
              subtitle: 'Share your code for quick adds.',
              onTap: onMyQr,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        child: Icon(icon),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
