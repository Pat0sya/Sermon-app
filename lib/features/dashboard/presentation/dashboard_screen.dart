import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sermon_mobile/core/theme/app_colors.dart';

import '../../../core/utils/server_presence.dart';
import '../../incidents/presentation/incident_details_screen.dart';
import '../../servers/presentation/server_details_screen.dart';
import '../data/dashboard_repository.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      ref.invalidate(dashboardProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'normal':
        return Colors.green;
      case 'offline':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _presenceColor(dynamic lastSeenAt) {
    switch (getServerPresence(lastSeenAt)) {
      case ServerPresenceStatus.online:
        return Colors.green;
      case ServerPresenceStatus.offline:
        return Colors.red;
      case ServerPresenceStatus.unknown:
        return Colors.grey;
    }
  }

  String _incidentStatusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Открыт';
      case 'in_progress':
        return 'В работе';
      case 'closed':
        return 'Закрыт';
      default:
        return status;
    }
  }

  String _serverStatusLabel(String status) {
    switch (status) {
      case 'normal':
        return 'Норма';
      case 'warning':
        return 'Предупреждение';
      case 'critical':
        return 'Критично';
      case 'offline':
        return 'Офлайн';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return dashboardAsync.when(
      data: (dashboard) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardProvider);
            await ref.read(dashboardProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 1100
                    ? 4
                    : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.42,
                children: [
                  _StatCard(
                    title: 'Всего серверов',
                    value: dashboard.totalServers.toString(),
                    icon: Icons.dns,
                  ),
                  _StatCard(
                    title: 'Онлайн',
                    value: dashboard.onlineServers.toString(),
                    icon: Icons.cloud_done,
                  ),
                  _StatCard(
                    title: 'Офлайн',
                    value: dashboard.offlineServers.toString(),
                    icon: Icons.cloud_off,
                  ),
                  _StatCard(
                    title: 'Warning',
                    value: dashboard.warningServers.toString(),
                    icon: Icons.warning_amber,
                  ),
                  _StatCard(
                    title: 'Critical',
                    value: dashboard.criticalServers.toString(),
                    icon: Icons.error_outline,
                  ),
                  _StatCard(
                    title: 'Открытые инциденты',
                    value: dashboard.openIncidents.toString(),
                    icon: Icons.report_problem,
                  ),
                  _StatCard(
                    title: 'В работе',
                    value: dashboard.inProgressIncidents.toString(),
                    icon: Icons.build_circle_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Последние серверы',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (dashboard.recentServers.isEmpty)
                        const Text('Нет данных')
                      else
                        ...dashboard.recentServers.map(
                          (server) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(server.name),
                            subtitle: Text('${server.host} • ${server.os}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: _presenceColor(server.lastSeenAt),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      server.status,
                                    ).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _serverStatusLabel(server.status),
                                    style: TextStyle(
                                      color: _statusColor(server.status),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ServerDetailsScreen(serverId: server.id),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Последние инциденты',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (dashboard.recentIncidents.isEmpty)
                        const Text('Нет данных')
                      else
                        ...dashboard.recentIncidents.map(
                          (incident) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${incident.server.name} • ${incident.metricType.toUpperCase()}',
                            ),
                            subtitle: Text(incident.message),
                            trailing: Text(
                              _incidentStatusLabel(incident.status),
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => IncidentDetailsScreen(
                                    incidentId: incident.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Ошибка: $error'),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  Color _iconBg(String title) {
    if (title.contains('Офлайн')) return AppColors.neutral.withOpacity(0.12);
    if (title.contains('Critical')) return AppColors.danger.withOpacity(0.12);
    if (title.contains('Warning')) return AppColors.warning.withOpacity(0.12);
    if (title.contains('Открытые')) return AppColors.danger.withOpacity(0.12);
    if (title.contains('В работе')) return AppColors.warning.withOpacity(0.12);
    if (title.contains('Онлайн')) return AppColors.success.withOpacity(0.12);
    return AppColors.primary.withOpacity(0.12);
  }

  Color _iconColor(String title) {
    if (title.contains('Офлайн')) return AppColors.neutral;
    if (title.contains('Critical')) return AppColors.danger;
    if (title.contains('Warning')) return AppColors.warning;
    if (title.contains('Открытые')) return AppColors.danger;
    if (title.contains('В работе')) return AppColors.warning;
    if (title.contains('Онлайн')) return AppColors.success;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _iconBg(title),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _iconColor(title)),
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
