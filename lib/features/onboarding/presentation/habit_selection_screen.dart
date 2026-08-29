import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:break_free/core/data/habit_catalog.dart';
import 'package:break_free/core/providers/habit_provider.dart';
import 'package:break_free/core/providers/onboarding_provider.dart';

class HabitSelectionScreen extends ConsumerStatefulWidget {
  const HabitSelectionScreen({super.key});

  @override
  ConsumerState<HabitSelectionScreen> createState() =>
      _HabitSelectionScreenState();
}

class _HabitSelectionScreenState extends ConsumerState<HabitSelectionScreen> {
  final List<String> _selectedHabits = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Fight')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Select the habits you want to break. You can track more than one.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                for (final category in HabitCatalog.categories) ...[
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                        ),
                    itemCount: category.options.length,
                    itemBuilder: (context, index) =>
                        _buildHabitTile(context, category.options[index]),
                  ),
                  const SizedBox(height: 28),
                ],
                _buildSafetyNote(context),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: _selectedHabits.isEmpty ? null : _saveAndContinue,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(_continueLabel()),
            ),
          ),
        ],
      ),
    );
  }

  String _continueLabel() {
    final count = _selectedHabits.length;
    if (count == 0) return 'Continue';
    return count == 1 ? 'Continue with 1 habit' : 'Continue with $count habits';
  }

  Widget _buildHabitTile(BuildContext context, HabitOption option) {
    final isSelected = _selectedHabits.contains(option.title);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedHabits.remove(option.title);
          } else {
            _selectedHabits.add(option.title);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                option.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Withdrawal from alcohol and some other drugs can be medically dangerous.
  /// This app is a habit tracker, not treatment, and shouldn't imply otherwise.
  Widget _buildSafetyNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Stopping alcohol or other drugs suddenly can be unsafe. If you '
              'drink or use daily, talk to a doctor or a local support service '
              'before you quit.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndContinue() async {
    final provider = context.read<HabitProvider>();
    for (final title in _selectedHabits) {
      await provider.addHabit(title, HabitCatalog.emojiFor(title), []);
    }
    // Marks onboarding done so the router stops routing here.
    await ref.read(onboardingProvider.notifier).complete();
    if (!mounted) return;
    context.go('/');
  }
}
