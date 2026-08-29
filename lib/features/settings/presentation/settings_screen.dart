import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:break_free/core/data/reminder_settings_repository.dart';
import 'package:break_free/core/notifications/notification_service.dart';
import 'package:break_free/core/providers/habit_provider.dart';
import 'package:break_free/core/providers/game_provider.dart';
import 'package:break_free/features/dashboard/presentation/streak_provider.dart';
import 'package:break_free/core/providers/streak_policy_provider.dart';
import 'package:break_free/core/providers/onboarding_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  ReminderSettings _reminder = ReminderSettings.defaults;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    final loaded = await context.read<ReminderSettingsRepository>().load();
    if (!mounted) return;
    setState(() => _reminder = loaded);
  }

  Future<void> _setReminderEnabled(bool enabled) async {
    if (_busy) return;
    setState(() => _busy = true);

    final repository = context.read<ReminderSettingsRepository>();
    final notifications = context.read<NotificationService>();

    try {
      if (enabled) {
        final granted = await notifications.requestPermission();
        if (!granted) {
          // Leave the switch off rather than promising a reminder the system
          // will never deliver.
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Notifications are turned off for Break Free in your system '
                'settings.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        await notifications.scheduleDailyReminder(
          hour: _reminder.hour,
          minute: _reminder.minute,
        );
      } else {
        await notifications.cancelDailyReminder();
      }

      final updated = _reminder.copyWith(enabled: enabled);
      await repository.save(updated);
      if (!mounted) return;
      setState(() => _reminder = updated);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminder.hour, minute: _reminder.minute),
    );
    if (picked == null || !mounted) return;

    final repository = context.read<ReminderSettingsRepository>();
    final notifications = context.read<NotificationService>();

    final updated = _reminder.copyWith(
      hour: picked.hour,
      minute: picked.minute,
    );
    await repository.save(updated);
    if (updated.enabled) {
      await notifications.scheduleDailyReminder(
        hour: updated.hour,
        minute: updated.minute,
      );
    }
    if (!mounted) return;
    setState(() => _reminder = updated);
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip, color: Color(0xFF2A9D8F)),
            SizedBox(width: 10),
            Text('Privacy & Data'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Stored on your device',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your habits, journal entries, progress and settings are stored '
                'locally on your device.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Anonymous sign-in',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'The app signs in anonymously so it can keep your progress '
                'associated with this install. We never ask for your name, '
                'email or phone number.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Data Deletion & Rights',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'You can delete all your data at any time by using the "Reset '
                'All Progress" button in Settings, clearing the app storage in '
                'your device settings, or uninstalling the App.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Full Privacy Policy URL',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const SelectableText(
                'https://chaubeyprashant.github.io/break-free-privacy-policy/privacy.html',
                style: TextStyle(
                  color: Color(0xFF2A9D8F),
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Expanded(child: Text('Reset All Progress?')),
          ],
        ),
        content: const Text(
          'This will permanently delete all your habits, level progress, coins, '
          'streaks, and journal entries. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // Close the confirmation dialog
              Navigator.pop(dialogContext);

              final notifications = context.read<NotificationService>();

              // Clear local storage
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              // The reminder preference went with it, so stop the reminder too.
              await notifications.cancelDailyReminder();

              if (!context.mounted) return;

              // Reload/refresh all providers to reflect the empty state
              await Future.wait([
                context.read<HabitProvider>().refresh(),
                context.read<GameProvider>().refresh(),
                context.read<StreakProvider>().reload(),
                context.read<StreakPolicyProvider>().refresh(),
              ]);

              // The onboarding flag went with the cleared prefs, so send the
              // user back through habit selection.
              ref.read(onboardingProvider.notifier).reset();

              if (!context.mounted) return;

              // Go back to the onboarding screen
              context.go('/onboarding');
            },
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<GameProvider>().progress;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Break Free Hero'),
            accountEmail: Text(
              'Level ${progress.level} · ${progress.levelTitle}',
            ),
            currentAccountPicture: const CircleAvatar(child: Text('🦸')),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Daily check-in reminder'),
            subtitle: Text(
              _reminder.enabled
                  ? 'Every day at ${_reminder.label}'
                  : 'Off',
            ),
            value: _reminder.enabled,
            onChanged: _busy ? null : _setReminderEnabled,
          ),
          if (_reminder.enabled)
            ListTile(
              leading: const SizedBox(width: 24),
              title: const Text('Reminder time'),
              subtitle: Text(_reminder.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickReminderTime,
            ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy & Data'),
            onTap: () => _showPrivacyDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Reset All Progress'),
            textColor: Colors.red,
            onTap: () => _showResetConfirmDialog(context, ref),
          ),
        ],
      ),
    );
  }
}
