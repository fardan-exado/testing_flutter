import 'package:hive/hive.dart';
import 'package:test_flutter/core/constants/hive_type_id.dart';
import 'package:test_flutter/features/artikel/models/kategori/kategori_artikel_cache.dart';
import 'package:test_flutter/data/models/komunitas/komunitas.dart';

part 'komunitas_cache.g.dart';

@HiveType(typeId: HiveTypeId.postingan)
class KomunitasPostinganCache extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  int userId;

  @HiveField(2)
  int kategoriId;

  @HiveField(3)
  String judul;

  @HiveField(4)
  String excerpt;

  @HiveField(5)
  String cover;

  @HiveField(6)
  List<String> daftarGambar;

  @HiveField(7)
  int totalLikes;

  @HiveField(8)
  int totalKomentar;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  @HiveField(11)
  DateTime cachedAt;

  @HiveField(12)
  String penulis;

  @HiveField(13)
  KategoriArtikelCache kategori;

  KomunitasPostinganCache({
    required this.id,
    required this.userId,
    required this.kategoriId,
    required this.judul,
    required this.excerpt,
    required this.cover,
    required this.daftarGambar,
    required this.totalLikes,
    required this.totalKomentar,
    required this.createdAt,
    required this.updatedAt,
    required this.cachedAt,
    required this.penulis,
    required this.kategori,
  });

  factory KomunitasPostinganCache.fromKomunitasPostingan(
    KomunitasPostingan artikel,
  ) {
    return KomunitasPostinganCache(
      id: artikel.id,
      userId: artikel.userId,
      kategoriId: artikel.kategoriId,
      judul: artikel.judul,
      excerpt: artikel.excerpt,
      cover: artikel.cover,
      daftarGambar: artikel.daftarGambar,
      totalLikes: artikel.totalLikes,
      totalKomentar: artikel.totalKomentar,
      createdAt: artikel.createdAt,
      updatedAt: artikel.updatedAt,
      cachedAt: DateTime.now(),
      penulis: artikel.penulis,
      kategori: KategoriArtikelCache.fromKategoriArtikel(artikel.kategori),
    );
  }

  KomunitasPostingan toKomunitasPostingan() {
    return KomunitasPostingan(
      id: id,
      userId: userId,
      kategoriId: kategoriId,
      judul: judul,
      excerpt: excerpt,
      cover: cover,
      daftarGambar: daftarGambar,
      totalLikes: totalLikes,
      totalKomentar: totalKomentar,
      createdAt: createdAt,
      updatedAt: updatedAt,
      penulis: penulis,
      kategori: kategori.toKategoriArtikel(),
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
  String penulis;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  DateTime cachedAt;

  KomentarPostinganCache({
    required this.id,
    required this.postinganId,
    required this.userId,
    required this.komentar,
    required this.penulis,
    required this.createdAt,
    required this.updatedAt,
    required this.cachedAt,
  });

  factory KomentarPostinganCache.fromKomentarPostingan(Komentar komentar) {
    return KomentarPostinganCache(
      id: komentar.id,
      postinganId: komentar.postinganId,
      userId: komentar.userId,
      komentar: komentar.komentar,
      penulis: komentar.penulis,
      createdAt: komentar.createdAt,
      updatedAt: komentar.updatedAt,
      cachedAt: DateTime.now(),
    );
  }

  Komentar toKomentarPostingan() {
    return Komentar(
      id: id,
      postinganId: postinganId,
      userId: userId,
      komentar: komentar,
      penulis: penulis,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
