// ignore_for_file: use_build_context_synchronously

part of 'package:patient_tracker/app_modules.dart';

class FeelingsPage extends StatefulWidget {
  const FeelingsPage({
    super.key,
    required this.initialScore,
    required this.history,
    required this.safetyPlan,
    required this.onSafetyPlanChanged,
  });
  final int initialScore;
  final List<FeelingEntry> history;
  final SafetyPlanData safetyPlan;
  final ValueChanged<SafetyPlanData> onSafetyPlanChanged;
  @override
  State<FeelingsPage> createState() => _FeelingsPageState();
}

class FeelingsResult {
  FeelingsResult({
    required this.score,
    required this.when,
    this.journalNote,
  });

  final int score;
  final DateTime when;
  final String? journalNote;
}

enum _LowMoodAction { education, messageNurse, miniGame, meditation }

class _LowMoodSupportResult {
  const _LowMoodSupportResult({this.action, this.journalNote});

  final _LowMoodAction? action;
  final String? journalNote;
}

String supportiveMessageForScore(int s) {
  final rand = math.Random();

  const positive = [
    "Love to see it! Keep that momentum 🌟",
    "You're on a roll—proud of you!",
    "Great vibes—carry them with you today!",
    "Awesome mood! Share it with someone you care about.",
  ];
  const neutral = [
    "Steady is good—small wins count.",
    "Neutral today—how about a short walk or deep breaths?",
    "You're holding it together. A tiny reset can help.",
  ];
  const supportive = [
    "You're not alone. One small step counts today ❤️",
    "Be gentle with yourself—this feeling will pass.",
    "Try 3 slow breaths. I’m with you.",
    "Text someone you trust—even a short hello helps.",
  ];

  String pick(List<String> list) => list[rand.nextInt(list.length)];

  if (s >= 4) return pick(positive);
  if (s == 3) return pick(neutral);
  return pick(supportive);
}

class FeelingsCelebrationOverlay extends StatefulWidget {
  const FeelingsCelebrationOverlay({
    super.key,
    required this.score,
    required this.emoji,
    required this.message,
  });

  final int score;
  final String emoji;
  final String message;

  @override
  State<FeelingsCelebrationOverlay> createState() =>
      _FeelingsCelebrationOverlayState();
}

