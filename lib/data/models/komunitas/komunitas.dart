import 'package:test_flutter/features/artikel/models/kategori/kategori_artikel.dart';

class KomunitasPostingan {
  final int id;
  final int userId;
  final int kategoriId;
  final String judul;
  final String cover;
  final String? isi; // Tambahkan field konten
  final List<String> daftarGambar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String excerpt;
  final String penulis;
  final KategoriArtikel kategori;
  final int totalLikes;
  final int totalKomentar;
  final bool? liked; // Tambahkan field liked
  final List<Komentar>? komentars;

  KomunitasPostingan({
    required this.id,
    required this.userId,
    required this.kategoriId,
    required this.judul,
    required this.excerpt,
    required this.cover,
    this.isi,
    required this.daftarGambar,
    required this.totalLikes,
    required this.totalKomentar,
    required this.createdAt,
    required this.updatedAt,
    required this.penulis,
    required this.kategori,
    this.liked,
    this.komentars,
  });

  factory KomunitasPostingan.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is String) return int.tryParse(value) ?? 0;
      return value as int;
    }

    return KomunitasPostingan(
      id: parseInt(json['id']),
      userId: parseInt(json['user_id']),
      kategoriId: parseInt(json['kategori_id']),
      judul: json['judul'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      isi: json['konten'] as String?, // Map dari 'konten'
      daftarGambar: (json['daftar_gambar'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      totalLikes: parseInt(json['total_likes']),
      totalKomentar: parseInt(json['total_komentar']),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      penulis: json['penulis'] as String? ?? 'User',
      kategori: KategoriArtikel.fromJson(
        json['kategori'] as Map<String, dynamic>,
      ),
      liked: json['liked'] as bool?,
      komentars: (json['komentars'] as List<dynamic>?)
          ?.map((e) => Komentar.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'kategori_id': kategoriId,
      'judul': judul,
      'excerpt': excerpt,
      'cover': cover,
      'konten': isi,
      'daftar_gambar': daftarGambar,
      'total_likes': totalLikes,
      'total_komentar': totalKomentar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'penulis': penulis,
      'kategori': kategori.toJson(),
      'liked': liked,
      'komentars': komentars?.map((e) => e.toJson()).toList(),
    };
  }

  KomunitasPostingan copyWith({
    List<Komentar>? komentars,
    bool? liked,
    int? totalLikes,
    int? totalKomentar,
  }) {
    return KomunitasPostingan(
      id: id,
      userId: userId,
      kategoriId: kategoriId,
      judul: judul,
      excerpt: excerpt,
      cover: cover,
      isi: isi,
      daftarGambar: daftarGambar,
      totalLikes: totalLikes ?? this.totalLikes,
      totalKomentar: totalKomentar ?? this.totalKomentar,
      createdAt: createdAt,
      updatedAt: updatedAt,
      penulis: penulis,
      kategori: kategori,
      liked: liked ?? this.liked,
      komentars: komentars ?? this.komentars,
    );
  }
}

class Komentar {
  final int id;
  final int postinganId;
  final int userId;
  final String komentar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String penulis;
  final bool? isAnonymous; // Tambahkan field ini

  Komentar({
    required this.id,
    required this.postinganId,
    required this.userId,
    required this.komentar,
    required this.createdAt,
    required this.updatedAt,
    required this.penulis,
    this.isAnonymous,
  });

  factory Komentar.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is String) return int.tryParse(value) ?? 0;
      return value as int;
    }

    return Komentar(
      id: parseInt(json['id']),
      userId: parseInt(json['user_id']),
      postinganId: parseInt(json['postingan_id']),
      komentar: json['komentar'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      penulis: json['penulis'] as String? ?? 'User',
      isAnonymous: json['is_anonymous'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'postingan_id': postinganId,
      'komentar': komentar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'penulis': penulis,
      'is_anonymous': isAnonymous,
    };
  }
}