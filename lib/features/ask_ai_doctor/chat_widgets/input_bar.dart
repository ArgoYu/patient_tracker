import 'package:flutter/material.dart';

typedef SendCallback = Future<void> Function(String text);
typedef InsertTextCallback = void Function(String text);
typedef StopRecordingCallback = Future<String?> Function();

class AskAiDoctorInputBar extends StatefulWidget {
  const AskAiDoctorInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onInsertText,
    this.isRecording = false,
    this.recordingDuration = Duration.zero,
    this.waveformLevel = 0,
    this.isStreaming = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final SendCallback onSend;
  final VoidCallback onStartRecording;
  final StopRecordingCallback onStopRecording;
  final InsertTextCallback onInsertText;
  final bool isRecording;
  final Duration recordingDuration;
  final double waveformLevel;
  final bool isStreaming;

  @override
  State<AskAiDoctorInputBar> createState() => _AskAiDoctorInputBarState();
}

class _AskAiDoctorInputBarState extends State<AskAiDoctorInputBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSend =
        widget.controller.text.trim().isNotEmpty && !widget.isStreaming;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isRecording)
              _RecordingBanner(
                duration: widget.recordingDuration,
                waveformLevel: widget.waveformLevel,
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add context',
                    onPressed: _openAttachmentPicker,
                  ),
                  Expanded(
                    child: Scrollbar(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        minLines: 1,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Describe symptoms or ask a question…',
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      widget.isRecording ? Icons.stop_circle : Icons.mic_none,
                      color: widget.isRecording
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                    tooltip: widget.isRecording ? 'Stop recording' : 'Voice input',
                    onPressed: () async {
                      if (widget.isRecording) {
                        final text = await widget.onStopRecording();
                        if (text != null) {
                          widget.onInsertText(text);
                        }
                      } else {
                        widget.onStartRecording();
                      }
                      setState(() {});
                    },
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: FilledButton.icon(
                      onPressed: canSend ? _handleSend : null,
                      icon: const Icon(Icons.send),
                      label: const Text('Send'),
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

  Future<void> _handleSend() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    await widget.onSend(text);
    if (!mounted) return;
    widget.controller.clear();
    setState(() {});
  }

  void _openAttachmentPicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Insert content'),
              subtitle: Text('Pick consult data to insert into your prompt'),
            ),
            ..._attachmentOptions.map(
              (option) => ListTile(
                leading: Icon(option.icon),
                title: Text(option.title),
                subtitle: Text(option.subtitle),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onInsertText(option.template);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _RecordingBanner extends StatelessWidget {
  const _RecordingBanner({
    required this.duration,
    required this.waveformLevel,
  });

  final Duration duration;
  final double waveformLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (waveformLevel * 0.7 + 0.3).clamp(0.0, 1.0).toDouble();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.graphic_eq, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.9),
                backgroundColor:
                    theme.colorScheme.onPrimaryContainer.withOpacity(0.2),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatDuration(duration),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _AttachmentOption {
  const _AttachmentOption({
    required this.title,
    required this.subtitle,
    required this.template,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String template;
  final IconData icon;
}

const List<_AttachmentOption> _attachmentOptions = <_AttachmentOption>[
  _AttachmentOption(
    title: 'Insert consult summary',
    subtitle: 'Key points from the latest consult',
    template: '[Consult summary]\n- Respiratory symptoms improved 40%\n- Continue inhaled meds\n',
    icon: Icons.receipt_long_outlined,
  ),
  _AttachmentOption(
    title: 'Insert prescription',
    subtitle: 'Medication name + dosage',
    template: 'Prescription: Azithromycin 250 mg once daily for 4 days.\n',
    icon: Icons.medical_information_outlined,
  ),
  _AttachmentOption(
    title: 'Insert test results',
    subtitle: 'Lab / imaging summary',
    template:
        'Lab results: CBC within normal limits, CRP 3 mg/L, chest X-ray shows mild interstitial markings.\n',
    icon: Icons.fact_check_outlined,
  ),
];
