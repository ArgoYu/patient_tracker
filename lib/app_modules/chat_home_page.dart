part of 'package:patient_tracker/app_modules.dart';

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {
    'personal_care_ai': GlobalKey(),
    'doctor': GlobalKey(),
    'nurse': GlobalKey(),
    'peer': GlobalKey(),
    'group': GlobalKey(),
  };
  String? _focusThreadId;
  String? _focusThreadTitle;
  Color _flashColor = const Color(0xFFFFF4CC);
  String? _highlighted;
  bool _handledInitialArgs = false;
  Timer? _highlightTimer;

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handledInitialArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map) return;

    final focusId =
        (args['focusThreadId'] as String?) ?? (args['targetSection'] as String?);
    final focusTitle = args['focusThreadTitle'] as String?;
    final flash = args['flashColor'] as String?;

    if (focusId != null || focusTitle != null) {
      _focusThreadId = focusId;
      _focusThreadTitle = focusTitle;
      _flashColor = _parseHex(flash ?? '#FFF4CC');
      _handledInitialArgs = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryFocusTarget());
      return;
    }

    final legacyTarget = args['targetSection'] as String?;
    if (legacyTarget != null && _sectionKeys.containsKey(legacyTarget)) {
      _handledInitialArgs = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSection(legacyTarget);
        _activateHighlight(legacyTarget);
      });
    }
  }

  void _scrollToSection(String section) {
    final context = _sectionKeys[section]?.currentContext;
    if (context == null) return;
    final box = context.findRenderObject() as RenderBox?;
    final offset = box?.localToGlobal(Offset.zero);
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;
    if (offset == null) return;
    final targetOffset = _scrollController.offset +
        offset.dy -
        topPadding -
        AiDesignTokens.spacing16;
    _scrollController.animateTo(
      targetOffset.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _tryFocusTarget() {
    final targetId = _resolveThreadId();
    if (targetId == null) return;
    final key = ChatItemKeyRegistry.I.keyOf(targetId);
    final ctx = key?.currentContext;
    if (ctx == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryFocusTarget());
      return;
    }
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      alignment: 0.1,
    );
    _activateHighlight(targetId);
  }

  String? _resolveThreadId() {
    if (_focusThreadId != null &&
        (_sectionKeys.containsKey(_focusThreadId!) ||
            ChatItemKeyRegistry.I.keyOf(_focusThreadId!) != null)) {
      return _focusThreadId;
    }
    final title = _focusThreadTitle;
    if (title == null) return null;
    for (final section in _sections) {
      if (section.title == title || section.subtitle == title) {
        return section.id;
      }
    }
    return null;
  }

  Color _parseHex(String hex) {
    var value = hex.trim();
    if (value.startsWith('#')) {
      value = value.substring(1);
    }
    if (value.length == 6) {
      value = 'FF$value';
    }
    int parsed;
    try {
      parsed = int.parse(value, radix: 16);
    } catch (_) {
      parsed = 0xFFFFF4CC;
    }
    return Color(parsed);
  }

  void _activateHighlight(String section) {
    setState(() => _highlighted = section);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _highlighted = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Home', style: AiTextStyles.title16(context)),
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          AiDesignTokens.spacing16,
          AiDesignTokens.spacing16,
          AiDesignTokens.spacing16,
          AiDesignTokens.spacing24,
        ),
        children: [
          for (final section in _sections)
            Padding(
              key: _sectionKeys[section.id],
              padding: const EdgeInsets.only(bottom: AiDesignTokens.spacing16),
              child: FocusHighlight(
                key: ChatItemKeyRegistry.I.registerKey(section.id),
                highlight: _highlighted == section.id,
                color: _flashColor,
                child: _ChatSectionCard(
                  section: section,
                  highlighted: _highlighted == section.id,
                  onTap: () => _openChat(section),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openChat(_ChatSection section) {
    final theme = Theme.of(context);
    final contact = PersonalChatContact(
      type: section.contactType,
      name: section.contactName,
      subtitle: section.description,
      icon: section.icon,
      color: section.contactColor ?? theme.colorScheme.primary,
      contactId: section.id,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DirectChatPage(contact: contact),
      ),
    );
  }
}

class _ChatSectionCard extends StatelessWidget {
  const _ChatSectionCard({
    required this.section,
    required this.highlighted,
    required this.onTap,
  });

  final _ChatSection section;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = highlighted
        ? theme.colorScheme.primary.withValues(alpha: 0.6)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.4);
    return InkWell(
      borderRadius: AiDesignTokens.cardRadius,
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AiDesignTokens.cardRadius,
          border: Border.all(
            color: borderColor,
            width: highlighted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow
                  .withValues(alpha: AiDesignTokens.shadowOpacity),
              blurRadius: AiDesignTokens.shadowBlur,
              offset: const Offset(0, AiDesignTokens.shadowOffsetY),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AiDesignTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(section.icon,
                    size: AiDesignTokens.iconSize,
                    color: theme.colorScheme.primary),
                const SizedBox(width: AiDesignTokens.spacing12),
                Expanded(
                  child: Text(
                    section.title,
                    style: AiTextStyles.title16(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AiDesignTokens.spacing12),
            Text(
              section.subtitle,
              style: AiTextStyles.body13(context),
            ),
            const SizedBox(height: AiDesignTokens.spacing12),
            Text(
              section.description,
              style: AiTextStyles.body13(context).copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatSection {
  const _ChatSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    this.contactType = PersonalChatType.custom,
    String? contactName,
    this.contactColor,
  }) : contactName = contactName ?? subtitle;

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final PersonalChatType contactType;
  final String contactName;
  final Color? contactColor;
}

const List<_ChatSection> _sections = [
  _ChatSection(
    id: 'personal_care_ai',
    title: 'My Personal Care AI',
    subtitle: 'Ask your AI coach for next steps anytime.',
    description:
        'Plan follow-ups, get medication reminders, and share quick updates.',
    icon: Icons.support_agent_outlined,
    contactType: PersonalChatType.aiCoach,
    contactName: 'My Personal Care AI',
    contactColor: Color(0xFF2563EB),
  ),
  _ChatSection(
    id: 'doctor',
    title: 'Care Team · Doctor',
    subtitle: 'Dr. Chen',
    description:
        'Medical questions, treatment decisions, and prescription updates.',
    icon: Icons.medical_information_outlined,
    contactType: PersonalChatType.doctor,
    contactColor: Color(0xFF0EA5E9),
  ),
  _ChatSection(
    id: 'nurse',
    title: 'Care Team · Nurse',
    subtitle: 'Nurse Lee',
    description: 'Vitals check-ins, medication timing, and follow-up care.',
    icon: Icons.volunteer_activism_outlined,
  ),
  _ChatSection(
    id: 'peer',
    title: 'Peer Mentor',
    subtitle: 'Coach Riley',
    description: 'Accountability buddy for daily goals and encouragement.',
    icon: Icons.groups_2_outlined,
  ),
  _ChatSection(
    id: 'group',
    title: 'Support Group',
    subtitle: 'Recovery Circle',
    description: 'Share wins, challenges, and keep each other motivated.',
    icon: Icons.forum_outlined,
  ),
];
