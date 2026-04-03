import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sermon_mobile/core/utils/error_message.dart';
import 'package:sermon_mobile/features/servers/presentation/widgets/empty_state_view.dart';

import '../../../core/theme/app_colors.dart';
import '../data/incident_repository.dart';
import 'incident_details_screen.dart';

class IncidentsScreen extends ConsumerStatefulWidget {
  const IncidentsScreen({super.key});

  @override
  ConsumerState<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends ConsumerState<IncidentsScreen> {
  String? selectedStatus;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      ref.invalidate(incidentsProvider(selectedStatus));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.danger;
      case 'in_progress':
        return AppColors.warning;
      case 'closed':
        return AppColors.success;
      default:
        return AppColors.neutral;
    }
  }

  String _statusLabel(String status) {
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

  String _metricLabel(String metricType) {
    switch (metricType) {
      case 'cpu':
        return 'CPU';
      case 'ram':
        return 'RAM';
      case 'disk':
        return 'Disk';
      default:
        return metricType.toUpperCase();
    }
  }

  IconData _metricIcon(String metricType) {
    switch (metricType) {
      case 'cpu':
        return Icons.memory_outlined;
      case 'ram':
        return Icons.developer_board_outlined;
      case 'disk':
        return Icons.storage_outlined;
      default:
        return Icons.warning_amber_outlined;
    }
  }

  Color _metricColor(String metricType) {
    switch (metricType) {
      case 'cpu':
        return AppColors.primary;
      case 'ram':
        return Colors.blue;
      case 'disk':
        return AppColors.warning;
      default:
        return AppColors.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(incidentsProvider(selectedStatus));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: DropdownButtonFormField<String?>(
                borderRadius: BorderRadius.circular(14),
                decoration: const InputDecoration(
                  labelText: 'Статус инцидентов',
                ),
                items: const [
                  DropdownMenuItem<String?>(value: null, child: Text('Все')),
                  DropdownMenuItem<String?>(
                    value: 'open',
                    child: Text('Открыт'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'in_progress',
                    child: Text('В работе'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'closed',
                    child: Text('Закрыт'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value;
                  });
                  ref.invalidate(incidentsProvider(value));
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: incidentsAsync.when(
            data: (incidents) {
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(incidentsProvider(selectedStatus));
                  await ref.read(incidentsProvider(selectedStatus).future);
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (incidents.isEmpty)
                      const EmptyStateView(
                        icon: Icons.task_alt_outlined,
                        title: 'Инцидентов нет',
                        subtitle: 'Сейчас в системе нет активных проблем.',
                      )
                    else
                      ...incidents.map(
                        (incident) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => IncidentDetailsScreen(
                                      incidentId: incident.id,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: _metricColor(
                                              incident.metricType,
                                            ).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: Icon(
                                            _metricIcon(incident.metricType),
                                            color: _metricColor(
                                              incident.metricType,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                incident.server.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${incident.server.host} • ${_metricLabel(incident.metricType)}',
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusColor(
                                              incident.status,
                                            ).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            _statusLabel(incident.status),
                                            style: TextStyle(
                                              color: _statusColor(
                                                incident.status,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      incident.message,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _IncidentInfoChip(
                                          icon: Icons.router_outlined,
                                          label: incident.server.host,
                                        ),
                                        _IncidentInfoChip(
                                          icon: Icons.flag_outlined,
                                          label:
                                              'Порог: ${incident.thresholdValue.toStringAsFixed(1)}%',
                                        ),
                                        _IncidentInfoChip(
                                          icon: Icons.show_chart_outlined,
                                          label:
                                              'Факт: ${incident.actualValue.toStringAsFixed(1)}%',
                                          accentColor: _statusColor(
                                            incident.status,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
                child: Text(
                  getErrorMessage(error),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }
}

class _IncidentInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accentColor;

  const _IncidentInfoChip({
    required this.icon,
    required this.label,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = accentColor ?? AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
