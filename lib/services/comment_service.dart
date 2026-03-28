import '../models/comment.dart';
import 'api_client.dart';

class CommentService {
  final ApiClient _client = ApiClient();

  Future<List<Comment>> getComments(String eventId,
      {int limit = 20, int offset = 0}) async {
    final response = await _client.dio.get(
      '/events/$eventId/comments',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return (response.data as List)
        .map((json) => Comment.fromJson(json))
        .toList();
  }

  Future<Comment> createComment(String eventId, String text) async {
    final response = await _client.dio.post(
      '/events/$eventId/comments',
      data: {'text': text},
    );
    return Comment.fromJson(response.data);
  }

  Future<void> deleteComment(String eventId, String commentId) async {
    await _client.dio.delete('/events/$eventId/comments/$commentId');
  }
}
