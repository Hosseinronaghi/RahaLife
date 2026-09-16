import 'package:flutter/material.dart';

import 'raha_tokens.dart';

class RahaSurface extends StatelessWidget {
  const RahaSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(RahaSpacing.md),
    this.onTap,
    this.accent,
    this.radius = RahaRadius.card,
    this.showAccentGlow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accent;
  final double radius;
  final bool showAccentGlow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = accent ?? scheme.primary;
    final dark = theme.brightness == Brightness.dark;
    final border = scheme.outlineVariant.withValues(alpha: dark ? 0.58 : 0.72);

    final content = Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: dark ? 0.14 : 0.055),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (showAccentGlow)
            PositionedDirectional(
              top: -56,
              end: -36,
              child: IgnorePointer(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        tint.withValues(alpha: dark ? 0.19 : 0.12),
                        tint.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class RahaHeroPanel extends StatelessWidget {
  const RahaHeroPanel({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.accent,
    this.child,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final Color? accent;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = accent ?? scheme.primary;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            Color.alphaBlend(
              tint.withValues(alpha: dark ? 0.16 : 0.10),
              scheme.surfaceContainerLow,
            ),
            scheme.surfaceContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(RahaRadius.hero),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.55 : 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: dark ? 0.08 : 0.07),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          PositionedDirectional(
            top: -46,
            end: -30,
            child: _Orb(size: 150, color: tint.withValues(alpha: 0.11)),
          ),
          PositionedDirectional(
            bottom: -52,
            end: 72,
            child: _Orb(
              size: 112,
              color: scheme.tertiary.withValues(alpha: 0.07),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(RahaSpacing.xl),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: dark ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: tint, size: 27),
                  ),
                  const SizedBox(width: RahaSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: RahaSpacing.xs),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                      if (child != null) ...[
                        const SizedBox(height: RahaSpacing.md),
                        child!,
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: RahaSpacing.sm),
                  trailing!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RahaMetricTile extends StatelessWidget {
  const RahaMetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = accent ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RahaSpacing.sm,
        vertical: RahaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(width: RahaSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleSmall),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    ),
  );
}
