import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:break_free/features/settings/data/accountability_repository.dart';

class AdultInterventionScreen extends StatelessWidget {
  final String url;
  
  const AdultInterventionScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.pan_tool_rounded,
                size: 100,
                color: Colors.redAccent,
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 32),
              Text(
                'Hold on a second.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 16),
              Text(
                'We detected adult content in your browser.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  url,
                  style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 32),
              Text(
                'Take a deep breath. Think about your goals.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 600.ms),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  context.go('/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Return to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ).animate().fadeIn(delay: 800.ms).moveY(begin: 20, end: 0),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Send Accountability SMS if enabled
                  accountabilityRepository.sendSmsOnRelapse('Adult Content');
                  // Navigate to relapse logger
                  context.push('/relapse');
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white54,
                ),
                child: const Text('I slipped up (Log Relapse)'),
              ).animate().fadeIn(delay: 1000.ms),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
