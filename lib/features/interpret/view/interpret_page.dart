// lib/features/interpret/view/interpret_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../controller/interpret_controller.dart';
import '../models/interpret_models.dart';
import '../services/interpret_services.dart';
import '../widgets/demo_mic.dart';

class InterpretPage extends StatefulWidget {
  const InterpretPage({super.key});

  static const String routeName = '/interpret';

  @override
  State<InterpretPage> createState() => _InterpretPageState();
}

class _InterpretPageState extends State<InterpretPage> {
  late final InterpretController _controller;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _sourceScroll = ScrollController();
  final ScrollController _targetScroll = ScrollController();
  bool _sourceAutoScroll = true;
  bool _targetAutoScroll = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = InterpretController(
      stt: SpeechToTextSttService(),
      mt: const MockMtService(),
      tts: FlutterTtsService(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    _sourceScroll.dispose();
    _targetScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<InterpretController>.value(
      value: _controller,
      child: Consumer<InterpretController>(
        builder: (context, controller, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollIfNeeded(_sourceScroll, _sourceAutoScroll);
            _scrollIfNeeded(_targetScroll, _targetAutoScroll);
          });
          return Scaffold(
            appBar: AppBar(
              title: const Text('Interpreter'),
              actions: [
                IconButton(
                  tooltip: 'Engine settings',
                  icon: const Icon(Icons.settings_suggest_outlined),
                  onPressed: () => _showSettingsSheet(context, controller),
                ),
                IconButton(
                  tooltip: 'Session logs',
                  icon: const Icon(Icons.folder_open_outlined),
                  onPressed: () => _showSessionLogs(context, controller),
                ),
              ],
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildBanner(controller),
                    _LanguageBar(
                      langIn: controller.langIn,
                      langOut: controller.langOut,
                      onSwap: controller.swapLanguages,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: _CaptionPanel(
                              title: 'Speaker captions',
                              icon: Icons.mic_none,
                              segments: controller.source,
                              scrollController: _sourceScroll,
                              autoScrollEnabled: _sourceAutoScroll,
                              onAutoScrollChanged: (enabled) {
                                setState(() => _sourceAutoScroll = enabled);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _CaptionPanel(
                              title: 'Listener captions',
                              icon: Icons.translate,
                              segments: controller.target,
                              scrollController: _targetScroll,
                              autoScrollEnabled: _targetAutoScroll,
                              onAutoScrollChanged: (enabled) {
                                setState(() => _targetAutoScroll = enabled);
                              },
                              footer: controller.translationPending ||
                                      controller.ttsPending
                                  ? const _TypingDots()
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ControlsSection(
                      controller: controller,
                      onCopy: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await controller.copyTranscript();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Captions copied to clipboard.'),
                          ),
                        );
                      },
                      onSave: () async {
                        if (_isSaving) return;
                        setState(() => _isSaving = true);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final file = await controller
                              .exportTranscript(InterpretExportFormat.srt);
                          await Share.shareXFiles(
                            [XFile(file.path)],
                            text: 'Simultaneous interpretation log',
                          );
                        } catch (_) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Failed to save session.'),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isSaving = false);
                          }
                        }
                      },
                      isSaving: _isSaving,
                    ),
                    const SizedBox(height: 12),
                    _TypeBar(
                      controller: controller,
                      textController: _textController,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBanner(InterpretController controller) {
    if (controller.errorMessage != null) {
      return _InlineBanner(
        icon: Icons.error_outline,
        color: Colors.red,
        message: controller.errorMessage!,
      );
    }
    if (controller.infoBanner != null) {
      return _InlineBanner(
        icon: Icons.info_outline,
        color: Colors.blue,
        message: controller.infoBanner!,
      );
    }
    return const SizedBox.shrink();
  }

  void _scrollIfNeeded(ScrollController controller, bool autoScroll) {
    if (!autoScroll || !controller.hasClients) return;
    controller.animateTo(
      controller.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _showSettingsSheet(
      BuildContext context, InterpretController controller) {
    final languages = <String>[
      'en-US',
      'en-GB',
      'es-ES',
      'es-MX',
      'fr-FR',
      'de-DE',
      'pt-BR',
      'zh-CN',
      'zh-TW',
      'ja-JP',
      'ko-KR',
    ];
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interpreter settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _LanguageDropdown(
                    value: controller.langIn,
                    options: languages,
                    label: 'Input language',
                    onChanged: (value) {
                      if (value == null) return;
                      controller.langIn = value;
                      controller.clearCaptions();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LanguageDropdown(
                    value: controller.langOut,
                    options: languages,
                    label: 'Output language',
                    onChanged: (value) {
                      if (value == null) return;
                      controller.langOut = value;
                      controller.clearCaptions();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Hands-free'),
              subtitle:
                  const Text('Tap mic to latch, long press for push-to-talk.'),
              value: controller.handsFree,
              onChanged: (_) => controller.toggleHandsFree(),
            ),
            SwitchListTile(
              title: const Text('Enable TTS playback'),
              value: controller.ttsEnabled,
              onChanged: (_) => controller.toggleTts(),
            ),
            const SizedBox(height: 8),
            Text('Playback speed (${controller.ttsRate.toStringAsFixed(2)}x)'),
            Slider(
              value: controller.ttsRate,
              onChanged: controller.setTtsRate,
              min: 0.5,
              max: 1.5,
            ),
            Text(
                'Playback volume (${controller.ttsVolume.toStringAsFixed(2)})'),
            Slider(
              value: controller.ttsVolume,
              onChanged: controller.setTtsVolume,
              min: 0.1,
              max: 1.0,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSessionLogs(
    BuildContext context,
    InterpretController controller,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session log',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: controller.hasCaptions
                  ? ListView.builder(
                      itemCount: controller.source.length,
                      itemBuilder: (_, index) {
                        final src = controller.source[index];
                        final tgt = index < controller.target.length
                            ? controller.target[index]
                            : null;
                        return ListTile(
                          title: Text(src.text),
                          subtitle: Text(
                            tgt?.text ?? 'Awaiting translation…',
                          ),
                          trailing: Text(
                            TimeOfDay.fromDateTime(src.ts).format(context),
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Text('No captions yet. Tap the mic to begin.'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageBar extends StatelessWidget {
  const _LanguageBar({
    required this.langIn,
    required this.langOut,
    required this.onSwap,
  });

  final String langIn;
  final String langOut;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _LanguageChip(
            label: describeLanguage(langIn),
            icon: Icons.mic,
            color: scheme.primaryContainer,
          ),
        ),
        IconButton(
          onPressed: onSwap,
          icon: const Icon(Icons.swap_horiz),
          tooltip: 'Swap languages',
        ),
        Expanded(
          child: _LanguageChip(
            label: describeLanguage(langOut),
            icon: Icons.volume_up,
            color: scheme.secondaryContainer,
          ),
        ),
      ],
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: scheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptionPanel extends StatelessWidget {
  const _CaptionPanel({
    required this.title,
    required this.icon,
    required this.segments,
    required this.scrollController,
    required this.autoScrollEnabled,
    required this.onAutoScrollChanged,
    this.footer,
  });

  final String title;
  final IconData icon;
  final List<Segment> segments;
  final ScrollController scrollController;
  final bool autoScrollEnabled;
  final ValueChanged<bool> onAutoScrollChanged;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(icon),
                title: Text(title),
                subtitle: Text('${segments.length} entries'),
                trailing: autoScrollEnabled
                    ? const Text('Live', style: TextStyle(color: Colors.green))
                    : const Text('Paused'),
              ),
              const Divider(height: 1),
              Expanded(
                child: NotificationListener<UserScrollNotification>(
                  onNotification: (notification) {
                    if (notification.direction == ScrollDirection.forward) {
                      onAutoScrollChanged(false);
                    } else if (notification.direction ==
                            ScrollDirection.reverse &&
                        scrollController.hasClients &&
                        scrollController.offset >=
                            scrollController.position.maxScrollExtent - 24) {
                      onAutoScrollChanged(true);
                    }
                    return false;
                  },
                  child: segments.isEmpty
                      ? const Center(
                          child: Text(
                            'Live captions will appear here.',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: segments.length,
                          itemBuilder: (context, index) {
                            final segment = segments[index];
                            return _CaptionTile(segment: segment);
                          },
                        ),
                ),
              ),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 8, bottom: 12),
                  child: footer,
                ),
            ],
          ),
        ),
        if (!autoScrollEnabled)
          Positioned(
            right: 12,
            bottom: 24,
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Jump to live'),
              onPressed: () => onAutoScrollChanged(true),
            ),
          ),
      ],
    );
  }
}

class _CaptionTile extends StatelessWidget {
  const _CaptionTile({required this.segment});

  final Segment segment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = segment.isFinal
        ? theme.textTheme.titleMedium
        : theme.textTheme.titleMedium?.copyWith(
            color: theme.textTheme.titleMedium?.color?.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                TimeOfDay.fromDateTime(segment.ts).format(context),
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(width: 6),
              Icon(
                segment.isFinal ? Icons.check_circle : Icons.circle_outlined,
                size: 14,
                color: segment.isFinal ? Colors.green : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(segment.text.isEmpty ? '…' : segment.text, style: style),
        ],
      ),
    );
  }
}

class _ControlsSection extends StatelessWidget {
  const _ControlsSection({
    required this.controller,
    required this.onCopy,
    required this.onSave,
    required this.isSaving,
  });

  final InterpretController controller;
  final Future<void> Function() onCopy;
  final Future<void> Function() onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DemoMic(
          onCaption: (source, target) async {
            controller.appendSourceCaption(source);
            controller.appendTargetCaption(target);
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ControlIconButton(
              tooltip: controller.ttsEnabled ? 'Mute TTS' : 'Unmute TTS',
              icon: controller.ttsEnabled
                  ? Icons.volume_up
                  : Icons.volume_off_outlined,
              onPressed: controller.toggleTts,
            ),
            const SizedBox(width: 12),
            _ControlIconButton(
              tooltip: 'Copy captions',
              icon: Icons.copy_all_outlined,
              onPressed: onCopy,
            ),
            const SizedBox(width: 12),
            _ControlIconButton(
              tooltip: 'Save log',
              icon: Icons.save_alt,
              busy: isSaving,
              onPressed: isSaving ? null : onSave,
            ),
          ],
        ),
      ],
    );
  }
}

class _ControlIconButton extends StatelessWidget {
  const _ControlIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.busy = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: busy ? null : onPressed,
        icon: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
        final value = _controller.value;
        final activeDots = (value * 3).ceil();
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: CircleAvatar(
                radius: 4,
                backgroundColor: index < activeDots
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.2),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TypeBar extends StatelessWidget {
  const _TypeBar({
    required this.controller,
    required this.textController,
  });

  final InterpretController controller;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textController,
      minLines: 1,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Type instead…',
        filled: true,
        suffixIcon: IconButton(
          icon: const Icon(Icons.send),
          onPressed: () {
            final text = textController.text;
            textController.clear();
            controller.typeAndTranslate(text);
          },
        ),
      ),
      onSubmitted: (value) {
        textController.clear();
        controller.typeAndTranslate(value);
      },
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({
    required this.value,
    required this.options,
    required this.label,
    this.onChanged,
  });

  final String value;
  final List<String> options;
  final String label;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      value: value,
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(describeLanguage(option)),
          ),
      ],
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
