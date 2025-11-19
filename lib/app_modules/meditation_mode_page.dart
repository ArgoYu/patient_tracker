// ignore_for_file: use_build_context_synchronously

part of 'package:patient_tracker/app_modules.dart';

class MeditationModePage extends StatefulWidget {
  const MeditationModePage({
    super.key,
    this.initialFeelingsScore,
    this.feelingHistory,
    this.onFeelingsSaved,
    this.safetyPlan,
    this.onSafetyPlanChanged,
  });

  final int? initialFeelingsScore;
  final List<FeelingEntry>? feelingHistory;
  final void Function(int score, DateTime when, String? note)? onFeelingsSaved;
  final SafetyPlanData? safetyPlan;
  final ValueChanged<SafetyPlanData>? onSafetyPlanChanged;

  @override
  State<MeditationModePage> createState() => _MeditationModePageState();
}

enum _MeditationJourney {
  choose,
  meditationSetup,
  meditationRunning,
  breathingSetup,
  breathingRunning,
}

class _BreathingPhase {
  const _BreathingPhase(
      {required this.label,
      required this.cue,
      required this.seconds,
      required this.icon});

  final String label;
  final String cue;
  final int seconds;
  final IconData icon;
}

class _MeditationModePageState extends State<MeditationModePage> {
  static const Map<String, String> _presets = {
    'None': '',
    'White Noise':
        'https://cdn.pixabay.com/download/audio/2021/09/30/audio_2a8ad8544b.mp3?filename=white-noise-ambient-9093.mp3',
    'Rain':
        'https://cdn.pixabay.com/download/audio/2021/09/16/audio_0a8d9b819c.mp3?filename=rain-and-thunder-ambient-6133.mp3',
    'Waves':
        'https://cdn.pixabay.com/download/audio/2022/03/15/audio_7d5f6b0159.mp3?filename=waves-on-beach-112941.mp3',
    'Forest':
        'https://cdn.pixabay.com/download/audio/2021/10/12/audio_87b3a9ff45.mp3?filename=forest-ambience-ambient-9796.mp3',
  };
  static const List<_BreathingPhase> _breathingPhases = [
    _BreathingPhase(
        label: 'Inhale',
        cue: 'Draw a deep breath through the nose.',
        seconds: 4,
        icon: Icons.arrow_upward_rounded),
    _BreathingPhase(
        label: 'Exhale',
        cue: 'Release the air slowly through pursed lips.',
        seconds: 6,
        icon: Icons.arrow_downward_rounded),
  ];
  final AudioPlayer _player = AudioPlayer();
  Timer? _timer;
  String _selectedPreset = 'White Noise';
  final TextEditingController _customUrl = TextEditingController(text: '');
  double _volume = 0.6;
  int _durationMin = 15;
  int _remaining = 15 * 60;
  bool _blockBack = false;
  _MeditationJourney _journey = _MeditationJourney.choose;
  int _breathingRounds = 6;
  int _breathingRoundsRemaining = 6;
  int _breathingPhaseIndex = 0;
  int _breathingSecondsLeft = 0;
  int? _currentFeelingScore;
  SafetyPlanData? _currentSafetyPlan;

  bool get _canLogFeeling =>
      widget.initialFeelingsScore != null &&
      widget.feelingHistory != null &&
      widget.onFeelingsSaved != null &&
      widget.safetyPlan != null &&
      widget.onSafetyPlanChanged != null;

  @override
  void initState() {
    super.initState();
    if (_canLogFeeling) {
      _currentFeelingScore = widget.initialFeelingsScore;
      _currentSafetyPlan = widget.safetyPlan;
    }
  }

