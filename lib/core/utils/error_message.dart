import 'package:dio/dio.dart';

String getErrorMessage(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    String? backendError;
    if (data is Map<String, dynamic>) {
      final raw = data['error'];
      if (raw is String && raw.trim().isNotEmpty) {
        backendError = raw;
      }
    }

    switch (statusCode) {
      case 400:
        return backendError ?? 'Некорректный запрос';
      case 401:
        return 'Неверный логин или пароль';
      case 403:
        return backendError ?? 'Недостаточно прав для выполнения операции';
      case 404:
        return backendError ?? 'Данные не найдены';
      case 409:
        return backendError ?? 'Конфликт данных';
      case 500:
        return 'Внутренняя ошибка сервера';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Сервер не отвечает';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Нет соединения с сервером';
    }

    return backendError ?? 'Ошибка сети';
  }

  return error.toString();
}