class _FeelingsCelebrationOverlayState extends State<FeelingsCelebrationOverlay>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 5));
  late final AnimationController _heroController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _fadeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _heroScale =
      CurvedAnimation(parent: _heroController, curve: Curves.elasticOut);
  late final Animation<double> _fadeAnimation =
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    _heroController.forward();
    _fadeController.forward();
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _heroController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String _headline() {
    if (widget.score >= 5) return 'Incredible mood check-in!';
    if (widget.score == 4) return 'Great energy today!';
    return 'Steady and strong';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final gradientColors = isDark
        ? [
            cs.surface.withValues(alpha: 0.96),
            cs.surfaceContainerHighest.withValues(alpha: 0.94),
            cs.primaryContainer.withValues(alpha: 0.85),
          ]
        : [
            cs.primary.withValues(alpha: 0.9),
            cs.secondary.withValues(alpha: 0.86),
            cs.tertiary.withValues(alpha: 0.82),
          ];
    final headlineColor = isDark ? cs.onSurface : Colors.white;
    final subheadColor =
        isDark ? cs.onSurfaceVariant.withValues(alpha: 0.88) : Colors.white70;
    final closeColor = headlineColor;
    final heroOuterColor = isDark
        ? Colors.black.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.24);
    final heroBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.45);
    final heroShadowColor =
        Colors.black.withValues(alpha: isDark ? 0.45 : 0.28);
    final cardBackgroundColor = isDark
        ? cs.surfaceContainerHighest.withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.94);
    final cardBorderColor = cs.outline.withValues(alpha: isDark ? 0.36 : 0.2);
    final cardTextColor =
        isDark ? cs.onSurface : Colors.black.withValues(alpha: 0.84);
    final cardSubtextColor = isDark
        ? cs.onSurfaceVariant.withValues(alpha: 0.85)
        : Colors.black.withValues(alpha: 0.64);
    final buttonBackground = isDark ? cs.primary : Colors.white;
    final buttonForeground = isDark ? cs.onPrimary : cs.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 110,
                  maxBlastForce: 18,
                  minBlastForce: 6,
                  emissionFrequency: 0.02,
                  gravity: 0.16,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      color: closeColor,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Spacer(),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        ScaleTransition(
                          scale: _heroScale,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: heroOuterColor,
                              border: Border.all(
                                color: heroBorderColor,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: heroShadowColor,
                                  blurRadius: 26,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.emoji,
                              style: const TextStyle(fontSize: 68),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _headline(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: headlineColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mood score ${widget.score}/5',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: subheadColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: cardBackgroundColor,
                            border: Border.all(color: cardBorderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.message,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: cardTextColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Capture what helped today so you can repeat it tomorrow.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cardSubtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: buttonBackground,
                          foregroundColor: buttonForeground,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          textStyle: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Keep this feeling going'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeelingsSupportOverlay extends StatefulWidget {
  const FeelingsSupportOverlay({
    super.key,
    required this.supportMessage,
    required this.isCrisis,
    this.onCallEmergency,
    this.onCallHotline,
    this.news = const [],
    required this.safetyPlan,
    this.onSafetyPlanChanged,
    this.initialJournal,
  });

  final String supportMessage;
  final bool isCrisis;
  final VoidCallback? onCallEmergency;
  final VoidCallback? onCallHotline;
  final List<HospitalNewsItem> news;
  final SafetyPlanData safetyPlan;
  final ValueChanged<SafetyPlanData>? onSafetyPlanChanged;
  final String? initialJournal;

  @override
  State<FeelingsSupportOverlay> createState() => _FeelingsSupportOverlayState();
}

class HospitalNewsItem {
  const HospitalNewsItem({required this.title, required this.snippet});
  final String title;
  final String snippet;
}

const List<HospitalNewsItem> _kHospitalNewsItems = [
  HospitalNewsItem(
      title: 'New sleep therapy wing opens',
      snippet: 'Our inpatient unit now offers guided light therapy rooms.'),
  HospitalNewsItem(
      title: 'Nutrition workshop this Friday',
      snippet: 'Join the dietitian team for quick meal-prep demos at 2:00 PM.'),
  HospitalNewsItem(
      title: 'Mindfulness lounge refreshed',
      snippet: 'Soft kettles and VR calm sessions available daily.'),
];

class _FeelingsSupportOverlayState extends State<FeelingsSupportOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _heroController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _fadeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _heroScale =
      CurvedAnimation(parent: _heroController, curve: Curves.elasticOut);
  late final Animation<double> _fadeAnimation =
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);

  bool get _allowDismiss => !widget.isCrisis;

  @override
  void initState() {
    super.initState();
    _heroController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final gradientColors = isDark
        ? [
            cs.surface.withValues(alpha: 0.96),
            cs.surfaceContainerHighest.withValues(alpha: 0.94),
            cs.primaryContainer.withValues(alpha: 0.75),
          ]
        : [
            cs.primary.withValues(alpha: 0.9),
            cs.secondary.withValues(alpha: 0.86),
            cs.tertiary.withValues(alpha: 0.78),
          ];
    final heroOuterColor = isDark
        ? Colors.black.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.24);
    final heroBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.5);
    final heroInnerColor = isDark ? cs.surfaceContainerHighest : Colors.white;
    final heroIconColor = isDark ? cs.errorContainer : cs.secondary;
    final closeColor = isDark ? cs.onSurface : Colors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const Positioned.fill(child: _FloatingHearts()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: _allowDismiss
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            color: closeColor,
                            onPressed: () => Navigator.of(context).pop(),
                          )
                        : const SizedBox(height: 48, width: 48),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final minHeight =
                          math.max(0.0, constraints.maxHeight - 24);
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight:
                                minHeight, // keep centered when space allows
                          ),
                          child: Center(
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ScaleTransition(
                                    scale: _heroScale,
                                    child: Container(
                                      padding: const EdgeInsets.all(26),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: heroOuterColor,
                                        border: Border.all(
                                            color: heroBorderColor, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                                alpha: isDark ? 0.45 : 0.28),
                                            blurRadius: 24,
                                            offset: const Offset(0, 18),
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(22),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: heroInnerColor,
                                        ),
                                        child: Icon(
                                          Icons.favorite_rounded,
                                          size: 48,
                                          color: heroIconColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 580),
                                    child: _LowMoodSupportCard(
                                      supportMessage: widget.supportMessage,
                                      isCrisis: widget.isCrisis,
                                      onCallEmergency: widget.onCallEmergency,
                                      onCallHotline: widget.onCallHotline,
                                      news: widget.news,
                                      safetyPlan: widget.safetyPlan,
                                      onSafetyPlanChanged:
                                          widget.onSafetyPlanChanged,
                                      initialJournal: widget.initialJournal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartParticle {
  _HeartParticle({
    required this.x,
    required this.offset,
    required this.speed,
    required this.scale,
  });

  final double x;
  final double offset;
  final double speed;
  final double scale;
}

class _FloatingHearts extends StatefulWidget {
  const _FloatingHearts();

  @override
  State<_FloatingHearts> createState() => _FloatingHeartsState();
}

class _FloatingHeartsState extends State<_FloatingHearts>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  late final List<_HeartParticle> _particles;
  final math.Random _rand = math.Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(
      16,
      (_) => _HeartParticle(
        x: _rand.nextDouble(),
        offset: _rand.nextDouble(),
        speed: 0.5 + _rand.nextDouble() * 0.9,
        scale: 0.6 + _rand.nextDouble() * 1.1,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = [
      cs.secondary.withValues(alpha: 0.75),
      cs.primary.withValues(alpha: 0.65),
      Colors.pinkAccent.withValues(alpha: 0.7),
    ];
    return IgnorePointer(
      child: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => CustomPaint(
            painter: _HeartsPainter(
              progress: _controller.value,
              particles: _particles,
              colors: colors,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeartsPainter extends CustomPainter {
  _HeartsPainter({
    required this.progress,
    required this.particles,
    required this.colors,
  });

  final double progress;
  final List<_HeartParticle> particles;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < particles.length; i++) {
      final particle = particles[i];
      final double t = ((progress * particle.speed) + particle.offset) % 1.0;
      final dy = size.height - (size.height + 120) * t;
      final dx = particle.x * size.width +
          math.sin((t + particle.offset) * math.pi * 2) * 30;
      final opacity = (1 - t).clamp(0.0, 1.0);
      final color = colors[i % colors.length].withValues(alpha: opacity * 0.8);
      final double fontSize = 28 * particle.scale * (0.8 + (1 - t) * 0.4);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '❤',
          style: TextStyle(fontSize: fontSize, color: color),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final offset = Offset(
        dx - textPainter.width / 2,
        dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _HeartsPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.particles != particles ||
      oldDelegate.colors != colors;
}

class _LowMoodSupportCard extends StatefulWidget {
  const _LowMoodSupportCard({
    required this.supportMessage,
    this.isCrisis = false,
    this.onCallEmergency,
    this.onCallHotline,
    this.news = const [],
    required this.safetyPlan,
    this.onSafetyPlanChanged,
    this.initialJournal,
  });

  final String supportMessage;
  final bool isCrisis;
  final VoidCallback? onCallEmergency;
  final VoidCallback? onCallHotline;
  final List<HospitalNewsItem> news;
  final SafetyPlanData safetyPlan;
  final ValueChanged<SafetyPlanData>? onSafetyPlanChanged;
  final String? initialJournal;

  @override
  State<_LowMoodSupportCard> createState() => _LowMoodSupportCardState();
}

class _LowMoodSupportCardState extends State<_LowMoodSupportCard> {
  final TextEditingController _journalController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _safetyCheckComplete = false;
  bool _safetyPlanReviewed = false;
  bool _showValidationError = false;
  late SafetyPlanData _plan;

  @override
  void dispose() {
    _journalController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _plan = widget.safetyPlan;
    if (widget.initialJournal?.isNotEmpty == true) {
      _journalController.text = widget.initialJournal!;
    }
  }

  bool get _canComplete =>
      !widget.isCrisis || (_safetyCheckComplete && _safetyPlanReviewed);

  void _markSafetyCheck(bool? value) {
    setState(() {
      _safetyCheckComplete = value ?? false;
      if (_safetyCheckComplete) _showValidationError = false;
    });
  }

  void _handleEmergencyCall() {
    widget.onCallEmergency?.call();
  }

  void _handleHotlineCall() {
    widget.onCallHotline?.call();
  }

  void _handleSafetyPlanUpdated(SafetyPlanData data) {
    widget.onSafetyPlanChanged?.call(data);
    setState(() {
      _plan = data;
      _safetyPlanReviewed = true;
      _showValidationError = false;
    });
  }

  Future<void> _openSafetyPlan() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SafetyPlanPage(
        initialData: _plan,
        onSave: _handleSafetyPlanUpdated,
      ),
    ));
    if (!mounted) return;
    setState(() {
      _safetyPlanReviewed = true;
      _showValidationError = false;
    });
  }

  Future<void> _callEmergencyContact() async {
    final phone = _plan.emergencyContactPhone.trim();
    if (phone.isEmpty) return;
    final dial = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (dial.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: dial);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      showToast(context,
          'Unable to reach ${_plan.emergencyContactName.isEmpty ? phone : _plan.emergencyContactName}.');
    }
  }

  void _close(_LowMoodAction? action) {
    if (!_canComplete) {
      _requireSafetyFeedback();
      return;
    }
    final note = _journalController.text.trim();
    Navigator.of(context).pop(
      _LowMoodSupportResult(
        action: action,
        journalNote: note.isEmpty ? null : note,
      ),
    );
  }

  void _requireSafetyFeedback() {
    setState(() => _showValidationError = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleActionTap(_LowMoodAction action) {
    if (widget.isCrisis && !_canComplete) {
      _requireSafetyFeedback();
      return;
    }
    _close(action);
  }

  Widget _buildCrisisSection(ThemeData theme, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Immediate safety check',
            style: theme.textTheme.titleSmall?.copyWith(
              color: cs.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a moment to confirm you are safe and reach out for support right away.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 6),
          Text(
            'Before you continue, review the steps in your safety plan so you know the next actions to take.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _safetyCheckComplete,
                onChanged: _markSafetyCheck,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'I’ve checked in with myself and can stay present while getting help.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openSafetyPlan,
              icon: const Icon(Icons.shield_outlined),
              label: Text(
                _safetyPlanReviewed
                    ? 'Review safety plan again'
                    : 'Review safety plan now',
              ),
            ),
          ),
          if (_safetyPlanReviewed) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.check_circle, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Safety plan reviewed. If you still need help, reach out to your supports below.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Need immediate support?',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
              ),
              onPressed:
                  widget.onCallEmergency == null ? null : _handleEmergencyCall,
              icon: const Icon(Icons.local_phone),
              label: const Text('Call hospital emergency'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  widget.onCallHotline == null ? null : _handleHotlineCall,
              icon: const Icon(Icons.support_agent),
              label: const Text('Call 988 Lifeline'),
            ),
          ),
          if (_plan.hasEmergencyContact) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _callEmergencyContact,
                icon: const Icon(Icons.phone_in_talk),
                label: Text(
                  _plan.emergencyContactName.isEmpty
                      ? 'Call emergency contact'
                      : 'Call ${_plan.emergencyContactName}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final footerPadding = widget.isCrisis
        ? const EdgeInsets.fromLTRB(24, 16, 24, 24)
        : const EdgeInsets.fromLTRB(24, 12, 24, 24);
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    final containerColor = isDark
        ? cs.surfaceContainerHighest.withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.96);
    final borderColor = isDark
        ? cs.outline.withValues(alpha: 0.24)
        : cs.primary.withValues(alpha: 0.18);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 540),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                blurRadius: 34,
                offset: const Offset(0, 26),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'It sounds like today is tough',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.supportMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.28),
                indent: 24,
                endIndent: 24,
              ),
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: false,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.isCrisis) _buildCrisisSection(theme, cs),
                          if (widget.isCrisis) const SizedBox(height: 18),
                          _LowMoodSupportOption(
                            icon: Icons.auto_stories_outlined,
                            title: 'Read calming mental health tips',
                            subtitle:
                                'Open education resources with grounding exercises.',
                            color: cs.primary,
                            onTap: () =>
                                _handleActionTap(_LowMoodAction.education),
                          ),
                          const SizedBox(height: 10),
                          _LowMoodSupportOption(
                            icon: Icons.forum_outlined,
                            title: 'Chat with your nurse',
                            subtitle:
                                'Share how you are feeling and ask for guidance.',
                            color: cs.secondary,
                            onTap: () =>
                                _handleActionTap(_LowMoodAction.messageNurse),
                          ),
                          const SizedBox(height: 10),
                          _LowMoodSupportOption(
                            icon: Icons.self_improvement,
                            title: 'Try a guided meditation',
                            subtitle:
                                'Enter meditation mode to regulate your breathing.',
                            color: cs.primaryContainer,
                            onTap: () =>
                                _handleActionTap(_LowMoodAction.meditation),
                          ),
                          const SizedBox(height: 10),
                          _LowMoodSupportOption(
                            icon: Icons.videogame_asset_outlined,
                            title: 'Take a mindful game break',
                            subtitle:
                                'Play a quick mini game to reset your mind.',
                            color: cs.tertiary,
                            onTap: () =>
                                _handleActionTap(_LowMoodAction.miniGame),
                          ),
                          if (_plan.hasEmergencyContact) ...[
                            const SizedBox(height: 10),
                            _LowMoodSupportOption(
                              icon: Icons.phone_in_talk,
                              title: _plan.emergencyContactName.isEmpty
                                  ? 'Call emergency contact'
                                  : 'Call ${_plan.emergencyContactName}',
                              subtitle: _plan.emergencyContactPhone,
                              color: cs.primary,
                              onTap: _callEmergencyContact,
                            ),
                          ],
                          if (widget.news.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Text('Helpful updates',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                )),
                            const SizedBox(height: 8),
                            ...widget.news
                                .map((item) => _SupportNewsTile(item: item)),
                          ],
                          const SizedBox(height: 20),
                          Text('Quick journal',
                              style: theme.textTheme.titleSmall),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _journalController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText:
                                  'Write a few sentences about what is going on…',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'We’ll save this note with today’s mood so you can revisit or share it.',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.7)),
                          ),
                          if (_showValidationError) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Complete the safety check and review your safety plan before continuing.',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: cs.error),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: footerPadding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!widget.isCrisis) ...[
                      TextButton(
                        onPressed: () => _close(null),
                        child: const Text('Skip for now'),
                      ),
                      const SizedBox(width: 12),
                    ],
                    FilledButton(
                      onPressed: () {
                        if (_canComplete) {
                          _close(null);
                        } else {
                          _requireSafetyFeedback();
                        }
                      },
                      child: Text(widget.isCrisis ? 'Continue' : 'Done'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LowMoodSupportOption extends StatelessWidget {
  const _LowMoodSupportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color accent = color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.22),
              accent.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: accent.withValues(alpha: 0.24),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: accent),
          ],
        ),
      ),
    );
  }
}

