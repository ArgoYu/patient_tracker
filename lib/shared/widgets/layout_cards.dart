import 'package:flutter/material.dart';

import '../../core/theme/color_scheme_extensions.dart';
import '../../core/theme/theme_tokens.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.status,
    this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String title;
  final String status;
  final VoidCallback? onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final baseSurface = scheme.surfaceContainerHigh;
    final cardColor =
        isPrimary ? scheme.heroCardColor(baseSurface) : baseSurface;
    final iconColor = scheme.primary;
    final borderColor = scheme.cardBorderColor.withValues(alpha: 0.45);
    final horizontalPadding =
        AppThemeTokens.cardPadding + (isPrimary ? 4 : 0);
    final verticalPadding = AppThemeTokens.cardPadding - 6 + (isPrimary ? 2 : 0);

    return Material(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppThemeTokens.cardRadius),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppThemeTokens.cardRadius),
        onTap: onTap,
        splashFactory: InkRipple.splashFactory,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppThemeTokens.cardRadius),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.iconContainerFillColor,
                  borderRadius:
                      BorderRadius.circular(AppThemeTokens.smallRadius),
                  border: Border.all(
                    color: scheme.cardBorderColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: isPrimary ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      height: 1.12,
                      color: scheme.onSurface,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.18,
                    ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_outward,
                  size: 16,
                  color: scheme.tertiaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionContainer extends StatelessWidget {
  const SectionContainer({
    super.key,
    this.header,
    required this.child,
    this.padding,
  });

  final Widget? header;
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppThemeTokens.cardRadius),
        border: Border.all(
          color: scheme.cardBorderColor.withValues(alpha: 0.35),
        ),
      ),
      padding: padding ?? const EdgeInsets.all(AppThemeTokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            header!,
            SizedBox(height: AppThemeTokens.gap),
          ],
          child,
        ],
      ),
    );
  }
}

class PrimaryPanelCard extends StatelessWidget {
  const PrimaryPanelCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shadowColor = scheme.shadow.withValues(
      alpha: scheme.brightness == Brightness.dark ? 0.45 : 0.22,
    );
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppThemeTokens.cardPadding),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppThemeTokens.cardRadius),
        border: Border.all(
          color: borderColor ??
              scheme.cardBorderColor.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
