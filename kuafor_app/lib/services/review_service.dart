import 'package:dio/dio.dart';

class ReviewService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.1.105:5069/api',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  Future<List<dynamic>> getReviews() async {
    try {
      final response = await _dio.get('/Review');
      if (response.statusCode == 200) return response.data as List<dynamic>;
      return [];
    } on DioException catch (e) {
      print('getReviews hatası: ${e.response?.data ?? e.message}');
      return [];
    }
  }

  Future<List<dynamic>> getSalonReviews(int salonId) async {
    try {
      final response = await _dio.get('/Review/salon/$salonId');
      if (response.statusCode == 200) return response.data as List<dynamic>;
      return [];
    } on DioException catch (e) {
      print('getSalonReviews hatası: ${e.response?.data ?? e.message}');
      return [];
    }
  }

  Future<bool> addReview({
    required int salonId,
    required int userId,
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await _dio.post('/Review', data: {
        'salonId': salonId,
        'userId': userId,
        'rating': rating,
        'comment': comment,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('addReview hatası: ${e.response?.data ?? e.message}');
      return false;
    }
  }
}