import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/models/journal_entry.dart';
import 'package:break_free/core/providers/entitlement_provider.dart';
import 'package:break_free/core/providers/habit_provider.dart';
import 'package:break_free/core/providers/journal_provider.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/async_state_view.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/journal/presentation/journal_entry_editor_screen.dart';
import 'package:break_free/features/journal/presentation/journal_insights_panel.dart';
import 'package:break_free/features/subscription/domain/premium_feature.dart';
import 'package:break_free/features/subscription/presentation/premium_lock_sheet.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openEditor({JournalEntry? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JournalEntryEditorScreen(existing: existing),
      ),
    );
  }

  Future<void> _confirmDelete(JournalEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This removes the entry from this device. It cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<JournalProvider>().delete(entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        bottom: TabBar(
          controller: _tabs,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Reflections'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.edit_outlined, size: 20),
        label: const Text('Reflect'),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _EntriesTab(onOpen: _openEditor, onDelete: _confirmDelete),
          const _InsightsGate(),
        ],
      ),
    );
  }
}

class _InsightsGate extends StatelessWidget {
  const _InsightsGate();

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<EntitlementProvider>().isPremium;
    if (premium) return const JournalInsightsPanel();
    return AsyncEmptyView(
      icon: Icons.insights_outlined,
      title: PremiumFeature.journalInsights.title,
      subtitle: PremiumFeature.journalInsights.benefit,
      actionLabel: 'Upgrade to Break Free Premium',
      onAction: () => showPremiumLockSheet(context, feature: PremiumFeature.journalInsights),
    );
  }
}

class _EntriesTab extends StatelessWidget {
  const _EntriesTab({required this.onOpen, required this.onDelete});

  final Future<void> Function({JournalEntry? existing}) onOpen;
  final Future<void> Function(JournalEntry entry) onDelete;

  @override
  Widget build(BuildContext context) {
    return Consumer2<JournalProvider, HabitProvider>(
      builder: (context, journal, habits, _) {
        if (!journal.isLoaded) {
          return const AsyncLoadingView(message: 'Loading journal…');
        }
        if (journal.error != null) {
          return AsyncErrorView(message: journal.error!, onRetry: journal.reload);
        }
        if (journal.isEmpty) {
          return AsyncEmptyView(
            icon: Icons.menu_book_outlined,
            title: 'No reflections yet',
            subtitle: 'Mood, triggers, and what helped — stored only on this device.',
            actionLabel: 'Write first reflection',
            onAction: () => onOpen(),
          );
        }

        final dateFmt = DateFormat.yMMMd().add_jm();
        return RefreshIndicator(
          onRefresh: journal.reload,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(BfSpacing.screenH, BfSpacing.sm, BfSpacing.screenH, 88),
            itemCount: journal.entries.length,
            separatorBuilder: (_, __) => const BfDivider(),
            itemBuilder: (context, index) {
              final entry = journal.entries[index];
              String? habitTitle;
              if (entry.habitId != null) {
                for (final h in habits.habits) {
                  if (h.id == entry.habitId) {
                    habitTitle = h.title;
                    break;
                  }
                }
              }
              return InkWell(
                onTap: () => onOpen(existing: entry),
                onLongPress: () => onDelete(entry),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: BfSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dateFmt.format(entry.date),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          if (entry.isRelapse)
                            Text(
                              'Slip',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                        ],
                      ),
                      const SizedBox(height: BfSpacing.xs),
                      Text(
                        entry.note.isNotEmpty ? entry.note : 'No notes',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: entry.note.isEmpty
                            ? Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)
                            : Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: BfSpacing.xs),
                      Text(
                        [
                          'Mood ${entry.moodRating.round()}/5',
                          if (entry.urgeIntensity > 0) 'Urge ${entry.urgeIntensity.round()}/10',
                          if (entry.triggersIdentified.isNotEmpty) entry.triggersIdentified.first,
                          if (habitTitle != null) habitTitle,
                          if (entry.copingMethod != null && entry.copingMethod!.isNotEmpty)
                            'Helped: ${entry.copingMethod}',
                        ].join('  ·  '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
