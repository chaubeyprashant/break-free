import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/providers/protection_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';

class CompanionAlertPrefsScreen extends StatelessWidget {
  const CompanionAlertPrefsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Companion alerts')),
      body: Consumer<ProtectionProvider>(
        builder: (context, protection, _) {
          final prefs = protection.config.companionAlerts;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              BfSpacing.screenH,
              BfSpacing.sm,
              BfSpacing.screenH,
              BfSpacing.huge,
            ),
            children: [
              Text(
                'With a linked companion and Premium, Break Free can send short accountability '
                'summaries. Full URLs and notification bodies are never synced.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: BfSpacing.lg),
              const BfSectionLabel('Alerts'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Blocked attempts'),
                subtitle: const Text('e.g. “Blocked app attempt”'),
                value: prefs.blockedAttempts,
                activeThumbColor: BfColors.accent,
                onChanged: (v) => protection.updateCompanionAlerts(prefs.copyWith(blockedAttempts: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Protection disabled'),
                value: prefs.protectionDisabled,
                activeThumbColor: BfColors.accent,
                onChanged: (v) => protection.updateCompanionAlerts(prefs.copyWith(protectionDisabled: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Permission removed'),
                value: prefs.permissionRemoved,
                activeThumbColor: BfColors.accent,
                onChanged: (v) => protection.updateCompanionAlerts(prefs.copyWith(permissionRemoved: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Major configuration changes'),
                value: prefs.configChanged,
                activeThumbColor: BfColors.accent,
                onChanged: (v) => protection.updateCompanionAlerts(prefs.copyWith(configChanged: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Relapse events'),
                value: prefs.relapseEvents,
                activeThumbColor: BfColors.accent,
                onChanged: (v) => protection.updateCompanionAlerts(prefs.copyWith(relapseEvents: v)),
              ),
            ],
          );
        },
      ),
    );
  }
}
