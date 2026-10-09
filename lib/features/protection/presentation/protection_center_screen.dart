import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/models/protection_event.dart';
import 'package:break_free/core/providers/entitlement_provider.dart';
import 'package:break_free/core/providers/protection_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/async_state_view.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/app_blocker/data/app_blocker_repository.dart';
import 'package:break_free/features/subscription/domain/premium_feature.dart';
import 'package:break_free/features/subscription/presentation/premium_lock_sheet.dart';

class ProtectionCenterScreen extends StatefulWidget {
  const ProtectionCenterScreen({super.key});

  @override
  State<ProtectionCenterScreen> createState() => _ProtectionCenterScreenState();
}

class _ProtectionCenterScreenState extends State<ProtectionCenterScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProtectionProvider>().reload();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<ProtectionProvider>().reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Protection')),
      body: Consumer<ProtectionProvider>(
        builder: (context, protection, _) {
          if (!protection.isLoaded) return const AsyncLoadingView();
          if (protection.error != null) {
            return AsyncErrorView(message: protection.error!, onRetry: protection.reload);
          }

          final active = protection.isProtectionActive;
          final browsers = protection.supportedBrowsers;
          final apps = appBlockerRepository.blockedApps.length;
          final schedulesOn = protection.schedules.where((s) => s.enabled).length;

          return RefreshIndicator(
            onRefresh: protection.reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                BfSpacing.screenH,
                BfSpacing.sm,
                BfSpacing.screenH,
                BfSpacing.huge,
              ),
              children: [
                Text(
                  active ? '● Protected' : '○ Unprotected',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: BfSpacing.xs),
                Text(
                  active
                      ? 'Apps $apps  ·  Domains ${protection.config.customDomains.length}  ·  Schedules $schedulesOn'
                      : _disabledReason(protection),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable protection'),
                  value: protection.config.protectionEnabled,
                  activeThumbColor: BfColors.accent,
                  onChanged: (v) => protection.updateConfig(
                    protection.config.copyWith(protectionEnabled: v),
                  ),
                ),
                if (!protection.accessibilityEnabled) ...[
                  const SizedBox(height: BfSpacing.sm),
                  Text(
                    'Accessibility is required for app and supported-browser filtering.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: BfSpacing.sm),
                  BfPrimaryButton(
                    label: 'Open Accessibility settings',
                    onPressed: () => protection.openAccessibilitySettings(),
                  ),
                ],

                const SizedBox(height: BfSpacing.sectionGap),
                const BfSectionLabel('Permissions'),
                const SizedBox(height: BfSpacing.xs),
                BfListRow(
                  title: 'Accessibility',
                  subtitle: protection.accessibilityEnabled ? 'Granted' : 'Required',
                  trailing: protection.accessibilityEnabled
                      ? const Icon(Icons.check, size: 18, color: BfColors.success)
                      : TextButton(onPressed: protection.openAccessibilitySettings, child: const Text('Fix')),
                ),
                BfListRow(
                  title: 'Notification access',
                  subtitle: protection.notificationAccessEnabled ? 'Granted' : 'Optional scanner',
                  trailing: protection.notificationAccessEnabled
                      ? const Icon(Icons.check, size: 18, color: BfColors.success)
                      : TextButton(onPressed: protection.openNotificationSettings, child: const Text('Fix')),
                  showDivider: false,
                ),

                const SizedBox(height: BfSpacing.sectionGap),
                const BfSectionLabel('Apps'),
                const SizedBox(height: BfSpacing.xs),
                BfListRow(
                  title: 'Protected apps',
                  subtitle: '$apps selected',
                  onTap: () => context.push('/app-blocker'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Always-on app blocking'),
                  subtitle: const Text('Off = only during active schedules'),
                  value: protection.config.alwaysOnApps,
                  activeThumbColor: BfColors.accent,
                  onChanged: (v) => protection.updateConfig(
                    protection.config.copyWith(alwaysOnApps: v),
                    configChangedAlert: true,
                  ),
                ),

                const SizedBox(height: BfSpacing.lg),
                const BfSectionLabel('Websites'),
                const SizedBox(height: BfSpacing.xs),
                Text(
                  'Works with supported browsers only — not a VPN or DNS filter.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Adult content'),
                  value: protection.config.webAdultEnabled,
                  activeThumbColor: BfColors.accent,
                  onChanged: (v) => protection.updateConfig(
                    protection.config.copyWith(webAdultEnabled: v),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Gambling sites'),
                  value: protection.config.webGamblingEnabled,
                  activeThumbColor: BfColors.accent,
                  onChanged: (v) => protection.updateConfig(
                    protection.config.copyWith(webGamblingEnabled: v),
                  ),
                ),
                BfListRow(
                  title: 'Custom domains',
                  subtitle: '${protection.config.customDomains.length} listed',
                  onTap: () => context.push('/protection/domains'),
                  showDivider: false,
                ),
                if (browsers.isNotEmpty) ...[
                  const SizedBox(height: BfSpacing.xs),
                  Text(
                    'Supported: ${browsers.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],

                const SizedBox(height: BfSpacing.sectionGap),
                const BfSectionLabel('Schedules'),
                const SizedBox(height: BfSpacing.xs),
                ...protection.schedules.map(
                  (s) => BfListRow(
                    title: s.name,
                    subtitle: '${s.timeLabel}  ·  ${s.enabled ? 'On' : 'Off'}',
                    onTap: () => context.push('/protection/schedule', extra: s),
                    showDivider: true,
                  ),
                ),
                BfListRow(
                  title: 'Add schedule',
                  subtitle: context.watch<EntitlementProvider>().isPremium
                      ? 'Night, work, or custom windows'
                      : 'Free includes ${FreeTier.maxSchedules} · Premium unlocks more',
                  onTap: () {
                    final entitlement = context.read<EntitlementProvider>();
                    if (!entitlement.isPremium &&
                        protection.schedules.length >= FreeTier.maxSchedules) {
                      showPremiumLockSheet(context, feature: PremiumFeature.advancedSchedules);
                      return;
                    }
                    context.push('/protection/schedule');
                  },
                  showDivider: false,
                ),
                if (protection.activeSchedulesNow.isNotEmpty) ...[
                  const SizedBox(height: BfSpacing.xs),
                  Text(
                    'Active now: ${protection.activeSchedulesNow.map((s) => s.name).join(', ')}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: BfColors.accent),
                  ),
                ],

                const SizedBox(height: BfSpacing.sectionGap),
                const BfSectionLabel('Options'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Allow “Continue anyway”'),
                  subtitle: Text('${protection.config.continueAnywayMinutes}-minute bypass'),
                  value: protection.config.allowContinueAnyway,
                  activeThumbColor: BfColors.accent,
                  onChanged: (v) => protection.updateConfig(
                    protection.config.copyWith(allowContinueAnyway: v),
                  ),
                ),
                BfListRow(
                  title: 'Companion alerts',
                  subtitle: 'Short accountability summaries only',
                  onTap: () {
                    if (!context.read<EntitlementProvider>().isPremium) {
                      showPremiumLockSheet(context, feature: PremiumFeature.advancedCompanionAlerts);
                      return;
                    }
                    context.push('/protection/companion-alerts');
                  },
                ),
                BfListRow(
                  title: 'Notification scanner',
                  onTap: () {
                    if (!context.read<EntitlementProvider>().isPremium) {
                      showPremiumLockSheet(context, feature: PremiumFeature.transactionScanner);
                      return;
                    }
                    context.push('/scanner-settings');
                  },
                  showDivider: false,
                ),

                const SizedBox(height: BfSpacing.sectionGap),
                const BfSectionLabel('Network'),
                const SizedBox(height: BfSpacing.xs),
                Text(
                  'VPN / DNS filtering is not enabled. Website protection uses supported browsers via Accessibility.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: BfSpacing.sectionGap),
                const BfSectionLabel('Recent events'),
                const SizedBox(height: BfSpacing.xs),
                ..._historyTiles(context, protection),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _historyTiles(BuildContext context, ProtectionProvider protection) {
    if (protection.recentEvents.isEmpty) {
      return [
        Text(
          'No protection events yet.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ];
    }
    final isPremium = context.watch<EntitlementProvider>().isPremium;
    final visible = isPremium
        ? protection.recentEvents.take(12)
        : protection.recentEvents.take(FreeTier.freeProtectionHistory);
    return [
      ...visible.map(
        (e) => BfListRow(
          title: e.title ?? e.companionSummary,
          subtitle: _formatTime(e.timestamp),
          leading: Icon(_iconFor(e.type), size: 18),
          showDivider: true,
        ),
      ),
      if (!isPremium && protection.recentEvents.length > FreeTier.freeProtectionHistory)
        BfListRow(
          title: 'Older history',
          subtitle: 'Premium unlocks full protection history',
          onTap: () => showPremiumLockSheet(
            context,
            feature: PremiumFeature.advancedProtectionHistory,
          ),
          showDivider: false,
        ),
    ];
  }

  String _disabledReason(ProtectionProvider p) {
    if (!p.config.protectionEnabled) return 'Master switch is off.';
    if (!p.accessibilityEnabled) return 'Accessibility permission is required.';
    return 'Protection is not active.';
  }

  IconData _iconFor(ProtectionEventType type) => switch (type) {
        ProtectionEventType.appBlocked => Icons.block,
        ProtectionEventType.websiteBlocked ||
        ProtectionEventType.customDomainBlocked =>
          Icons.public_off,
        ProtectionEventType.notificationIntervention => Icons.notifications_none,
        ProtectionEventType.protectionDisabled ||
        ProtectionEventType.permissionRemoved =>
          Icons.warning_amber_outlined,
        ProtectionEventType.scheduleStarted ||
        ProtectionEventType.scheduleEnded =>
          Icons.schedule,
        ProtectionEventType.continueAnyway => Icons.directions_walk,
        ProtectionEventType.configChanged => Icons.tune,
      };

  String _formatTime(DateTime t) {
    final local = t.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
