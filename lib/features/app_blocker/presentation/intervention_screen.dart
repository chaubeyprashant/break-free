import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:break_free/features/settings/data/accountability_repository.dart';

class InterventionScreen extends StatelessWidget {
  final String packageName;

  const InterventionScreen({
    super.key,
    required this.packageName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Immersive panic/intervention mode
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.self_improvement,
                size: 100,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 32),
              const Text(
                'Pause and Breathe',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You are trying to open a restricted app.\n\nTake a deep breath. Is this a mindful choice, or a habit loop?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // User chose to stop - reward them and go back to dashboard
                  context.go('/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close App & Stay Focused',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  accountabilityRepository.sendSmsOnRelapse('App Usage');
                  // Navigate to relapse logger
                  context.push('/relapse');
                },
                child: Text(
                  'I slipped up (Log Relapse)',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
