import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mukti/core/providers/habit_provider.dart';

class ReflectionScreen extends StatelessWidget {
  const ReflectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reflection')),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          // Placeholder for journal integration
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_graph, size: 64, color: Colors.teal),
                SizedBox(height: 16),
                Text('Journal & Insights Coming Soon'),
              ],
            ),
          );
        },
      ),
    );
  }
}
