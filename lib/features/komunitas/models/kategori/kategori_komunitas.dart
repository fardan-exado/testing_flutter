class KategoriKomunitas {
  final int id;
  final String nama;
  final String? iconPath;
  final String? icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  KategoriKomunitas({
    required this.id,
    required this.nama,
    this.iconPath,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KategoriKomunitas.fromJson(Map<String, dynamic> json) {
    return KategoriKomunitas(
      id: json['id'] as int,
      nama: json['nama'] as String,
      iconPath: json['icon_path'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'icon_path': iconPath,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory KategoriKomunitas.empty() {
    return KategoriKomunitas(
      id: 0,
      nama: '',
      iconPath: '',
      icon: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
