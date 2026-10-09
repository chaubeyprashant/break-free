import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/models/recovery_action.dart';
import 'package:break_free/core/providers/recovery_plan_provider.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';

/// Reorder, enable/disable, rename, add custom actions, or reset the plan.
class RecoveryPlanEditScreen extends StatelessWidget {
  const RecoveryPlanEditScreen({super.key});

  Future<void> _promptForAction(BuildContext context, {RecoveryAction? existing}) async {
    final controller = TextEditingController(text: existing?.title ?? '');
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add a step' : 'Rename step'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'e.g. Call my brother'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
    if (title == null || title.trim().isEmpty || !context.mounted) return;
    final provider = context.read<RecoveryPlanProvider>();
    if (existing == null) {
      await provider.addCustomAction(title);
    } else {
      await provider.rename(existing.id, title);
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset plan?'),
        content: const Text('Custom steps will be removed and the default plan restored.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<RecoveryPlanProvider>().resetToDefaults();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_outlined),
            tooltip: 'Reset to defaults',
            onPressed: () => _confirmReset(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _promptForAction(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add step'),
      ),
      body: Consumer<RecoveryPlanProvider>(
        builder: (context, provider, _) {
          final plan = provider.plan;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(BfSpacing.screenH, BfSpacing.sm, BfSpacing.screenH, BfSpacing.xs),
                child: Text(
                  'Drag to reorder. Turn off anything you do not want. Everything stays on this device.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(BfSpacing.screenH, BfSpacing.xs, BfSpacing.screenH, 96),
                  itemCount: plan.length,
                  onReorderItem: (oldIndex, newIndex) => provider.reorder(oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final action = plan[index];
                    return Column(
                      key: ValueKey(action.id),
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ReorderableDragStartListener(
                            index: index,
                            child: Icon(
                              Icons.drag_handle,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                          title: Text(
                            action.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: action.enabled
                                      ? null
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                          ),
                          subtitle: Text(switch (action.kind) {
                            RecoveryActionKind.checklist => action.isCustom ? 'Custom step' : 'Checklist step',
                            RecoveryActionKind.breathing => 'Opens breathing',
                            RecoveryActionKind.urgeSurfing => 'Opens urge surfing',
                            RecoveryActionKind.contactCompanion => 'Opens companion',
                            RecoveryActionKind.replaceHabit => 'Opens activities',
                          }),
                          onTap: action.isCustom ? () => _promptForAction(context, existing: action) : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (action.isCustom)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  tooltip: 'Delete',
                                  onPressed: () => provider.remove(action.id),
                                ),
                              Switch(
                                value: action.enabled,
                                onChanged: (v) => provider.setEnabled(action.id, v),
                              ),
                            ],
                          ),
                        ),
                        if (index < plan.length - 1) const BfDivider(),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
