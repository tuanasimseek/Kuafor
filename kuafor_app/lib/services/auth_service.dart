import 'package:dio/dio.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:5069/api', // iOS simülatör için
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  // 🔹 Login
  Future<String?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/Auth/login',
        data: {'email': email, 'password': password},
      );

      print('🔹 Login response: ${response.data}');

      if (response.statusCode == 200 && response.data['token'] != null) {
        return response.data['token'];
      } else {
        print('Login başarısız: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Login hatası: $e');
      return null;
    }
  }

  // 🔹 Kayıt isteği
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        '/Auth/register',
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      print('🔹 Register response: ${response.data}');

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Register başarısız: ${response.data}');
        return false;
      }
    } catch (e) {
      print('Register hatası: $e');
      return false;
    }
  }

  // 🔹 Kullanıcı bilgisi
  Future<Map<String, dynamic>?> getUserInfo(String token) async {
    try {
      final response = await _dio.get(
        '/Users/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('🔹 /Users/me yanıtı: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        // Backend'te sadece email ve message dönüyor, Flutter tarafı için genişletelim
        return {
          'email': data['email'] ?? '',
          'name': data['email']?.split('@').first ?? 'Kullanıcı',
          'role': data['role'] ?? 'admin', // varsayılan admin
          'message': data['message'] ?? '',
        };
      } else {
        print('Kullanıcı bilgisi alınamadı, durum: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Kullanıcı bilgisi alınamadı: $e');
      return null;
    }
  }
}
