import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sermon_mobile/core/theme/app_colors.dart';
import 'package:sermon_mobile/core/utils/date_utils.dart';
import 'package:sermon_mobile/features/auth/data/auth_state_controller.dart';

import 'package:sermon_mobile/features/servers/presentation/widgets/section_title.dart';

import '../data/incident_repository.dart';

class IncidentDetailsScreen extends ConsumerStatefulWidget {
  final int incidentId;

  const IncidentDetailsScreen({super.key, required this.incidentId});

  @override
  ConsumerState<IncidentDetailsScreen> createState() =>
      _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends ConsumerState<IncidentDetailsScreen> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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

  Future<void> _updateStatus(String status) async {
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(incidentRepositoryProvider)
          .updateStatus(incidentId: widget.incidentId, status: status);

      ref.invalidate(incidentByIdProvider(widget.incidentId));
      ref.invalidate(incidentCommentsProvider(widget.incidentId));
      ref.invalidate(incidentsProvider(null));
      ref.invalidate(incidentsProvider('open'));
      ref.invalidate(incidentsProvider('in_progress'));
      ref.invalidate(incidentsProvider('closed'));

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Статус обновлён')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(incidentRepositoryProvider)
          .addComment(incidentId: widget.incidentId, comment: text);

      _commentController.clear();
      ref.invalidate(incidentCommentsProvider(widget.incidentId));

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Комментарий добавлен')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateControllerProvider);
    final currentUser = authState.asData?.value;
    final isAdmin = currentUser?.role == 'admin';
    final incidentAsync = ref.watch(incidentByIdProvider(widget.incidentId));
    final commentsAsync = ref.watch(
      incidentCommentsProvider(widget.incidentId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Карточка инцидента')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          incidentAsync.when(
            data: (incident) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${incident.server.name} • ${incident.metricType.toUpperCase()}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text('Статус: ${_statusLabel(incident.status)}'),
                    Text('Сообщение: ${incident.message}'),
                    Text(
                      'Порог: ${incident.thresholdValue.toStringAsFixed(1)}',
                    ),
                    Text('Факт: ${incident.actualValue.toStringAsFixed(1)}'),
                    Text('Начало: ${formatDate(incident.startedAt)}'),
                    if (incident.closedAt != null)
                      Text('Закрыт: ${formatDate(incident.closedAt!)}'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _updateStatus('in_progress'),
                          child: const Text('В работу'),
                        ),

                        if (isAdmin)
                          ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => _updateStatus('closed'),
                            child: const Text('Закрыть'),
                          ),

                        ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _updateStatus('open'),
                          child: const Text('Открыть'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Ошибка загрузки инцидента: $e'),
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
                  const SectionTitle(
                    title: 'Комментарии',
                    subtitle: 'Хронология действий по инциденту',
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Введите ваш комментарий...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _addComment,
                      child: const Text('Добавить комментарий'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          commentsAsync.when(
            data: (comments) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Комментарии',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (comments.isEmpty)
                      const Text('Комментариев пока нет')
                    else
                      ...comments.map(
                        (comment) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.user?.username ?? 'Пользователь',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(comment.comment),
                              const SizedBox(height: 4),
                              Text(
                                formatDate(comment.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Divider(),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Ошибка загрузки комментариев: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
