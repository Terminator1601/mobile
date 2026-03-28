import 'package:dio/dio.dart';

import '../models/auth_response.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String gender,
  }) async {
    final response = await _client.dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'gender': gender,
    });
    return User.fromJson(response.data);
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final auth = AuthResponse.fromJson(response.data);
    await _client.saveToken(auth.accessToken);
    if (auth.refreshToken.isNotEmpty) {
      await _client.saveRefreshToken(auth.refreshToken);
    }
    return auth;
  }

  Future<void> logout() async {
    await _client.clearToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await _client.getToken();
    return token != null;
  }
}
