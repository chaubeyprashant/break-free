import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/providers/achievement_provider.dart';
import 'package:break_free/core/providers/activity_provider.dart';
import 'package:break_free/core/providers/check_in_provider.dart';
import 'package:break_free/core/providers/cloud_backup_provider.dart';
import 'package:break_free/core/providers/daily_quest_provider.dart';
import 'package:break_free/core/providers/game_provider.dart';
import 'package:break_free/core/providers/habit_provider.dart';
import 'package:break_free/core/providers/journal_provider.dart';
import 'package:break_free/core/providers/protection_provider.dart';
import 'package:break_free/core/providers/recovery_plan_provider.dart';
import 'package:break_free/core/providers/settings_provider.dart';
import 'package:break_free/core/providers/streak_policy_provider.dart';
import 'package:break_free/core/providers/urge_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/auth/presentation/auth_provider.dart';

/// Manual + automatic cloud backup to Firestore (signed-in accounts).
class CloudBackupScreen extends StatefulWidget {
  const CloudBackupScreen({super.key});

  @override
  State<CloudBackupScreen> createState() => _CloudBackupScreenState();
}

class _CloudBackupScreenState extends State<CloudBackupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final backup = context.read<CloudBackupProvider>();
      backup.onAuthChanged(signedIn: auth.user != null);
    });
  }

  Future<void> _backup() async {
    final backup = context.read<CloudBackupProvider>();
    final ok = await backup.backupNow();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(backup.message ?? (ok ? 'Backup saved.' : 'Backup failed.'))),
    );
    backup.acknowledge();
  }

  Future<void> _restore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from cloud?'),
        content: const Text(
          'This replaces habits, streaks, XP, urges, journal, protection settings, '
          'and related progress on this device with your latest cloud backup. '
          'It cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final backup = context.read<CloudBackupProvider>();
    final ok = await backup.restoreNow(
      habits: context.read<HabitProvider>(),
      game: context.read<GameProvider>(),
      urges: context.read<UrgeProvider>(),
      journal: context.read<JournalProvider>(),
      checkIns: context.read<CheckInProvider>(),
      settings: context.read<SettingsProvider>(),
      protection: context.read<ProtectionProvider>(),
      recoveryPlan: context.read<RecoveryPlanProvider>(),
      streakPolicy: context.read<StreakPolicyProvider>(),
      activities: context.read<ActivityProvider>(),
      achievements: context.read<AchievementProvider>(),
      quests: context.read<DailyQuestProvider>(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(backup.message ?? (ok ? 'Restored.' : 'Restore failed.'))),
    );
    backup.acknowledge();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final backup = context.watch<CloudBackupProvider>();
    final busy = backup.status == CloudBackupStatus.backingUp ||
        backup.status == CloudBackupStatus.restoring ||
        backup.status == CloudBackupStatus.loading;
    final meta = backup.meta;
    final lastLabel = meta == null
        ? 'No cloud backup yet'
        : 'Last backup ${DateFormat('d MMM yyyy · h:mm a').format(meta.updatedAt.toLocal())}';

    return Scaffold(
      appBar: AppBar(title: const Text('Cloud backup')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BfSpacing.screenH,
          BfSpacing.sm,
          BfSpacing.screenH,
          BfSpacing.huge,
        ),
        children: [
          Text(
            'Save progress to your Break Free account so reinstalling the app '
            'does not wipe habits, streaks, XP, urges, journal, or protection settings.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: BfSpacing.md),
          BfSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.user == null ? 'Sign in required' : 'Linked to your account',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: BfSpacing.xxs),
                Text(
                  auth.user == null
                      ? 'Cloud backup uses Firebase Auth. Sign in from Profile first.'
                      : lastLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (meta != null) ...[
                  const SizedBox(height: BfSpacing.xxs),
                  Text(
                    '${meta.keyCount} items stored',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: BfColors.accent),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: BfSpacing.lg),
          const BfSectionLabel('Actions'),
          const SizedBox(height: BfSpacing.sm),
          BfPrimaryButton(
            label: busy && backup.status == CloudBackupStatus.backingUp ? 'Backing up…' : 'Back up now',
            onPressed: auth.user == null || busy ? null : _backup,
          ),
          const SizedBox(height: BfSpacing.sm),
          BfSecondaryButton(
            label: busy && backup.status == CloudBackupStatus.restoring ? 'Restoring…' : 'Restore from cloud',
            onPressed: auth.user == null || busy || !backup.hasCloudBackup ? null : _restore,
          ),
          const SizedBox(height: BfSpacing.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto-backup'),
            subtitle: const Text('Upload quietly when the app goes to the background'),
            value: backup.autoBackupEnabled,
            activeThumbColor: BfColors.accent,
            onChanged: auth.user == null
                ? null
                : (v) => context.read<CloudBackupProvider>().setAutoBackupEnabled(v),
          ),
          const SizedBox(height: BfSpacing.md),
          Text(
            'Backups stay under your user account in Firebase. '
            'Notification bodies and payment details are never included. '
            'Premium status still comes from Google Play, not from this backup.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
