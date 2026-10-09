import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:break_free/core/providers/entitlement_provider.dart';
import 'package:break_free/core/providers/habit_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/subscription/domain/premium_feature.dart';
import 'package:break_free/features/subscription/presentation/premium_lock_sheet.dart';

class HabitSelectionScreen extends StatefulWidget {
  const HabitSelectionScreen({super.key});

  @override
  State<HabitSelectionScreen> createState() => _HabitSelectionScreenState();
}

class _HabitSelectionScreenState extends State<HabitSelectionScreen> {
  final List<String> _selectedHabits = [];

  static const _habitOptions = <({String title, IconData icon, String iconKey})>[
    (title: 'Porn/Masturbation', icon: Icons.visibility_off_outlined, iconKey: 'visibility_off'),
    (title: 'Smoking', icon: Icons.smoke_free_outlined, iconKey: 'smoke_free'),
    (title: 'Alcohol', icon: Icons.local_bar_outlined, iconKey: 'local_bar'),
    (title: 'Junk Food', icon: Icons.restaurant_outlined, iconKey: 'restaurant'),
    (title: 'Social Media', icon: Icons.phone_iphone_outlined, iconKey: 'phone'),
    (title: 'Gaming', icon: Icons.sports_esports_outlined, iconKey: 'gaming'),
    (title: 'Gambling', icon: Icons.casino_outlined, iconKey: 'casino'),
    (title: 'Impulse Shopping', icon: Icons.shopping_bag_outlined, iconKey: 'shopping'),
    (title: 'Doomscrolling', icon: Icons.nightlight_outlined, iconKey: 'night'),
    (title: 'Toxic Messaging', icon: Icons.chat_bubble_outline, iconKey: 'chat'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your habits')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(BfSpacing.screenH, BfSpacing.sm, BfSpacing.screenH, BfSpacing.md),
            child: Text(
              'Choose what you want to change. You can add more later with Premium.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: BfSpacing.screenH),
              itemCount: _habitOptions.length,
              separatorBuilder: (_, __) => const BfDivider(),
              itemBuilder: (context, index) {
                final habit = _habitOptions[index];
                final isSelected = _selectedHabits.contains(habit.title);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    habit.icon,
                    color: isSelected ? BfColors.accent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                  title: Text(
                    habit.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                  ),
                  trailing: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? BfColors.accent : Theme.of(context).colorScheme.outline,
                    size: 22,
                  ),
                  onTap: () {
                    final entitlement = context.read<EntitlementProvider>();
                    final existingCount = context.read<HabitProvider>().habits.length;
                    if (isSelected) {
                      setState(() => _selectedHabits.remove(habit.title));
                      return;
                    }
                    final wouldHave = existingCount + _selectedHabits.length + 1;
                    if (!entitlement.isPremium && wouldHave > entitlement.maxHabits) {
                      showPremiumLockSheet(context, feature: PremiumFeature.multipleHabits);
                      return;
                    }
                    setState(() => _selectedHabits.add(habit.title));
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(BfSpacing.screenH, BfSpacing.sm, BfSpacing.screenH, BfSpacing.xl),
            child: FilledButton(
              onPressed: _selectedHabits.isEmpty
                  ? null
                  : () async {
                      final provider = context.read<HabitProvider>();
                      for (final habitTitle in _selectedHabits) {
                        final habitOption = _habitOptions.firstWhere(
                          (element) => element.title == habitTitle,
                        );
                        await provider.addHabit(
                          habitTitle,
                          habitOption.iconKey,
                          [],
                        );
                      }
                      if (context.mounted) context.go('/');
                    },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, BfSpacing.minTouch),
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