class _SupportNewsTile extends StatelessWidget {
  const _SupportNewsTile({required this.item});

  final HospitalNewsItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.article_outlined,
              size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(item.snippet),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const List<String> _kEmotionTags = [
  'Grateful',
  'Joyful',
  'Calm',
  'Hopeful',
  'Proud',
  'Stressed',
  'Anxious',
  'Overwhelmed',
  'Sad',
];

const List<String> _kContextTags = [
  'Work',
  'Family',
  'Friends',
  'Health',
  'Rest',
  'Outdoors',
  'Creative',
  'Travel',
  'Learning',
];

class _FeelingsPageState extends State<FeelingsPage> {
  static const _emojis = ['😞', '🙁', '😐', '🙂', '😄'];
  static const List<String> _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  static final Uri _emergencyCallUri = Uri(scheme: 'tel', path: '911');
  static final Uri _hotlineCallUri = Uri(scheme: 'tel', path: '988');
  late int score;
  late SafetyPlanData _plan;
  final Set<String> _selectedEmotionTags = <String>{};
  final Set<String> _selectedContextTags = <String>{};
  String _journalNote = '';
  bool _historyExpanded = false;
  late DateTime _historyMonth;
  DateTime? _selectedHistoryDay;

  @override
  void initState() {
    super.initState();
    score = widget.initialScore.clamp(1, 5);
    _plan = widget.safetyPlan;
    final now = DateTime.now();
    _historyMonth = DateTime(now.year, now.month);
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _launchExternal(Uri uri, String failureMessage) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      showToast(context, failureMessage);
    }
  }

