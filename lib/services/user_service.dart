import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../models/event.dart';
import '../models/user.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _client = ApiClient();

  Future<User> getMe() async {
    final response = await _client.dio.get('/users/me');
    return User.fromJson(response.data);
  }

  Future<User> getUser(String userId) async {
    final response = await _client.dio.get('/users/$userId');
    return User.fromJson(response.data);
  }

  Future<User> updateProfile({
    String? name,
    String? gender,
    String? profilePicture,
    String? bio,
    List<String>? interests,
    Map<String, String>? socialLinks,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (gender != null) data['gender'] = gender;
    if (profilePicture != null) data['profile_picture'] = profilePicture;
    if (bio != null) data['bio'] = bio;
    if (interests != null) data['interests'] = interests;
    if (socialLinks != null) data['social_links'] = socialLinks;

    final response = await _client.dio.patch('/users/me', data: data);
    return User.fromJson(response.data);
  }

  Future<User> uploadProfilePicture(XFile file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.name,
      ),
    });

    final response = await _client.dio.post(
      '/users/me/profile-picture',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
    return User.fromJson(response.data);
  }

  Future<UserStats> getUserStats() async {
    final response = await _client.dio.get('/users/me/stats');
    return UserStats.fromJson(response.data);
  }

  Future<List<Event>> getMyEvents({required String type}) async {
    final response = await _client.dio
        .get('/users/me/events', queryParameters: {'type': type});
    return (response.data as List)
        .map((json) => Event.fromJson(json))
        .toList();
  }

  Future<List<Event>> getMyBookmarks() async {
    final response = await _client.dio.get('/users/me/bookmarks');
    return (response.data as List)
        .map((json) => Event.fromJson(json))
        .toList();
  }

  Future<void> followUser(String userId) async {
    await _client.dio.post('/users/$userId/follow');
  }

  Future<void> unfollowUser(String userId) async {
    await _client.dio.delete('/users/$userId/follow');
  }

  Future<List<User>> getMyFollowing() async {
    final response = await _client.dio.get('/users/me/following');
    return (response.data as List)
        .map((json) => User.fromJson(json))
        .toList();
  }
}

class UserStats {
  final int eventsCreated;
  final int eventsAttended;
  final int followersCount;
  final int followingCount;

  UserStats({
    required this.eventsCreated,
    required this.eventsAttended,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    final totalCreated = json['total_events_created'];
    final totalAttended = json['total_events_attended'];
    return UserStats(
      eventsCreated: (totalCreated ?? json['events_created']) ?? 0,
      eventsAttended: (totalAttended ?? json['events_attended']) ?? 0,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
    );
  }
}
