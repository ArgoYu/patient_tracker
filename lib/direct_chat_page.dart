import 'dart:async';

import 'package:flutter/material.dart';

import 'chat_settings_page.dart';
import 'data/models/goal.dart';
import 'data/models/ai_co_consult_outcome.dart';
import 'features/my_ai/controller/ai_co_consult_service.dart';

/// Example page demonstrating a one-to-one chat experience.
class DirectChatPage extends StatefulWidget {
  const DirectChatPage({
    super.key,
    required this.contact,
    this.initialComposerText,
  });

  final PersonalChatContact contact;
  final String? initialComposerText;

  @override
  State<DirectChatPage> createState() => _DirectChatPageState();
}

class _DirectChatPageState extends State<DirectChatPage> {
  late final List<_DirectMessage> _messages;
  late final TextEditingController _textController;
  final _scrollController = ScrollController();
  final AiCoConsultCoordinator _coConsultCoordinator =
      AiCoConsultCoordinator.instance;

  Timer? _autoReplyTimer;
  Timer? _deliveryTimer;
  Timer? _readTimer;
  bool _notificationsMuted = false;
  bool _readReceiptsEnabled = true;
  bool _autoDownloadMedia = true;
  bool _smartRepliesEnabled = true;
  bool _aiCoConsultEnabled = false;
  bool _coConsultBusy = false;
  AiCoConsultOutcome? _lastOutcome;
  int _doctorReplyIndex = 0;
  late final List<String> _doctorReplyScript;

  bool get _isDoctorConversation =>
      widget.contact.type == PersonalChatType.doctor;

  @override
  void initState() {
    super.initState();
    _messages = _seedConversation(widget.contact);
    _doctorReplyScript = _buildDoctorReplyScript();
    final initialComposer = widget.initialComposerText?.trim() ?? '';
    _textController = TextEditingController(
      text: initialComposer.isEmpty ? '' : initialComposer,
    );
  }

