import 'package:dio/dio.dart';

class NotificationService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:5069/api',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  Future<List<dynamic>> getUserNotifications(int userId) async {
    try {
      final response = await _dio.get('/Notification/user/$userId');
      if (response.statusCode == 200) return response.data as List<dynamic>;
      return [];
    } on DioException catch (e) {
      print('getUserNotifications hatası: ${e.response?.data ?? e.message}');
      return [];
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await _dio.put('/Notification/$notificationId/read');
      return response.statusCode == 204 || response.statusCode == 200;
    } on DioException catch (e) {
      print('markAsRead hatası: ${e.response?.data ?? e.message}');
      return false;
    }
  }
}