import 'package:dio/dio.dart';

class CampaignService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:5069/api',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  Future<List<dynamic>> getCampaigns() async {
    try {
      final response = await _dio.get('/Campaign');
      if (response.statusCode == 200) return response.data as List<dynamic>;
      return [];
    } on DioException catch (e) {
      print('getCampaigns hatası: ${e.response?.data ?? e.message}');
      return [];
    }
  }

  Future<List<dynamic>> getSalonCampaigns(int salonId) async {
    try {
      final response = await _dio.get('/Campaign/salon/$salonId');
      if (response.statusCode == 200) return response.data as List<dynamic>;
      return [];
    } on DioException catch (e) {
      print('getSalonCampaigns hatası: ${e.response?.data ?? e.message}');
      return [];
    }
  }
}