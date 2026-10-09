import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';

/// Support tab — calm entry to urge surfing, breathing, recovery tools.
class SupportHubScreen extends StatelessWidget {
  const SupportHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BfSpacing.screenH,
          BfSpacing.xs,
          BfSpacing.screenH,
          BfSpacing.huge,
        ),
        children: [
          Text(
            'When it gets hard',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: BfSpacing.xs),
          Text(
            'You don\'t have to white-knuckle it alone. Start with ninety seconds.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: BfSpacing.xl),
          BfPrimaryButton(
            label: 'I\'m having an urge',
            onPressed: () => context.push('/urge'),
          ),
          const SizedBox(height: BfSpacing.xs),
          BfSecondaryButton(
            label: 'Start 90s breathing',
            onPressed: () => context.push('/panic'),
          ),
          const SizedBox(height: BfSpacing.sectionGap),
          const BfSectionLabel('Tools'),
          const SizedBox(height: BfSpacing.xs),
          BfListRow(
            title: 'Recovery plan',
            subtitle: 'Your steps when you need help',
            onTap: () => context.push('/help'),
          ),
          BfListRow(
            title: 'Replace the habit',
            subtitle: 'Short activities that interrupt the loop',
            onTap: () => context.push('/replace'),
          ),
          BfListRow(
            title: 'Urge history',
            subtitle: 'What you\'ve already ridden out',
            onTap: () => context.push('/urge/history'),
            showDivider: false,
          ),
        ],
      ),
    );
  }
}
