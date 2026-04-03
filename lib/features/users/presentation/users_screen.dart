import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sermon_mobile/core/utils/app_snackbar.dart';
import 'package:sermon_mobile/core/utils/error_message.dart';
import 'package:sermon_mobile/features/servers/presentation/widgets/empty_state_view.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../data/user_repository.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.primary;
      case 'operator':
        return AppColors.warning;
      default:
        return AppColors.neutral;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Администратор';
      case 'operator':
        return 'Оператор';
      default:
        return role;
    }
  }

  Color _activeColor(bool isActive) {
    return isActive ? AppColors.success : AppColors.neutral;
  }

  String _activeLabel(bool isActive) {
    return isActive ? 'Активен' : 'Отключён';
  }

  Color _passwordStateColor(bool mustChangePassword) {
    return mustChangePassword ? AppColors.warning : AppColors.success;
  }

  String _passwordStateLabel(bool mustChangePassword) {
    return mustChangePassword ? 'Смена пароля требуется' : 'Пароль подтверждён';
  }

  Future<void> _showResetPasswordDialog(
    BuildContext context,
    WidgetRef ref,
    int userId,
  ) async {
    final passwordController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Сбросить пароль'),
              content: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Новый временный пароль',
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
                                .read(userRepositoryProvider)
                                .resetPassword(
                                  userId: userId,
                                  newPassword: passwordController.text.trim(),
                                );

                            ref.invalidate(usersProvider);

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Пароль сброшен')),
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
                  child: const Text('Сбросить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCreateUserDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'operator';
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Добавить пользователя'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'Логин'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Временный пароль',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Роль'),
                      items: const [
                        DropdownMenuItem(
                          value: 'operator',
                          child: Text('Оператор'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Администратор'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedRole = value;
                          });
                        }
                      },
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
                                .read(userRepositoryProvider)
                                .createUser(
                                  username: usernameController.text.trim(),
                                  password: passwordController.text.trim(),
                                  role: selectedRole,
                                );

                            ref.invalidate(usersProvider);

                            if (context.mounted) {
                              Navigator.pop(context);
                              AppSnackbar.success(
                                context,
                                'Пользователь создан',
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              SnackBar(content: Text(getErrorMessage(e)));
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return usersAsync.when(
      data: (users) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(usersProvider);
            await ref.read(usersProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateUserDialog(context, ref),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Добавить пользователя'),
                ),
              ),
              const SizedBox(height: 16),
              if (users.isEmpty)
                const EmptyStateView(
                  icon: Icons.people_outline,
                  title: 'Пользователей нет',
                  subtitle: 'Добавьте оператора или администратора.',
                )
              else
                ...users.map(
                  (user) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
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
                                    color: _roleColor(
                                      user.role,
                                    ).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    user.role == 'admin'
                                        ? Icons.admin_panel_settings_outlined
                                        : Icons.support_agent_outlined,
                                    color: _roleColor(user.role),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.username,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Создан: ${formatDate(user.createdAt)}',
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
                                    color: _roleColor(
                                      user.role,
                                    ).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _roleLabel(user.role),
                                    style: TextStyle(
                                      color: _roleColor(user.role),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _UserInfoChip(
                                  icon: Icons.verified_user_outlined,
                                  label: _activeLabel(user.isActive),
                                  accentColor: _activeColor(user.isActive),
                                ),
                                _UserInfoChip(
                                  icon: Icons.lock_reset_outlined,
                                  label: _passwordStateLabel(
                                    user.mustChangePassword,
                                  ),
                                  accentColor: _passwordStateColor(
                                    user.mustChangePassword,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _showResetPasswordDialog(
                                    context,
                                    ref,
                                    user.id,
                                  ),
                                  child: const Text('Сбросить пароль'),
                                ),
                                if (user.isActive)
                                  OutlinedButton(
                                    onPressed: () async {
                                      try {
                                        await ref
                                            .read(userRepositoryProvider)
                                            .deactivateUser(user.id);
                                        ref.invalidate(usersProvider);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Пользователь деактивирован',
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
                                              content: Text(getErrorMessage(e)),
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
                                            .read(userRepositoryProvider)
                                            .activateUser(user.id);
                                        ref.invalidate(usersProvider);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Пользователь активирован',
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
                                              content: Text(getErrorMessage(e)),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text('Включить'),
                                  ),
                              ],
                            ),
                          ],
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

class _UserInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;

  const _UserInfoChip({
    required this.icon,
    required this.label,
    required this.accentColor,
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
          Icon(icon, size: 16, color: accentColor),
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
