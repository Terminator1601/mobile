class ChatMessage {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      eventId: json['event_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? 'Unknown',
      text: json['text'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
