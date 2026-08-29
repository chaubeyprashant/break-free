import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/entities/activity_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardDataSource dataSource;

  DashboardRepositoryImpl({DashboardDataSource? dataSource})
      : dataSource = dataSource ?? DashboardLocalDataSource();

  @override
  Future<DashboardStatsEntity> getDashboardStats() async {
    return dataSource.fetchDashboardStats();
  }

  @override
  Future<List<ActivityEntity>> getRecentActivities() async {
    return dataSource.fetchRecentActivities();
  }
}
