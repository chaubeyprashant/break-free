import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/entities/activity_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardState {
  final DashboardStatsEntity stats;
  final List<ActivityEntity> recentActivities;

  DashboardState({
    required this.stats,
    required this.recentActivities,
  });
}

final dashboardProvider = AsyncNotifierProvider<DashboardNotifier, DashboardState>(() {
  return DashboardNotifier();
});

class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    return _fetchDashboardData();
  }

  Future<DashboardState> _fetchDashboardData() async {
    final repository = ref.read(dashboardRepositoryProvider);
    
    // Fetch both simultaneously
    final results = await Future.wait([
      repository.getDashboardStats(),
      repository.getRecentActivities(),
    ]);

    return DashboardState(
      stats: results[0] as DashboardStatsEntity,
      recentActivities: results[1] as List<ActivityEntity>,
    );
  }

  /// Re-reads local storage while keeping the current data on screen, so
  /// checking in or logging a slip updates the numbers without a spinner.
  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _fetchDashboardData());
  }
}
