class User {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final String gender;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    required this.gender,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profilePicture: json['profile_picture'],
      gender: json['gender'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'profile_picture': profilePicture,
        'gender': gender,
      };
}
