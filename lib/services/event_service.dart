import '../models/event.dart';
import 'api_client.dart';

class EventService {
  final ApiClient _client = ApiClient();

  Future<List<Event>> getNearbyEvents({
    required double lat,
    required double lng,
    double radius = 5000,
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
  }) async {
    final response = await _client.dio.post('/events', data: {
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'max_participants': maxParticipants,
      'is_private': isPrivate,
      'interest_tag': interestTag,
    });
    return Event.fromJson(response.data);
  }

  Future<void> joinEvent(String eventId) async {
    await _client.dio.post('/events/$eventId/join');
  }
}
