import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/providers/entitlement_provider.dart';
import 'package:break_free/core/providers/protection_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/subscription/domain/premium_feature.dart';
import 'package:break_free/features/subscription/presentation/premium_lock_sheet.dart';

class CustomDomainsScreen extends StatefulWidget {
  const CustomDomainsScreen({super.key});

  @override
  State<CustomDomainsScreen> createState() => _CustomDomainsScreenState();
}

class _CustomDomainsScreenState extends State<CustomDomainsScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final protection = context.read<ProtectionProvider>();
    final entitlement = context.read<EntitlementProvider>();
    if (!entitlement.isPremium &&
        protection.config.customDomains.length >= FreeTier.maxCustomDomains) {
      showPremiumLockSheet(context, feature: PremiumFeature.expandedCustomBlocklist);
      return;
    }
    try {
      await protection.addDomain(_controller.text);
      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _edit(String domain) async {
    final controller = TextEditingController(text: domain);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit domain'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'example.com'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (next == null || !mounted) return;
    try {
      await context.read<ProtectionProvider>().editDomain(domain, next);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _remove(String domain) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove domain?'),
        content: Text('Stop blocking $domain?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<ProtectionProvider>().removeDomain(domain);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom domains')),
      body: Consumer<ProtectionProvider>(
        builder: (context, protection, _) {
          final domains = protection.config.customDomains;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              BfSpacing.screenH,
              BfSpacing.sm,
              BfSpacing.screenH,
              BfSpacing.huge,
            ),
            children: [
              Text(
                'Works with supported browsers. Domains are normalized; matching uses the host or its subdomains.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: BfSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'Domain',
                        hintText: 'example.com',
                      ),
                      onSubmitted: (_) => _add(),
                    ),
                  ),
                  const SizedBox(width: BfSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: FilledButton(onPressed: _add, child: const Text('Add')),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enforce custom domains'),
                value: protection.config.customDomainsEnabled,
                activeThumbColor: BfColors.accent,
                onChanged: (v) => protection.updateConfig(
                  protection.config.copyWith(customDomainsEnabled: v),
                ),
              ),
              Text(
                context.watch<EntitlementProvider>().isPremium
                    ? '${domains.length} domains'
                    : '${domains.length} / ${FreeTier.maxCustomDomains} free domains',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: BfSpacing.md),
              const BfSectionLabel('List'),
              const SizedBox(height: BfSpacing.xs),
              if (domains.isEmpty)
                Text(
                  'No custom domains yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...domains.map(
                  (d) => BfListRow(
                    title: d,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _edit(d),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _remove(d),
                        ),
                      ],
                    ),
                    showDivider: d != domains.last,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
