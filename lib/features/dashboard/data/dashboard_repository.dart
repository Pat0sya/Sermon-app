import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/server_presence.dart';
import '../../incidents/data/incident_repository.dart';
import '../../servers/data/server_repository.dart';
import '../domain/dashboard_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref);
});

final dashboardProvider = FutureProvider<DashboardModel>((ref) async {
  return ref.read(dashboardRepositoryProvider).loadDashboard();
});

class DashboardRepository {
  final Ref ref;

  DashboardRepository(this.ref);

  Future<DashboardModel> loadDashboard() async {
    final serverRepo = ref.read(serverRepositoryProvider);
    final incidentRepo = ref.read(incidentRepositoryProvider);

    final servers = await serverRepo.getServers();
    final allIncidents = await incidentRepo.getIncidents();
    final openIncidents = await incidentRepo.getIncidents(status: 'open');
    final inProgressIncidents = await incidentRepo.getIncidents(
      status: 'in_progress',
    );

    final onlineServers = servers
        .where(
          (s) => getServerPresence(s.lastSeenAt) == ServerPresenceStatus.online,
        )
        .length;

    final offlineServers = servers
        .where(
          (s) =>
              getServerPresence(s.lastSeenAt) == ServerPresenceStatus.offline,
        )
        .length;

    final warningServers = servers.where((s) => s.status == 'warning').length;
    final criticalServers = servers.where((s) => s.status == 'critical').length;

    final recentServers = servers.take(5).toList();
    final recentIncidents = allIncidents.take(5).toList();

    return DashboardModel(
      totalServers: servers.length,
      onlineServers: onlineServers,
      offlineServers: offlineServers,
      warningServers: warningServers,
      criticalServers: criticalServers,
      openIncidents: openIncidents.length,
      inProgressIncidents: inProgressIncidents.length,
      recentServers: recentServers,
      recentIncidents: recentIncidents,
    );
  }
}
