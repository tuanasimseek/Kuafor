import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/review.dart';
import '../models/campaign.dart';
import '../models/notification.dart';

class ApiService {
  // Mac localhost için 127.0.0.1 kullan (emulator için 10.0.2.2 olur)
  static const String baseUrl = 'http://127.0.0.1:5069/api';

  // Review API'leri
  Future<List<Review>> getSalonReviews(int salonId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/review/salon/$salonId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Review.fromJson(json)).toList();
      } else {
        throw Exception('Yorumlar yüklenemedi');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  Future<Review> createReview(Review review) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/review'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(review.toJson()),
      );

      if (response.statusCode == 200) {
        return Review.fromJson(json.decode(response.body));
      } else {
        throw Exception('Yorum eklenemedi');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // Campaign API'leri
  Future<List<Campaign>> getAllCampaigns() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/campaign'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Campaign.fromJson(json)).toList();
      } else {
        throw Exception('Kampanyalar yüklenemedi');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  Future<List<Campaign>> getSalonCampaigns(int salonId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/campaign/salon/$salonId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Campaign.fromJson(json)).toList();
      } else {
        throw Exception('Kampanyalar yüklenemedi');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // Notification API'leri
  Future<List<AppNotification>> getUserNotifications(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notification/user/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AppNotification.fromJson(json)).toList();
      } else {
        throw Exception('Bildirimler yüklenemedi');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notification/$notificationId/read'),
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Bildirim güncellenemedi');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/notification/$notificationId'),
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Bildirim silinemedi');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }
}
