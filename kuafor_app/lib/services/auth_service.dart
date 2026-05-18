import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://kuafor-019f.onrender.com/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> login(String identifier, String password) async {
    try {
      final response = await _dio.post(
        '/Auth/login',
        data: {
          'identifier': identifier,
          'email': identifier,
          'password': password,
        },
      );

      if (response.statusCode == 200 &&
          response.data['token'] != null) {
        final token = response.data['token'].toString();
        await saveToken(token);
        return token;
      }

      return null;
    } on DioException catch (e) {
      print('LOGIN ERROR TYPE: ${e.type}');
      print('LOGIN STATUS: ${e.response?.statusCode}');
      print('LOGIN DATA: ${e.response?.data}');
      print('LOGIN MESSAGE: ${e.message}');
      print('LOGIN URL: ${e.requestOptions.uri}');
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
    String? username,
    String? salonName,
    String? salonAddress,
    double? salonLatitude,
    double? salonLongitude,
  }) async {
    try {
      final data = <String, dynamic>{
        'fullName': fullName,
        'email': email,
        if (username != null && username.isNotEmpty) 'username': username,
        'password': password,
        'role': role,
        if (salonName != null) 'salonName': salonName,
        if (salonAddress != null) 'salonAddress': salonAddress,
        if (salonLatitude != null) 'salonLatitude': salonLatitude,
        if (salonLongitude != null) 'salonLongitude': salonLongitude,
      };

      final response = await _dio.post(
        '/Auth/register',
        data: data,
      );

      print("REGISTER STATUS: ${response.statusCode}");
      print("REGISTER BODY: ${response.data}");

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } on DioException catch (e) {
      print('REGISTER ERROR TYPE: ${e.type}');
      print('REGISTER STATUS: ${e.response?.statusCode}');
      print('REGISTER DATA: ${e.response?.data}');
      print('REGISTER MESSAGE: ${e.message}');
      print('REGISTER URL: ${e.requestOptions.uri}');
      return false;
    } catch (e) {
      print('Register genel hata: $e');
      return false;
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn(scopes: ['email', 'profile']).signIn();
      if (googleUser == null) return null;
      return _socialLogin(
        provider: 'Google',
        providerId: googleUser.id,
        email: googleUser.email,
        fullName: googleUser.displayName ?? googleUser.email.split('@').first,
      );
    } catch (e) {
      print('Google giriş hatası: $e');
      return null;
    }
  }

  Future<String?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final email = credential.email;
      if (email == null || email.isEmpty) {
        return null;
      }
      final fullName = [
        credential.givenName,
        credential.familyName,
      ].whereType<String>().where((p) => p.isNotEmpty).join(' ');
      return _socialLogin(
        provider: 'Apple',
        providerId: credential.userIdentifier ?? email,
        email: email,
        fullName: fullName.isEmpty ? email.split('@').first : fullName,
      );
    } catch (e) {
      print('Apple giriş hatası: $e');
      return null;
    }
  }

  Future<String?> _socialLogin({
    required String provider,
    required String providerId,
    required String email,
    required String fullName,
  }) async {
    try {
      final response = await _dio.post('/Auth/social-login', data: {
        'provider': provider,
        'providerId': providerId,
        'email': email,
        'fullName': fullName,
      });
      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'].toString();
        await saveToken(token);
        return token;
      }
    } catch (e) {
      print('$provider sosyal giriş API hatası: $e');
    }
    return null;
  }

  Future<String?> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/Auth/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode == 200 &&
          response.data['message'] != null) {
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
      final response = await _dio.get(
        '/Users/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 &&
          response.data != null) {
        final data = response.data;
        final role = data['Role'] ?? data['role'] ?? '';

        return {
          'id': data['Id'] ?? data['id'] ?? 0,
          'email': data['Email'] ?? data['email'] ?? '',
          'name': data['FullName'] ??
              data['fullName'] ??
              data['name'] ??
              (data['email']
                      ?.toString()
                      .split('@')
                      .first ??
                  'Kullanıcı'),
          'role': role,
          'message':
              data['Message'] ?? data['message'] ?? '',
          'profileImageUrl':
              data['ProfileImageUrl'] ??
                  data['profileImageUrl'] ??
                  '',
        };
      }

      return null;
    } on DioException catch (e) {
      print(
          'Kullanıcı bilgisi Dio hatası: ${e.response?.data ?? e.message}');
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
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      print(
          'Update profile Dio hatası: ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      print('Update profile genel hata: $e');
      return false;
    }
  }

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

      if (response.statusCode == 200 &&
          response.data['profileImageUrl'] != null) {
        return response.data['profileImageUrl'].toString();
      }

      return null;
    } on DioException catch (e) {
      print(
          'Upload photo Dio hatası: ${e.response?.data ?? e.message}');
      return null;
    } catch (e) {
      print('Upload photo genel hata: $e');
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    await _storage.write(
      key: 'jwt_token',
      value: token,
    );
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }
}