  bool get _hasJournalDraft =>
      _selectedEmotionTags.isNotEmpty ||
      _selectedContextTags.isNotEmpty ||
      _journalNote.trim().isNotEmpty;

  String _composeJournalNote() {
    final parts = <String>[];
    if (_selectedEmotionTags.isNotEmpty) {
      parts.add('Emotions: ${_selectedEmotionTags.join(', ')}');
    }
    if (_selectedContextTags.isNotEmpty) {
      parts.add('Context: ${_selectedContextTags.join(', ')}');
    }
    final freeform = _journalNote.trim();
    if (freeform.isNotEmpty) {
      if (parts.isNotEmpty) {
        parts.add('');
      }
      parts.add(freeform);
    }
    return parts.join('\n');
  }

  Color _scoreAccent(ColorScheme cs) {
    final t = ((score - 1) / 4).clamp(0.0, 1.0);
    return Color.lerp(cs.error, cs.primary, t) ?? cs.primary;
  }

  String _moodHeadline() {
    switch (score) {
      case 1:
        return "Let's ground together";
      case 2:
        return "Small steps count today";
      case 3:
        return "Steady and present";
      case 4:
        return "Great momentum!";
      case 5:
        return "Radiating good energy";
      default:
        return "Checking in";
    }
  }

  String _moodSubtext() {
    switch (score) {
      case 1:
        return 'Pause, breathe, and lean on your supports. You are not alone.';
      case 2:
        return 'Choose one gentle action—text someone, stretch, or journal.';
      case 3:
        return 'Notice what is working and carry it forward through the day.';
      case 4:
        return 'Celebrate the wins and share your good mood with someone.';
      case 5:
        return 'Bottle this feeling—maybe jot down what sparked it!';
      default:
        return 'Take a mindful moment before saving today’s feeling.';
    }
  }

