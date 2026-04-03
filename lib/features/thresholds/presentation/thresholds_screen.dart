import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/threshold_repository.dart';
import '../domain/threshold_model.dart';

class ThresholdsScreen extends ConsumerWidget {
  const ThresholdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thresholdsAsync = ref.watch(thresholdsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Пороговые значения')),
      body: thresholdsAsync.when(
        data: (thresholds) {
          if (thresholds.isEmpty) {
            return const Center(child: Text('Порогов нет'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(thresholdsProvider);
              await ref.read(thresholdsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: thresholds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final threshold = thresholds[index];
                return _ThresholdCard(threshold: threshold);
              },
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
      ),
    );
  }
}

class _ThresholdCard extends ConsumerWidget {
  final ThresholdModel threshold;

  const _ThresholdCard({required this.threshold});

  Future<void> _editThreshold(BuildContext context, WidgetRef ref) async {
    final warningController = TextEditingController(
      text: threshold.warningValue.toString(),
    );
    final criticalController = TextEditingController(
      text: threshold.criticalValue.toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Изменить ${threshold.metricType.toUpperCase()}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: warningController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Warning',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: criticalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Critical',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(context, false),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final warning = int.tryParse(
                            warningController.text.trim(),
                          );
                          final critical = int.tryParse(
                            criticalController.text.trim(),
                          );

                          if (warning == null || critical == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Введите числа')),
                            );
                            return;
                          }

                          setState(() => isSaving = true);

                          try {
                            await ref
                                .read(thresholdRepositoryProvider)
                                .updateThreshold(
                                  metricType: threshold.metricType,
                                  warningValue: warning,
                                  criticalValue: critical,
                                );
                            if (context.mounted) {
                              Navigator.pop(context, true);
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

    if (result == true) {
      ref.invalidate(thresholdsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Порог обновлён')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(threshold.metricType.toUpperCase()),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Warning: ${threshold.warningValue}%\nCritical: ${threshold.criticalValue}%',
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _editThreshold(context, ref),
        ),
      ),
    );
  }
}
