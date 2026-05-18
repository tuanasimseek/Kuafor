import 'package:dio/dio.dart';

class ReviewService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://kuafor-019f.onrender.com/api',
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
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) return data;
        if (data is Map && data['reviews'] is List) {
          return data['reviews'] as List<dynamic>;
        }
      }
      return [];
    } on DioException catch (e) {
      print('getSalonReviews hatası: ${e.response?.data ?? e.message}');
      return [];
    }
  }

  Future<Map<String, dynamic>> getSalonReviewSummary(int salonId) async {
    try {
      final response = await _dio.get('/Review/salon/$salonId');
      if (response.statusCode == 200 && response.data is Map) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return {'averageRating': 0, 'count': 0, 'reviews': []};
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
