import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';

class TransactionInterventionScreen extends StatelessWidget {
  final String notificationText;

  const TransactionInterventionScreen({super.key, required this.notificationText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BfColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BfSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.warning_amber_rounded, size: 72, color: BfColors.warning)
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: BfSpacing.xxl),
              Text(
                'Risk keyword matched',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: BfColors.textPrimaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: BfSpacing.md),
              Text(
                'A notification matched one of your scanner categories. '
                'The body is not stored — only this intervention.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: BfColors.textSecondaryDark,
                      height: 1.45,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: BfSpacing.lg),
              Container(
                padding: const EdgeInsets.all(BfSpacing.md),
                decoration: BoxDecoration(
                  color: BfColors.inkElevated,
                  borderRadius: BorderRadius.circular(BfRadius.md),
                  border: Border.all(color: BfColors.borderDark),
                ),
                child: Text(
                  notificationText,
                  style: const TextStyle(
                    color: BfColors.textTertiaryDark,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: BfSpacing.xxl),
              Text(
                'Are you relapsing? Take a deep breath.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: BfColors.textPrimaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 600.ms),
              const Spacer(),
              BfPrimaryButton(
                label: 'I am strong — return home',
                onPressed: () => context.go('/'),
              ).animate().fadeIn(delay: 800.ms).moveY(begin: 20, end: 0),
              const SizedBox(height: BfSpacing.md),
              TextButton(
                onPressed: () => context.push('/relapse'),
                child: const Text(
                  'I slipped up (log relapse)',
                  style: TextStyle(color: BfColors.textTertiaryDark),
                ),
              ).animate().fadeIn(delay: 1000.ms),
              const SizedBox(height: BfSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