  Widget _moodHeroCard() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = _scoreAccent(cs);
    final highlight = _moodHeadline();
    final detail = _moodSubtext();
    final emoji = _emojis[score - 1];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.08),
            cs.surface.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highlight,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  detail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wellnessQuickActionsCard() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = _scoreAccent(cs);
    final actions = <_QuickAction>[
      _QuickAction(
        label: 'Mindfulness session',
        icon: Icons.self_improvement,
        onPressed: () => _handleLowMoodAction(_LowMoodAction.meditation),
      ),
      _QuickAction(
        label: 'Mini game break',
        icon: Icons.videogame_asset_outlined,
        onPressed: () => _handleLowMoodAction(_LowMoodAction.miniGame),
      ),
      const _QuickAction(
        label: 'Breathing break',
        icon: Icons.air,
        message: 'Try 4-7-8 breathing for one minute.',
      ),
      const _QuickAction(
        label: 'Hydrate',
        icon: Icons.local_drink_outlined,
        message: 'Sip a glass of water slowly.',
      ),
    ];

    return Glass(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on_outlined, color: accent),
                const SizedBox(width: 8),
                Text('Quick actions', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: actions
                  .map(
                    (action) => ActionChip(
                      avatar: Icon(action.icon, size: 18, color: accent),
                      label: Text(action.label),
                      onPressed: () {
                        if (action.onPressed != null) {
                          action.onPressed!();
                        } else if (action.message != null) {
                          showToast(context, action.message!);
                        }
                      },
                      backgroundColor:
                          cs.surfaceContainerHighest.withValues(alpha: 0.22),
                      labelStyle: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _journalHubCard() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasDraft = _hasJournalDraft;
    final notePreview = _journalNote.trim();
    String? summaryText(Set<String> values) =>
        values.isEmpty ? null : values.join(', ');
    final hasHistoryEntries = widget.history.any(_hasJournalContent);

    return Glass(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.edit_note, color: cs.primary, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Journal',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Capture today’s feeling and revisit past reflections.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _openJournalComposer,
                  icon: const Icon(Icons.add),
                  label: const Text('Add entry'),
                ),
              ],
            ),
            if (hasDraft) ...[
              const SizedBox(height: 16),
              if (_selectedEmotionTags.isNotEmpty)
                _JournalSummaryRow(
                  icon: Icons.emoji_emotions_outlined,
                  label: 'Emotions',
                  value: summaryText(_selectedEmotionTags)!,
                ),
              if (_selectedContextTags.isNotEmpty)
                _JournalSummaryRow(
                  icon: Icons.layers_outlined,
                  label: 'Context',
                  value: summaryText(_selectedContextTags)!,
                ),
              if (notePreview.isNotEmpty)
                _JournalSummaryRow(
                  icon: Icons.notes_outlined,
                  label: 'Notes',
                  value: notePreview,
                ),
            ],
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _toggleHistoryExpanded,
              icon: Icon(
                _historyExpanded
                    ? Icons.expand_less
                    : Icons.event_available_outlined,
              ),
              label: Text(
                  _historyExpanded ? 'Hide history' : 'View journal history'),
            ),
            if (_historyExpanded) ...[
              const SizedBox(height: 12),
              _buildJournalHistorySection(),
            ],
            if (!hasHistoryEntries)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'No journal entries yet—log today to start building your history.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleHistoryExpanded() {
    setState(() => _historyExpanded = !_historyExpanded);
  }

  Widget _buildJournalHistorySection() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final monthKey = DateTime(_historyMonth.year, _historyMonth.month);
    final entriesByDay = _entriesByDay(monthKey);
    final days = _calendarDaysForMonth(monthKey);
    final selectedDay = _selectedHistoryDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: () => _changeHistoryMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Center(
                child: Text(
                  _monthLabel(monthKey),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: () => _changeHistoryMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: _weekdayLabels
              .map((label) => Expanded(
                    child: Center(
                      child: Text(label,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            if (day == null) {
              return const SizedBox.shrink();
            }
            final key = DateTime(day.year, day.month, day.day);
            final hasEntry = entriesByDay.containsKey(key);
            final isSelected =
                selectedDay != null && _sameDay(selectedDay, key);
            final bgColor = isSelected
                ? cs.primary.withValues(alpha: 0.18)
                : hasEntry
                    ? cs.primary.withValues(alpha: 0.08)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.12);
            final borderColor = isSelected
                ? cs.primary
                : hasEntry
                    ? cs.primary.withValues(alpha: 0.45)
                    : cs.outline.withValues(alpha: 0.25);

            return GestureDetector(
              onTap: hasEntry
                  ? () => _openJournalEntryDetails(
                      key, entriesByDay[key] ?? const <FeelingEntry>[])
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: hasEntry
                            ? cs.onPrimaryContainer
                            : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    if (hasEntry)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.bookmark,
                          size: 14,
                          color: cs.primary,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          entriesByDay.isEmpty
              ? 'No journal entries this month yet. Your saved reflections will appear here.'
              : 'Tap a highlighted day to review journal notes and add comments.',
          style:
              theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  void _changeHistoryMonth(int delta) {
    setState(() {
      final tentative =
          DateTime(_historyMonth.year, _historyMonth.month + delta);
      _historyMonth = DateTime(tentative.year, tentative.month);
      final selected = _selectedHistoryDay;
      if (selected != null &&
          (selected.year != _historyMonth.year ||
              selected.month != _historyMonth.month)) {
        _selectedHistoryDay = null;
      }
    });
  }

  String _monthLabel(DateTime month) =>
      '${_monthNames[month.month - 1]} ${month.year}';

  bool _hasJournalContent(FeelingEntry entry) =>
      (entry.note?.trim().isNotEmpty ?? false) || entry.comments.isNotEmpty;

  Map<DateTime, List<FeelingEntry>> _entriesByDay(DateTime month) {
    final map = <DateTime, List<FeelingEntry>>{};
    for (final entry in widget.history) {
      if (!_hasJournalContent(entry)) continue;
      final key = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (key.year == month.year && key.month == month.month) {
        map.putIfAbsent(key, () => <FeelingEntry>[]).add(entry);
      }
    }
    for (final list in map.values) {
      list.sort((a, b) => b.date.compareTo(a.date));
    }
    return map;
  }

  List<DateTime?> _calendarDaysForMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final totalDays = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = (firstDay.weekday + 6) % 7; // Monday = 0
    final days = <DateTime?>[];
    for (var i = 0; i < firstWeekday; i++) {
      days.add(null);
    }
    for (var day = 1; day <= totalDays; day++) {
      days.add(DateTime(month.year, month.month, day));
    }
    while (days.length % 7 != 0) {
      days.add(null);
    }
    return days;
  }

  List<FeelingEntry> _entriesForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    final entries = widget.history
        .where(
            (entry) => _sameDay(entry.date, key) && _hasJournalContent(entry))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Future<void> _openJournalEntryDetails(
      DateTime day, List<FeelingEntry> entries) async {
    if (entries.isEmpty) return;
    setState(() => _selectedHistoryDay = day);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final displayEntries = _entriesForDay(day);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Text(
                    formatDate(day),
                    style: Theme.of(sheetContext)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${displayEntries.length} journal entr${displayEntries.length == 1 ? 'y' : 'ies'}',
                    style: Theme.of(sheetContext).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  for (final entry in displayEntries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Glass(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.emoji_emotions_outlined,
                                      color: Theme.of(sheetContext)
                                          .colorScheme
                                          .primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Mood ${entry.score}/5 · ${formatTime(entry.date)}',
                                    style: Theme.of(sheetContext)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (entry.note?.isNotEmpty ?? false)
                                Text(
                                  entry.note!,
                                  style: Theme.of(sheetContext)
                                      .textTheme
                                      .bodyMedium,
                                )
                              else
                                Text(
                                  'No journal note saved.',
                                  style: Theme.of(sheetContext)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: Theme.of(sheetContext)
                                              .colorScheme
                                              .onSurfaceVariant),
                                ),
                              const SizedBox(height: 12),
                              Text(
                                'Comments',
                                style: Theme.of(sheetContext)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              if (entry.comments.isEmpty)
                                Text(
                                  'No comments yet.',
                                  style: Theme.of(sheetContext)
                                      .textTheme
                                      .bodySmall,
                                )
                              else
                                ...entry.comments.map(
                                  (comment) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          comment.text,
                                          style: Theme.of(sheetContext)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatDateTime(comment.createdAt),
                                          style: Theme.of(sheetContext)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                  color: Theme.of(sheetContext)
                                                      .colorScheme
                                                      .onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.tonalIcon(
                                  onPressed: () => _addCommentToEntry(
                                    entry,
                                    () => setSheetState(() {}),
                                  ),
                                  icon: const Icon(Icons.add_comment_outlined),
                                  label: const Text('Add comment'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addCommentToEntry(
      FeelingEntry entry, VoidCallback refreshSheet) async {
    final input = await promptText(context, 'Add comment');
    if (!mounted) return;
    final trimmed = input?.trim();
    if (trimmed == null) return;
    if (trimmed.isEmpty) {
      showToast(context, 'Comment cannot be empty.');
      return;
    }
    setState(() {
      entry.comments.add(FeelingComment(text: trimmed));
    });
    refreshSheet();
    showToast(context, 'Comment added.');
  }

  Future<void> _openJournalComposer() async {
    final result = await Navigator.of(context).push<_JournalDraftResult>(
      MaterialPageRoute(
        builder: (_) => _JournalComposerPage(
          initialEmotions: _selectedEmotionTags.toList(),
          initialContexts: _selectedContextTags.toList(),
          initialNote: _journalNote,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedEmotionTags
          ..clear()
          ..addAll(result.emotions);
        _selectedContextTags
          ..clear()
          ..addAll(result.contexts);
        _journalNote = result.note.trim();
      });
    }
  }

  Future<void> _showFeelingsCelebration(int score, String message) {
    final emoji = _emojis[(score - 1).clamp(0, _emojis.length - 1)];
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (ctx, animation, _) => FadeTransition(
          opacity: animation,
          child: FeelingsCelebrationOverlay(
            score: score,
            emoji: emoji,
            message: message,
          ),
        ),
      ),
    );
  }

  Future<_LowMoodSupportResult?> _showLowMoodSupportOverlay(
      {required int score, required String message, String? initialJournal}) {
    final isCrisis = score == 1;
    return Navigator.of(context).push<_LowMoodSupportResult>(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: !isCrisis,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (ctx, animation, _) => FadeTransition(
          opacity: animation,
          child: FeelingsSupportOverlay(
            supportMessage: message,
            isCrisis: isCrisis,
            onCallEmergency: _callEmergencyLine,
            onCallHotline: _callHotline,
            news: _kHospitalNewsItems,
            safetyPlan: _plan,
            onSafetyPlanChanged: (updated) {
              widget.onSafetyPlanChanged(updated);
              setState(() => _plan = updated);
            },
            initialJournal: initialJournal,
          ),
        ),
      ),
    );
  }

  void _callEmergencyLine() {
    _launchExternal(_emergencyCallUri, 'Unable to place the emergency call.');
  }

  void _callHotline() {
    _launchExternal(_hotlineCallUri, 'Unable to connect to 988.');
  }

  Future<void> _handleLowMoodAction(_LowMoodAction action) async {
    switch (action) {
      case _LowMoodAction.education:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const EducationPage(),
        ));
        break;
      case _LowMoodAction.messageNurse:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const CareTeamMessagesPage(
            initialConversation: ConversationType.nurse,
          ),
        ));
        break;
      case _LowMoodAction.miniGame:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const MiniGamesPage(),
        ));
        break;
      case _LowMoodAction.meditation:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const MeditationModePage(),
        ));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
          title: const Text("Today’s Feelings"),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Text('How do you feel today?',
                  style: Theme.of(context).textTheme.titleMedium)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final idx = i + 1;
              final selected = score == idx;
              return GestureDetector(
                onTap: () => setState(() => score = idx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? cs.primaryContainer.withValues(alpha: 0.55)
                        : Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: selected
                            ? cs.primary
                            : Colors.white.withValues(alpha: 0.16)),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x11000000),
                          blurRadius: 6,
                          offset: Offset(0, 3))
                    ],
                  ),
                  child: Text(_emojis[i], style: const TextStyle(fontSize: 26)),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Align(
              alignment: Alignment.centerLeft,
              child: Text('Selected: ${_emojis[score - 1]} (score $score/5)')),
          const SizedBox(height: 12),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                onPressed: () async {
                  final now = DateTime.now();
                  _LowMoodSupportResult? support;
                  final encouragement = supportiveMessageForScore(score);
                  String? journalNote;
                  final quickNote = _composeJournalNote();
                  if (quickNote.trim().isNotEmpty) {
                    journalNote = quickNote;
                  }

                  if (score <= 2) {
                    support = await _showLowMoodSupportOverlay(
                      score: score,
                      message: encouragement,
                      initialJournal: journalNote,
                    );
                    if (!mounted) return;
                    if (support?.action != null) {
                      await _handleLowMoodAction(support!.action!);
                    }
                    final overlayNote = support?.journalNote?.trim();
                    if (overlayNote != null) {
                      if (overlayNote.isNotEmpty) {
                        setState(() => _journalNote = overlayNote);
                        journalNote = overlayNote;
                      } else {
                        setState(() => _journalNote = '');
                        journalNote = null;
                      }
                    }
                  } else {
                    await _showFeelingsCelebration(score, encouragement);
                  }

                  if (!mounted) return;
                  Navigator.pop(
                    context,
                    FeelingsResult(
                      score: score,
                      when: now,
                      journalNote: (journalNote?.trim().isNotEmpty ?? false)
                          ? journalNote
                          : null,
                    ),
                  );
                },
                child: const Text('Save feeling'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _moodHeroCard(),
          const SizedBox(height: 16),
          _journalHubCard(),
          const SizedBox(height: 16),
          _wellnessQuickActionsCard(),
        ],
      ),
    );
  }
}

