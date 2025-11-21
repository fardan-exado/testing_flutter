import 'package:test_flutter/features/artikel/models/kategori/kategori_artikel.dart';

class Artikel {
  final int id;
  final int kategoriId;
  final String judul;
  final String coverPath;
  final String tipe;
  final String? konten;
  final String? videoUrl;
  final List<String>? daftarGambar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? excerpt;
  final String? penulis;
  final KategoriArtikel kategori;

  Artikel({
    required this.id,
    required this.kategoriId,
    required this.judul,
    required this.coverPath,
    required this.tipe,
    this.videoUrl,
    this.konten,
    this.daftarGambar,
    required this.createdAt,
    required this.updatedAt,
    this.excerpt,
    this.penulis,
    required this.kategori,
  });

  Artikel.empty()
    : id = 0,
      kategoriId = 0,
      judul = '',
      coverPath = '',
      tipe = '',
      videoUrl = null,
      konten = null,
      daftarGambar = const [],
      createdAt = DateTime.now(),
      updatedAt = DateTime.now(),
      excerpt = null,
      penulis = null,
      kategori = KategoriArtikel.empty();

  factory Artikel.fromJson(Map<String, dynamic> json) {
    return Artikel(
      id: json['id'] as int,
      kategoriId: json['kategori_id'] as int,
      judul: json['judul'] as String,
      coverPath: json['cover_path'] as String,
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
      kategori: KategoriArtikel.fromJson(
        json['kategori'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kategori_id': kategoriId,
      'judul': judul,
      'cover_path': coverPath,
      'tipe': tipe,
      'video_url': videoUrl,
      'konten': konten,
      'daftar_gambar': daftarGambar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'excerpt': excerpt,
      'penulis': penulis,
      'kategori': kategori.toJson(),
    };
  }
}
