// ignore_for_file: prefer_const_declarations

import 'package:flutter/material.dart';

import '../voice_chat/voice_chat_page.dart';
import 'mock_ai_service.dart';
import 'widgets/ai_feature_card.dart';

/// A simple hub page exposing primary and advanced AI tools.
///
/// Sample router integration:
/// ```
/// routes: {
///   MyAiPage.routeName: (context) => const MyAiPage(),
/// }
/// ```
class MyAiPage extends StatefulWidget {
  const MyAiPage({super.key, this.service = const MockAiService()});

  static const String routeName = '/my_ai';

  final MockAiService service;

  @override
  State<MyAiPage> createState() => _MyAiPageState();
}

class _MyAiPageState extends State<MyAiPage> {
  static const double _pagePadding = 16;
  static const double _sectionSpacing = 16;
  static const double _sectionTitleBottomSpacing = 8;
  static const double _cardSpacing = 16;
  static const double _singleColumnBreakpoint = 480;
  static const double _singleColumnAspectRatio = 3.0;
  static const double _twoColumnAspectRatio = 2.6;

  late final Future<_MyAiHubData> _hubData = _loadHubData();

  Future<_MyAiHubData> _loadHubData() async {
    final results = await Future.wait([
      widget.service.fetchHubSummaries(),
      widget.service.fetchAdvancedHighlights(),
    ]);
    return _MyAiHubData(
      summaries: results[0] as Map<String, String>,
      advancedHighlights: results[1] as List<String>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My AI')),
      body: FutureBuilder<_MyAiHubData>(
        future: _hubData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load AI features: ${snapshot.error}'),
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No AI features available.'));
          }
          final summaries = data.summaries;
          return LayoutBuilder(
            builder: (context, constraints) {
              final isSingleColumn =
                  constraints.maxWidth < _singleColumnBreakpoint;
              final coreCards = _buildCoreCards(
                context,
                summaries,
                isSingleColumn,
              );
              final advancedCards = _buildAdvancedCards(context, data);

              return ListView(
                padding: const EdgeInsets.all(_pagePadding),
                children: [
                  AiFeatureCard(
                    icon: Icons.groups_2_outlined,
                    title: 'AI Co-Consult',
                    subtitle: summaries['coConsult'] ??
                        'Collaborate with AI specialists on complex cases.',
                    ctaLabel: 'Open Co-Consult',
                    ctaIcon: Icons.arrow_outward,
                    onTap: () {},
                  ),
                  const SizedBox(height: _sectionSpacing),
                  Text(
                    'Core Tools',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: _sectionTitleBottomSpacing),
                  coreCards,
                  const SizedBox(height: _sectionSpacing),
                  Text(
                    'Advanced Preview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: _sectionTitleBottomSpacing),
                  advancedCards,
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCoreCards(
    BuildContext context,
    Map<String, String> summaries,
    bool isSingleColumn,
  ) {
    final features = [
      (
        icon: Icons.groups_2_outlined,
        title: 'Co-Consult',
        subtitle: summaries['coConsult'] ??
            'Coordinate with AI specialists on complex cases.',
        cta: 'Continue Co-Consult',
      ),
      (
        icon: Icons.description_outlined,
        title: 'Report Generator',
        subtitle: summaries['reportGenerator'] ??
            'Generate on-demand summaries and patient reports.',
        cta: 'Create Report',
      ),
      (
        icon: Icons.question_answer_outlined,
        title: 'Ask-AI-Doctor',
        subtitle: summaries['askAiDoctor'] ??
            'Get instant answers to medical questions.',
        cta: 'Ask Now',
      ),
      (
        icon: Icons.timeline_outlined,
        title: 'Timeline Planner',
        subtitle: summaries['timelinePlanner'] ??
            'Plan treatment milestones with AI suggestions.',
        cta: 'View Timeline',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSingleColumn ? 1 : 2,
        mainAxisSpacing: _cardSpacing,
        crossAxisSpacing: _cardSpacing,
        childAspectRatio:
            isSingleColumn ? _singleColumnAspectRatio : _twoColumnAspectRatio,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return AiFeatureCard(
          icon: feature.icon,
          title: feature.title,
          subtitle: feature.subtitle,
          ctaLabel: feature.cta,
          onTap: () {},
        );
      },
    );
  }

  Widget _buildAdvancedCards(BuildContext context, _MyAiHubData data) {
    final advanced = data.advancedHighlights;
    final descriptors = const [
      (
        title: 'Voice Chat AI',
        icon: Icons.record_voice_over_outlined,
        cta: 'Start Voice Session',
      ),
      (
        title: 'Multi-language',
        icon: Icons.translate_outlined,
        cta: 'Browse Languages',
      ),
      (
        title: 'Risk Alert',
        icon: Icons.warning_amber_outlined,
        cta: 'Review Alerts',
      ),
    ];

    return Column(
      children: List.generate(descriptors.length, (index) {
        final descriptor = descriptors[index];
        final blurb = index < advanced.length
            ? advanced[index]
            : 'Preview upcoming AI capabilities.';
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == descriptors.length - 1 ? 0 : _cardSpacing,
          ),
          child: AiFeatureCard(
            icon: descriptor.icon,
            title: descriptor.title,
            subtitle: blurb,
            ctaLabel: descriptor.cta,
            onTap: () => _handleAdvancedTap(context, descriptor.title),
          ),
        );
      }),
    );
  }

  void _handleAdvancedTap(BuildContext context, String title) {
    switch (title) {
      case 'Voice Chat AI':
        Navigator.of(context).pushNamed(VoiceChatPage.routeName);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title is coming soon.')),
        );
    }
  }
}

class _MyAiHubData {
  const _MyAiHubData({
    required this.summaries,
    required this.advancedHighlights,
  });

  final Map<String, String> summaries;
  final List<String> advancedHighlights;
}
