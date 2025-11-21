import 'package:hive/hive.dart';
import 'package:test_flutter/core/constants/hive_type_id.dart';
import 'package:test_flutter/data/models/user/user.dart';
import 'package:test_flutter/features/artikel/models/kategori/kategori_artikel_cache.dart';
import 'package:test_flutter/features/komunitas/models/komunitas/komunitas.dart';

part 'komunitas_cache.g.dart';

@HiveType(typeId: HiveTypeId.postingan)
class KomunitasPostinganCache extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  int userId;

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
  List<String>? daftarGambar;

  @HiveField(16)
  String? coverPath;

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
    this.daftarGambar,
    this.coverPath,
  });

  factory KomunitasPostinganCache.fromKomunitasPostingan(
    KomunitasPostingan data,
  ) {
    return KomunitasPostinganCache(
      id: data.id,
      userId: data.userId,
      postinganId: data.postinganId,
      judul: data.judul,
      konten: data.konten,
      excerpt: data.excerpt,
      isAnonymous: data.isAnonymous,
      isPublished: data.isPublished,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      cachedAt: DateTime.now(),
      kategori: data.kategori != null
          ? KategoriArtikelCache.fromKategoriArtikel(data.kategori!)
          : null,
      likesCount: data.likesCount,
      komentarsCount: data.komentarsCount,
      liked: data.liked,
      daftarGambar: data.daftarGambar,
      coverPath: data.coverPath,
    );
  }

  KomunitasPostingan toKomunitasPostingan() {
    return KomunitasPostingan(
      id: id,
      userId: userId,
      postinganId: postinganId,
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
      komentars: null,
      likes: null,
      user: null,
      daftarGambar: daftarGambar,
      coverPath: coverPath,
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

  factory KomentarPostinganCache.fromKomentarPostingan(Komentar data) {
    return KomentarPostinganCache(
      id: data.id,
      postinganId: data.postinganId,
      userId: data.userId,
      komentar: data.komentar,
      isAnonymous: data.isAnonymous,
      isPublished: data.isPublished,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      user: data.user,
      cachedAt: DateTime.now(),
    );
  }

  Komentar toKomentarPostingan() {
    return Komentar(
      id: id,
      postinganId: postinganId,
      userId: userId,
      komentar: komentar,
      isAnonymous: isAnonymous,
      isPublished: isPublished,
      createdAt: createdAt,
      updatedAt: updatedAt,
      user: user,
    );
  }
}
