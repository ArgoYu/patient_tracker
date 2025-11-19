part of 'package:patient_tracker/app_modules.dart';

class CareTeamMessagesPage extends StatefulWidget {
  const CareTeamMessagesPage({
    super.key,
    this.initialConversation,
    this.highlightConversation,
  });

  final ConversationType? initialConversation;
  final ConversationType? highlightConversation;

  @override
  State<CareTeamMessagesPage> createState() => _CareTeamMessagesPageState();
}

enum ConversationType { coach, physician, nurse, peer, group }

class _ChatContact {
  const _ChatContact({
    required this.type,
    required this.name,
    required this.role,
    required this.icon,
    required this.color,
  });

  final ConversationType type;
  final String name;
  final String role;
  final IconData icon;
  final Color color;
}

const List<_ChatContact> _careTeamContacts = [
  _ChatContact(
    type: ConversationType.coach,
    name: 'my personal care AI',
    role: 'Care coach',
    icon: Icons.support_agent,
    color: Color(0xFF3B82F6),
  ),
  _ChatContact(
    type: ConversationType.peer,
    name: 'Peer supporter',
    role: 'Peer mentor',
    icon: Icons.handshake_outlined,
    color: Color(0xFFFB923C),
  ),
  _ChatContact(
    type: ConversationType.physician,
    name: 'Dr. Wang',
    role: 'Primary physician',
    icon: Icons.local_hospital,
    color: Color(0xFF6366F1),
  ),
  _ChatContact(
    type: ConversationType.nurse,
    name: 'Nurse Kim',
    role: 'Care nurse',
    icon: Icons.volunteer_activism,
    color: Color(0xFF10B981),
  ),
  _ChatContact(
    type: ConversationType.group,
    name: 'Recovery circle',
    role: 'Support group',
    icon: Icons.groups_3_outlined,
    color: Color(0xFF14B8A6),
  ),
];

class _CareTeamMessagesPageState extends State<CareTeamMessagesPage> {
  List<_ChatContact> get _contacts => _careTeamContacts;

  late final Map<ConversationType, List<_Msg>> _threads;
  late final Map<ConversationType, List<String>> _autoReplies;
  late final Map<ConversationType, int> _replyCursor;
  late final Map<ConversationType, bool> _replyPending;
  late ConversationType _activeConversation;
  ConversationType? _highlightedConversation;
  Timer? _highlightTimer;
  bool _routeArgsHandled = false;

  final TextEditingController _composer = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _notificationsMuted = false;
  bool _readReceiptsEnabled = true;
  bool _autoDownloadMedia = true;
  bool _smartRepliesEnabled = true;

