import 'package:dio/dio.dart';

class SalonService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:5069/api',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  Future<List<dynamic>> getSalons() async {
    try {
      final response = await _dio.get('/Salon');
      if (response.statusCode == 200) return response.data as List<dynamic>;
      return [];
    } on DioException catch (e) {
      print('getSalons hatası: ${e.response?.data ?? e.message}');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getSalonDetail(int salonId) async {
    try {
      final response = await _dio.get('/Salon/$salonId');
      if (response.statusCode == 200)
        return response.data as Map<String, dynamic>;
      return null;
    } on DioException catch (e) {
      print('getSalonDetail hatası: ${e.response?.data ?? e.message}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSalonByOwner(int ownerId) async {
    try {
      final response = await _dio.get('/Salon/owner/$ownerId');
      if (response.statusCode == 200)
        return response.data as Map<String, dynamic>;
      return null;
    } on DioException catch (e) {
      print('getSalonByOwner hatası: ${e.response?.data ?? e.message}');
      return null;
    }
  }

  // YENİ — stilistin çalıştığı salonu getirir
  Future<Map<String, dynamic>?> getSalonByStylist(int stylistId) async {
    try {
      final response = await _dio.get('/Salon/stylist/$stylistId');
      if (response.statusCode == 200)
        return response.data as Map<String, dynamic>;
      return null;
    } on DioException catch (e) {
      print('getSalonByStylist hatası: ${e.response?.data ?? e.message}');
      return null;
    }
  }
}