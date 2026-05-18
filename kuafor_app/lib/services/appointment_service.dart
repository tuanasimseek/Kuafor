import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AppointmentService {
  static const String _base = 'https://kuafor-019f.onrender.com/api/Appointment';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getCustomerAppointments(int customerId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/customer/$customerId'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  Future<List<dynamic>> getStylistAppointments(int stylistId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/stylist/$stylistId'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  Future<List<dynamic>> getSalonAppointments(int salonId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/salon/$salonId'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  Future<List<dynamic>> getBusySlots(int stylistId, String date) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/busy-slots?stylistId=$stylistId&date=$date'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  List<DateTime> parseBusySlotDates(List<dynamic> slots) {
    return slots.map<DateTime?>((slot) {
      try {
        if (slot is Map) {
          final raw = slot['appointmentDate'] ?? slot['AppointmentDate'];
          if (raw == null) return null;
          return DateTime.parse(raw.toString()).toLocal();
        }
        return DateTime.parse(slot.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }).whereType<DateTime>().toList();
  }

  Future<({Map? data, String? error})> createAppointment({
    required int customerId,
    required int stylistId,
    required int salonId,
    required int serviceId,
    required DateTime appointmentDate,
    required int durationMinutes,
    String? notes,
  }) async {
    try {
      final body = jsonEncode({
        'customerId': customerId,
        'stylistId': stylistId,
        'salonId': salonId,
        'serviceId': serviceId,
        'appointmentDate': appointmentDate.toUtc().toIso8601String(),
        'durationMinutes': durationMinutes,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      final res = await http.post(
        Uri.parse(_base),
        headers: await _headers(),
        body: body,
      );
      if (res.statusCode == 200) {
        return (data: jsonDecode(res.body) as Map, error: null);
      } else {
        final decoded = jsonDecode(res.body);
        final msg = decoded['message'] ?? 'Randevu oluşturulamadı';
        return (data: null, error: msg as String);
      }
    } catch (e) {
      return (data: null, error: 'Bağlantı hatası');
    }
  }

  Future<bool> updateStatus(int appointmentId, String status) async {
    try {
      final res = await http.put(
        Uri.parse('$_base/$appointmentId/status'),
        headers: await _headers(),
        body: jsonEncode({'status': status}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<({bool success, String? error})> cancelAppointment(
      int appointmentId, int customerId) async {
    try {
      final res = await http.put(
        Uri.parse('$_base/$appointmentId/cancel?customerId=$customerId'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) return (success: true, error: null);
      final decoded = jsonDecode(res.body);
      return (success: false, error: decoded['message'] as String?);
    } catch (_) {
      return (success: false, error: 'Bağlantı hatası');
    }
  }
}
