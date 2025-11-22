import 'package:test_flutter/data/models/user/user.dart';
import 'package:test_flutter/features/artikel/models/kategori/kategori_artikel.dart';

bool? _parseBoolNullable(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) return value == "1" || value.toLowerCase() == "true";
  return null;
}

bool _parseBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) return value == "1" || value.toLowerCase() == "true";
  return false;
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) {
    if (value.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(value);
    } catch (e) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}

class KomunitasPostingan {
  final int id;
  final int? userId;
  final String? coverPath;
  final List<String>? daftarGambar;
  final String judul;
  final String? konten;
  final String excerpt;
  final bool isAnonymous;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;
  final KategoriArtikel? kategori;
  final List<Komentar>? komentars;
  final List<Like>? likes;
  final int? likesCount;
  final int? komentarsCount;
  final bool? liked;

  KomunitasPostingan({
    required this.id,
    this.userId,
    this.coverPath,
    this.daftarGambar,
    required this.judul,
    this.konten,
    required this.excerpt,
    required this.isAnonymous,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.kategori,
    this.komentars,
    this.likes,
    this.likesCount,
    this.komentarsCount,
    this.liked,
  });

  factory KomunitasPostingan.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is String) return int.tryParse(v) ?? 0;
      return v as int;
    }

    // Safely handle daftar_gambar list
    List<String>? parseDaftarGambar(dynamic value) {
      if (value == null) return null;
      if (value is! List) return null;
      return value.where((e) => e != null).map((e) => e.toString()).toList();
    }

    return KomunitasPostingan(
      id: parseInt(json['id']),
      userId: json['user_id'] != null ? parseInt(json['user_id']) : null,

      coverPath: json['cover_path'] as String?,
      daftarGambar: parseDaftarGambar(json['daftar_gambar']),

      judul: (json['judul'] as String? ?? '').trim(),
      konten: (json['konten'] as String?)?.trim(),
      excerpt: (json['excerpt'] as String? ?? '').trim(),

      isAnonymous: _parseBool(json['is_anonymous']),
      isPublished: _parseBool(json['is_published']),

      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),

      user: json['user'] != null ? User.fromJson(json['user']) : null,

      kategori: json['kategori'] != null
          ? KategoriArtikel.fromJson(json['kategori'])
          : null,

      komentars: (json['komentars'] as List?)
          ?.map((e) => Komentar.fromJson(e))
          .toList(),

      likes: (json['likes'] as List?)?.map((e) => Like.fromJson(e)).toList(),

      likesCount: json['likes_count'] != null
          ? parseInt(json['likes_count'])
          : null,
      komentarsCount: json['komentars_count'] != null
          ? parseInt(json['komentars_count'])
          : null,
      liked: _parseBoolNullable(json['liked']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'cover_path': coverPath,
      'daftar_gambar': daftarGambar,
      'judul': judul,
      'konten': konten,
      'excerpt': excerpt,
      'is_anonymous': isAnonymous,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user': user?.toJson(),
      'kategori': kategori?.toJson(),
      'komentars': komentars?.map((e) => e.toJson()).toList(),
      'likes': likes?.map((e) => e.toJson()).toList(),
      'likes_count': likesCount,
      'komentars_count': komentarsCount,
      'liked': liked,
    };
  }

  KomunitasPostingan copyWith({
    List<Komentar>? komentars,
    List<Like>? likes,
    int? likesCount,
    int? komentarsCount,
    bool? liked,
  }) {
    return KomunitasPostingan(
      id: id,
      userId: userId,
      judul: judul,
      konten: konten,
      excerpt: excerpt,
      isAnonymous: isAnonymous,
      isPublished: isPublished,
      createdAt: createdAt,
      updatedAt: updatedAt,
      user: user,
      kategori: kategori,
      komentars: komentars ?? this.komentars,
      likes: likes ?? this.likes,
      likesCount: likesCount ?? this.likesCount,
      komentarsCount: komentarsCount ?? this.komentarsCount,
      liked: liked ?? this.liked,
    );
  }
}

class Komentar {
  final int id;
  final int userId;
  final int postinganId;
  final String komentar;
  final bool? isAnonymous;
  final bool? isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;

  Komentar({
    required this.id,
    required this.userId,
    required this.postinganId,
    required this.komentar,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.isAnonymous,
    this.isPublished,
  });

  factory Komentar.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is String) return int.tryParse(v) ?? 0;
      return v as int;
    }

    return Komentar(
      id: parseInt(json['id']),
      userId: parseInt(json['user_id']),
      postinganId: parseInt(json['postingan_id']),
      komentar: json['komentar'] as String? ?? '',
      isAnonymous: _parseBool(json['is_anonymous']),
      isPublished: _parseBool(json['is_published']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'postingan_id': postinganId,
      'komentar': komentar,
      'is_anonymous': isAnonymous,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user': user?.toJson(),
    };
  }
}

class Like {
  final int id;
  final int userId;
  final int postinganId;
  final bool isLike;

  Like({
    required this.id,
    required this.userId,
    required this.postinganId,
    required this.isLike,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is String) return int.tryParse(v) ?? 0;
      return v as int;
    }

    return Like(
      id: parseInt(json['id']),
      userId: parseInt(json['user_id']),
      postinganId: parseInt(json['postingan_id']),
      isLike: _parseBool(json['is_like']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'postingan_id': postinganId,
    'is_like': isLike,
  };
}
