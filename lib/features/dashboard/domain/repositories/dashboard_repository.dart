import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../entities/dashboard_stats_entity.dart';
import '../entities/activity_entity.dart';
import '../../data/repositories/dashboard_repository_impl.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(); // Later we can inject the datasource
});

abstract class DashboardRepository {
  Future<DashboardStatsEntity> getDashboardStats();
  Future<List<ActivityEntity>> getRecentActivities();
}
