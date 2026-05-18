import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AuthService _authService = AuthService();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://kuafor-019f.onrender.com/api',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<Options> _options() async {
    final token = await _authService.getToken();
    return Options(headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  Future<void> initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'kuafor_channel',
      'Kuaför Bildirimleri',
      channelDescription: 'Randevu ve salon bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotifications.show(id, title, body, notificationDetails,
        payload: payload);
  }

  Future<List<dynamic>> getUserNotifications(int userId) async {
    try {
      final response = await _dio.get(
        '/Notification/user/$userId',
        options: await _options(),
      );
      if (response.statusCode == 200) return response.data as List<dynamic>;
      return [];
    } on DioException catch (e) {
      print('getUserNotifications hatası: ${e.response?.data ?? e.message}');
      return [];
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await _dio.put(
        '/Notification/$notificationId/read',
        options: await _options(),
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } on DioException catch (e) {
      print('markAsRead hatası: ${e.response?.data ?? e.message}');
      return false;
    }
  }

  Future<bool> markAllAsRead(int userId) async {
    try {
      final response = await _dio.put(
        '/Notification/user/$userId/read-all',
        options: await _options(),
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } on DioException catch (e) {
      print('markAllAsRead hatası: ${e.response?.data ?? e.message}');
      return false;
    }
  }
}