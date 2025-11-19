// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

const double _cardRadius = 16;
const double _cardPadding = 16;
const double _cardElevation = 1;
const double _iconContainerSize = 44;
const double _iconSize = 22;
const double _iconContainerRadius = 12;
const double _titleBottomSpacing = 6;
const double _iconBottomSpacing = 12;
const double _ctaTopSpacing = 12;

/// Reusable card representation for AI hub features.
class AiFeatureCard extends StatelessWidget {
  const AiFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.ctaLabel,
    this.ctaIcon = Icons.chevron_right,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? ctaLabel;
  final IconData ctaIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final titleStyle =
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    final subtitleStyle =
        theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]);

    return Material(
      elevation: _cardElevation,
      borderRadius: BorderRadius.circular(_cardRadius),
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(_cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: _iconContainerSize,
                width: _iconContainerSize,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(_iconContainerRadius),
                ),
                child: Icon(icon, size: _iconSize, color: primary),
              ),
              const SizedBox(height: _iconBottomSpacing),
              Text(title,
                  style: titleStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: _titleBottomSpacing),
              Text(
                subtitle,
                style: subtitleStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (ctaLabel != null) ...[
                const SizedBox(height: _ctaTopSpacing),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onTap,
                    icon: Icon(ctaIcon, size: 18),
                    label: Text(ctaLabel!),
                    style: TextButton.styleFrom(
                      foregroundColor: primary,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(0, 0),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
