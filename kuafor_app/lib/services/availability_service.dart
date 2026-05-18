import 'package:dio/dio.dart';
import 'auth_service.dart';

class AvailabilityService {
  static const String _base = 'https://kuafor-019f.onrender.com/api';
  final AuthService _authService = AuthService();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<Options> _options() async {
    final token = await _authService.getToken();
    return Options(headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  Future<List<dynamic>> getStylistAvailability(int stylistId) async {
    try {
      final res = await _dio.get(
        '$_base/Availability/stylist/$stylistId',
        options: await _options(),
      );
      if (res.statusCode == 200 && res.data is List) {
        return res.data as List<dynamic>;
      }
    } catch (_) {}
    return _defaultRows(stylistId);
  }

  Future<bool> saveStylistAvailability({
    required int stylistId,
    required List<Map<String, dynamic>> rows,
  }) async {
    try {
      final res = await _dio.put(
        '$_base/Availability/stylist/$stylistId',
        data: rows,
        options: await _options(),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  List<dynamic> _defaultRows(int stylistId) {
    return List.generate(7, (index) {
      final day = index + 1;
      return {
        'stylistId': stylistId,
        'dayOfWeek': day,
        'isOpen': day <= 5,
        'openTime': '09:00',
        'closeTime': '18:00',
      };
    });
  }
}
