import 'user.dart';

class Event {
  final String id;
  final String title;
  final String? description;
  final double latitude;
  final double longitude;
  final DateTime startTime;
  final DateTime endTime;
  final int maxParticipants;
  final bool isPrivate;
  final String? interestTag;
  final String createdBy;
  final DateTime createdAt;
  final User? creator;
  final int participantCount;
  final double? distanceMeters;
  final String? coverImage;
  final bool isUserParticipant;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.startTime,
    required this.endTime,
    required this.maxParticipants,
    required this.isPrivate,
    this.interestTag,
    required this.createdBy,
    required this.createdAt,
    this.creator,
    this.participantCount = 0,
    this.distanceMeters,
    this.coverImage,
    this.isUserParticipant = false,
  });

  bool get isLive {
    final now = DateTime.now().toUtc();
    return startTime.isBefore(now) && endTime.isAfter(now);
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      maxParticipants: json['max_participants'],
      isPrivate: json['is_private'],
      interestTag: json['interest_tag'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      creator:
          json['creator'] != null ? User.fromJson(json['creator']) : null,
      participantCount: json['participant_count'] ?? 0,
      distanceMeters: json['distance_meters'] != null
          ? (json['distance_meters'] as num).toDouble()
          : null,
      coverImage: json['cover_image'],
      isUserParticipant: json['is_user_participant'] ?? false,
    );
  }
}