class _JournalSummaryRow extends StatelessWidget {
  const _JournalSummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    this.message,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final String? message;
  final VoidCallback? onPressed;
}

class _JournalDraftResult {
  _JournalDraftResult({
    required this.emotions,
    required this.contexts,
    required this.note,
  });

  final List<String> emotions;
  final List<String> contexts;
  final String note;
}

class _JournalComposerPage extends StatefulWidget {
  const _JournalComposerPage({
    required this.initialEmotions,
    required this.initialContexts,
    required this.initialNote,
  });

  final List<String> initialEmotions;
  final List<String> initialContexts;
  final String initialNote;

  @override
  State<_JournalComposerPage> createState() => _JournalComposerPageState();
}

class _JournalComposerPageState extends State<_JournalComposerPage> {
  late final TextEditingController _noteController =
      TextEditingController(text: widget.initialNote);
  late final Set<String> _emotions =
      LinkedHashSet<String>.from(widget.initialEmotions);
  late final Set<String> _contexts =
      LinkedHashSet<String>.from(widget.initialContexts);

  @override
  void initState() {
    super.initState();
    _noteController.addListener(_onNoteChanged);
  }

  @override
  void dispose() {
    _noteController.removeListener(_onNoteChanged);
    _noteController.dispose();
    super.dispose();
  }

