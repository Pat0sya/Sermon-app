import '../../incidents/domain/incident_model.dart';
import '../../servers/domain/server_model.dart';

class DashboardModel {
  final int totalServers;
  final int onlineServers;
  final int offlineServers;
  final int warningServers;
  final int criticalServers;
  final int openIncidents;
  final int inProgressIncidents;
  final List<ServerModel> recentServers;
  final List<IncidentModel> recentIncidents;

  DashboardModel({
    required this.totalServers,
    required this.onlineServers,
    required this.offlineServers,
    required this.warningServers,
    required this.criticalServers,
    required this.openIncidents,
    required this.inProgressIncidents,
    required this.recentServers,
    required this.recentIncidents,
  });
}
