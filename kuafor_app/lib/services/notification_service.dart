import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:5069/api',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Local notification'ı başlat
  Future<void> initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
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

  // Local bildirim göster (Firebase foreground mesajları için)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
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

  // Kullanıcının bildirimlerini API'den getir
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

  // Bildirimi okundu olarak işaretle
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