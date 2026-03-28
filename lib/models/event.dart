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
  final List<String> mediaUrls;
  final bool isUserParticipant;
  final bool isBookmarked;
  final double? averageRating;
  final int reviewCount;

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
    this.mediaUrls = const [],
    this.isUserParticipant = false,
    this.isBookmarked = false,
    this.averageRating,
    this.reviewCount = 0,
  });

  bool get isLive {
    final now = DateTime.now().toUtc();
    return startTime.isBefore(now) && endTime.isAfter(now);
  }

  bool get isUpcoming {
    final now = DateTime.now().toUtc();
    return startTime.isAfter(now);
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    final parsedMediaUrls = _parseMediaUrls(json);

    final parsedCoverImage =
        (json['cover_image'] ?? json['coverImage']) as String?;

    final fallbackCoverImage = parsedMediaUrls.firstWhere(
      _isImageUrl,
      orElse: () => parsedMediaUrls.isNotEmpty ? parsedMediaUrls.first : '',
    );

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
      coverImage: (parsedCoverImage != null && parsedCoverImage.isNotEmpty)
          ? parsedCoverImage
          : (fallbackCoverImage.isNotEmpty ? fallbackCoverImage : null),
      mediaUrls: parsedMediaUrls,
      isUserParticipant: json['is_user_participant'] ?? false,
      isBookmarked: json['is_bookmarked'] ?? false,
      averageRating: json['average_rating'] != null
          ? (json['average_rating'] as num).toDouble()
          : null,
      reviewCount: json['review_count'] ?? 0,
    );
  }

  static List<String> _parseMediaUrls(Map<String, dynamic> json) {
    final urls = <String>[];

    void addUrl(dynamic value) {
      if (value is String && value.isNotEmpty) {
        urls.add(value);
      }
    }

    void addFromList(dynamic source) {
      if (source is List) {
        for (final item in source) {
          if (item is String) {
            addUrl(item);
          } else if (item is Map<String, dynamic>) {
            addUrl(item['url']);
            addUrl(item['secure_url']);
            addUrl(item['media_url']);
            addUrl(item['file_url']);
          }
        }
      }
    }

    addFromList(json['media_urls']);
    addFromList(json['mediaUrls']);
    addFromList(json['media']);
    addFromList(json['attachments']);

    final deduped = <String>[];
    final seen = <String>{};
    for (final url in urls) {
      if (seen.add(url)) {
        deduped.add(url);
      }
    }
    return deduped;
  }

  static bool _isImageUrl(String url) {
    final clean = url.split('?').first.toLowerCase();
    return clean.endsWith('.jpg') ||
        clean.endsWith('.jpeg') ||
        clean.endsWith('.png') ||
        clean.endsWith('.webp');
  }
}
