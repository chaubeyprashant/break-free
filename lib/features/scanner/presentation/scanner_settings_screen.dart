import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/providers/protection_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/scanner/data/notification_scanner_repository.dart';

class ScannerSettingsScreen extends StatefulWidget {
  const ScannerSettingsScreen({super.key});

  @override
  State<ScannerSettingsScreen> createState() => _ScannerSettingsScreenState();
}

class _ScannerSettingsScreenState extends State<ScannerSettingsScreen> with WidgetsBindingObserver {
  final _repository = NotificationScannerRepository();
  bool _isServiceEnabled = false;

  static const _categories = <String, String>{
    'smoking': 'Smoking / vape',
    'alcohol': 'Alcohol',
    'junk_food': 'Junk food delivery',
    'gambling': 'Gambling',
    'shopping': 'Impulse shopping',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkServiceStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkServiceStatus();
    }
  }

  Future<void> _checkServiceStatus() async {
    final isEnabled = await _repository.isScannerEnabled();
    if (mounted) setState(() => _isServiceEnabled = isEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification scanner')),
      body: Consumer<ProtectionProvider>(
        builder: (context, protection, _) {
          final config = protection.config;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              BfSpacing.screenH,
              BfSpacing.sm,
              BfSpacing.screenH,
              BfSpacing.huge,
            ),
            children: [
              Text(
                _isServiceEnabled ? '● Permission granted' : '○ Permission needed',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: BfSpacing.xs),
              Text(
                _isServiceEnabled
                    ? 'Keywords match on-device. Notification text is not stored.'
                    : 'Enable Notification Access so Break Free can scan for risk keywords.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (!_isServiceEnabled) ...[
                const SizedBox(height: BfSpacing.md),
                BfPrimaryButton(
                  label: 'Open notification access',
                  onPressed: () => _repository.openScannerSettings(),
                ),
              ],
              const SizedBox(height: BfSpacing.sectionGap),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Scanner enabled'),
                subtitle: const Text('Master switch on this device'),
                value: config.scannerEnabled,
                activeThumbColor: BfColors.accent,
                onChanged: (v) => protection.updateConfig(config.copyWith(scannerEnabled: v)),
              ),
              const SizedBox(height: BfSpacing.md),
              const BfSectionLabel('Cooldown'),
              const SizedBox(height: BfSpacing.sm),
              ...[60, 120, 300].map((sec) {
                final label = switch (sec) {
                  60 => '1 minute',
                  120 => '2 minutes',
                  _ => '5 minutes',
                };
                final selected = config.scannerCooldownSeconds == sec;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(label),
                  trailing: selected
                      ? const Icon(Icons.check, size: 20, color: BfColors.accent)
                      : null,
                  onTap: () => protection.updateConfig(config.copyWith(scannerCooldownSeconds: sec)),
                );
              }),
              const SizedBox(height: BfSpacing.lg),
              const BfSectionLabel('Categories'),
              const SizedBox(height: BfSpacing.xs),
              Text(
                'Matched categories open an intervention and explain why — without saving the notification body.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: BfSpacing.sm),
              ..._categories.entries.map((e) {
                final selected = config.scannerCategories.contains(e.key);
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.value),
                  value: selected,
                  activeColor: BfColors.accent,
                  onChanged: (v) {
                    final next = {...config.scannerCategories};
                    if (v == true) {
                      next.add(e.key);
                    } else {
                      next.remove(e.key);
                    }
                    protection.updateConfig(config.copyWith(scannerCategories: next));
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
