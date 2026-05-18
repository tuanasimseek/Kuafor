import 'package:dio/dio.dart';

class ServiceService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://kuafor-019f.onrender.com/api',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  Future<List<dynamic>> getSalonServices(int salonId) async {
    try {
      final response = await _dio.get('/Service/salon/$salonId');
      if (response.statusCode == 200) return response.data as List<dynamic>;
      return [];
    } on DioException catch (e) {
      print('getSalonServices hatası: ${e.response?.data ?? e.message}');
      return [];
    }
  }

  Future<List<dynamic>> getStylistServices(int stylistId) async {
    try {
      final response = await _dio.get('/Service/stylist/$stylistId');
      if (response.statusCode == 200) return response.data as List<dynamic>;
      return [];
    } on DioException catch (e) {
      print('getStylistServices hatası: ${e.response?.data ?? e.message}');
      return [];
    }
  }

  Future<bool> createService({
    required int salonId,
    required String name,
    required double price,
    required int durationMinutes,
  }) async {
    try {
      final response = await _dio.post('/Service', data: {
        'salonId': salonId,
        'name': name,
        'price': price,
        'durationMinutes': durationMinutes,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('createService hatası: ${e.response?.data ?? e.message}');
      return false;
    }
  }

  Future<bool> createStylistService({
    required int stylistId,
    required int salonId,
    required String name,
    required double price,
    required int durationMinutes,
  }) async {
    try {
      final response = await _dio.post('/Service', data: {
        'stylistId': stylistId,
        'salonId': salonId,
        'name': name,
        'price': price,
        'durationMinutes': durationMinutes,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('createStylistService hatası: ${e.response?.data ?? e.message}');
      return false;
    }
  }

  Future<bool> deleteService(int serviceId) async {
    try {
      final response = await _dio.delete('/Service/$serviceId');
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      print('deleteService hatası: ${e.response?.data ?? e.message}');
      return false;
    }
  }

  Future<bool> updateService({
    required int serviceId,
    required String name,
    required double price,
    required int durationMinutes,
  }) async {
    try {
      final response = await _dio.put('/Service/$serviceId', data: {
        'name': name,
        'price': price,
        'durationMinutes': durationMinutes,
      });
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      print('updateService hatası: ${e.response?.data ?? e.message}');
      return false;
    }
  }
}