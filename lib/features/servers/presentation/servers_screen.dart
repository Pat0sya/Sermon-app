import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sermon_mobile/core/utils/error_message.dart';
import 'package:sermon_mobile/features/auth/data/auth_state_controller.dart';
import 'package:sermon_mobile/features/servers/presentation/widgets/empty_state_view.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/server_presence.dart';

import '../data/server_repository.dart';
import '../domain/agent_token_response.dart';
import '../domain/server_model.dart';
import 'server_details_screen.dart';

class ServersScreen extends ConsumerStatefulWidget {
  const ServersScreen({super.key});

  @override
  ConsumerState<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends ConsumerState<ServersScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      ref.invalidate(serversProvider);
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
      case 'critical':
        return 'Критично';
      case 'warning':
        return 'Предупреждение';
      case 'normal':
        return 'Норма';
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

  Future<void> _showAgentTokenDialog(
    BuildContext context, {
    required String title,
    required String token,
  }) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Сохраните token. Он нужен для настройки агента.'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  token,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: token));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Token скопирован')),
                  );
                }
              },
              child: const Text('Копировать'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCreateServerDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    final hostController = TextEditingController();
    final osController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Добавить сервер'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Имя сервера',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hostController,
                      decoration: const InputDecoration(labelText: 'IP / Host'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: osController,
                      decoration: const InputDecoration(labelText: 'ОС'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Описание'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          try {
                            final result = await ref
                                .read(serverRepositoryProvider)
                                .createServer(
                                  name: nameController.text.trim(),
                                  host: hostController.text.trim(),
                                  os: osController.text.trim(),
                                  description: descriptionController.text
                                      .trim(),
                                );

                            ref.invalidate(serversProvider);

                            if (context.mounted) {
                              Navigator.pop(context);
                              await _showAgentTokenDialog(
                                context,
                                title: 'Сервер создан',
                                token: result.agentToken,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(getErrorMessage(e))),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() => isLoading = false);
                            }
                          }
                        },
                  child: const Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditServerDialog(
    BuildContext context,
    WidgetRef ref,
    ServerModel server,
  ) async {
    final nameController = TextEditingController(text: server.name);
    final hostController = TextEditingController(text: server.host);
    final osController = TextEditingController(text: server.os);
    final descriptionController = TextEditingController(
      text: server.description,
    );
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Редактировать сервер'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Имя сервера',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hostController,
                      decoration: const InputDecoration(labelText: 'IP / Host'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: osController,
                      decoration: const InputDecoration(labelText: 'ОС'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Описание'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          try {
                            await ref
                                .read(serverRepositoryProvider)
                                .updateServer(
                                  id: server.id,
                                  name: nameController.text.trim(),
                                  host: hostController.text.trim(),
                                  os: osController.text.trim(),
                                  description: descriptionController.text
                                      .trim(),
                                );

                            ref.invalidate(serversProvider);

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Сервер обновлён'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(getErrorMessage(e))),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() => isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final serversAsync = ref.watch(serversProvider);
    final authState = ref.watch(authStateControllerProvider);
    final user = authState.asData?.value;
    final isAdmin = user?.role == 'admin';

    return serversAsync.when(
      data: (servers) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(serversProvider);
            await ref.read(serversProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isAdmin) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCreateServerDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить сервер'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (servers.isEmpty)
                const EmptyStateView(
                  icon: Icons.dns_outlined,
                  title: 'Список серверов пуст',
                  subtitle: 'Добавьте первый сервер, чтобы начать мониторинг.',
                )
              else
                ...servers.map(
                  (server) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ServerDetailsScreen(serverId: server.id),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(
                                        0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.dns_outlined,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          server.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
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
                                  _InfoChip(
                                    icon: Icons.memory_outlined,
                                    label: server.os,
                                  ),
                                  _InfoChip(
                                    icon: Icons.power_settings_new,
                                    label: server.isActive
                                        ? 'Активен'
                                        : 'Отключён',
                                  ),
                                  _InfoChip(
                                    icon: Icons.radio_button_checked,
                                    label:
                                        'Агент: ${_presenceLabel(server.lastSeenAt)}',
                                    dotColor: _presenceColor(server.lastSeenAt),
                                  ),
                                ],
                              ),
                              if (server.description.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  server.description,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              if (isAdmin)
                                Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () => _showEditServerDialog(
                                          context,
                                          ref,
                                          server,
                                        ),
                                        child: const Text('Редактировать'),
                                      ),
                                      OutlinedButton(
                                        onPressed: () async {
                                          try {
                                            final AgentTokenResponse result =
                                                await ref
                                                    .read(
                                                      serverRepositoryProvider,
                                                    )
                                                    .regenerateAgentToken(
                                                      server.id,
                                                    );

                                            if (context.mounted) {
                                              await _showAgentTokenDialog(
                                                context,
                                                title: 'Новый agent token',
                                                token: result.agentToken,
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    getErrorMessage(e),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        child: const Text(
                                          'Перевыпустить token',
                                        ),
                                      ),
                                      if (server.isActive)
                                        OutlinedButton(
                                          onPressed: () async {
                                            try {
                                              await ref
                                                  .read(
                                                    serverRepositoryProvider,
                                                  )
                                                  .deactivateServer(server.id);
                                              ref.invalidate(serversProvider);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Сервер отключён',
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      getErrorMessage(e),
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: const Text('Отключить'),
                                        )
                                      else
                                        OutlinedButton(
                                          onPressed: () async {
                                            try {
                                              await ref
                                                  .read(
                                                    serverRepositoryProvider,
                                                  )
                                                  .activateServer(server.id);
                                              ref.invalidate(serversProvider);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Сервер включён',
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      getErrorMessage(e),
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: const Text('Включить'),
                                        ),
                                    ],
                                  ),
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
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? dotColor;

  const _InfoChip({required this.icon, required this.label, this.dotColor});

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
