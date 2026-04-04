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
      final response = await _dio.post('/Auth/login',
          data: {'email': email, 'password': password});
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
    String? salonName,
    String? salonAddress,
  }) async {
    try {
      final data = {
        'fullName': fullName,
        'email':    email,
        'password': password,
        'role':     role,
        if (salonName    != null) 'salonName':    salonName,
        if (salonAddress != null) 'salonAddress': salonAddress,
      };

      final response = await _dio.post('/Auth/register', data: data);
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
      final response = await _dio.post('/Auth/forgot-password',
          data: {'email': email});
      if (response.statusCode == 200 && response.data['message'] != null) {
        return response.data['message'].toString();
      }
      return 'İşlem tamamlandı.';
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return 'Bir hata oluştu.';
    } catch (e) {
      return 'Bir hata oluştu.';
    }
  }

  Future<Map<String, dynamic>?> getUserInfo(String token) async {
    try {
      final response = await _dio.get('/Users/me',
          options: Options(
              headers: {'Authorization': 'Bearer $token'}));
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final role = data['Role'] ?? data['role'] ?? '';
        return {
          'id':      data['Id']      ?? data['id']      ?? 0,
          'email':   data['Email']   ?? data['email']   ?? '',
          'name':    data['FullName'] ?? data['fullName'] ?? data['name'] ??
              (data['email']?.toString().split('@').first ?? 'Kullanıcı'),
          'role':    role,
          'message': data['Message'] ?? data['message'] ?? '',
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
      final response = await _dio.put('/Users/update',
          data: {'fullName': fullName, 'password': password},
          options: Options(
              headers: {'Authorization': 'Bearer $token'}));
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