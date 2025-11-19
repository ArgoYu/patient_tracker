// ignore_for_file: unused_field

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'chat_settings_page.dart';

/// ===================== MESSAGES =====================
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final List<_Message> _messages = [];
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  bool _isComposing = false;
  bool _botTyping = false;
  bool _notificationsMuted = false;
  bool _allowMentions = true;
  bool _shareReadReceipts = true;
  bool _dailyDigestEnabled = false;

  // Bot simulation
  Timer? _botTypingTimer;
  Timer? _botResponseTimer;

  @override
  void dispose() {
    _botTypingTimer?.cancel();
    _botResponseTimer?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _messages.insert(
          0,
          _Message(
            sender: MessageSender.user,
            type: MessageType.text,
            text: trimmed,
            timestamp: DateTime.now(),
            status: MessageStatus.sent,
          ));
      _isComposing = false;
    });
    _textController.clear();
    _scrollToBottom();

    // Simulate bot response
    _botTypingTimer = Timer(const Duration(milliseconds: 600), () {
      setState(() => _botTyping = true);
      _scrollToBottom();
    });

    _botResponseTimer = Timer(const Duration(seconds: 2), () {
      setState(() {
        _messages.insert(
            0,
            _Message(
              sender: MessageSender.bot,
              type: MessageType.text,
              text: 'I am a bot. I do not understand.',
              timestamp: DateTime.now(),
              status: MessageStatus.sent,
            ));
        _botTyping = false;
      });
      _scrollToBottom();
    });
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted || pickedFile == null) return;
    setState(() {
      _messages.insert(
        0,
        _Message(
          sender: MessageSender.user,
          type: MessageType.image,
          text: 'Shared an image',
          imageUrl: pickedFile.path,
          timestamp: DateTime.now(),
          status: MessageStatus.sent,
        ),
      );
    });
    _scrollToBottom();
    _showSnackBar('Image shared with the group');
  }

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Group Info',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text('This is a support group for patients.'),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMoreActions() async {
    final action = await showModalBottomSheet<_GroupMoreAction>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group actions',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _MoreActionTile(
                  icon: Icons.info_outline,
                  title: 'Community guidelines',
                  subtitle: 'Review group expectations',
                  onTap: () => Navigator.of(context)
                      .pop(_GroupMoreAction.guidelines),
                ),
                _MoreActionTile(
                  icon: Icons.search,
                  title: 'Search chat',
                  subtitle: 'Find past conversations',
                  onTap: () =>
                      Navigator.of(context).pop(_GroupMoreAction.search),
                ),
                _MoreActionTile(
                  icon: _notificationsMuted
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  title: _notificationsMuted
                      ? 'Unmute notifications'
                      : 'Mute notifications',
                  subtitle: _notificationsMuted
                      ? 'Notifications are currently muted'
                      : 'Receive group updates',
                  onTap: () => Navigator.of(context)
                      .pop(_GroupMoreAction.toggleMute),
                ),
                _MoreActionTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Shared media',
                  subtitle: 'See photos and files',
                  onTap: () =>
                      Navigator.of(context).pop(_GroupMoreAction.media),
                ),
                _MoreActionTile(
                  icon: Icons.settings_suggest_outlined,
                  title: 'Chat preferences',
                  subtitle: 'Adjust your personal settings',
                  onTap: () => Navigator.of(context)
                      .pop(_GroupMoreAction.preferences),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _GroupMoreAction.guidelines:
        _showGroupInfo();
        break;
      case _GroupMoreAction.search:
        await _openSearch();
        break;
      case _GroupMoreAction.toggleMute:
        _toggleMute();
        break;
      case _GroupMoreAction.media:
        _openSharedMedia();
        break;
      case _GroupMoreAction.preferences:
        await _openPreferences();
        break;
    }
  }

  Future<void> _openSearch() async {
    if (_messages.isEmpty) {
      _showSnackBar('No messages to search yet');
      return;
    }
    final result = await showSearch<_Message?>(
      context: context,
      delegate: _GroupChatSearchDelegate(List<_Message>.from(_messages)),
    );
    if (!mounted || result == null) return;
    final preview = (result.text ?? '').trim().isEmpty
        ? 'Shared media'
        : result.text!;
    _showSnackBar('Found message: $preview');
  }

  void _toggleMute() {
    setState(() => _notificationsMuted = !_notificationsMuted);
    _showSnackBar(_notificationsMuted
        ? 'Group notifications muted'
        : 'Group notifications unmuted');
  }

  void _openSharedMedia() {
    final mediaItems = _messages
        .where((msg) => msg.type == MessageType.image)
        .map(
          (msg) {
            final timeLabel = MaterialLocalizations.of(context).formatTimeOfDay(
              TimeOfDay.fromDateTime(msg.timestamp),
            );
            return ChatMediaItem(
              title: msg.text ?? 'Shared image',
              subtitle: 'Shared at $timeLabel',
              icon: Icons.photo_outlined,
            );
          },
        )
        .toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatMediaGalleryPage(
          title: 'Group shared media',
          items: mediaItems,
        ),
      ),
    );
  }

  Future<void> _openPreferences() async {
    final result = await Navigator.of(context).push<Map<String, bool>>(
      MaterialPageRoute(
        builder: (_) => ChatPreferencesPage(
          title: 'Group chat preferences',
          options: [
            ChatPreferenceOption(
              key: 'mentions',
              title: 'Allow @ mentions',
              subtitle: 'Members can tag you in updates',
              icon: Icons.alternate_email_outlined,
              value: _allowMentions,
            ),
            ChatPreferenceOption(
              key: 'receipts',
              title: 'Share read receipts',
              subtitle: 'Let others know when you read messages',
              icon: Icons.mark_chat_read_outlined,
              value: _shareReadReceipts,
            ),
            ChatPreferenceOption(
              key: 'digest',
              title: 'Daily digest summary',
              subtitle: 'Receive a morning recap of highlights',
              icon: Icons.calendar_today_outlined,
              value: _dailyDigestEnabled,
            ),
          ],
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _allowMentions = result['mentions'] ?? _allowMentions;
      _shareReadReceipts = result['receipts'] ?? _shareReadReceipts;
      _dailyDigestEnabled = result['digest'] ?? _dailyDigestEnabled;
    });
    _showSnackBar('Preferences updated');
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Chat'),
        leading: IconButton(
          tooltip: 'Group info',
          icon: const Icon(Icons.group_outlined),
          onPressed: _showGroupInfo,
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showMoreActions,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: _messages.length + (_botTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_botTyping && index == 0) {
                  return const _TypingIndicator();
                }
                final message = _messages[_botTyping ? index - 1 : index];
                return _MessageBubble(
                  message: message,
                  onInteraction: (interaction) {
                    // Handle message interactions
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              '${interaction.toString().split('.').last} message')),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _composerButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      splashRadius: 22,
    );
  }

  Widget _buildTextComposer() {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: IconTheme(
        data: IconThemeData(color: theme.colorScheme.secondary),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Row(
            children: [
              _composerButton(
                icon: Icons.photo_library,
                onPressed: _pickImage,
              ),
              const SizedBox(width: 4),
              _composerButton(
                icon: Icons.mic,
                onPressed: () {
                  // TODO: Implement voice message functionality
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _textController,
                  onChanged: (text) {
                    setState(() {
                      _isComposing = text.trim().isNotEmpty;
                    });
                  },
                  onSubmitted: _sendMessage,
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Send a message',
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _composerButton(
                icon: Icons.send,
                onPressed: _isComposing
                    ? () => _sendMessage(_textController.text)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MessageInteraction { reply, emoji, like, copy, forward }

enum _GroupMoreAction {
  guidelines,
  search,
  toggleMute,
  media,
  preferences,
}

class _MoreActionTile extends StatelessWidget {
  const _MoreActionTile({
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
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}

class _GroupChatSearchDelegate extends SearchDelegate<_Message?> {
  _GroupChatSearchDelegate(this.messages);

  final List<_Message> messages;

  List<_Message> _filter(String query) => messages
      .where((msg) =>
          (msg.text ?? '').toLowerCase().contains(query.toLowerCase()))
      .toList();

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Search messages'));
    }
    return _buildList(context);
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = _filter(query);
    if (results.isEmpty) {
      return const Center(child: Text('No results'));
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final message = results[index];
        final preview = (message.text ?? '').trim().isEmpty
            ? 'Shared media'
            : message.text!;
        final timeLabel = MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay.fromDateTime(message.timestamp),
        );
        return ListTile(
          leading: Icon(
            message.sender == MessageSender.user
                ? Icons.person_outline
                : Icons.android_outlined,
          ),
          title: Text(preview),
          subtitle: Text(timeLabel),
          onTap: () => close(context, message),
        );
      },
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onInteraction});

  final _Message message;
  final ValueChanged<_MessageInteraction> onInteraction;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  onInteraction(_MessageInteraction.reply);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_emotions_outlined),
                title: const Text('React'),
                onTap: () {
                  onInteraction(_MessageInteraction.emoji);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.thumb_up_alt_outlined),
                title: const Text('Like'),
                onTap: () {
                  onInteraction(_MessageInteraction.like);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.text ?? ''));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.forward),
                title: const Text('Forward'),
                onTap: () {
                  onInteraction(_MessageInteraction.forward);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUser) const CircleAvatar(child: Icon(Icons.android)),
            const SizedBox(width: 8.0),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: isUser
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Text(
                  message.text ?? '',
                  style: TextStyle(
                    color: isUser
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            if (isUser) const CircleAvatar(child: Icon(Icons.person)),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: const Row(
        children: [
          CircleAvatar(child: Icon(Icons.android)),
          SizedBox(width: 8.0),
          Text('Bot is typing...'),
        ],
      ),
    );
  }
}

class _Message {
  const _Message({
    required this.sender,
    required this.type,
    this.text,
    this.imageUrl,
    required this.timestamp,
    required this.status,
  });

  final MessageSender sender;
  final MessageType type;
  final String? text;
  final String? imageUrl;
  final DateTime timestamp;
  final MessageStatus status;
}

enum MessageSender { user, bot }

enum MessageType { text, image, audio }

enum MessageStatus { sending, sent, delivered, read }
