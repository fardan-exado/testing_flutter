import 'package:hive/hive.dart';
import 'package:test_flutter/core/constants/hive_type_id.dart';
import 'package:test_flutter/data/models/user/user.dart';
import 'package:test_flutter/features/artikel/models/kategori/kategori_artikel_cache.dart';
import 'package:test_flutter/features/komunitas/models/komunitas/komunitas.dart';

part 'komunitas_cache.g.dart';

String _safeString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

List<String> _safeListString(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value
        .where((e) => e != null && e.toString().isNotEmpty)
        .map((e) => e.toString())
        .toList();
  }
  return [];
}

@HiveType(typeId: HiveTypeId.postingan)
class KomunitasPostinganCache extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  int? userId;

  @HiveField(2)
  int? postinganId;

  @HiveField(3)
  String judul;

  @HiveField(4)
  String? konten;

  @HiveField(5)
  String excerpt;

  @HiveField(6)
  bool isAnonymous;

  @HiveField(7)
  bool isPublished;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  DateTime cachedAt;

  @HiveField(11)
  KategoriArtikelCache? kategori;

  @HiveField(12)
  int? likesCount;

  @HiveField(13)
  int? komentarsCount;

  @HiveField(14)
  bool? liked;

  @HiveField(15)
  List<String> daftarGambar = [];

  @HiveField(16)
  String coverPath = '';

  KomunitasPostinganCache({
    required this.id,
    required this.userId,
    this.postinganId,
    required this.judul,
    this.konten,
    required this.excerpt,
    required this.isAnonymous,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    required this.cachedAt,
    this.kategori,
    this.likesCount,
    this.komentarsCount,
    this.liked,
    List<String>? daftarGambar,
    String? coverPath,
  }) : daftarGambar = _safeListString(daftarGambar),
       coverPath = _safeString(coverPath);

  factory KomunitasPostinganCache.fromKomunitasPostingan(KomunitasPostingan d) {
    return KomunitasPostinganCache(
      id: d.id,
      userId: d.userId,
      postinganId: null,
      judul: d.judul,
      konten: d.konten,
      excerpt: d.excerpt,
      isAnonymous: d.isAnonymous,
      isPublished: d.isPublished,
      createdAt: d.createdAt,
      updatedAt: d.updatedAt,
      cachedAt: DateTime.now(),
      kategori: d.kategori != null
          ? KategoriArtikelCache.fromKategoriArtikel(d.kategori!)
          : null,
      likesCount: d.likesCount,
      komentarsCount: d.komentarsCount,
      liked: d.liked,
      daftarGambar: _safeListString(d.daftarGambar),
      coverPath: _safeString(d.coverPath),
    );
  }

  KomunitasPostingan toKomunitasPostingan() {
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
      kategori: kategori?.toKategoriArtikel(),
      liked: liked,
      likesCount: likesCount,
      komentarsCount: komentarsCount,
      daftarGambar: _safeListString(daftarGambar),
      coverPath: _safeString(coverPath),
      komentars: null,
      likes: null,
      user: null,
    );
  }
}

@HiveType(typeId: HiveTypeId.komentarPostingan)
class KomentarPostinganCache extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  int postinganId;

  @HiveField(2)
  int userId;

  @HiveField(3)
  String komentar;

  @HiveField(4)
  bool? isAnonymous;

  @HiveField(5)
  bool? isPublished;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  @HiveField(8)
  User? user;

  @HiveField(9)
  DateTime cachedAt;

  KomentarPostinganCache({
    required this.id,
    required this.postinganId,
    required this.userId,
    required this.komentar,
    this.isAnonymous,
    this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    required this.cachedAt,
    this.user,
  });

  factory KomentarPostinganCache.fromKomentarPostingan(Komentar d) {
    return KomentarPostinganCache(
      id: d.id,
      postinganId: d.postinganId,
      userId: d.userId,
      komentar: _safeString(d.komentar),
      isAnonymous: d.isAnonymous,
      isPublished: d.isPublished,
      createdAt: d.createdAt,
      updatedAt: d.updatedAt,
      user: d.user,
      cachedAt: DateTime.now(),
    );
  }

  Komentar toKomentarPostingan() {
    return Komentar(
      id: id,
      postinganId: postinganId,
      userId: userId,
      komentar: _safeString(komentar),
      isAnonymous: isAnonymous,
      isPublished: isPublished,
      createdAt: createdAt,
      updatedAt: updatedAt,
      user: user,
    );
  }
}
