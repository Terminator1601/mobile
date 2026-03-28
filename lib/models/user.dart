class User {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final String gender;
  final String? bio;
  final List<String> interests;
  final Map<String, String> socialLinks;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    required this.gender,
    this.bio,
    this.interests = const [],
    this.socialLinks = const {},
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profilePicture: json['profile_picture'],
      gender: json['gender'],
      bio: json['bio'],
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : [],
      socialLinks: json['social_links'] != null
          ? Map<String, String>.from(json['social_links'])
          : {},
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'profile_picture': profilePicture,
        'gender': gender,
        'bio': bio,
        'interests': interests,
        'social_links': socialLinks,
      };
}
