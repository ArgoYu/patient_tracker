import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'chat_viewmodel.dart';
import 'chat_widgets/input_bar.dart';
import 'chat_widgets/message_bubble.dart';
import 'chat_widgets/typing_indicator.dart';
import 'models/chat_message.dart';
import 'models/consult_context.dart';

class AskAiDoctorChatScreen extends StatelessWidget {
  const AskAiDoctorChatScreen({super.key});

  static const String routeName = '/ask_ai_doctor/chat';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AskAiDoctorChatVM>(
      create: (_) => AskAiDoctorChatVM()..loadLatestConsult(),
      child: const _AskAiDoctorChatView(),
    );
  }
}

class _AskAiDoctorChatView extends StatefulWidget {
  const _AskAiDoctorChatView();

  @override
  State<_AskAiDoctorChatView> createState() => _AskAiDoctorChatViewState();
}

class _AskAiDoctorChatViewState extends State<_AskAiDoctorChatView> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  int _lastMessageCount = 0;
  String? _lastErrorMessage;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AskAiDoctorChatVM>();
    _maybeScroll(vm);
    _handleError(vm.errorMessage);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ask-AI-Doctor'),
            SizedBox(height: 2),
            Text(
              'Personalized care guidance',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Regenerate last response',
            onPressed: vm.messages.isEmpty
                ? null
                : () => vm.regenerate(vm.messages.last.id),
          ),
          PopupMenuButton<_ChatMenu>(
            onSelected: (value) => _handleMenu(value, vm),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ChatMenu.clear,
                child: Text('Clear conversation'),
              ),
              PopupMenuItem(
                value: _ChatMenu.export,
                child: Text('Export'),
              ),
              PopupMenuItem(
                value: _ChatMenu.feedback,
                child: Text('Feedback'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildConversation(vm)),
          if (vm.isStreaming)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: TextButton.icon(
                onPressed: () => vm.stopStreaming(),
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Stop generating'),
              ),
            ),
          AskAiDoctorInputBar(
            controller: _controller,
            focusNode: _focusNode,
            onSend: (text) async {
              await vm.send(text);
              _scrollToBottom();
            },
            onStartRecording: vm.startRecording,
            onStopRecording: vm.stopRecording,
            onInsertText: _insertText,
            isRecording: vm.isRecording,
            recordingDuration: vm.recordingDuration,
            waveformLevel: vm.waveformLevel,
            isStreaming: vm.isStreaming,
          ),
        ],
      ),
    );
  }

  Widget _buildConversation(AskAiDoctorChatVM vm) {
    if (vm.messages.isEmpty) {
      return ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          _EmptyStateCard(
            onSampleTap: _insertText,
            onInsertConsult: () {
              final consult = vm.latestConsult;
              if (consult != null) {
                _insertText(
                    '${consult.summary}\n${consult.highlights.join('\n')}');
              }
            },
            consultContext: vm.latestConsult,
            toggleValue: vm.insertLatestConsult,
            onToggleChanged:
                vm.latestConsult == null ? null : vm.toggleConsultContext,
            isLoadingContext: vm.isLoadingConsult,
          ),
        ],
      );
    }

    final reversed = vm.messages.reversed.toList(growable: false);
    final typingOffset = vm.isStreaming ? 1 : 0;
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: reversed.length + typingOffset,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        if (vm.isStreaming && index == 0) {
          return const TypingIndicator();
        }
        final message = reversed[index - typingOffset];
        final hasError = message.meta?['status'] == 'error';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MessageBubble(
              message: message,
              isMine: message.isUser,
              onLongPress: () => _showMessageActions(message),
            ),
            if (hasError)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => vm.regenerate(message.id),
                  child: const Text('Retry'),
                ),
              ),
          ],
        );
      },
    );
  }

  void _maybeScroll(AskAiDoctorChatVM vm) {
    if (vm.messages.length == _lastMessageCount) return;
    _lastMessageCount = vm.messages.length;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void _insertText(String text) {
    if (text.isEmpty) return;
    final current = _controller.text;
    final selection = _controller.selection;
    final insertIndex =
        selection.isValid ? selection.baseOffset : current.length;
    final head = current.substring(0, insertIndex);
    final tail = current.substring(insertIndex);
    final buffer = StringBuffer()..write(head);
    final needsLeadingBreak =
        head.isNotEmpty && !head.endsWith('\n') && !head.endsWith(' ');
    if (needsLeadingBreak) {
      buffer.write('\n');
    }
    buffer.write(text.trim());
    final needsTrailingSpace =
        tail.isNotEmpty && !text.trimRight().endsWith('\n');
    if (needsTrailingSpace) {
      buffer.write('\n');
    } else if (tail.isEmpty) {
      buffer.write(' ');
    }
    buffer.write(tail);
    _controller.text = buffer.toString();
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    FocusScope.of(context).requestFocus(_focusNode);
    setState(() {});
  }

  Future<void> _showMessageActions(ChatMessage message) async {
    final vm = context.read<AskAiDoctorChatVM>();
    final action = await showModalBottomSheet<_MessageAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copy'),
              onTap: () => Navigator.pop(context, _MessageAction.copy),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, _MessageAction.delete),
            ),
            if (!message.isUser)
              ListTile(
                leading: const Icon(Icons.autorenew),
                title: const Text('Regenerate'),
                onTap: () => Navigator.pop(context, _MessageAction.regenerate),
              ),
          ],
        ),
      ),
    );
    switch (action) {
      case _MessageAction.copy:
        await Clipboard.setData(ClipboardData(text: message.text));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Copied to clipboard')),
          );
        }
        break;
      case _MessageAction.delete:
        vm.deleteMessage(message.id);
        break;
      case _MessageAction.regenerate:
        await vm.regenerate(message.id);
        break;
      default:
        break;
    }
  }

  void _handleMenu(_ChatMenu action, AskAiDoctorChatVM vm) {
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case _ChatMenu.clear:
        vm.clear();
        messenger.showSnackBar(const SnackBar(content: Text('Conversation cleared')));
        break;
      case _ChatMenu.export:
        messenger
            .showSnackBar(const SnackBar(content: Text('Chat history exported (mock)')));
        break;
      case _ChatMenu.feedback:
        messenger.showSnackBar(
          const SnackBar(content: Text('Thanks for the feedback! We will keep improving.')),
        );
        break;
    }
  }

  void _handleError(String? message) {
    if (message == null || message == _lastErrorMessage) return;
    _lastErrorMessage = message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    });
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.onSampleTap,
    required this.onInsertConsult,
    required this.consultContext,
    required this.toggleValue,
    required this.onToggleChanged,
    required this.isLoadingContext,
  });

  final ValueChanged<String> onSampleTap;
  final VoidCallback onInsertConsult;
  final ConsultContext? consultContext;
  final bool toggleValue;
  final ValueChanged<bool>? onToggleChanged;
  final bool isLoadingContext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.chat_bubble_outline,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Start a new consult chat',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Sample questions',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _samplePrompts
                  .map(
                    (prompt) => ActionChip(
                      label: Text(prompt),
                      onPressed: () => onSampleTap(prompt),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: toggleValue,
              onChanged: onToggleChanged,
              title: const Text('Use latest consult context'),
              subtitle: Text(
                isLoadingContext
                    ? 'Loading consult context…'
                    : consultContext == null
                        ? 'No consult available'
                        : 'Consult time ${DateFormat('MMM d HH:mm').format(consultContext!.generatedAt)}',
              ),
            ),
            if (consultContext != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onInsertConsult,
                icon: const Icon(Icons.download_done_outlined),
                label: const Text('Insert latest consult summary'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _MessageAction { copy, delete, regenerate }

enum _ChatMenu { clear, export, feedback }

const List<String> _samplePrompts = <String>[
  'Chest tightness is getting worse. Should we adjust the inhaler dose?',
  'What meds should I prepare before flying?',
  'Night cough disrupts sleep. Any quick relief tips?',
];
