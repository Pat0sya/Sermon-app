import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sermon_mobile/features/auth/data/auth_state_controller.dart';
import 'package:sermon_mobile/features/servers/presentation/widgets/section_title.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/server_presence.dart';

import '../data/server_details_repository.dart';
import '../domain/server_threshold_model.dart';
import 'widgets/metric_chart.dart';

class ServerDetailsScreen extends ConsumerStatefulWidget {
  final int serverId;

  const ServerDetailsScreen({super.key, required this.serverId});

  @override
  ConsumerState<ServerDetailsScreen> createState() =>
      _ServerDetailsScreenState();
}

class _ServerDetailsScreenState extends ConsumerState<ServerDetailsScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      ref.invalidate(serverByIdProvider(widget.serverId));
      ref.invalidate(currentMetricsProvider(widget.serverId));
      ref.invalidate(cpuHistoryProvider(widget.serverId));
      ref.invalidate(ramHistoryProvider(widget.serverId));
      ref.invalidate(diskHistoryProvider(widget.serverId));
      ref.invalidate(serverThresholdsProvider(widget.serverId));
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
        return AppColors.danger;
      case 'warning':
        return AppColors.warning;
      case 'normal':
        return AppColors.success;
      case 'offline':
        return AppColors.neutral;
      default:
        return AppColors.neutral;
    }
  }

  String _statusLabel(String status) {
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

  Color _presenceColor(dynamic lastSeenAt) {
    switch (getServerPresence(lastSeenAt)) {
      case ServerPresenceStatus.online:
        return AppColors.success;
      case ServerPresenceStatus.offline:
        return AppColors.danger;
      case ServerPresenceStatus.unknown:
        return AppColors.neutral;
    }
  }

  String _presenceLabel(dynamic lastSeenAt) {
    switch (getServerPresence(lastSeenAt)) {
      case ServerPresenceStatus.online:
        return 'Онлайн';
      case ServerPresenceStatus.offline:
        return 'Офлайн';
      case ServerPresenceStatus.unknown:
        return 'Нет данных';
    }
  }

  String _formatLastSeen(dynamic lastSeenAt) {
    if (lastSeenAt == null) return 'Нет данных';

    DateTime? seenAt;

    if (lastSeenAt is String) {
      seenAt = DateTime.tryParse(lastSeenAt)?.toLocal();
    } else if (lastSeenAt is int) {
      seenAt = DateTime.fromMillisecondsSinceEpoch(lastSeenAt * 1000).toLocal();
    }

    if (seenAt == null) return 'Нет данных';
    return formatDate(seenAt);
  }

  Future<void> _showThresholdsDialog(
    BuildContext context,
    WidgetRef ref,
    List<ServerThresholdModel> thresholds,
  ) async {
    ServerThresholdModel? findThreshold(String metricType) {
      try {
        return thresholds.firstWhere((e) => e.metricType == metricType);
      } catch (_) {
        return null;
      }
    }

    final cpu = findThreshold('cpu');
    final ram = findThreshold('ram');
    final disk = findThreshold('disk');

    final cpuWarn = TextEditingController(
      text: cpu?.warningValue.toString() ?? '80',
    );
    final cpuCrit = TextEditingController(
      text: cpu?.criticalValue.toString() ?? '90',
    );
    final ramWarn = TextEditingController(
      text: ram?.warningValue.toString() ?? '80',
    );
    final ramCrit = TextEditingController(
      text: ram?.criticalValue.toString() ?? '90',
    );
    final diskWarn = TextEditingController(
      text: disk?.warningValue.toString() ?? '85',
    );
    final diskCrit = TextEditingController(
      text: disk?.criticalValue.toString() ?? '95',
    );

    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Настройка порогов'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _thresholdFieldGroup('CPU', cpuWarn, cpuCrit),
                    const SizedBox(height: 12),
                    _thresholdFieldGroup('RAM', ramWarn, ramCrit),
                    const SizedBox(height: 12),
                    _thresholdFieldGroup('Disk', diskWarn, diskCrit),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final cpuW = int.tryParse(cpuWarn.text.trim());
                          final cpuC = int.tryParse(cpuCrit.text.trim());
                          final ramW = int.tryParse(ramWarn.text.trim());
                          final ramC = int.tryParse(ramCrit.text.trim());
                          final diskW = int.tryParse(diskWarn.text.trim());
                          final diskC = int.tryParse(diskCrit.text.trim());

                          final values = [cpuW, cpuC, ramW, ramC, diskW, diskC];
                          if (values.any((v) => v == null)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Введите корректные числа'),
                              ),
                            );
                            return;
                          }

                          if (!(cpuW! < cpuC! &&
                              ramW! < ramC! &&
                              diskW! < diskC!)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Warning должен быть меньше Critical',
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() => isSaving = true);

                          try {
                            await ref
                                .read(serverDetailsRepositoryProvider)
                                .updateServerThreshold(
                                  serverId: widget.serverId,
                                  metricType: 'cpu',
                                  warningValue: cpuW,
                                  criticalValue: cpuC,
                                );
                            await ref
                                .read(serverDetailsRepositoryProvider)
                                .updateServerThreshold(
                                  serverId: widget.serverId,
                                  metricType: 'ram',
                                  warningValue: ramW,
                                  criticalValue: ramC,
                                );
                            await ref
                                .read(serverDetailsRepositoryProvider)
                                .updateServerThreshold(
                                  serverId: widget.serverId,
                                  metricType: 'disk',
                                  warningValue: diskW,
                                  criticalValue: diskC,
                                );

                            ref.invalidate(
                              serverThresholdsProvider(widget.serverId),
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Пороги обновлены'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Ошибка: $e')),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() => isSaving = false);
                            }
                          }
                        },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _thresholdFieldGroup(
    String title,
    TextEditingController warningController,
    TextEditingController criticalController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: warningController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Warning'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: criticalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Critical'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final serverAsync = ref.watch(serverByIdProvider(widget.serverId));
    final currentMetricsAsync = ref.watch(
      currentMetricsProvider(widget.serverId),
    );
    final cpuHistoryAsync = ref.watch(cpuHistoryProvider(widget.serverId));
    final ramHistoryAsync = ref.watch(ramHistoryProvider(widget.serverId));
    final diskHistoryAsync = ref.watch(diskHistoryProvider(widget.serverId));
    final thresholdsAsync = ref.watch(
      serverThresholdsProvider(widget.serverId),
    );

    final authState = ref.watch(authStateControllerProvider);
    final currentUser = authState.asData?.value;
    final isAdmin = currentUser?.role == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Карточка сервера')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(serverByIdProvider(widget.serverId));
          ref.invalidate(currentMetricsProvider(widget.serverId));
          ref.invalidate(cpuHistoryProvider(widget.serverId));
          ref.invalidate(ramHistoryProvider(widget.serverId));
          ref.invalidate(diskHistoryProvider(widget.serverId));
          ref.invalidate(serverThresholdsProvider(widget.serverId));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            serverAsync.when(
              data: (server) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.dns_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  server.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  server.host,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
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
                                server.status,
                              ).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _statusLabel(server.status),
                              style: TextStyle(
                                color: _statusColor(server.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ServerInfoChip(
                            icon: Icons.memory_outlined,
                            label: server.os,
                          ),
                          _ServerInfoChip(
                            icon: Icons.power_settings_new,
                            label: server.isActive ? 'Активен' : 'Отключён',
                          ),
                          _ServerInfoChip(
                            icon: Icons.radio_button_checked,
                            label:
                                'Агент: ${_presenceLabel(server.lastSeenAt)}',
                            dotColor: _presenceColor(server.lastSeenAt),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Последняя активность: ${_formatLastSeen(server.lastSeenAt)}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      if (server.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          server.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Ошибка загрузки сервера: $e'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            currentMetricsAsync.when(
              data: (metrics) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        title: 'Текущие метрики',
                        subtitle: 'Текущая загрузка CPU, RAM и диска',
                      ),
                      const SizedBox(height: 14),
                      _MetricProgressCard(
                        label: 'CPU',
                        value: metrics.cpuUsage,
                        color: AppColors.primary,
                        icon: Icons.memory_outlined,
                      ),
                      const SizedBox(height: 12),
                      _MetricProgressCard(
                        label: 'RAM',
                        value: metrics.ramUsage,
                        color: Colors.blue,
                        icon: Icons.developer_board_outlined,
                      ),
                      const SizedBox(height: 12),
                      _MetricProgressCard(
                        label: 'Disk',
                        value: metrics.diskUsage,
                        color: AppColors.warning,
                        icon: Icons.storage_outlined,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Обновлено: ${formatDate(metrics.collectedAt)}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Ошибка загрузки метрик: $e'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            thresholdsAsync.when(
              data: (thresholds) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Пороги сервера',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (isAdmin)
                            ElevatedButton(
                              onPressed: () => _showThresholdsDialog(
                                context,
                                ref,
                                thresholds,
                              ),
                              child: const Text('Настроить'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (thresholds.isEmpty)
                        const Text('Нет данных по порогам')
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: thresholds
                              .map(
                                (t) => _ServerInfoChip(
                                  icon: Icons.tune_outlined,
                                  label:
                                      '${t.metricType.toUpperCase()}: ${t.warningValue}% / ${t.criticalValue}%',
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Ошибка загрузки порогов: $e'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            cpuHistoryAsync.when(
              data: (items) => MetricChart(
                title: 'График CPU',
                items: items,
                color: AppColors.primary,
              ),
              loading: () => const _ChartLoadingCard(title: 'График CPU'),
              error: (e, _) => _ChartErrorCard(title: 'График CPU', error: e),
            ),
            const SizedBox(height: 16),
            ramHistoryAsync.when(
              data: (items) => MetricChart(
                title: 'График RAM',
                items: items,
                color: Colors.blue,
              ),
              loading: () => const _ChartLoadingCard(title: 'График RAM'),
              error: (e, _) => _ChartErrorCard(title: 'График RAM', error: e),
            ),
            const SizedBox(height: 16),
            diskHistoryAsync.when(
              data: (items) => MetricChart(
                title: 'График Disk',
                items: items,
                color: AppColors.warning,
              ),
              loading: () => const _ChartLoadingCard(title: 'График Disk'),
              error: (e, _) => _ChartErrorCard(title: 'График Disk', error: e),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricProgressCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _MetricProgressCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = (value.clamp(0, 100)) / 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${value.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: 10,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? dotColor;

  const _ServerInfoChip({
    required this.icon,
    required this.label,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
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
          if (dotColor != null) ...[
            Icon(Icons.circle, size: 9, color: dotColor),
            const SizedBox(width: 6),
          ] else ...[
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ChartLoadingCard extends StatelessWidget {
  final String title;

  const _ChartLoadingCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 180,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title),
            const SizedBox(height: 12),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _ChartErrorCard extends StatelessWidget {
  final String title;
  final Object error;

  const _ChartErrorCard({required this.title, required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('$title: ошибка $error'),
      ),
    );
  }
}
