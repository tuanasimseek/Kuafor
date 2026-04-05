import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.1.105:5069/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30), // upload için biraz daha uzun
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
    double? salonLatitude,
    double? salonLongitude,
  }) async {
    try {
      final data = <String, dynamic>{
        'fullName': fullName,
        'email':    email,
        'password': password,
        'role':     role,
        if (salonName      != null) 'salonName':      salonName,
        if (salonAddress   != null) 'salonAddress':   salonAddress,
        if (salonLatitude  != null) 'salonLatitude':  salonLatitude,
        if (salonLongitude != null) 'salonLongitude': salonLongitude,
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
      final response =
          await _dio.post('/Auth/forgot-password', data: {'email': email});
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
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final role = data['Role'] ?? data['role'] ?? '';
        return {
          'id':              data['Id']             ?? data['id']             ?? 0,
          'email':           data['Email']          ?? data['email']          ?? '',
          'name':            data['FullName']       ?? data['fullName']       ?? data['name'] ??
              (data['email']?.toString().split('@').first ?? 'Kullanıcı'),
          'role':            role,
          'message':         data['Message']        ?? data['message']        ?? '',
          'profileImageUrl': data['ProfileImageUrl'] ?? data['profileImageUrl'] ?? '',
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
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Update profile Dio hatası: ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      print('Update profile genel hata: $e');
      return false;
    }
  }

  /// Profil fotoğrafı upload eder.
  /// Başarılıysa sunucudan dönen tam URL'yi (http://...) döndürür.
  /// Hata durumunda null döner.
  Future<String?> uploadProfilePhoto({
    required String token,
    required String filePath,
  }) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/Users/upload-photo',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['profileImageUrl'] != null) {
        return response.data['profileImageUrl'].toString();
      }
      return null;
    } on DioException catch (e) {
      print('Upload photo Dio hatası: ${e.response?.data ?? e.message}');
      return null;
    } catch (e) {
      print('Upload photo genel hata: $e');
      return null;
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