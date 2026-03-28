import 'user.dart';

class Comment {
  final String id;
  final String eventId;
  final User user;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.eventId,
    required this.user,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      eventId: json['event_id'],
      user: User.fromJson(json['user']),
      text: json['text'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
