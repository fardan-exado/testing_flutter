class Anak {
  final int id;
  final String? avatar;
  final String name;
  final String email;
  final String role;
  final String authMethod;

  Anak({
    required this.id,
    required this.avatar,
    required this.name,
    required this.email,
    required this.role,
    required this.authMethod,
  });

  factory Anak.fromJson(Map<String, dynamic> json) {
    return Anak(
      id: json['id'],
      avatar: json['avatar'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      authMethod: json['auth_method'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'avatar': avatar,
      'name': name,
      'email': email,
      'role': role,
      'auth_method': authMethod,
    };
  }
}
