import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/providers/check_in_provider.dart';
import 'package:break_free/core/providers/danger_window_provider.dart';
import 'package:break_free/core/providers/entitlement_provider.dart';
import 'package:break_free/core/providers/game_provider.dart';
import 'package:break_free/core/providers/settings_provider.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/async_state_view.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/auth/presentation/auth_provider.dart';
import 'package:break_free/features/settings/presentation/privacy_settings_screen.dart';
import 'package:break_free/features/subscription/domain/premium_feature.dart';
import 'package:break_free/features/subscription/presentation/premium_lock_sheet.dart';

/// Keep in sync with `version:` in pubspec.yaml.
const String kAppVersionLabel = '1.1.5';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _pickTheme(BuildContext context, SettingsProvider settings) async {
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('System'),
              trailing: settings.themeMode == ThemeMode.system ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, ThemeMode.system),
            ),
            ListTile(
              title: const Text('Light'),
              trailing: settings.themeMode == ThemeMode.light ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, ThemeMode.light),
            ),
            ListTile(
              title: const Text('Dark'),
              trailing: settings.themeMode == ThemeMode.dark ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, ThemeMode.dark),
            ),
          ],
        ),
      ),
    );
    if (selected != null) await settings.setThemeMode(selected);
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System',
      };

  Future<void> _confirmResetLocal(BuildContext context, {required bool deleteAllLocal}) async {
    final title = deleteAllLocal ? 'Delete local data?' : 'Reset progress?';
    final body = deleteAllLocal
        ? 'This clears habits, streaks, XP, urges, journal, quests, and settings stored on this device. Your Firebase account and companion link in the cloud are not deleted.'
        : 'This resets local habits, streaks, XP, urges, journal, and quests on this device. Your Firebase account and companion link are not deleted.';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(deleteAllLocal ? 'Delete local data' : 'Reset progress'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final settings = context.read<SettingsProvider>();
    final checkIns = context.read<CheckInProvider>();
    await settings.clearLocalProgress();
    await checkIns.clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleteAllLocal
              ? 'Local data cleared. Restart the app to reload a clean state.'
              : 'Progress reset. Restart the app to reload a clean state.',
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again. Local data on this device is kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<AuthProvider>().signOut();
    if (context.mounted) context.go('/auth');
  }

  void _openPremiumOr(BuildContext context, PremiumFeature feature, VoidCallback open) {
    if (!context.read<EntitlementProvider>().isPremium) {
      showPremiumLockSheet(context, feature: feature);
      return;
    }
    open();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final settings = context.watch<SettingsProvider>();
    final entitlement = context.watch<EntitlementProvider>();
    final user = auth.user;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : (user?.email ?? 'Break Free user');
    final email = user?.email ?? 'Signed in';

    if (!settings.isLoaded) {
      return const Scaffold(body: AsyncLoadingView());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BfSpacing.screenH,
          BfSpacing.xs,
          BfSpacing.screenH,
          BfSpacing.huge,
        ),
        children: [
          const BfSectionLabel('Account'),
          const SizedBox(height: BfSpacing.sm),
          Text(displayName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: BfSpacing.xxs),
          Text(
            '$email  ·  Level ${game.progress.level}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: BfSpacing.md),
          BfListRow(
            title: 'Break Free Premium',
            subtitle: entitlement.isPremium ? 'Active' : 'More control and deeper insights',
            onTap: () => context.push('/subscription'),
          ),
          BfListRow(
            title: 'Cloud backup',
            subtitle: 'Save progress so reinstall does not wipe it',
            onTap: () => context.push('/cloud-backup'),
            showDivider: false,
          ),

          const SizedBox(height: BfSpacing.sectionGap),
          const BfSectionLabel('Recovery'),
          const SizedBox(height: BfSpacing.xs),
          BfListRow(
            title: 'Habits',
            subtitle: 'What you\'re working on',
            onTap: () => context.push('/habit-selection'),
          ),
          BfListRow(
            title: 'Recovery plan',
            subtitle: 'Steps when you need help',
            onTap: () => context.push('/help/edit'),
          ),
          BfListRow(
            title: 'Accountability companion',
            subtitle: 'Link someone you trust',
            onTap: () => _openPremiumOr(
              context,
              PremiumFeature.companionSync,
              () => context.push('/companion'),
            ),
            showDivider: false,
          ),

          const SizedBox(height: BfSpacing.sectionGap),
          const BfSectionLabel('Protection'),
          const SizedBox(height: BfSpacing.xs),
          BfListRow(
            title: 'Protected apps',
            subtitle: 'Choose apps to interrupt',
            onTap: () => context.push('/app-blocker'),
          ),
          BfListRow(
            title: 'Website protection',
            subtitle: 'Supported browsers, domains, schedules',
            onTap: () => context.go('/protection'),
          ),
          BfListRow(
            title: 'Notification scanner',
            subtitle: 'Keyword interventions',
            onTap: () => _openPremiumOr(
              context,
              PremiumFeature.transactionScanner,
              () => context.push('/scanner-settings'),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Protection reminders'),
            subtitle: const Text('Danger-window alerts on this device'),
            value: settings.protectionRemindersEnabled,
            onChanged: (value) async {
              await settings.setProtectionRemindersEnabled(value);
              if (context.mounted) {
                await context.read<DangerWindowProvider>().setReminderEnabled(value);
              }
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Daily reminders'),
            subtitle: const Text('Encourage clean-day check-ins'),
            value: settings.dailyRemindersEnabled,
            onChanged: settings.setDailyRemindersEnabled,
          ),

          const SizedBox(height: BfSpacing.sectionGap),
          const BfSectionLabel('Preferences'),
          const SizedBox(height: BfSpacing.xs),
          BfListRow(
            title: 'Theme',
            subtitle: _themeLabel(settings.themeMode),
            onTap: () => _pickTheme(context, settings),
            showDivider: false,
          ),

          const SizedBox(height: BfSpacing.sectionGap),
          const BfSectionLabel('Privacy'),
          const SizedBox(height: BfSpacing.xs),
          BfListRow(
            title: 'Privacy & data',
            subtitle: 'What stays on device vs Firebase',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
              );
            },
          ),
          BfListRow(
            title: 'Reset progress',
            subtitle: 'Clear local streaks and XP — not your account',
            onTap: () => _confirmResetLocal(context, deleteAllLocal: false),
          ),
          BfListRow(
            title: 'Delete local data',
            subtitle: 'Includes local preferences',
            onTap: () => _confirmResetLocal(context, deleteAllLocal: true),
            showDivider: false,
          ),

          const SizedBox(height: BfSpacing.sectionGap),
          const BfSectionLabel('About'),
          const SizedBox(height: BfSpacing.xs),
          BfListRow(
            title: 'Version',
            subtitle: 'Break Free $kAppVersionLabel',
            showDivider: false,
          ),
          const SizedBox(height: BfSpacing.lg),
          TextButton(
            onPressed: () => _confirmSignOut(context),
            child: Text(
              'Sign out',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
