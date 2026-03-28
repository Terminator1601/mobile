import 'package:dio/dio.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../models/event.dart';
import 'api_client.dart';

class EventService {
  final ApiClient _client = ApiClient();
  static const int _maxMediaSizeBytes = 20 * 1024 * 1024;
  static const Set<String> _allowedMediaExtensions = {
    'jpg',
    'jpeg',
    'png',
    'mp4',
    'mov',
  };

  Future<List<Event>> getNearbyEvents({
    required double lat,
    required double lng,
    double radius = 50000,
    String? interestTag,
  }) async {
    final params = <String, dynamic>{
      'lat': lat,
      'lng': lng,
      'radius': radius,
    };
    if (interestTag != null) params['interest_tag'] = interestTag;

    final response =
        await _client.dio.get('/events/nearby', queryParameters: params);
    return (response.data as List)
        .map((json) => Event.fromJson(json))
        .toList();
  }

  Future<Event> getEvent(String eventId) async {
    final response = await _client.dio.get('/events/$eventId');
    return Event.fromJson(response.data);
  }

  Future<Event> createEvent({
    required String title,
    String? description,
    required double latitude,
    required double longitude,
    required DateTime startTime,
    required DateTime endTime,
    int maxParticipants = 50,
    bool isPrivate = false,
    String? interestTag,
    String? coverImage,
    List<String>? mediaUrls,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'max_participants': maxParticipants,
      'is_private': isPrivate,
      'interest_tag': interestTag,
      'cover_image': coverImage,
    };

    if (mediaUrls != null && mediaUrls.isNotEmpty) {
      payload['media_urls'] = mediaUrls;
    }

    final response = await _client.dio.post('/events', data: payload);
    return Event.fromJson(response.data);
  }

  Future<String> uploadMedia(XFile file) async {
    final extension = _fileExtension(file.name);
    if (!_allowedMediaExtensions.contains(extension)) {
      throw Exception('Only JPG, PNG, MP4, and MOV files are allowed.');
    }

    final size = await File(file.path).length();
    if (size > _maxMediaSizeBytes) {
      throw Exception('Each file must be 20MB or less.');
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.name,
      ),
    });

    final response = await _client.dio.post(
      '/uploads/media',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final directUrl =
          data['url'] ?? data['secure_url'] ?? data['file_url'] ?? data['media_url'];
      if (directUrl is String && directUrl.isNotEmpty) {
        return directUrl;
      }

      final nested = data['data'];
      if (nested is Map<String, dynamic>) {
        final nestedUrl = nested['url'] ??
            nested['secure_url'] ??
            nested['file_url'] ??
            nested['media_url'];
        if (nestedUrl is String && nestedUrl.isNotEmpty) {
          return nestedUrl;
        }
      }
    }

    throw Exception('Media upload succeeded but no media URL was returned');
  }

  String _fileExtension(String fileName) {
    final parts = fileName.toLowerCase().split('.');
    if (parts.length < 2) return '';
    return parts.last;
  }

  Future<void> joinEvent(String eventId) async {
    await _client.dio.post('/events/$eventId/join');
  }

  Future<void> leaveEvent(String eventId) async {
    await _client.dio.delete('/events/$eventId/join');
  }

  Future<Event> updateEvent(String eventId, Map<String, dynamic> data) async {
    final response = await _client.dio.patch('/events/$eventId', data: data);
    return Event.fromJson(response.data);
  }

  Future<void> deleteEvent(String eventId) async {
    await _client.dio.delete('/events/$eventId');
  }

  Future<bool> toggleBookmark(String eventId) async {
    final response = await _client.dio.post('/events/$eventId/bookmark');
    return response.data['bookmarked'] ?? false;
  }

  Future<List<Event>> getRecommendedEvents({
    required double lat,
    required double lng,
    double radius = 50000,
  }) async {
    final response = await _client.dio.get('/events/recommended',
        queryParameters: {'lat': lat, 'lng': lng, 'radius': radius});
    return (response.data as List)
        .map((json) => Event.fromJson(json))
        .toList();
  }
}
