import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/providers/danger_window_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';

/// Shows the user's busiest urge period as a plain behavioural observation and
/// lets them opt in to a reminder at its start. [compact] hides the toggle and
/// is used on the dashboard; the full card lives on the history screen.
class DangerWindowCard extends StatelessWidget {
  const DangerWindowCard({super.key, this.compact = false, this.onTap});

  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Consumer<DangerWindowProvider>(
      builder: (context, provider, _) {
        final window = provider.window;

        if (window == null) {
          if (compact) return const SizedBox.shrink();
          return _Shell(
            icon: Icons.schedule_rounded,
            iconColor: BfColors.textTertiaryDark,
            title: 'No danger window yet',
            body: 'Once a few urges are logged, this shows the time of day they cluster in. '
                'It is based only on what you record here.',
          );
        }

        final body = '${window.count} of your ${window.total} logged urges happened between ${window.label}. '
            'That is your busiest period so far, based only on your own entries.';

        return _Shell(
          icon: Icons.nightlight_round,
          iconColor: BfColors.warning,
          title: 'Highest-risk period: ${window.label}',
          body: body,
          onTap: onTap,
          trailing: compact
              ? Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                )
              : null,
          footer: compact
              ? null
              : SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Protection reminder'),
                  subtitle: Text(
                    provider.reminderEnabled
                        ? 'You will get a notification when ${window.label} starts.'
                        : 'Get a notification when this period starts. Off until you turn it on.',
                  ),
                  value: provider.reminderEnabled,
                  activeThumbColor: BfColors.accent,
                  onChanged: (v) => provider.setReminderEnabled(v),
                ),
        );
      },
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    this.trailing,
    this.footer,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final Widget? trailing;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BfSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: BfSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: BfSpacing.xxs),
                    Text(body, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: BfSpacing.xs), trailing!],
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: BfSpacing.md),
            const BfDivider(),
            const SizedBox(height: BfSpacing.xs),
            footer!,
          ],
        ],
      ),
    );
  }
}
