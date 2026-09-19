import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:break_free/features/auth/presentation/auth_provider.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'Welcome to',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 8),
              Text(
                'Break Free',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 32),
              const Text(
                '🔑',
                style: TextStyle(fontSize: 80),
                textAlign: TextAlign.center,
              ).animate().scale(delay: 300.ms, duration: 500.ms),
              const SizedBox(height: 48),
              if (authProvider.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    authProvider.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton.icon(
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                        final success = await context.read<AuthProvider>().signInWithGoogle();
                        if (success && context.mounted) {
                          context.go('/habit-selection');
                        }
                      },
                icon: const Icon(Icons.login),
                label: const Text('Continue with Google'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                        final success = await context.read<AuthProvider>().signInAnonymously();
                        if (success && context.mounted) {
                          context.go('/habit-selection');
                        }
                      },
                icon: const Icon(Icons.person_outline),
                label: const Text('Continue as Guest'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
              ).animate().fadeIn(delay: 500.ms),
              if (authProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 24.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
