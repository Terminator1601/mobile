import 'package:dio/dio.dart';
import '../models/place_result.dart';

class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;

  late final Dio _dio;

  GeocodingService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://nominatim.openstreetmap.org',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent': 'EventDiscoveryApp/1.0',
        'Accept': 'application/json',
      },
    ));
  }

  Future<List<PlaceResult>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _dio.get('/search', queryParameters: {
        'q': query,
        'format': 'json',
        'limit': 5,
        'addressdetails': 1,
      });
      final List data = response.data;
      return data.map((json) => PlaceResult.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get('/reverse', queryParameters: {
        'lat': latitude,
        'lon': longitude,
        'format': 'json',
        'zoom': 18,
        'addressdetails': 1,
      });

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final displayName = data['display_name']?.toString().trim();
        if (displayName != null && displayName.isNotEmpty) {
          return displayName;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
