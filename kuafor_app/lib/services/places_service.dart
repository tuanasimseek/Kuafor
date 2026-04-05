// lib/services/places_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesService {
  static const String _userAgent = 'KuaforApp/1.0';

  Future<List<PlacePrediction>> getSuggestions(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return [];
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/search').replace(queryParameters: {
        'q': trimmed,
        'format': 'json',
        'addressdetails': '1',
        'limit': '7',
        'countrycodes': 'tr',
        'accept-language': 'tr',
      });
      final res = await http.get(uri, headers: {'User-Agent': _userAgent, 'Accept-Language': 'tr'});
      print('[Places] Nominatim status: ${res.statusCode}');
      print('[Places] Nominatim body (ilk 300): ${res.body.substring(0, res.body.length.clamp(0, 300))}');
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((item) {
        final map = item as Map<String, dynamic>;
        return PlacePrediction(
          placeId: map['place_id'].toString(),
          description: map['display_name'] as String,
          latitude: double.parse(map['lat'] as String),
          longitude: double.parse(map['lon'] as String),
        );
      }).toList();
    } catch (e) {
      print('[Places] getSuggestions exception: $e');
      return [];
    }
  }

  Future<PlaceDetail?> getDetail(String placeId) async {
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/lookup').replace(queryParameters: {
        'osm_ids': 'N$placeId',
        'format': 'json',
        'addressdetails': '1',
        'accept-language': 'tr',
      });
      final res = await http.get(uri, headers: {'User-Agent': _userAgent, 'Accept-Language': 'tr'});
      print('[Places] Nominatim lookup status: ${res.statusCode}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        if (data.isNotEmpty) {
          final map = data.first as Map<String, dynamic>;
          return PlaceDetail(
            formattedAddress: map['display_name'] as String? ?? '',
            latitude: double.parse(map['lat'] as String),
            longitude: double.parse(map['lon'] as String),
          );
        }
      }
    } catch (e) {
      print('[Places] getDetail exception: $e');
    }
    return null;
  }
}

class PlacePrediction {
  final String placeId;
  final String description;
  final double? latitude;
  final double? longitude;

  const PlacePrediction({
    required this.placeId,
    required this.description,
    this.latitude,
    this.longitude,
  });
}

class PlaceDetail {
  final String formattedAddress;
  final double latitude;
  final double longitude;

  const PlaceDetail({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });
}