  @override
  void didUpdateWidget(covariant MeditationModePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_canLogFeeling) {
      _currentFeelingScore = widget.initialFeelingsScore;
      _currentSafetyPlan = widget.safetyPlan;
    } else {
      _currentFeelingScore = null;
      _currentSafetyPlan = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.stop();
    _player.dispose();
    _customUrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _blockBack = true;
      _remaining = _durationMin * 60;
      _journey = _MeditationJourney.meditationRunning;
    });
    final url = _customUrl.text.trim().isNotEmpty
        ? _customUrl.text.trim()
        : (_presets[_selectedPreset] ?? '');
    if (url.isNotEmpty) {
      try {
        await _player.stop();
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.setVolume(_volume);
        await _player.play(UrlSource(url));
      } catch (e) {
        if (mounted) {
          showToast(context,
              'Unable to start audio track. Session will continue silently.');
        }
      }
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          t.cancel();
          _finish();
        }
      });
    });
  }

  Future<void> _finish() async {
    await _player.stop();
    if (!mounted) return;
    setState(() {
      _blockBack = false;
      _journey = _MeditationJourney.choose;
    });
    if (mounted) Navigator.pop(context);
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final canPop = !_blockBack && _journey == _MeditationJourney.choose;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _handleBackRequest();
        if (shouldPop && mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titleForJourney()),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: _journey == _MeditationJourney.choose || _blockBack
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _goToSelection,
                ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: Padding(
            key: ValueKey(_journey),
            padding: const EdgeInsets.all(16),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  String _titleForJourney() {
    switch (_journey) {
      case _MeditationJourney.choose:
        return 'Mindfulness';
      case _MeditationJourney.meditationSetup:
      case _MeditationJourney.meditationRunning:
        return 'Mindfulness';
      case _MeditationJourney.breathingSetup:
      case _MeditationJourney.breathingRunning:
        return 'Breathing Coach';
    }
  }

  Future<bool> _handleBackRequest() async {
    if (_blockBack) return false;
    if (_journey != _MeditationJourney.choose) {
      FocusScope.of(context).unfocus();
      setState(() => _journey = _MeditationJourney.choose);
      return false;
    }
    return true;
  }

  void _goToSelection() {
    if (_blockBack) return;
    FocusScope.of(context).unfocus();
    setState(() => _journey = _MeditationJourney.choose);
  }

  void _openMeditationSetup() {
    FocusScope.of(context).unfocus();
    setState(() {
      _journey = _MeditationJourney.meditationSetup;
      _blockBack = false;
    });
  }

  void _openBreathingSetup() {
    FocusScope.of(context).unfocus();
    setState(() {
      _journey = _MeditationJourney.breathingSetup;
      _blockBack = false;
    });
  }

  int get _breathingRoundDuration =>
      _breathingPhases.fold<int>(0, (total, phase) => total + phase.seconds);

  String _latestFeelingSummary() {
    final history = widget.feelingHistory;
    if (history == null || history.isEmpty) {
      return 'No entries yet. Take a mindful minute to note how you feel.';
    }
    final latest = history.last;
    return 'Last logged ${formatDateTime(latest.date)} · Score ${latest.score}/5';
  }

  Future<void> _openFeelingsLog() async {
    if (!_canLogFeeling ||
        _currentSafetyPlan == null ||
        widget.feelingHistory == null ||
        widget.initialFeelingsScore == null) {
      return;
    }
    FocusScope.of(context).unfocus();
    final result = await Navigator.of(context).push<FeelingsResult>(
      MaterialPageRoute(
        builder: (_) => FeelingsPage(
          initialScore: _currentFeelingScore ?? widget.initialFeelingsScore!,
          history: widget.feelingHistory!,
          safetyPlan: _currentSafetyPlan!,
          onSafetyPlanChanged: (plan) {
            widget.onSafetyPlanChanged?.call(plan);
            setState(() => _currentSafetyPlan = plan);
          },
        ),
      ),
    );
    if (result != null) {
      setState(() => _currentFeelingScore = result.score);
      widget.onFeelingsSaved?.call(
        result.score,
        result.when,
        result.journalNote,
      );
    }
  }

  Widget _buildBody() {
    switch (_journey) {
      case _MeditationJourney.choose:
        return _chooseUI();
      case _MeditationJourney.meditationSetup:
        return _meditationSetupUI();
      case _MeditationJourney.meditationRunning:
        return _meditationRunningUI();
      case _MeditationJourney.breathingSetup:
        return _breathingSetupUI();
      case _MeditationJourney.breathingRunning:
        return _breathingRunningUI();
    }
  }

  Widget _chooseUI() {
    final text = Theme.of(context).textTheme;
    return ListView(
      children: [
        Text('Find your focus',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
            'Pick a practice that fits how you feel right now. Each one guides you back to a calmer baseline.',
            style: text.bodyMedium),
        const SizedBox(height: 24),
        _practiceTile(
          icon: Icons.self_improvement_rounded,
          title: 'Mindfulness Practice',
          subtitle:
              'Set an intention, choose background audio, and settle into mindful stillness for a custom length.',
          highlights: const ['Timer control', 'Ambient soundscapes'],
          onTap: _openMeditationSetup,
        ),
        const SizedBox(height: 16),
        _practiceTile(
          icon: Icons.air_rounded,
          title: 'Breathing Coach',
          subtitle:
              'Follow a paced 4-6 breath sequence with no breath holds to ease anxiety and return to steady focus.',
          highlights: const ['Science-backed rhythm', 'Guided cues'],
          onTap: _openBreathingSetup,
        ),
        if (_canLogFeeling) ...[
          const SizedBox(height: 16),
          _practiceTile(
            icon: Icons.mood_outlined,
            title: "Log today's feeling",
            subtitle: _latestFeelingSummary(),
            highlights: const ['Track mood', 'Mindful journaling'],
            onTap: _openFeelingsLog,
          ),
        ],
      ],
    );
  }

  Widget _practiceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    List<String> highlights = const [],
  }) {
    final text = Theme.of(context).textTheme;
    return Glass(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 52),
                const SizedBox(height: 16),
                Text(title,
                    style:
                        text.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(subtitle, style: text.bodyMedium),
                if (highlights.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: highlights
                        .map((h) => Chip(
                              label: Text(h),
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _meditationSetupUI() {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final cs = theme.colorScheme;
    final tips = [
      (
        'Prepare your space',
        'Sit upright, plant your feet, and let shoulders drop. A blanket or cushion can help you stay relaxed longer.',
      ),
      (
        'Guide your breath',
        'Inhale slowly for a count of four, hold for two, then exhale for six. Use the timer to keep a steady rhythm.',
      ),
      (
        'Notice, don’t judge',
        'When thoughts drift, acknowledge them gently and bring attention back to the breath or a calming word.',
      ),
    ];
    final copingChips = [
      '5–4–3–2–1 grounding',
      'Box breathing',
      'Body scan check-in',
      'Positive mantra repeat',
      'Journaling after session',
    ];

    return ListView(children: [
      Glass(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mindfulness primer',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 8),
              Text(
                'Use this space to reset your nervous system. Slow breathing and mindful attention can lower heart rate, calm the mind, and make coping with symptoms easier.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text('Set yourself up for success',
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 8),
              ...tips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 2),
                      Icon(Icons.brightness_1,
                          size: 8, color: cs.primary.withValues(alpha: 0.9)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: text.bodyMedium,
                            children: [
                              TextSpan(
                                text: '${tip.$1}: ',
                                style: text.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: tip.$2),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Coping skills to pair with your session',
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: copingChips
                    .map(
                      (chip) => Chip(
                        label: Text(chip),
                        backgroundColor: cs.tertiary.withValues(alpha: 0.12),
                        labelStyle: text.bodySmall,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Glass(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Duration', style: text.titleMedium),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: Slider(
                  min: 5,
                  max: 60,
                  divisions: 11,
                  value: _durationMin.toDouble(),
                  label: '$_durationMin min',
                  onChanged: (v) => setState(() => _durationMin = v.round()))),
          SizedBox(
              width: 64,
              child: Text('$_durationMin min', textAlign: TextAlign.center))
        ]),
      ])),
      const SizedBox(height: 12),
      Glass(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Preset sound', style: text.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
            initialValue: _selectedPreset,
            items: _presets.keys
                .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                .toList(),
            onChanged: (v) => setState(() => _selectedPreset = v ?? 'None'),
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.music_note),
                border: OutlineInputBorder())),
        const SizedBox(height: 12),
        Text('Custom URL (overrides preset if filled)',
            style: text.titleMedium),
        const SizedBox(height: 8),
        TextField(
            controller: _customUrl,
            decoration: const InputDecoration(
                hintText: 'https://example.com/ambient.mp3',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder())),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.volume_up),
          Expanded(
              child: Slider(
                  min: 0,
                  max: 1,
                  divisions: 10,
                  value: _volume,
                  onChanged: (v) async {
                    setState(() => _volume = v);
                    await _player.setVolume(v);
                  })),
          SizedBox(
              width: 48,
              child: Text((_volume * 100).round().toString(),
                  textAlign: TextAlign.right))
        ]),
      ])),
      const SizedBox(height: 16),
      FilledButton(onPressed: _start, child: const Text('Start')),
    ]);
  }

  Widget _breathingSetupUI() {
    final text = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final cadenceDescription = _breathingPhases
        .map((phase) => '${phase.label} ${phase.seconds}s')
        .join(' • ');
    final suggestions = [
      'Let the belly lead the breath, then the ribs, then the chest.',
      'Keep shoulders soft. Relax the jaw and place your tongue on the palate.',
      'If you feel dizzy, return to natural breathing for a round before rejoining.',
    ];
    final int totalSeconds = _breathingRoundDuration * _breathingRounds;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    final String totalLabel = minutes > 0
        ? '$minutes min ${seconds.toString().padLeft(2, '0')} s'
        : '$seconds s';

    return ListView(
      children: [
        Glass(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Breathing for anxiety relief',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 8),
                Text(
                  'The 4-6 cadence keeps the exhale longer than the inhale without any breath holding, which can cue the nervous system to downshift.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(cadenceDescription),
                      backgroundColor: cs.primary.withValues(alpha: 0.1),
                    ),
                    Chip(
                      label: const Text('Rounds are gentle and slow'),
                      backgroundColor: cs.tertiary.withValues(alpha: 0.12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...suggestions.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 2),
                        Icon(Icons.brightness_1,
                            size: 8, color: cs.primary.withValues(alpha: 0.9)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(tip, style: text.bodyMedium)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Glass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text('Rounds', style: text.titleMedium),
              ),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      min: 3,
                      max: 10,
                      divisions: 7,
                      value: _breathingRounds.toDouble(),
                      onChanged: (v) =>
                          setState(() => _breathingRounds = v.round()),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text('$_breathingRounds',
                        textAlign: TextAlign.center, style: text.titleMedium),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total duration ≈ $totalLabel',
                        style: text.bodyMedium),
                    const SizedBox(height: 4),
                    Text('One round • $_breathingRoundDuration s',
                        style: text.bodySmall),
                    const SizedBox(height: 4),
                    Text('Pattern • $cadenceDescription',
                        style: text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            _startBreathing();
          },
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Begin guided breath'),
        ),
      ],
    );
  }

  Future<void> _startBreathing() async {
    FocusScope.of(context).unfocus();
    await _player.stop();
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _journey = _MeditationJourney.breathingRunning;
      _blockBack = true;
      _breathingRoundsRemaining = _breathingRounds;
      _breathingPhaseIndex = 0;
      _breathingSecondsLeft = _breathingPhases.first.seconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      var completeSession = false;
      setState(() {
        if (_breathingSecondsLeft > 0) {
          _breathingSecondsLeft--;
        }
        if (_breathingSecondsLeft <= 0) {
          final isLastPhase =
              _breathingPhaseIndex == _breathingPhases.length - 1;
          if (isLastPhase) {
            _breathingRoundsRemaining--;
            if (_breathingRoundsRemaining <= 0) {
              timer.cancel();
              completeSession = true;
              return;
            }
          }
          _breathingPhaseIndex = isLastPhase ? 0 : _breathingPhaseIndex + 1;
          _breathingSecondsLeft =
              _breathingPhases[_breathingPhaseIndex].seconds;
        }
      });
      if (completeSession) {
        _finishBreathing();
      }
    });
  }

  Future<void> _finishBreathing() async {
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _blockBack = false;
      _journey = _MeditationJourney.choose;
    });
    if (mounted) Navigator.pop(context);
  }

  Widget _breathingRunningUI() {
    final text = Theme.of(context).textTheme;
    final phase = _breathingPhases[_breathingPhaseIndex];
    final int displaySecondsLeft =
        _breathingSecondsLeft < 0 ? 0 : _breathingSecondsLeft;
    final double phaseProgress =
        (phase.seconds - displaySecondsLeft) / phase.seconds;
    final int roundsCompleted = _breathingRounds - _breathingRoundsRemaining;
    final int currentRound = math.max(1, roundsCompleted + 1);
    final nextPhase =
        _breathingPhases[(_breathingPhaseIndex + 1) % _breathingPhases.length];

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Glass(
            padding: const EdgeInsets.all(28),
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: phaseProgress.clamp(0.0, 1.0),
                      strokeWidth: 10,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(phase.icon, size: 48),
                      const SizedBox(height: 12),
                      Text(phase.label,
                          style: text.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${displaySecondsLeft}s', style: text.titleLarge),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Round $currentRound of $_breathingRounds',
              style: text.titleMedium),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(phase.cue,
                style: text.bodyLarge, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          Text('Next: ${nextPhase.label}',
              style: text.bodyMedium?.copyWith(
                  color: text.bodyMedium?.color?.withValues(alpha: 0.7))),
          const SizedBox(height: 32),
          TextButton(
              onPressed: _finishBreathing, child: const Text('End practice')),
        ],
      ),
    );
  }

  Widget _meditationRunningUI() {
    final text = Theme.of(context).textTheme;
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.self_improvement, size: 64),
      const SizedBox(height: 12),
      Text(_fmt(_remaining), style: text.displaySmall),
      const SizedBox(height: 8),
      const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
              'Stay with your breath. Keep the app open. The page will close automatically when the timer finishes.',
              textAlign: TextAlign.center)),
      const SizedBox(height: 24),
      TextButton(onPressed: _finish, child: const Text('End session')),
    ]));
  }
}

/// ===================== Edit Profile =====================
