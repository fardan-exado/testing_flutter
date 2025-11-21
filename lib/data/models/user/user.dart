class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? noHp;
  final String? alamat;
  final String? authMethod;
  final String? onboardingComplete;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.noHp,
    this.alamat,
    this.authMethod,
    this.onboardingComplete,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> m) {
    return User(
      id: m['id'] is String ? int.parse(m['id']) : m['id'] as int,
      name: m['name'] ?? '',
      email: m['email'] ?? '',
      phone: m['phone'] ?? '',
      role: m['role'] ?? '',
      noHp: m['no_hp'] ?? '',
      alamat: m['alamat'] ?? '',
      authMethod: m['auth_method'] ?? '',
      onboardingComplete: m['onboarding_complete'] ?? '',
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String),
    );
  }

  factory User.fromMap(Map<String, dynamic> m) {
    return User(
      id: m['id'] is String ? int.parse(m['id']) : m['id'] as int,
      name: m['name'] ?? '',
      email: m['email'] ?? '',
      phone: m['phone'] ?? '',
      role: m['role'] ?? '',
      noHp: m['no_hp'] ?? '',
      alamat: m['alamat'] ?? '',
      authMethod: m['auth_method'] ?? '',
      onboardingComplete: m['onboarding_complete'] ?? '',
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'no_hp': noHp,
      'alamat': alamat,
      'auth_method': authMethod,
      'onboarding_complete': onboardingComplete,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class AuthResponse {
  final String token;
  final User user;

  const AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
    );
  }
}
