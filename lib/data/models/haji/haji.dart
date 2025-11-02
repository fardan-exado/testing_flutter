class Haji {
  final int id;
  final String judul;
  final String cover;
  final String tipe;
  final String? konten;
  final String? videoUrl;
  final List<String>? daftarGambar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? excerpt;
  final String? penulis;

  Haji({
    required this.id,
    required this.judul,
    required this.cover,
    required this.tipe,
    this.videoUrl,
    this.konten,
    this.daftarGambar,
    required this.createdAt,
    required this.updatedAt,
    this.excerpt,
    this.penulis,
  });

  Haji.empty()
    : id = 0,
      judul = '',
      cover = '',
      tipe = '',
      videoUrl = null,
      konten = null,
      daftarGambar = const [],
      createdAt = DateTime.now(),
      updatedAt = DateTime.now(),
      excerpt = null,
      penulis = null;

  factory Haji.fromJson(Map<String, dynamic> json) {
    return Haji(
      id: json['id'] as int,
      judul: json['judul'] as String,
      cover: json['cover'] as String,
      tipe: json['tipe'] as String,
      videoUrl: json['video_url'] as String?,
      konten: json['konten'] as String?,
      daftarGambar:
          (json['daftar_gambar'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      excerpt: json['excerpt'] as String?,
      penulis: json['penulis'] as String? ?? 'Admin',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'cover': cover,
      'tipe': tipe,
      'video_url': videoUrl,
      'konten': konten,
      'daftar_gambar': daftarGambar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'excerpt': excerpt,
      'penulis': penulis,
    };
  }
}
