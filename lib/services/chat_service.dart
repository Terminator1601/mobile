import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/chat_message.dart';
import 'api_client.dart';

class ChatService {
  final ApiClient _client = ApiClient();

  static const String _wsBaseUrl =
      'wss://explorer-backend-g4xb.onrender.com';

  Future<List<ChatMessage>> getChatHistory(String eventId,
      {int limit = 50}) async {
    final response = await _client.dio.get(
      '/events/$eventId/chat/history',
      queryParameters: {'limit': limit},
    );
    return (response.data as List)
        .map((json) => ChatMessage.fromJson(json))
        .toList();
  }

  String getWebSocketUrl(String eventId, String token) {
    return '$_wsBaseUrl/events/$eventId/chat?token=$token';
  }
}
