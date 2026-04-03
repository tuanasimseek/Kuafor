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

  Future<String?> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/Auth/forgot-password',
        data: {
          'email': email,
        },
      );

      print('🔹 Forgot password response: ${response.data}');

      if (response.statusCode == 200 && response.data['message'] != null) {
        return response.data['message'].toString();
      }

      return 'İşlem tamamlandı.';
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      print('Forgot password Dio hatası: ${e.response?.data ?? e.message}');
      return 'Bir hata oluştu.';
    } catch (e) {
      print('Forgot password genel hata: $e');
      return 'Bir hata oluştu.';
    }
  }

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
          'id': data['id'] ?? 0,
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

  Future<bool> updateProfile({
    required String token,
    String? fullName,
    String? password,
  }) async {
    try {
      final response = await _dio.put(
        '/Users/update',
        data: {
          'fullName': fullName,
          'password': password,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('🔹 Update profile response: ${response.data}');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Update profile Dio hatası: ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      print('Update profile genel hata: $e');
      return false;
    }
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }
}