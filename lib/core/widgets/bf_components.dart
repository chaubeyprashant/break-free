import 'package:flutter/material.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';

/// Section label — small caps-style hierarchy without shouting.
class BfSectionLabel extends StatelessWidget {
  const BfSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
          ),
    );
  }
}

/// Subtle surface used instead of nested cards.
class BfSurface extends StatelessWidget {
  const BfSurface({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final content = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(BfSpacing.md),
      decoration: BoxDecoration(
        color: dark ? BfColors.inkElevated : BfColors.paperElevated,
        borderRadius: BorderRadius.circular(BfRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BfRadius.md),
        child: content,
      ),
    );
  }
}

class BfDivider extends StatelessWidget {
  const BfDivider({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: indent, endIndent: indent);
  }
}

/// Primary full-width action.
class BfPrimaryButton extends StatelessWidget {
  const BfPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, BfSpacing.minTouch),
        ),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, BfSpacing.minTouch),
      ),
      child: Text(label),
    );
  }
}

class BfSecondaryButton extends StatelessWidget {
  const BfSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, BfSpacing.minTouch),
        ),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, BfSpacing.minTouch),
      ),
      child: Text(label),
    );
  }
}

/// Quiet list row — preferred over icon-in-circle cards.
class BfListRow extends StatelessWidget {
  const BfListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: leading,
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: trailing ??
              (onTap != null
                  ? Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                    )
                  : null),
          onTap: onTap,
        ),
        if (showDivider) const BfDivider(),
      ],
    );
  }
}

/// Large streak / metric number with quiet caption.
class BfMetric extends StatelessWidget {
  const BfMetric({
    super.key,
    required this.value,
    required this.label,
    this.align = TextAlign.left,
  });

  final String value;
  final String label;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          value,
          textAlign: align,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: BfSpacing.xxs),
        Text(
          label.toUpperCase(),
          textAlign: align,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.4,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
              ),
        ),
      ],
    );
  }
}

class BfEmptyState extends StatelessWidget {
  const BfEmptyState({
    super.key,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BfSpacing.xxl, horizontal: BfSpacing.lg),
      child: Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          if (body != null) ...[
            const SizedBox(height: BfSpacing.xs),
            Text(body!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: BfSpacing.md),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Subtle XP toast-style feedback instead of celebratory overlays.
class BfXpChip extends StatelessWidget {
  const BfXpChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BfSpacing.sm, vertical: BfSpacing.xxs),
      decoration: BoxDecoration(
        color: BfColors.accentSoft,
        borderRadius: BorderRadius.circular(BfRadius.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: BfColors.accent),
      ),
    );
  }
}
