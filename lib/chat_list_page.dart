import 'package:flutter/material.dart';
import 'package:patient_tracker/chat_page.dart';
import 'package:patient_tracker/core/theme/theme_tokens.dart';
import 'package:patient_tracker/direct_chat_page.dart';
import 'package:patient_tracker/shared/widgets/layout_cards.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppThemeTokens.pagePadding,
          AppThemeTokens.pagePadding,
          AppThemeTokens.pagePadding,
          AppThemeTokens.pagePadding,
        ),
        children: [
          _buildSearchBar(context),
          SizedBox(height: AppThemeTokens.gap),
          SectionContainer(
            header: _sectionHeader(
              context,
              icon: Icons.person_outline,
              title: 'Personal chats',
              count: personalChatContacts.length,
            ),
            child: Column(
              children: [
                for (var index = 0;
                    index < personalChatContacts.length;
                    index++) ...[
                  _buildPersonalRow(context, personalChatContacts[index]),
                  if (index < personalChatContacts.length - 1)
                    Divider(
                      color: theme.colorScheme.onSurface.withOpacity(0.08),
                      height: 1,
                    ),
                ],
              ],
            ),
          ),
          SizedBox(height: AppThemeTokens.gap),
          SectionContainer(
            header: _sectionHeader(
              context,
              icon: Icons.group_outlined,
              title: 'Group chats',
              count: _groupChats.length,
            ),
            child: Column(
              children: [
                for (var index = 0; index < _groupChats.length; index++) ...[
                  _buildGroupRow(context, _groupChats[index]),
                  if (index < _groupChats.length - 1)
                    Divider(
                      color: theme.colorScheme.onSurface.withOpacity(0.08),
                      height: 1,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        hintText: 'Search conversations',
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: theme.colorScheme.surface.withOpacity(0.4),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(
            color: theme.colorScheme.onSurface.withOpacity(0.12),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int count,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppThemeTokens.smallRadius),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Text(
          '$count',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalRow(
    BuildContext context,
    PersonalChatContact contact,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppThemeTokens.smallRadius),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DirectChatPage(contact: contact),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppThemeTokens.gap * 0.65,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: contact.color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(AppThemeTokens.smallRadius),
              ),
              child: Icon(contact.icon, color: contact.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupRow(BuildContext context, _GroupChat chat) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppThemeTokens.smallRadius),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MessagesPage(),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppThemeTokens.gap * 0.65,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.18),
                borderRadius: BorderRadius.circular(AppThemeTokens.smallRadius),
              ),
              child: Icon(
                Icons.group,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

const List<_GroupChat> _groupChats = [
  _GroupChat(
    title: 'General Support Group',
    subtitle: 'Alice: That sounds like a good plan!',
  ),
  _GroupChat(
    title: 'Meditation Group',
    subtitle: 'Bob: I found a great new meditation app.',
  ),
];

class _GroupChat {
  const _GroupChat({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}