  @override
  void initState() {
    super.initState();
    _threads = {
      for (final contact in _contacts) contact.type: <_Msg>[],
    };
    _autoReplies = {
      ConversationType.coach: [
        'Thanks for sharing. Want to tell me more about that?',
        'Good plan—shall we schedule a reminder?',
        'Noted. Try logging how you feel after your routine tonight.',
      ],
      ConversationType.peer: [
        'You got this. What helped you through the last tough moment?',
        'I relate to that—want to try a breathing exercise together?',
        'Proud of you for reaching out. Let’s take it one step at a time.',
      ],
      ConversationType.physician: [
        'Thanks, I will review before our Friday check-in.',
        'Please keep tracking sleep quality; it helps a lot.',
        'Reach out if symptoms change suddenly.',
      ],
      ConversationType.nurse: [
        'On it! I’ll update your chart.',
        'Remember to hydrate today.',
        'Thanks for the update—message me if you need anything else.',
      ],
      ConversationType.group: [
        'We’re cheering you on! What small win can you share today?',
        'Great question. Anyone else want to chime in?',
        'We’d love to hear how your week is going—share when ready.',
      ],
    };
    _replyCursor = {
      for (final contact in _contacts) contact.type: 0,
    };
    _replyPending = {
      for (final contact in _contacts) contact.type: false,
    };
    _activeConversation = widget.initialConversation ??
        widget.highlightConversation ??
        _contacts.first.type;
    _highlightedConversation = widget.highlightConversation;
    _seedConversations();
    if (_highlightedConversation != null) {
      _scheduleHighlightClear();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      if (_highlightedConversation != null) {
        _announceFocus(_highlightedConversation!);
      }
    });
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusConversation(target);
    });
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _composer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _seedConversations() {
    final now = DateTime.now();
    _threads[ConversationType.coach]!.addAll([
      _Msg(
        sender: 'my personal care AI',
        text: "Hi Argo! I'm here whenever you want to talk.",
        isUser: false,
        time: now.subtract(const Duration(minutes: 20)),
      ),
      _Msg(
        sender: 'You',
        text: "Hey! I'd like help keeping my medication schedule on track.",
        isUser: true,
        time: now.subtract(const Duration(minutes: 17)),
      ),
    ]);

    _threads[ConversationType.peer]!.addAll([
      _Msg(
        sender: 'Peer supporter',
        text: 'Hey! Checking in—how are cravings today?',
        isUser: false,
        time: now.subtract(const Duration(hours: 3, minutes: 5)),
      ),
    ]);

    _threads[ConversationType.physician]!.addAll([
      _Msg(
        sender: 'Dr. Wang',
        text: "Morning! Let's review your sleep logs this Friday.",
        isUser: false,
        time: now.subtract(const Duration(hours: 4, minutes: 12)),
      ),
    ]);

    _threads[ConversationType.nurse]!.addAll([
      _Msg(
        sender: 'Nurse Kim',
        text: 'Your labs are scheduled for Wednesday 9 AM.',
        isUser: false,
        time: now.subtract(const Duration(hours: 2, minutes: 30)),
      ),
    ]);

    _threads[ConversationType.group]!.addAll([
      _Msg(
        sender: 'Recovery circle',
        text: 'Welcome back! Share your wins or struggles anytime.',
        isUser: false,
        time: now.subtract(const Duration(hours: 6)),
      ),
    ]);
  }

  void _focusConversation(ConversationType type) {
    _highlightTimer?.cancel();
    setState(() {
      _activeConversation = type;
      _highlightedConversation = type;
    });
    _scheduleHighlightClear();
    _announceFocus(type);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _sendMessage() {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    final list = _threads[_activeConversation]!;
    setState(() {
      list.add(
        _Msg(
          sender: 'You',
          text: text,
          isUser: true,
          time: DateTime.now(),
        ),
      );
    });
    _composer.clear();
    _scrollToBottom();
    _scheduleAutoReply(_activeConversation);
  }

  void _scheduleAutoReply(ConversationType type) {
    if (_replyPending[type] == true) return;
    final replies = _autoReplies[type];
    if (replies == null || replies.isEmpty) return;
    _replyPending[type] = true;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) {
        _replyPending[type] = false;
        return;
      }
      final list = _threads[type]!;
      final contact = _contacts.firstWhere((c) => c.type == type);
      final cursor = _replyCursor[type] ?? 0;
      final reply = replies[cursor % replies.length];
      _replyCursor[type] = cursor + 1;
      setState(() {
        list.add(
          _Msg(
            sender: contact.name,
            text: reply,
            isUser: false,
            time: DateTime.now(),
          ),
        );
      });
      if (_activeConversation == type) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
      _replyPending[type] = false;
    });
  }

  void _scheduleHighlightClear() {
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _highlightedConversation = null);
    });
  }

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

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 60,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openSettings() async {
    final contact = _contacts.firstWhere((c) => c.type == _activeConversation);
    final selection = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ChatSettingsPage(
          title: '${contact.name} settings',
          entries: [
            const ChatSettingEntry(
              key: 'search',
              icon: Icons.search,
              title: 'Search chat',
            ),
            ChatSettingEntry(
              key: 'mute',
              icon: _notificationsMuted
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              title: _notificationsMuted
                  ? 'Unmute notifications'
                  : 'Mute notifications',
            ),
            const ChatSettingEntry(
              key: 'media',
              icon: Icons.folder_shared_outlined,
              title: 'Shared media',
            ),
            const ChatSettingEntry(
              key: 'preferences',
              icon: Icons.settings_suggest_outlined,
              title: 'Chat preferences',
            ),
          ],
          footer: _notificationsMuted
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Notifications are muted for this conversation.',
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
      case 'search':
        await _openSearch(contact);
        break;
      case 'mute':
        _toggleMute();
        break;
      case 'media':
        _openSharedMedia(contact);
        break;
      case 'preferences':
        await _openPreferences();
        break;
    }
  }

  void _toggleMute() {
    setState(() => _notificationsMuted = !_notificationsMuted);
    showToast(
      context,
      _notificationsMuted ? 'Notifications muted' : 'Notifications unmuted',
    );
  }

  Future<void> _openSearch(_ChatContact contact) async {
    final messages = _threads[_activeConversation] ?? [];
    final result = await showSearch<_Msg?>(
      context: context,
      delegate: _CareChatSearchDelegate(messages),
    );
    if (!mounted || result == null) return;
    final list = _threads[_activeConversation] ?? [];
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

  void _openSharedMedia(_ChatContact contact) {
    final list = _threads[_activeConversation] ?? [];
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
          title: '${contact.name} shared media',
          items: items,
        ),
      ),
    );
  }

  Future<void> _openPreferences() async {
    final result = await Navigator.of(context).push<Map<String, bool>>(
      MaterialPageRoute(
        builder: (_) => ChatPreferencesPage(
          title: 'Care team chat preferences',
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
              subtitle: 'Automatically download attachments.',
              icon: Icons.download_outlined,
              value: _autoDownloadMedia,
            ),
            ChatPreferenceOption(
              key: 'smartReplies',
              title: 'Smart replies',
              subtitle: 'Suggest quick responses in composer.',
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

  _ChatContact _contactForSender(String sender) {
    return _contacts.firstWhere(
      (c) => c.name == sender,
      orElse: () => _contacts.firstWhere((c) => c.type == _activeConversation),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _buildMessageBubble(_Msg message, bool showReadReceipt) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final contact = isUser
        ? _contacts.firstWhere((c) => c.type == _activeConversation)
        : _contactForSender(message.sender);
    final isDark = theme.brightness == Brightness.dark;
    final bubbleColor = isUser
        ? theme.colorScheme.primary.withValues(alpha: 0.94)
        : contact.color.withValues(alpha: isDark ? 0.28 : 0.18);
    final Color textColor = isUser
        ? theme.colorScheme.onPrimary
        : (isDark
            ? Colors.white.withValues(alpha: 0.92)
            : theme.colorScheme.onSurface.withValues(alpha: 0.9));

    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: contact.color.withValues(alpha: 0.18),
              child: Icon(contact.icon, color: contact.color, size: 18),
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
                    contact.name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          contact.color.withValues(alpha: isDark ? 0.95 : 0.85),
                    ),
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: contact.color
                              .withValues(alpha: isDark ? 0.35 : 0.22),
                          width: isUser ? 0 : 1,
                        ),
                      ),
                      child: Text(
                        message.text,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: textColor),
                      ),
                    ),
                  ),
                  if (isUser)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, size: 18),
                      ),
                    ),
                ],
              ),
              Text(
                _formatTime(message.time),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
              if (isUser && showReadReceipt)
                Text(
                  'Read',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: textColor.withValues(alpha: 0.7),
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
    final activeContact =
        _contacts.firstWhere((c) => c.type == _activeConversation);
    final messages = _threads[_activeConversation]!;
    final highlightActive = _highlightedConversation == _activeConversation;
    final highlightColor = _highlightAccent(_activeConversation);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Care Team Chat'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Video call',
            onPressed: () => showToast(context, 'Video call coming soon'),
            icon: const Icon(Icons.videocam_outlined),
          ),
          IconButton(
            tooltip: 'Voice call',
            onPressed: () => showToast(context, 'Voice call coming soon'),
            icon: const Icon(Icons.call_outlined),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: highlightActive
                    ? LinearGradient(
                        colors: [
                          highlightColor.withValues(alpha: 0.28),
                          highlightColor.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: highlightActive ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: highlightActive
                      ? highlightColor.withValues(alpha: 0.6)
                      : Colors.transparent,
                  width: 1.4,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        activeContact.color.withValues(alpha: 0.12),
                    child: Icon(activeContact.icon, color: activeContact.color),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeContact.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(activeContact.role,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.65),
                                  )),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final lastUserIndex = messages.lastIndexWhere((m) => m.isUser);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _buildMessageBubble(
                    msg,
                    _readReceiptsEnabled &&
                        index == lastUserIndex &&
                        msg.isUser,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Camera / gallery',
                  onPressed: () =>
                      showToast(context, 'Camera and gallery coming soon'),
                  icon: const Icon(Icons.camera_alt_outlined),
                ),
                Expanded(
                  child: TextField(
                    controller: _composer,
                    decoration: const InputDecoration(
                      hintText: 'Type a message…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  tooltip: 'Emoji',
                  onPressed: () => showToast(context, 'Stickers coming soon'),
                  icon: const Icon(Icons.emoji_emotions_outlined),
                ),
                IconButton(
                  tooltip: 'Voice message',
                  onPressed: () =>
                      showToast(context, 'Voice clips coming soon'),
                  icon: const Icon(Icons.mic_none_outlined),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  _Msg({
    required this.sender,
    required this.text,
    required this.isUser,
    required this.time,
  });

  final String sender;
  final String text;
  final bool isUser;
  final DateTime time;
}

class _CareChatSearchDelegate extends SearchDelegate<_Msg?> {
  _CareChatSearchDelegate(this.messages);

  final List<_Msg> messages;

  List<_Msg> _results(String query) => messages
      .where((msg) => msg.text.toLowerCase().contains(query.toLowerCase()))
      .toList();

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Search conversation'));
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
          subtitle: Text(_formatResultTime(msg.time)),
          onTap: () => close(context, msg),
        );
      },
    );
  }

  static String _formatResultTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
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

class _MealOptionTile extends StatelessWidget {
  const _MealOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final MealOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.55)
                : theme.colorScheme.outline.withValues(alpha: 0.25),
            width: selected ? 1.6 : 1,
          ),
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.09)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.14),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    option.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(Icons.check_circle,
                      color: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(option.description),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(
                  label: Text('${option.calories} kcal'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
                ...option.tags.map(
                  (tag) => Chip(
                    label: Text(tag),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            if (option.note != null) ...[
              const SizedBox(height: 6),
              Text(
                'Chef note: ${option.note!}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension on MealSlot {
  String get label => switch (this) {
        MealSlot.breakfast => 'Breakfast',
        MealSlot.lunch => 'Lunch',
        MealSlot.dinner => 'Dinner',
        MealSlot.snack => 'Refuel snack',
      };

  Color get color => switch (this) {
        MealSlot.breakfast => const Color(0xFFFFC857),
        MealSlot.lunch => const Color(0xFF4CC9F0),
        MealSlot.dinner => const Color(0xFFEE6352),
        MealSlot.snack => const Color(0xFF7F5AF0),
      };
}
