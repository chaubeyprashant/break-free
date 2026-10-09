import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/providers/settings_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/async_state_view.dart';
import 'package:break_free/core/widgets/bf_components.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & data')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          if (!settings.isLoaded) {
            return const AsyncLoadingView();
          }
          if (settings.error != null) {
            return AsyncErrorView(message: settings.error!, onRetry: settings.reload);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              BfSpacing.screenH,
              BfSpacing.sm,
              BfSpacing.screenH,
              BfSpacing.huge,
            ),
            children: [
              const BfSectionLabel('What Break Free stores'),
              const SizedBox(height: BfSpacing.sm),
              const _InfoBlock(
                title: 'On this device (local)',
                body:
                    'Habits, streaks, XP, urges, journal entries, recovery plan, daily quests, achievements, check-ins, and blocker preferences stay in local storage on your phone by default.',
              ),
              const SizedBox(height: BfSpacing.sm),
              const _InfoBlock(
                title: 'Cloud backup (optional)',
                body:
                    'When you are signed in, Profile → Cloud backup can upload those local progress keys to your Firebase user account (`users/{uid}/backup/snapshot`) so reinstalling the app does not wipe them. Auto-backup can upload quietly when the app backgrounds. Notification bodies and payment details are never included. Premium status still comes from Google Play.',
              ),
              const SizedBox(height: BfSpacing.sm),
              const _InfoBlock(
                title: 'Firebase Authentication',
                body:
                    'Google Sign-In creates an account so you can stay signed in. We store your auth identity with Firebase Auth.',
              ),
              const SizedBox(height: BfSpacing.sm),
              const _InfoBlock(
                title: 'Companion Sync (optional)',
                body:
                    'If you link a companion, Firestore stores a short code, companion link, and FCM device token. When you log a slip (or a blocked-app / adult-site event while linked), a relapse event can be mirrored to Firestore so your companion can be notified. Location is included only when you allow it below and the system grants permission.',
              ),
              const SizedBox(height: BfSpacing.sm),
              const _InfoBlock(
                title: 'Push notifications (FCM)',
                body:
                    'A device token is saved on your user document so companions can receive push alerts. Local protection reminders use on-device notifications and do not leave your phone.',
              ),
              const SizedBox(height: BfSpacing.sm),
              const _InfoBlock(
                title: 'Premium subscriptions',
                body:
                    'Purchases are processed by Google Play. Break Free does not store payment card details. A short offline cache may remember a recently verified Premium status until the store can be reached again; it cannot permanently unlock Premium by itself.',
              ),
              const SizedBox(height: BfSpacing.sm),
              const _InfoBlock(
                title: 'Why Accessibility is used',
                body:
                    'Accessibility lets Break Free see which app is in the foreground and, in supported browsers only, read the address-bar text to match your blocklists. Content is processed on-device. Break Free does not use Accessibility to control your device or scrape messages.',
              ),
              const SizedBox(height: BfSpacing.sm),
              const _InfoBlock(
                title: 'Why notification access is requested',
                body:
                    'Optional Transaction Scanner looks for risk keywords in notification title/text. Matches can open an intervention. Notification bodies are not stored — only a short local event such as “Notification intervention”.',
              ),
              const SizedBox(height: BfSpacing.sm),
              const _InfoBlock(
                title: 'Website information inspected',
                body:
                    'Only the address-bar text of supported browsers is checked against categories (adult, gambling) and your custom domains. Unsupported browsers are not filtered. There is no VPN or DNS filtering layer in this version.',
              ),
              const SizedBox(height: BfSpacing.sm),
              const _InfoBlock(
                title: 'What is stored vs synchronized',
                body:
                    'Protection schedules, custom domains, and local protection history stay on this device. Companion Sync (when linked and allowed) may send short summaries like “Protection was disabled” or “Blocked app attempt” — not full browsing history.',
              ),
              const SizedBox(height: BfSpacing.sm),
              const _InfoBlock(
                title: 'Accountability (not device lockdown)',
                body:
                    'If Accessibility is turned off, Break Free may show a local reminder and, if you opted in, notify a companion. The app does not prevent uninstall or force-reenable permissions.',
              ),
              const SizedBox(height: BfSpacing.sectionGap),
              const BfSectionLabel('Your choices'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Share location with companion on slips'),
                subtitle: const Text('Only applies when a companion is linked'),
                value: settings.shareLocationWithCompanion,
                activeThumbColor: BfColors.accent,
                onChanged: settings.setShareLocationWithCompanion,
              ),
              const SizedBox(height: BfSpacing.xs),
              Text(
                'Resetting local progress or deleting local data does not delete your Firebase account or companion documents in the cloud. Sign out separately if you want to leave this device signed out.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return BfSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: BfSpacing.xs),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
