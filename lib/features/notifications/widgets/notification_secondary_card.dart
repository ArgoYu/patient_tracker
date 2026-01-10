// lib/features/notifications/widgets/notification_secondary_card.dart
import 'package:flutter/material.dart';

import '../../../core/theme/color_scheme_extensions.dart';
import '../../../core/theme/theme_tokens.dart';

class NotificationSecondaryCard extends StatelessWidget {
  const NotificationSecondaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.supportingText,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? supportingText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cardColor = scheme.heroCardColor(scheme.surfaceContainerHigh);
    return Card(
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppThemeTokens.cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.secondary.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppThemeTokens.smallRadius),
                ),
                child: Icon(icon, color: scheme.secondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.secondaryTextColor,
                      ),
                    ),
                    if (supportingText != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        supportingText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.tertiaryTextColor,
                        ),
                      ),
                    ],
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
