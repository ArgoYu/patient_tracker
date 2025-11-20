import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kRiskIntroSeenKey = 'risk_alert_intro_seen_v2';
const kRiskIntroBannerDismissedKey = 'risk_alert_banner_dismissed_v1';

const _tTitle1 = 'What is Risk Alert?';
const _tBody1 =
    'Risk Alert scans the latest consultation notes to surface potential risk patterns and recommended follow-ups. It is a decision-support tool and not a medical diagnosis.';
const _tTitle2 = 'How it works';
const _tBody2 =
    'It evaluates predefined rules (e.g., symptoms and terms), collects evidence found in your latest note, and assigns weighted points per category.';
const _tTitle3 = 'Scoring';
String _tBody3(int maxScore) =>
    'Scores range 0–$maxScore.\nLow: 0–39 • Medium: 40–69 • High: 70–$maxScore.\nOpen “Scan details” to see which rules matched and why.';
const _tTitle4 = 'Privacy & Limitations';
const _tBody4 =
    'Analysis runs within this app environment and uses your latest consult note (transcript or typed).\nPattern matching may miss context—always review with your clinician. If you have acute symptoms, seek emergency care.';

Future<void> showRiskAlertIntroFlow(
  BuildContext context, {
  int maxScore = 100,
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Risk Alert Intro',
    pageBuilder: (_, __, ___) => _RiskIntroFlow(maxScore: maxScore),
    transitionBuilder: (ctx, anim, _, child) {
      return FadeTransition(opacity: anim, child: child);
    },
  );
}

class _RiskIntroFlow extends StatefulWidget {
  const _RiskIntroFlow({required this.maxScore});

  final int maxScore;

  @override
  State<_RiskIntroFlow> createState() => _RiskIntroFlowState();
}

class _RiskIntroFlowState extends State<_RiskIntroFlow> {
  final _pageController = PageController();
  int _index = 0;
  bool _dontShowAgain = false;

  List<_IntroPage> get _pages => [
        const _IntroPage(
          title: _tTitle1,
          body: _tBody1,
          gradient: [Color(0xFFEEF6FF), Color(0xFFF7FAFF)],
          hero: Icon(
            Icons.health_and_safety,
            size: 80,
            key: ValueKey('hero_health'),
          ),
        ),
        const _IntroPage(
          title: _tTitle2,
          body: _tBody2,
          gradient: [Color(0xFFF4FFF7), Color(0xFFF9FFFB)],
          hero: Icon(
            Icons.rule,
            size: 80,
            key: ValueKey('hero_rule'),
          ),
          bodyChild: _RulePreviewCard(),
        ),
        _IntroPage(
          title: _tTitle3,
          body: _tBody3(widget.maxScore),
          gradient: const [Color(0xFFFFF6F1), Color(0xFFFFFBF8)],
          hero: const Icon(
            Icons.stacked_bar_chart,
            size: 80,
            key: ValueKey('hero_score'),
          ),
          bodyChild: const _ScorePreviewBar(low: 39, med: 69),
        ),
        const _IntroPage(
          title: _tTitle4,
          body: _tBody4,
          gradient: [Color(0xFFF4F4FF), Color(0xFFFAFAFF)],
          hero: Icon(
            Icons.privacy_tip,
            size: 80,
            key: ValueKey('hero_privacy'),
          ),
        ),
      ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(kRiskIntroSeenKey) ?? false;
    if (!mounted) return;
    setState(() {
      _dontShowAgain = seen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Material(
              elevation: 6,
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _GradientHeader(
                    colors: pages[_index].gradient,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: pages[_index].hero,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: IconButton(
                            tooltip: 'Close',
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pages.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (_, i) {
                        final page = pages[i];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Text(
                                  page.title,
                                  key: ValueKey('t_$i'),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Text(
                                  page.body,
                                  key: ValueKey('b_$i'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (page.bodyChild != null) page.bodyChild!,
                              const Spacer(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      children: [
                        _Dots(
                          length: pages.length,
                          index: _index,
                          onTap: (i) => _pageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_index == pages.length - 1)
                          Row(
                            children: [
                              Switch(
                                value: _dontShowAgain,
                                onChanged: (value) async {
                                  setState(() => _dontShowAgain = value);
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool(
                                    kRiskIntroSeenKey,
                                    value,
                                  );
                                },
                              ),
                              const Text('Don’t show again'),
                            ],
                          ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                _index == pages.length - 1
                                    ? 'Remind me later'
                                    : 'Skip',
                              ),
                            ),
                            const Spacer(),
                            AnimatedOpacity(
                              opacity: _index == pages.length - 1 ? 1.0 : 0.9,
                              duration: const Duration(milliseconds: 200),
                              child: FilledButton(
                                onPressed: () async {
                                  if (_index < pages.length - 1) {
                                    _pageController.nextPage(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      curve: Curves.easeOut,
                                    );
                                    return;
                                  }
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool(kRiskIntroSeenKey, true);
                                  if (!mounted) return;
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  _index == pages.length - 1
                                      ? 'Get started'
                                      : 'Next',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroPage {
  const _IntroPage({
    required this.title,
    required this.body,
    required this.gradient,
    required this.hero,
    this.bodyChild,
  });

  final String title;
  final String body;
  final List<Color> gradient;
  final Widget hero;
  final Widget? bodyChild;
}

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({required this.colors, required this.child});

  final List<Color> colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.length,
    required this.index,
    required this.onTap,
  });

  final int length;
  final int index;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: List.generate(length, (i) {
        final active = i == index;
        return GestureDetector(
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black26,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

class _RulePreviewCard extends StatelessWidget {
  const _RulePreviewCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.only(top: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Example rules'),
            SizedBox(height: 8),
            _RuleRow(
              'Cardiovascular',
              'chest pain OR shortness of breath',
              '+40',
              matched: true,
            ),
            _RuleRow(
              'Metabolic',
              'weight gain OR thirst',
              '+25',
              matched: false,
            ),
            _RuleRow(
              'Mental Health',
              'anxiety OR insomnia',
              '+10',
              matched: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow(this.category, this.rule, this.weight,
      {required this.matched});

  final String category;
  final String rule;
  final String weight;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          matched ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: matched ? Colors.green : Colors.black38,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text('$category • $rule')),
        Text(
          weight,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ScorePreviewBar extends StatelessWidget {
  const _ScorePreviewBar({required this.low, required this.med});

  final int low;
  final int med;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Score scale'),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (_, constraints) {
                final width = constraints.maxWidth;
                final total = med + 1 + 30;
                final lowEnd = width * (low / total);
                final medEnd = width * (med / total);
                return Row(
                  children: [
                    Container(
                      width: lowEnd,
                      height: 8,
                      color: Colors.green.withOpacity(.25),
                    ),
                    Container(
                      width: medEnd - lowEnd,
                      height: 8,
                      color: Colors.orange.withOpacity(.25),
                    ),
                    Expanded(
                      child: Container(
                        height: 8,
                        color: Colors.red.withOpacity(.25),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 6),
            const Text(
              'Low  •  Medium  •  High',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
