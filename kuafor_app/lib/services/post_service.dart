import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String baseUrl = 'https://kuafor-019f.onrender.com/api';

class PostService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<Options> _authOptions() async {
    final token = await _getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // Tüm gönderileri getir (feed)
  Future<List<Map<String, dynamic>>> getAllPosts() async {
    try {
      final response = await _dio.get('$baseUrl/Posts');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('getAllPosts hata: $e');
      return [];
    }
  }

  // Salona ait gönderileri getir
  Future<List<Map<String, dynamic>>> getPostsBySalon(int salonId) async {
    try {
      final response = await _dio.get('$baseUrl/Posts/salon/$salonId');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('getPostsBySalon hata: $e');
      return [];
    }
  }

  // Gönderi oluştur → postId döner
  Future<int?> createPost({
    required String title,
    String? description,
    String category = 'Genel',
    required int salonId,
  }) async {
    try {
      final options = await _authOptions();
      final response = await _dio.post(
        '$baseUrl/Posts',
        data: {
          'title': title,
          'description': description,
          'category': category,
          'salonId': salonId,
        },
        options: options,
      );
      return response.data['id'];
    } catch (e) {
      print('createPost hata: $e');
      return null;
    }
  }

  // Fotoğraf yükle
  Future<bool> uploadPostImage({
    required int postId,
    required String filePath,
    String? tag, // "before", "after", null
    int order = 0,
  }) async {
    try {
      final token = await _getToken();
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      String url = '$baseUrl/Posts/$postId/upload-image?order=$order';
      if (tag != null) url += '&tag=$tag';

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'multipart/form-data',
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Upload post image hata: $e');
      return false;
    }
  }

  // Fotoğraf sil
  Future<bool> deletePostImage(int postId, int imageId) async {
    try {
      final options = await _authOptions();
      await _dio.delete('$baseUrl/Posts/$postId/images/$imageId',
          options: options);
      return true;
    } catch (e) {
      print('deletePostImage hata: $e');
      return false;
    }
  }

  // Gönderi sil
  Future<bool> deletePost(int postId) async {
    try {
      final options = await _authOptions();
      await _dio.delete('$baseUrl/Posts/$postId', options: options);
      return true;
    } catch (e) {
      print('deletePost hata: $e');
      return false;
    }
  }
}