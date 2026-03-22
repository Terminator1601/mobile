class AuthResponse {
  final String accessToken;
  final String tokenType;

  AuthResponse({required this.accessToken, this.tokenType = 'bearer'});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'] ?? 'bearer',
    );
  }
}
