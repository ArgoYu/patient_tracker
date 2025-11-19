import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/utils/toast.dart';
import 'controller/voice_chat_controller.dart';
import 'models/voice_chat_models.dart';
import 'services/voice_ai_service.dart';
import 'services/voice_ai_service_registry.dart';
import 'widgets/mic_hold_button.dart';
import 'widgets/voice_chat_bubble.dart';

class VoiceChatPage extends StatelessWidget {
  const VoiceChatPage({
    super.key,
    VoiceAiService? service,
    VoiceChatController Function()? controllerBuilder,
  })  : _serviceOverride = service,
        _controllerBuilder = controllerBuilder;

  static const String routeName = '/voice-chat';
  final VoiceAiService? _serviceOverride;
  final VoiceChatController Function()? _controllerBuilder;

  @override
  Widget build(BuildContext context) {
    final builder = _controllerBuilder;
    if (builder != null) {
      return ChangeNotifierProvider(
        create: (_) => builder(),
        child: const _VoiceChatView(),
      );
    }
    final service = _serviceOverride ?? VoiceAiServiceRegistry.instance.service;
    return ChangeNotifierProvider(
      create: (_) => VoiceChatController(service: service),
      child: const _VoiceChatView(),
    );
  }
}

class _VoiceChatView extends StatefulWidget {
  const _VoiceChatView();

  @override
  State<_VoiceChatView> createState() => _VoiceChatViewState();
}

class _VoiceChatViewState extends State<_VoiceChatView> {
  late final ScrollController _scrollController;
  late final TextEditingController _textController;
  VoiceChatController? _attachedController;
  bool _stickToBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    _textController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<VoiceChatController>();
    if (!identical(controller, _attachedController)) {
      _attachedController?.removeListener(_handleControllerChanged);
      _attachedController = controller..addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    _attachedController?.removeListener(_handleControllerChanged);
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (_stickToBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    final shouldStick = (maxExtent - offset) < 160;
    if (shouldStick != _stickToBottom) {
      setState(() => _stickToBottom = shouldStick);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VoiceChatController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Chat AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Language & Model',
            onPressed: () => _showLanguageSheet(controller),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!controller.micGranted)
              _PermissionBanner(controller: controller),
            if (!_stickToBottom)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: FilledButton.tonalIcon(
                    onPressed: _scrollToBottom,
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text('Jump to latest'),
                  ),
                ),
              ),
            Expanded(
              child: _TranscriptView(
                controller: controller,
                scrollController: _scrollController,
              ),
            ),
            if (controller.turns.any(
                (turn) => turn.role == ChatRole.ai && turn.text.isNotEmpty))
              Opacity(
                opacity: 0,
                alwaysIncludeSemantics: true,
                child: Text(
                  controller.turns
                      .lastWhere(
                        (turn) =>
                            turn.role == ChatRole.ai && turn.text.isNotEmpty,
                      )
                      .text,
                  key: const ValueKey('voice_chat_latest_ai_text'),
                ),
              ),
            if (controller.errorMessage != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            _BottomPanel(
              controller: controller,
              textController: _textController,
              onManualSend: _handleManualSend,
            ),
          ],
        ),
      ),
    );
  }

  void _handleManualSend(VoiceChatController controller) {
    final text = _textController.text;
    _textController.clear();
    controller.sendText(text);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _showLanguageSheet(VoiceChatController controller) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final options = <String>[
          'en-US',
          'es-ES',
          'zh-CN',
          'hi-IN',
        ];
        return ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Speech + TTS language'),
              subtitle: Text('Choose locale for STT and TTS playback.'),
            ),
            for (final option in options)
              ListTile(
                onTap: () => Navigator.pop(context, option),
                leading: Icon(
                  option == controller.languageCode
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                ),
                title: Text(option),
              ),
          ],
        );
      },
    );
    if (!mounted) return;
    if (selected != null && selected != controller.languageCode) {
      controller.setLanguage(selected);
      showToast(context, 'Language set to $selected');
    }
  }
}

class _TranscriptView extends StatelessWidget {
  const _TranscriptView({
    required this.controller,
    required this.scrollController,
  });

  final VoiceChatController controller;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final turns = List<ChatTurn>.from(controller.turns);
    final isHolding = controller.state == VoiceState.holding;
    if (isHolding || controller.partialTranscript.isNotEmpty) {
      turns.add(
        ChatTurn(
          role: ChatRole.user,
          text: controller.partialTranscript.isEmpty
              ? 'Holding...'
              : controller.partialTranscript,
          timestamp: DateTime.now(),
          isStreaming: true,
        ),
      );
    }
    if (turns.isEmpty) {
      return _TranscriptSkeleton(controller: controller);
    }
    final children = List.generate(
      turns.length,
      (index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: VoiceChatBubble(turn: turns[index]),
      ),
    );
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: children,
    );
  }
}

class _TranscriptSkeleton extends StatelessWidget {
  const _TranscriptSkeleton({required this.controller});

  final VoiceChatController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      itemCount: controller.state == VoiceState.processing ? 4 : 2,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ShimmerBox(color: theme.colorScheme.surfaceContainerHighest),
        );
      },
    );
  }
}

class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, required this.color});

  final Color color;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.3 + (_controller.value * 0.4);
        return Opacity(opacity: opacity, child: child);
      },
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.controller,
    required this.textController,
    required this.onManualSend,
  });

  final VoiceChatController controller;
  final TextEditingController textController;
  final ValueChanged<VoiceChatController> onManualSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HoldToTalkButton(
              onStateChanged: controller.syncUiState,
              mockGenerate: controller.generateMockHoldToTalkExchange,
            ),
            const SizedBox(height: 16),
            _SecondaryControls(controller: controller),
            const SizedBox(height: 12),
            _TextFallback(
              controller: controller,
              textController: textController,
              onManualSend: onManualSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryControls extends StatelessWidget {
  const _SecondaryControls({required this.controller});

  final VoiceChatController controller;

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: controller.ttsEnabled ? 'Mute TTS' : 'Unmute TTS',
          onPressed: controller.toggleTts,
          icon: Icon(
            controller.ttsEnabled ? Icons.volume_up : Icons.volume_off,
            color: iconColor,
          ),
        ),
        IconButton(
          tooltip: 'End session',
          onPressed: controller.hasTranscript ? controller.endSession : null,
          icon: Icon(Icons.stop_circle_outlined, color: iconColor),
        ),
      ],
    );
  }
}

class _TextFallback extends StatelessWidget {
  const _TextFallback({
    required this.controller,
    required this.textController,
    required this.onManualSend,
  });

  final VoiceChatController controller;
  final TextEditingController textController;
  final ValueChanged<VoiceChatController> onManualSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: textController,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onManualSend(controller),
            decoration: const InputDecoration(
              hintText: 'Type instead...',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16))),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: () => onManualSend(controller),
          child: const Icon(Icons.send),
        ),
      ],
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.controller});

  final VoiceChatController controller;

  @override
  Widget build(BuildContext context) {
    final permanentlyDenied = controller.micPermanentlyDenied;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.mic_off,
              color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              permanentlyDenied
                  ? 'Microphone access is blocked. Enable it in system settings to use voice chat.'
                  : 'Microphone access is required for voice chat.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (permanentlyDenied) {
                controller.openPermissionSettings();
              } else {
                controller.requestPermissions();
              }
            },
            child: Text(permanentlyDenied ? 'Open Settings' : 'Grant'),
          ),
        ],
      ),
    );
  }
}
