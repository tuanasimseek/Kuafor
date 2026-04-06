import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CampaignService {
  static const String _base = 'http://192.168.1.105:5069/api';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getCampaigns() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/Campaign'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> getSalonCampaigns(int salonId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/Campaign/salon/$salonId'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<({bool success, String? error})> createCampaign({
    required int salonId,
    required String title,
    required String description,
    required int discountPercent,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      final body = {
        'salonId': salonId,
        'title': title,
        'description': description,
        'discountPercent': discountPercent,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'isActive': true,
      };
      final res = await http.post(
        Uri.parse('$_base/Campaign'),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return (success: true, error: null);
      }
      return (success: false, error: 'Sunucu hatası: ${res.statusCode}');
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  Future<bool> deactivateCampaign(int campaignId) async {
    try {
      final res = await http.put(
        Uri.parse('$_base/Campaign/$campaignId/deactivate'),
        headers: await _headers(),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCampaign(int campaignId) async {
    try {
      final res = await http.delete(
        Uri.parse('$_base/Campaign/$campaignId'),
        headers: await _headers(),
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}