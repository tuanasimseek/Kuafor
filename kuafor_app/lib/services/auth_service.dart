import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:5069/api',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 🔹 Login
  Future<String?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/Auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      print('🔹 Login response: ${response.data}');

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'].toString();
        await saveToken(token);
        return token;
      }

      return null;
    } on DioException catch (e) {
      print('Login Dio hatası: ${e.response?.data ?? e.message}');
      return null;
    } catch (e) {
      print('Login genel hata: $e');
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

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('Register Dio hatası: ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      print('Register genel hata: $e');
      return false;
    }
  }

  // 🔹 Kullanıcı bilgisi
  Future<Map<String, dynamic>?> getUserInfo(String token) async {
    try {
      final response = await _dio.get(
        '/Users/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('🔹 /Users/me yanıtı: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        return {
          'email': data['email'] ?? '',
          'name': data['fullName'] ??
              data['name'] ??
              (data['email']?.toString().split('@').first ?? 'Kullanıcı'),
          'role': data['role'] ?? '',
          'message': data['message'] ?? '',
        };
      }

      return null;
    } on DioException catch (e) {
      print('Kullanıcı bilgisi Dio hatası: ${e.response?.data ?? e.message}');
      return null;
    } catch (e) {
      print('Kullanıcı bilgisi genel hata: $e');
      return null;
    }
  }

  // 🔹 Token kaydet
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  // 🔹 Token oku
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // 🔹 Token sil
  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }
}