  @override
  void dispose() {
    _autoReplyTimer?.cancel();
    _deliveryTimer?.cancel();
    _readTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    if (_aiCoConsultEnabled) {
      _coConsultCoordinator.completeSession();
    }
    super.dispose();
  }

  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _messages.add(
        _DirectMessage(
          text: trimmed,
          isUser: true,
          timestamp: DateTime.now(),
          status: DirectMessageStatus.sent,
        ),
      );
    });
    _textController.clear();
    _recordPatientMessage(trimmed);
    _scrollToBottom();
    final index = _messages.length - 1;
    _deliveryTimer?.cancel();
    _deliveryTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted || index >= _messages.length) return;
      setState(() {
        _messages[index] =
            _messages[index].copyWith(status: DirectMessageStatus.delivered);
      });
    });
    _readTimer?.cancel();
    _readTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || index >= _messages.length) return;
      setState(() {
        _messages[index] =
            _messages[index].copyWith(status: DirectMessageStatus.read);
      });
    });
    _scheduleAutoReply();
  }

  void _scheduleAutoReply() {
    _autoReplyTimer?.cancel();
    _autoReplyTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final reply = _isDoctorConversation
          ? _nextDoctorReply()
          : 'Sounds good! I’ll check in tomorrow night. Proud of you for sticking with the routine.';
      if (reply == null) return;
      setState(() {
        _messages.add(
          _DirectMessage(
            text: reply,
            isUser: false,
            timestamp: DateTime.now(),
            status: DirectMessageStatus.read,
          ),
        );
      });
      _recordClinicianMessage(reply);
      _scrollToBottom();
    });
  }

  void _recordPatientMessage(String message) {
    if (!_aiCoConsultEnabled) return;
    _coConsultCoordinator.recordPatientMessage(message);
  }

  void _recordClinicianMessage(String message) {
    if (!_aiCoConsultEnabled) return;
    _coConsultCoordinator.recordClinicianMessage(message);
  }

  List<String> _buildDoctorReplyScript() {
    return [
      'Great to see you. I read your logs and noticed you kept up with morning walks.',
      'Let’s extend the evening walk to 20 minutes and log how your energy feels right after.',
      'Please take Sertraline at 75 mg starting tomorrow morning with food.',
      'Add a simple breathing routine before bed at least three nights this week to calm racing thoughts.',
      'Schedule a video check-in in two weeks so we can review the medication change.',
    ];
  }

  String? _nextDoctorReply() {
    if (_doctorReplyIndex >= _doctorReplyScript.length) return null;
    final reply = _doctorReplyScript[_doctorReplyIndex];
    _doctorReplyIndex++;
    return reply;
  }

  Future<void> _toggleCoConsult() async {
    if (_coConsultBusy) return;
    if (_aiCoConsultEnabled) {
      await _endCoConsultSession();
    } else {
      _startCoConsultSession();
    }
  }

  void _startCoConsultSession() {
    if (!_isDoctorConversation) {
      _showActionSnack('AI Co-Consult is only available in consult conversations.');
      return;
    }
    final session = _coConsultCoordinator.startSession(
      conversationId:
          widget.contact.contactId ?? widget.contact.name.toLowerCase(),
      contactName: widget.contact.name,
    );
    if (session == null) {
      _showActionSnack('AI Co-Consult permission is not enabled.');
      return;
    }
    for (final message in _messages) {
      if (message.isUser) {
        session.record(
            AiCoConsultSpeaker.patient, message.text, message.timestamp);
      } else {
        session.record(
            AiCoConsultSpeaker.clinician, message.text, message.timestamp);
      }
    }
    setState(() {
      _aiCoConsultEnabled = true;
      _lastOutcome = null;
    });
    _showActionSnack('AI Co-Consult is now enabled, and AI is listening in.');
  }

  Future<void> _endCoConsultSession({bool showSheet = true}) async {
    if (!_aiCoConsultEnabled) return;
    setState(() {
      _coConsultBusy = true;
    });
    AiCoConsultOutcome? outcome;
    try {
      outcome = _coConsultCoordinator.completeSession();
    } catch (error) {
      _showActionSnack('There was a problem ending the AI Co-Consult session.');
    } finally {
      setState(() {
        _aiCoConsultEnabled = false;
        _coConsultBusy = false;
        if (outcome != null) {
          _lastOutcome = outcome;
        }
      });
    }
    if (!mounted || outcome == null) return;
    if (showSheet) {
      await _showOutcomeSheet(outcome);
    }
    _showActionSnack('AI Co-Consult summary is ready.');
  }

  Future<void> _showOutcomeSheet(AiCoConsultOutcome outcome) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _CoConsultSummarySheet(
        outcome: outcome,
        allowSignature: _coConsultCoordinator.isReportPendingReview,
        onShareWithPatient: () => _handleShareWithPatient(outcome),
      ),
    );
  }

  Future<void> _handleShareWithPatient(AiCoConsultOutcome outcome) async {
    if (!_coConsultCoordinator.isReportPendingReview) return;
    final signature = await _promptDoctorSignature();
    if (signature == null) return;
    final signedOutcome = _coConsultCoordinator.markDoctorReviewed(
      approved: true,
      signature: null,
      timestamp: DateTime.now(),
      signatureLabel: signature,
    );
    if (signedOutcome == null) {
      _showActionSnack('Unable to complete the signature. Please try again later.');
      return;
    }
    if (!mounted) return;
    setState(() => _lastOutcome = signedOutcome);
    await _showPatientReportDialog(signedOutcome);
    if (!mounted) return;
    _showActionSnack('Report has been signed and can now be shared with the patient.');
  }

  Future<String?> _promptDoctorSignature() async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setState) {
            final trimmed = controller.text.trim();
            return AlertDialog(
              title: const Text('Doctor Signature Confirmation'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your signature to confirm the report is accurate before sharing it with the patient.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Signature (Doctor name)',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
              actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: trimmed.isNotEmpty
                        ? () => Navigator.of(dialogContext).pop(trimmed)
                        : null,
                    child: const Text('Confirm'),
                  ),
              ],
            );
          },
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showPatientReportDialog(AiCoConsultOutcome outcome) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: const Text('Patient-visible Report'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Once the doctor signs, the following can be shared directly with the patient:',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SelectableText(
                  outcome.summary,
                  style: theme.textTheme.bodyMedium,
                ),
                if (outcome.planUpdates.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Health plan updates',
                    style: theme.textTheme.titleSmall,
                  ),
                  ...outcome.planUpdates.take(3).map((item) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child:
                            Text('• $item', style: theme.textTheme.bodySmall),
                      )),
                ],
                if (outcome.followUpQuestions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Suggested follow-up questions',
                    style: theme.textTheme.titleSmall,
                  ),
                  ...outcome.followUpQuestions.take(3).map((item) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child:
                            Text('• $item', style: theme.textTheme.bodySmall),
                      )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showActionSnack(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label)),
    );
  }

  void _toggleMute() {
    setState(() => _notificationsMuted = !_notificationsMuted);
    _showActionSnack(
        _notificationsMuted ? 'Notifications muted' : 'Notifications unmuted');
  }

  Future<void> _openSearch() async {
    final result = await showSearch<_DirectMessage?>(
      context: context,
      delegate: _DirectChatSearchDelegate(_messages),
    );
    if (!mounted || result == null) return;
    final index = _messages.indexOf(result);
    if (index == -1 || !_scrollController.hasClients) return;
    final target = (_scrollController.position.maxScrollExtent /
            (_messages.isEmpty ? 1 : _messages.length)) *
        index;
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _openSharedMedia() {
    final items = _messages
        .where((msg) => msg.text.contains('http'))
        .map((msg) => ChatMediaItem(
              title: msg.text,
              subtitle: _statusLabel(msg.status),
              icon: msg.text.contains('video')
                  ? Icons.play_circle_outline
                  : Icons.link,
            ))
        .toList();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatMediaGalleryPage(
          title: '${widget.contact.name} shared media',
          items: items,
        ),
      ),
    );
  }

  Future<void> _openPreferences() async {
    final result = await Navigator.of(context).push<Map<String, bool>>(
      MaterialPageRoute(
        builder: (_) => ChatPreferencesPage(
          title: 'Chat preferences',
          options: [
            ChatPreferenceOption(
              key: 'receipts',
              title: 'Read receipts',
              subtitle: 'Show when messages are read.',
              icon: Icons.visibility_outlined,
              value: _readReceiptsEnabled,
            ),
            ChatPreferenceOption(
              key: 'download',
              title: 'Auto-download media',
              subtitle: 'Automatically download photos and videos.',
              icon: Icons.download_outlined,
              value: _autoDownloadMedia,
            ),
            ChatPreferenceOption(
              key: 'smartReplies',
              title: 'Smart replies',
              subtitle: 'Suggest quick responses based on context.',
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
      _showActionSnack('Preferences updated');
    }
  }

  Future<void> _openSettings() async {
    final selection = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ChatSettingsPage(
          title: '${widget.contact.name} settings',
          entries: [
            const ChatSettingEntry(
              key: 'search',
              icon: Icons.search,
              title: 'Search chat',
              subtitle: 'Find messages, links, or keywords.',
            ),
            ChatSettingEntry(
              key: 'mute',
              icon: _notificationsMuted
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              title: _notificationsMuted
                  ? 'Unmute notifications'
                  : 'Mute notifications',
              subtitle: _notificationsMuted
                  ? 'Notifications will resume for this chat.'
                  : 'Silence alerts for this conversation.',
            ),
            const ChatSettingEntry(
              key: 'media',
              icon: Icons.photo_library_outlined,
              title: 'Shared media',
              subtitle: 'View photos, videos, and links.',
            ),
            const ChatSettingEntry(
              key: 'preferences',
              icon: Icons.settings_suggest_outlined,
              title: 'Chat preferences',
              subtitle: 'Receipts, downloads, smart replies.',
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
        await _openSearch();
        break;
      case 'mute':
        _toggleMute();
        break;
      case 'media':
        _openSharedMedia();
        break;
      case 'preferences':
        await _openPreferences();
        break;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 48,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final contact = widget.contact;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: contact.color.withValues(alpha: 0.18),
              child: Icon(contact.icon, color: contact.color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Last seen 5m ago',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_isDoctorConversation)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _coConsultBusy
                    ? const SizedBox(
                        key: ValueKey('co-consult-loading'),
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(strokeWidth: 2.6),
                      )
                    : TextButton.icon(
                        key: ValueKey<bool>(_aiCoConsultEnabled),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _toggleCoConsult(),
                        icon: Icon(
                          _aiCoConsultEnabled
                              ? Icons.podcasts
                              : Icons.podcasts_outlined,
                        ),
                        label: Text(
                          _aiCoConsultEnabled
                              ? 'AI Co-Consult Enabled'
                              : 'AI Co-Consult',
                        ),
                      ),
              ),
            ),
          IconButton(
            tooltip: 'Video call',
            onPressed: () => _showActionSnack('Video calling coming soon'),
            icon: const Icon(Icons.videocam_outlined),
          ),
          IconButton(
            tooltip: 'Voice call',
            onPressed: () => _showActionSnack('Voice calling coming soon'),
            icon: const Icon(Icons.call_outlined),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _aiCoConsultEnabled
                ? Padding(
                    key: const ValueKey('co-consult-live-banner'),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _CoConsultLiveBanner(
                      onEnd: () => _endCoConsultSession(),
                    ),
                  )
                : _lastOutcome != null
                    ? Padding(
                        key: const ValueKey('co-consult-outcome-preview'),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _CoConsultOutcomePreview(
                          outcome: _lastOutcome!,
                          onViewDetails: () => _showOutcomeSheet(_lastOutcome!),
                        ),
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('co-consult-empty'),
                      ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final lastUserIndex =
                    _messages.lastIndexWhere((msg) => msg.isUser);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _DirectMessageBubble(
                    message: message,
                    alignRight: message.isUser,
                    showStatus: index == lastUserIndex && message.isUser,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Camera / gallery',
                  onPressed: () =>
                      _showActionSnack('Camera and gallery coming soon'),
                  icon: const Icon(Icons.camera_alt_outlined),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: isDark ? 0.28 : 0.8),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Send a message…',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Emoji',
                  onPressed: () => _showActionSnack('Stickers coming soon'),
                  icon: const Icon(Icons.emoji_emotions_outlined),
                ),
                IconButton(
                  tooltip: 'Voice message',
                  onPressed: () =>
                      _showActionSnack('Voice recorder coming soon'),
                  icon: const Icon(Icons.mic_none_outlined),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                  ),
                  onPressed: () => _sendMessage(_textController.text),
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

class _DirectMessageBubble extends StatelessWidget {
  const _DirectMessageBubble({
    required this.message,
    required this.alignRight,
    required this.showStatus,
  });

  final _DirectMessage message;
  final bool alignRight;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = alignRight
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: isDark ? 0.35 : 0.75);
    final textColor =
        alignRight ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!alignRight)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blueGrey.withValues(alpha: 0.18),
                    child: const Icon(Icons.person, size: 18),
                  ),
                ),
              Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: alignRight
                        ? const Radius.circular(18)
                        : const Radius.circular(6),
                    bottomRight: alignRight
                        ? const Radius.circular(6)
                        : const Radius.circular(18),
                  ),
                ),
                child: Text(
                  message.text,
                  style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                ),
              ),
              if (alignRight)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.teal.withValues(alpha: 0.2),
                    child: const Icon(Icons.person, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatTimestamp(message.timestamp),
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          if (showStatus)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _statusLabel(message.status),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _CoConsultLiveBanner extends StatelessWidget {
  const _CoConsultLiveBanner({required this.onEnd});

  final Future<void> Function() onEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.28 : 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.podcasts, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI Co-Consult is listening in',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI summarizes key points and syncs care plans, goals, and medications in real time.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonal(
            onPressed: () => onEnd(),
            child: const Text('End'),
          ),
        ],
      ),
    );
  }
}

