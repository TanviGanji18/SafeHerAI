class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.createdAt,
  });

  String get uid => id;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'],
      createdAt: json['created_at'] ?? '',
    );
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AuthResult {
  final String accessToken;
  final String tokenType;
  final UserProfile user;

  AuthResult({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      user: UserProfile.fromJson(json['user']),
    );
  }
}
