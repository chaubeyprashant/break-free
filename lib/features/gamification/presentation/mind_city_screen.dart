import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/providers/entitlement_provider.dart';
import 'package:break_free/core/providers/game_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/subscription/domain/premium_feature.dart';
import 'package:break_free/features/subscription/presentation/premium_lock_sheet.dart';

/// Atmospheric progress space — rebuilding a world, not unlocking stickers.
class MindCityScreen extends StatelessWidget {
  const MindCityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BfColors.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: BfColors.textPrimaryDark,
        title: const Text('Mind City'),
      ),
      body: Consumer2<GameProvider, EntitlementProvider>(
        builder: (context, gameProvider, entitlement, child) {
          final level = gameProvider.progress.level;
          final premium = entitlement.isPremium;
          final unlocked = (level.clamp(1, 6));

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              BfSpacing.screenH,
              BfSpacing.sm,
              BfSpacing.screenH,
              BfSpacing.huge,
            ),
            children: [
              Text(
                'Level $level',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: BfColors.textPrimaryDark,
                    ),
              ),
              const SizedBox(height: BfSpacing.xs),
              Text(
                gameProvider.progress.levelTitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: BfColors.textSecondaryDark,
                    ),
              ),
              const SizedBox(height: BfSpacing.xl),
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(BfRadius.md),
                    border: Border.all(color: BfColors.borderDark),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF151B24),
                        Color(0xFF0B0D10),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 36,
                        child: Container(
                          height: 1,
                          color: BfColors.accent.withValues(alpha: 0.25),
                        ),
                      ),
                      ...List.generate(unlocked, (i) {
                        final left = 28.0 + i * 42;
                        final height = 28.0 + (i % 3) * 18;
                        return Positioned(
                          left: left,
                          bottom: 36,
                          child: Container(
                            width: 22,
                            height: height,
                            decoration: BoxDecoration(
                              color: BfColors.accent.withValues(alpha: 0.15 + i * 0.08),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              border: Border.all(color: BfColors.accent.withValues(alpha: 0.35)),
                            ),
                          ),
                        );
                      }),
                      if (premium)
                        Positioned(
                          right: 28,
                          bottom: 36,
                          child: Container(
                            width: 28,
                            height: 64,
                            decoration: BoxDecoration(
                              color: BfColors.accent.withValues(alpha: 0.35),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              border: Border.all(color: BfColors.accent),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          right: 16,
                          bottom: 48,
                          child: IconButton(
                            tooltip: 'Premium landmark',
                            onPressed: () => showPremiumLockSheet(
                              context,
                              feature: PremiumFeature.mindCityPremium,
                            ),
                            icon: const Icon(Icons.lock_outline, color: BfColors.textTertiaryDark, size: 20),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: BfSpacing.xl),
              const BfSectionLabel('Districts'),
              const SizedBox(height: BfSpacing.sm),
              ..._districts.map((d) {
                final open = level >= d.minLevel;
                return BfListRow(
                  title: d.name,
                  subtitle: open ? d.openCopy : 'Unlocks at level ${d.minLevel}',
                  trailing: Icon(
                    open ? Icons.check : Icons.lock_outline,
                    size: 18,
                    color: open ? BfColors.success : BfColors.textTertiaryDark,
                  ),
                  showDivider: d != _districts.last,
                );
              }),
              const SizedBox(height: BfSpacing.lg),
              Text(
                'Keep showing up. The skyline grows with your level — quietly.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BfColors.textSecondaryDark,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _District {
  const _District(this.name, this.minLevel, this.openCopy);
  final String name;
  final int minLevel;
  final String openCopy;
}

const _districts = [
  _District('Foundation', 1, 'Ground cleared. You started.'),
  _District('Quiet Block', 2, 'A place to steady yourself.'),
  _District('Harbor', 3, 'Room for harder days.'),
  _District('Lookout', 5, 'Longer view of your progress.'),
  _District('Landmark', 8, 'A mark of sustained recovery.'),
];