  void _onNoteChanged() => setState(() {});

  void _toggleEmotion(String tag) {
    setState(() {
      if (!_emotions.remove(tag)) {
        _emotions.add(tag);
      }
    });
  }

  void _toggleContext(String tag) {
    setState(() {
      if (!_contexts.remove(tag)) {
        _contexts.add(tag);
      }
    });
  }

  bool get _hasDraft =>
      _emotions.isNotEmpty ||
      _contexts.isNotEmpty ||
      _noteController.text.trim().isNotEmpty;

  void _reset() {
    setState(() {
      _emotions.clear();
      _contexts.clear();
      _noteController.clear();
    });
  }

  void _saveAndClose() {
    Navigator.of(context).pop(
      _JournalDraftResult(
        emotions: _emotions.toList(),
        contexts: _contexts.toList(),
        note: _noteController.text,
      ),
    );
  }

  Widget _buildTagWrap({
    required List<String> options,
    required Set<String> selection,
    required void Function(String tag) onToggle,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((tag) {
        final selected = selection.contains(tag);
        return FilterChip(
          label: Text(tag),
          selected: selected,
          onSelected: (_) => onToggle(tag),
          selectedColor: cs.primary.withValues(alpha: 0.24),
          checkmarkColor: cs.onPrimary,
          backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.24),
          side: BorderSide(
            color: selected
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: 0.5),
          ),
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Entry'),
        actions: [
          TextButton(
            onPressed: _saveAndClose,
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Emotions', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildTagWrap(
            options: _kEmotionTags,
            selection: _emotions,
            onToggle: _toggleEmotion,
          ),
          const SizedBox(height: 24),
          Text('What influenced it?', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildTagWrap(
            options: _kContextTags,
            selection: _contexts,
            onToggle: _toggleContext,
          ),
          const SizedBox(height: 24),
          Text('Notes', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            minLines: 4,
            maxLines: null,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: 'Describe what led to this mood or what you did.',
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.24),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: cs.primary),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: OutlinedButton.icon(
            onPressed: _hasDraft ? _reset : null,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
          ),
        ),
      ),
    );
  }
}

/// ===================== Trends =====================
