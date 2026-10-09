import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';

class InterventionScreen extends StatelessWidget {
  final String packageName;

  const InterventionScreen({
    super.key,
    required this.packageName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BfColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BfSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.self_improvement, size: 72, color: BfColors.accent),
              const SizedBox(height: BfSpacing.xxl),
              Text(
                'Pause and breathe',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: BfColors.textPrimaryDark,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: BfSpacing.md),
              Text(
                'You are trying to open a restricted app.\n\n'
                'Take a breath. Is this a mindful choice, or a habit loop?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: BfColors.textSecondaryDark,
                      height: 1.45,
                    ),
              ),
              const Spacer(),
              BfPrimaryButton(
                label: 'Close app & stay focused',
                onPressed: () => context.go('/'),
              ),
              const SizedBox(height: BfSpacing.md),
              TextButton(
                onPressed: () => context.push('/relapse'),
                child: const Text(
                  'I slipped up (log relapse)',
                  style: TextStyle(color: BfColors.textTertiaryDark),
                ),
              ),
              const SizedBox(height: BfSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
