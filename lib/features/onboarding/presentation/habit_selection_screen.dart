import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:break_free/core/providers/habit_provider.dart';

class HabitSelectionScreen extends StatefulWidget {
  const HabitSelectionScreen({super.key});

  @override
  State<HabitSelectionScreen> createState() => _HabitSelectionScreenState();
}

class _HabitSelectionScreenState extends State<HabitSelectionScreen> {
  final List<String> _selectedHabits = [];
  final List<Map<String, String>> _habitOptions = [
    {'title': 'Porn/Masturbation', 'icon': '🚫'},
    {'title': 'Smoking', 'icon': '🚬'},
    {'title': 'Alcohol', 'icon': '🍺'},
    {'title': 'Junk Food', 'icon': '🍔'},
    {'title': 'Social Media', 'icon': '📱'},
    {'title': 'Gaming', 'icon': '🎮'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Fight')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Select the habits you want to break.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _habitOptions.length,
              itemBuilder: (context, index) {
                final habit = _habitOptions[index];
                final isSelected = _selectedHabits.contains(habit['title']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedHabits.remove(habit['title']);
                      } else {
                        _selectedHabits.add(habit['title']!);
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
                                ).colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          habit['icon']!,
                          style: const TextStyle(fontSize: 40),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          habit['title']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: _selectedHabits.isEmpty
                  ? null
                  : () async {
                      final provider = context.read<HabitProvider>();
                      for (final habitTitle in _selectedHabits) {
                        final habitOption = _habitOptions.firstWhere(
                          (element) => element['title'] == habitTitle,
                          orElse: () => {'title': habitTitle, 'icon': '🚫'},
                        );
                        await provider.addHabit(
                          habitTitle,
                          habitOption['icon'] ?? '🚫',
                          [],
                        );
                      }
                      context.go('/');
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