class _CoConsultOutcomePreview extends StatelessWidget {
  const _CoConsultOutcomePreview({
    required this.outcome,
    required this.onViewDetails,
  });

  final AiCoConsultOutcome outcome;
  final Future<void> Function() onViewDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onViewDetails(),
      child: Ink(
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'AI Co-Consult summary ready',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(Icons.arrow_outward, color: theme.colorScheme.primary),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              outcome.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (outcome.planUpdates.isNotEmpty)
                  _SummaryChip(
                    icon: Icons.fact_check_outlined,
                    label: 'Plan updates ${outcome.planUpdates.length}',
                  ),
                if (outcome.goalProposals.isNotEmpty)
                  _SummaryChip(
                    icon: Icons.flag_outlined,
                    label: 'Goals ${outcome.goalProposals.length}',
                  ),
                if (outcome.medicationChanges.isNotEmpty)
                  _SummaryChip(
                    icon: Icons.vaccines_outlined,
                    label: 'Medications ${outcome.medicationChanges.length}',
                  ),
                if (outcome.followUpQuestions.isNotEmpty)
                  _SummaryChip(
                    icon: Icons.help_outline,
                    label: 'Follow-up questions ${outcome.followUpQuestions.length}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _CoConsultSummarySheet extends StatelessWidget {
  const _CoConsultSummarySheet({
    required this.outcome,
    required this.allowSignature,
    required this.onShareWithPatient,
  });

  final AiCoConsultOutcome outcome;
  final bool allowSignature;
  final Future<void> Function() onShareWithPatient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 48,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'AI Co-Consult Summary',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                outcome.summary,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (outcome.planUpdates.isNotEmpty) ...[
                const _SummarySectionHeader(
                  icon: Icons.fact_check_outlined,
                  label: 'Health plan updates',
                ),
                for (final item in outcome.planUpdates)
                  _SummaryBulletTile(label: item),
                const SizedBox(height: 16),
              ],
              if (outcome.goalProposals.isNotEmpty) ...[
                const _SummarySectionHeader(
                  icon: Icons.flag_outlined,
                  label: 'New / adjusted goals',
                ),
                for (final proposal in outcome.goalProposals)
                  _SummaryGoalTile(proposal: proposal),
                const SizedBox(height: 16),
              ],
              if (outcome.medicationChanges.isNotEmpty) ...[
                const _SummarySectionHeader(
                  icon: Icons.vaccines_outlined,
                  label: 'Medication updates',
                ),
                for (final change in outcome.medicationChanges)
                  _SummaryMedicationTile(change: change),
                const SizedBox(height: 16),
              ],
              if (outcome.followUpQuestions.isNotEmpty) ...[
                const _SummarySectionHeader(
                  icon: Icons.help_outline,
                  label: 'Suggested follow-up questions',
                ),
                for (final question in outcome.followUpQuestions)
                  _SummaryBulletTile(
                      label: question, leading: Icons.question_answer_outlined),
              ],
              if (allowSignature) ...[
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    try {
                      await onShareWithPatient();
                    } catch (_) {
                      // Share flow already shows feedback.
                    }
                  },
                  child: const Text('Confirm signature and share'),
                ),
                const SizedBox(height: 6),
                Text(
                  'Once the doctor confirms the signature, the report can be shared with the patient.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummarySectionHeader extends StatelessWidget {
  const _SummarySectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SummaryBulletTile extends StatelessWidget {
  const _SummaryBulletTile({required this.label, this.leading});

  final String label;
  final IconData? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            leading ?? Icons.radio_button_checked,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGoalTile extends StatelessWidget {
  const _SummaryGoalTile({required this.proposal});

  final AiCoConsultGoalProposal proposal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryLabel = proposal.category?.label() ?? 'Custom';
    final frequencyLabel = proposal.frequency?.label() ?? 'Weekly';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            proposal.title,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '$categoryLabel · $frequencyLabel',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (proposal.instructions != null) ...[
            const SizedBox(height: 6),
            Text(
              proposal.instructions!,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryMedicationTile extends StatelessWidget {
  const _SummaryMedicationTile({required this.change});

  final AiCoConsultMedicationChange change;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionLabel = switch (change.action) {
      AiMedicationAction.add => 'Add',
      AiMedicationAction.update => 'Update',
      AiMedicationAction.discontinue => 'Discontinue',
    };
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$actionLabel · ${change.name}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (change.dose != null) ...[
            const SizedBox(height: 4),
            Text(
              'Dose: ${change.dose}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (change.effect != null) ...[
            const SizedBox(height: 4),
            Text('Purpose: ${change.effect}', style: theme.textTheme.bodySmall),
          ],
          if (change.sideEffects != null) ...[
            const SizedBox(height: 4),
            Text('Notes: ${change.sideEffects}', style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _DirectMessage {
  const _DirectMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.status,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;
  final DirectMessageStatus status;

  _DirectMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    DirectMessageStatus? status,
  }) {
    return _DirectMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}

enum DirectMessageStatus { sent, delivered, read }

String _statusLabel(DirectMessageStatus status) {
  switch (status) {
    case DirectMessageStatus.sent:
      return 'Sent';
    case DirectMessageStatus.delivered:
      return 'Delivered';
    case DirectMessageStatus.read:
      return 'Read';
  }
}

class _DirectChatSearchDelegate extends SearchDelegate<_DirectMessage?> {
  _DirectChatSearchDelegate(this.messages);

  final List<_DirectMessage> messages;

  List<_DirectMessage> _filter(String query) => messages
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
    final results = _filter(query);
    if (results.isEmpty) {
      return const Center(child: Text('No results'));
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final msg = results[index];
        return ListTile(
          leading: Icon(msg.isUser ? Icons.person : Icons.chat_bubble_outline),
          title: Text(msg.text),
          subtitle: Text(_statusLabel(msg.status)),
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

enum PersonalChatType { maya, alex, doctor, aiCoach, custom }

class PersonalChatContact {
  const PersonalChatContact({
    required this.type,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.contactId,
  });

  final PersonalChatType type;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? contactId;
}

List<_DirectMessage> _seedConversation(PersonalChatContact contact) {
  final now = DateTime.now();
  switch (contact.type) {
    case PersonalChatType.maya:
      return [
        _DirectMessage(
          text:
              'Hey! I saved a new breathing exercise video you might like. Want the link?',
          isUser: false,
          timestamp: now.subtract(const Duration(minutes: 32)),
          status: DirectMessageStatus.read,
        ),
        _DirectMessage(
          text: 'Yes please—that sounds perfect for tonight.',
          isUser: true,
          timestamp: now.subtract(const Duration(minutes: 29)),
          status: DirectMessageStatus.read,
        ),
        _DirectMessage(
          text:
              'Here you go: https://calmhub.example/breathing. Let me know how it feels.',
          isUser: false,
          timestamp: now.subtract(const Duration(minutes: 28)),
          status: DirectMessageStatus.read,
        ),
        _DirectMessage(
          text: 'Thanks! I’ll try it after dinner and update you tomorrow.',
          isUser: true,
          timestamp: now.subtract(const Duration(minutes: 25)),
          status: DirectMessageStatus.read,
        ),
      ];
    case PersonalChatType.alex:
      return [
        _DirectMessage(
          text: 'Morning! I put together a new wind-down playlist for you.',
          isUser: false,
          timestamp: now.subtract(const Duration(minutes: 45)),
          status: DirectMessageStatus.read,
        ),
        _DirectMessage(
          text: 'Amazing—send it over!',
          isUser: true,
          timestamp: now.subtract(const Duration(minutes: 43)),
          status: DirectMessageStatus.read,
        ),
        _DirectMessage(
          text:
              'Sharing now: https://calmhub.example/winddown-vibes. It starts with softer instrumentals.',
          isUser: false,
          timestamp: now.subtract(const Duration(minutes: 42)),
          status: DirectMessageStatus.read,
        ),
        _DirectMessage(
          text:
              'Queued it for tonight. Thanks for looking out for my routine 😊',
          isUser: true,
          timestamp: now.subtract(const Duration(minutes: 39)),
          status: DirectMessageStatus.read,
        ),
      ];
    case PersonalChatType.doctor:
      return [
        _DirectMessage(
          text:
              'Hi, thanks for joining today. I reviewed your sleep and mood logs from the past two weeks.',
          isUser: false,
          timestamp: now.subtract(const Duration(minutes: 34)),
          status: DirectMessageStatus.read,
        ),
        _DirectMessage(
          text: 'Morning, doctor. I kept the logs but still wake up groggy.',
          isUser: true,
          timestamp: now.subtract(const Duration(minutes: 32)),
          status: DirectMessageStatus.read,
        ),
        _DirectMessage(
          text:
              'Let’s build in a gentle sunset walk and extend the routine to 20 minutes to help evening wind-down.',
          isUser: false,
          timestamp: now.subtract(const Duration(minutes: 30)),
          status: DirectMessageStatus.read,
        ),
        _DirectMessage(
          text: 'I can try that. Should I keep the sleep journal the same way?',
          isUser: true,
          timestamp: now.subtract(const Duration(minutes: 28)),
          status: DirectMessageStatus.read,
        ),
        _DirectMessage(
          text:
              'Yes, but add a quick note on how alert you feel after the morning dose of Sertraline.',
          isUser: false,
          timestamp: now.subtract(const Duration(minutes: 26)),
          status: DirectMessageStatus.read,
        ),
      ];
    case PersonalChatType.aiCoach:
      return [
        _DirectMessage(
          text:
              'Hi Argo! I’m keeping an eye on your care plan. Want a quick recap or to set a reminder?',
          isUser: false,
          timestamp: now.subtract(const Duration(minutes: 15)),
          status: DirectMessageStatus.read,
        ),
        _DirectMessage(
          text: 'Can you remind me about the evening inhaler?',
          isUser: true,
          timestamp: now.subtract(const Duration(minutes: 13)),
          status: DirectMessageStatus.read,
        ),
        _DirectMessage(
          text:
              'Absolutely. I’ll nudge you at 8:00 PM and log any follow-up notes you share.',
          isUser: false,
          timestamp: now.subtract(const Duration(minutes: 12)),
          status: DirectMessageStatus.read,
        ),
        _DirectMessage(
          text: 'Perfect, thanks for staying on top of things.',
          isUser: true,
          timestamp: now.subtract(const Duration(minutes: 11)),
          status: DirectMessageStatus.read,
        ),
      ];
    case PersonalChatType.custom:
      final contactName = contact.name;
      final greeting = contact.subtitle.toLowerCase().contains('qr')
          ? 'Thanks for scanning my QR code!'
          : 'Glad we could connect.';
      return [
        _DirectMessage(
          text: 'Hi there, this is $contactName. $greeting',
          isUser: false,
          timestamp: now.subtract(const Duration(minutes: 20)),
          status: DirectMessageStatus.read,
        ),
        _DirectMessage(
          text:
              'Hey $contactName! Looking forward to keeping each other accountable.',
          isUser: true,
          timestamp: now.subtract(const Duration(minutes: 18)),
          status: DirectMessageStatus.read,
        ),
      ];
  }
}

const PersonalChatContact personalChatMaya = PersonalChatContact(
  contactId: 'maya.chen',
  type: PersonalChatType.maya,
  name: 'Maya Chen',
  subtitle: 'Catch up on your daily reflection.',
  icon: Icons.person,
  color: Color(0xFF60A5FA),
);

const PersonalChatContact personalChatAlex = PersonalChatContact(
  contactId: 'alex.rivera',
  type: PersonalChatType.alex,
  name: 'Alex Rivera',
  subtitle: 'Shared a new playlist for your wind-down.',
  icon: Icons.person_outline,
  color: Color(0xFF8B5CF6),
);

const PersonalChatContact personalChatDoctor = PersonalChatContact(
  contactId: 'dr.chen',
  type: PersonalChatType.doctor,
  name: 'Dr. Chen (Psychiatry)',
  subtitle: 'Telehealth follow-up · medication review.',
  icon: Icons.medical_information_outlined,
  color: Color(0xFF0EA5E9),
);

const PersonalChatContact personalChatAiCoach = PersonalChatContact(
  contactId: 'personal_care_ai',
  type: PersonalChatType.aiCoach,
  name: 'My Personal Care AI',
  subtitle: 'Ask your AI coach for next steps anytime.',
  icon: Icons.support_agent_outlined,
  color: Color(0xFF2563EB),
);

const List<PersonalChatContact> personalChatContacts = [
  personalChatAiCoach,
  personalChatMaya,
  personalChatAlex,
  personalChatDoctor,
];
