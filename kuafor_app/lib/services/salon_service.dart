import 'package:dio/dio.dart';
import 'auth_service.dart';

class SalonService {
  static const String _base = 'http://192.168.1.105:5069/api';
  final AuthService _authService = AuthService();

  Future<Options> _options() async {
    final token = await _authService.getToken();
    return Options(headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<List<dynamic>> getSalons() async {
    try {
      final res = await _dio.get('$_base/Salon', options: await _options());
      if (res.statusCode == 200) return res.data as List<dynamic>;
      return [];
    } catch (_) { return []; }
  }

  Future<List<dynamic>> getNearbySalons({
    required double lat,
    required double lng,
    double radius = 10.0,
  }) async {
    try {
      final res = await _dio.get(
        '$_base/Salon/nearby',
        queryParameters: {'lat': lat, 'lng': lng, 'radius': radius},
        options: await _options(),
      );
      if (res.statusCode == 200) return res.data as List<dynamic>;
      return [];
    } catch (_) { return []; }
  }

  Future<Map<String, dynamic>?> getSalonDetail(int id) async {
    try {
      final res = await _dio.get('$_base/Salon/$id', options: await _options());
      if (res.statusCode == 200) return res.data as Map<String, dynamic>;
      return null;
    } catch (_) { return null; }
  }

  Future<Map<String, dynamic>?> getSalonByOwner(int ownerId) async {
    try {
      final res = await _dio.get('$_base/Salon/owner/$ownerId', options: await _options());
      if (res.statusCode == 200) return res.data as Map<String, dynamic>;
      return null;
    } catch (_) { return null; }
  }

  Future<Map<String, dynamic>?> getSalonByStylist(int stylistId) async {
    try {
      final res = await _dio.get('$_base/Salon/stylist/$stylistId', options: await _options());
      if (res.statusCode == 200) return res.data as Map<String, dynamic>;
      return null;
    } catch (_) { return null; }
  }

  // Salondaki çalışanları getir — BookingScreen stilist listesi için
  Future<List<dynamic>> getEmployeesBySalon(int salonId) async {
    try {
      final res = await _dio.get(
        '$_base/Employee/salon/$salonId',
        options: await _options(),
      );
      print('[SalonService] getEmployeesBySalon status: ${res.statusCode}');
      print('[SalonService] getEmployeesBySalon data: ${res.data}');
      if (res.statusCode == 200) return res.data as List<dynamic>;
      return [];
    } catch (e) {
      print('[SalonService] getEmployeesBySalon error: $e');
      return [];
    }
  }

  Future<({bool success, String? error})> updateSalon({
    required int salonId,
    String? name,
    String? address,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name        != null) body['name']        = name;
      if (address     != null) body['address']     = address;
      if (description != null) body['description'] = description;
      if (latitude    != null) body['latitude']    = latitude;
      if (longitude   != null) body['longitude']   = longitude;

      print('[SalonService] PUT ${'$_base/Salon/$salonId'} body: $body');
      final res = await _dio.put(
        '$_base/Salon/$salonId',
        data: body,
        options: await _options(),
      );
      print('[SalonService] PUT response: ${res.statusCode} ${res.data}');
      if (res.statusCode == 200) return (success: true, error: null);
      return (success: false, error: 'Sunucu hatası: ${res.statusCode}');
    } on DioException catch (e) {
      print('[SalonService] PUT DioException: ${e.response?.statusCode} ${e.response?.data}');
      final msg = e.response?.data?['message']?.toString()
          ?? e.response?.data?.toString()
          ?? e.message ?? 'Bağlantı hatası';
      return (success: false, error: msg);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }
}