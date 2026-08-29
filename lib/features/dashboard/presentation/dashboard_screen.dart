import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:break_free/core/data/activity_log_repository.dart';
import 'package:break_free/core/data/check_in_repository.dart';
import 'package:break_free/core/models/activity_event.dart';
import 'package:break_free/core/providers/game_provider.dart';
import 'package:break_free/features/gamification/presentation/level_up_overlay.dart';

import '../domain/entities/dashboard_stats_entity.dart';
import '../domain/entities/activity_entity.dart';
import 'providers/dashboard_provider.dart';
import 'widgets/stat_card.dart';
import 'widgets/progress_chart.dart';
import 'widgets/activity_list_item.dart';

/// Reward for completing a day. Levelling costs `level * 100` XP, so this is
/// roughly five clean days to reach level 2.
const int _checkInXp = 20;
const int _checkInCoins = 5;

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isCheckingIn = false;

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 24),
                      dashboardState.when(
                        data: (data) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCheckInCard(context, data.stats),
                            const SizedBox(height: 12),
                            _buildSlipLink(context),
                            const SizedBox(height: 24),
                            _buildStatsGrid(context, data.stats),
                            const SizedBox(height: 24),
                            ProgressChart(weeklyData: data.stats.weeklyProgressXP),
                            const SizedBox(height: 24),
                            _buildRecentActivities(context, data.recentActivities),
                            // Clearance for the floating Panic Button.
                            const SizedBox(height: 88),
                          ],
                        ),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, stack) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text('Error: $err', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildNavBar(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/panic'),
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
        icon: const Icon(Icons.warning_rounded),
        label: const Text('Panic Button'),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
    );
  }

  /// The daily action. Everything else on this screen is a consequence of it.
  Widget _buildCheckInCard(BuildContext context, DashboardStatsEntity stats) {
    final colorScheme = Theme.of(context).colorScheme;

    if (stats.hasCheckedInToday) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Checked in today',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '+$_checkInXp XP earned. See you tomorrow.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How did today go?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check in to keep your streak moving.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.85),
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isCheckingIn ? null : _handleCheckIn,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.onPrimary,
                foregroundColor: colorScheme.primary,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isCheckingIn
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: const Text('I stayed on track today'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  /// Deliberately quiet: logging a slip should never feel like a dare.
  Widget _buildSlipLink(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _openRelapseFlow,
        icon: Icon(
          Icons.refresh_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        label: Text(
          'Had a slip? Log it',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
      ),
    );
  }

  Future<void> _handleCheckIn() async {
    setState(() => _isCheckingIn = true);

    final checkIns = context.read<CheckInRepository>();
    final activityLog = context.read<ActivityLogRepository>();
    final game = context.read<GameProvider>();

    try {
      final recorded = await checkIns.recordCheckIn(
        when: DateTime.now(),
        xp: _checkInXp,
      );
      if (!recorded) return; // Already checked in today; never award twice.

      final levelledUp = await game.addXp(_checkInXp, coinBonus: _checkInCoins);
      await activityLog.record(
        ActivityEvent.now(
          type: ActivityEvent.checkIn,
          title: 'Checked in',
          description: 'Stayed on track (+$_checkInXp XP)',
        ),
      );
      if (levelledUp) {
        await activityLog.record(
          ActivityEvent.now(
            type: ActivityEvent.achievement,
            title: 'Level Up!',
            description: 'Reached level ${game.progress.level} — ${game.progress.levelTitle}',
          ),
        );
      }

      await ref.read(dashboardProvider.notifier).refresh();
      if (!mounted) return;

      if (levelledUp) {
        await _showLevelUp(game);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nice work. +$_checkInXp XP'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  Future<void> _showLevelUp(GameProvider game) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      pageBuilder: (dialogContext, animation, secondaryAnimation) => LevelUpOverlay(
        newLevel: game.progress.level,
        levelTitle: game.progress.levelTitle,
        onDismiss: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  Future<void> _openRelapseFlow() async {
    await context.push('/relapse');
    if (!mounted) return;
    await ref.read(dashboardProvider.notifier).refresh();
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back,',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            Text(
              'Hero', // Ideally fetch from AuthProvider
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('🦸', style: TextStyle(fontSize: 28)),
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildStatsGrid(BuildContext context, DashboardStatsEntity stats) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        StatCard(
          title: 'Current Streak',
          value: _formatStreak(stats),
          icon: Icons.local_fire_department_rounded,
          color: Colors.orange,
        ),
        StatCard(
          title: 'Total Check-ins',
          value: '${stats.totalCheckIns}',
          icon: Icons.check_circle_rounded,
          color: Colors.green,
        ),
        StatCard(
          title: 'Shields',
          value: '${stats.shieldsAvailable}',
          icon: Icons.shield_rounded,
          color: Colors.blue,
        ),
        StatCard(
          title: 'Coins',
          value: '${stats.totalCoins}',
          icon: Icons.monetization_on_rounded,
          color: Colors.amber,
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  /// Day one is counted in hours — "0 Days" is the wrong thing to show
  /// someone who is a few hours into this.
  String _formatStreak(DashboardStatsEntity stats) {
    if (stats.currentStreak < 1) {
      final hours = stats.currentStreakHours;
      return hours == 1 ? '1 Hour' : '$hours Hours';
    }
    return stats.currentStreak == 1 ? '1 Day' : '${stats.currentStreak} Days';
  }

  Widget _buildRecentActivities(
    BuildContext context,
    List<ActivityEntity> activities,
  ) {
    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text(
          'Your check-ins and milestones will show up here.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...activities.map((activity) => ActivityListItem(activity: activity)),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        onDestinationSelected: (index) {
          if (index == 0) return;
          if (index == 1) context.push('/city');
          if (index == 2) context.push('/reflection');
          if (index == 3) context.push('/settings');
        },
        selectedIndex: 0,
        elevation: 0,
        height: 70,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.location_city_rounded), label: 'City'),
          NavigationDestination(icon: Icon(Icons.book_rounded), label: 'Journal'),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}
