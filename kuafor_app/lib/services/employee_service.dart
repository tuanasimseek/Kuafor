import 'package:dio/dio.dart';

class EmployeeService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.1.105:5069/api',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  Future<List<dynamic>> getSalonEmployees(int salonId) async {
    try {
      final response = await _dio.get('/Employee/salon/$salonId');
      if (response.statusCode == 200) return response.data as List<dynamic>;
      return [];
    } on DioException catch (e) {
      print('getSalonEmployees hatası: ${e.response?.data ?? e.message}');
      return [];
    }
  }

  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    try {
      final response = await _dio.get('/Employee/find-user',
          queryParameters: {'email': email});
      if (response.statusCode == 200)
        return response.data as Map<String, dynamic>;
      return null;
    } on DioException catch (e) {
      print('findUserByEmail hatası: ${e.response?.data ?? e.message}');
      return null;
    }
  }

  Future<({Map<String, dynamic>? data, String? error})> addEmployee({
    required int userId,
    required int salonId,
  }) async {
    try {
      final response = await _dio.post('/Employee',
          data: {'userId': userId, 'salonId': salonId});
      if (response.statusCode == 200 || response.statusCode == 201) {
        return (data: response.data as Map<String, dynamic>, error: null);
      }
      return (data: null, error: 'Sunucu hatası');
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          e.response?.data?.toString() ??
          e.message ??
          'Bilinmeyen hata';
      print('addEmployee hatası: $msg');
      return (data: null, error: msg);
    }
  }

  Future<bool> deleteEmployee(int employeeId) async {
    try {
      final response = await _dio.delete('/Employee/$employeeId');
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      print('deleteEmployee hatası: ${e.response?.data ?? e.message}');
      return false;
    }
  }
}