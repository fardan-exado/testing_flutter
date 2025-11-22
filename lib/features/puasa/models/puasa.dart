class PuasaSunnah {
  final int id;
  final String nama;
  final String slug;
  final String? deskripsi;
  final String? iconPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  PuasaSunnah({
    required this.id,
    required this.nama,
    required this.slug,
    this.deskripsi,
    this.iconPath,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory PuasaSunnah.fromJson(Map<String, dynamic> json) {
    return PuasaSunnah(
      id: json['id'] as int,
      nama: json['nama'] as String,
      slug: json['slug'] as String,
      deskripsi: json['deskripsi'] as String?,
      iconPath: json['icon_path'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'slug': slug,
      'deskripsi': deskripsi,
      'icon_path': iconPath,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
