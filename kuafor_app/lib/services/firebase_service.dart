import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options.dart';
import 'notification_service.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background message: ${message.notification?.title}');
}

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    try {
      // Firebase'i başlat
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Background handler'ı kaydet
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Bildirim izni iste
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('Notification permission: ${settings.authorizationStatus}');

      // FCM Token al
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        print('FCM Token: $_fcmToken');
        // Bu token'ı backend'e kaydet
      }

      // Token değişikliklerini dinle
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('FCM Token refreshed: $newToken');
        // Backend'e yeni token'ı gönder
      });

      // Foreground mesajlarını dinle
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Bildirime tıklanınca
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Uygulama kapalıyken gelen bildirim ile açıldıysa
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization error: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('📨 Foreground message: ${message.notification?.title}');
    
    // Local notification göster
    if (message.notification != null) {
      NotificationService().showNotification(
        id: message.hashCode,
        title: message.notification!.title ?? 'Bildirim',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('📱 Message opened app: ${message.notification?.title}');
    // İlgili sayfaya yönlendir
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    print('✅ Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    print('❌ Unsubscribed from topic: $topic');
  }
}
