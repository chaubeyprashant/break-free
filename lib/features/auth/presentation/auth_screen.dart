import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/auth/presentation/auth_provider.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BfSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'BREAK FREE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 2,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
              ),
              const SizedBox(height: BfSpacing.md),
              Text(
                'Sign in to continue',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: BfSpacing.sm),
              Text(
                'Your recovery data stays on this device. Sign-in is for account sync and companion features.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: BfSpacing.xxl),
              if (authProvider.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: BfSpacing.md),
                  child: Text(
                    authProvider.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              BfPrimaryButton(
                label: authProvider.isLoading ? 'Signing in…' : 'Continue with Google',
                icon: Icons.login,
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                        final success = await context.read<AuthProvider>().signInWithGoogle();
                        if (success && context.mounted) {
                          context.go('/habit-selection');
                        }
                      },
              ),
              const SizedBox(height: BfSpacing.xs),
              BfSecondaryButton(
                label: 'Continue as guest',
                icon: Icons.person_outline,
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                        final success = await context.read<AuthProvider>().signInAnonymously();
                        if (success && context.mounted) {
                          context.go('/habit-selection');
                        }
                      },
              ),
              if (authProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: BfSpacing.xl),
                  child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
