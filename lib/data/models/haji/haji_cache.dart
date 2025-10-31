import 'package:hive/hive.dart';
import 'package:test_flutter/core/constants/hive_type_id.dart';
import 'package:test_flutter/data/models/haji/haji.dart';

part 'haji_cache.g.dart';

@HiveType(typeId: HiveTypeId.haji)
class HajiCache extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String judul;

  @HiveField(2)
  String cover;

  @HiveField(3)
  String tipe;

  @HiveField(4)
  String? videoUrl;

  @HiveField(5)
  List<String>? daftarGambar;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  @HiveField(8)
  String? excerpt;

  @HiveField(9)
  String? penulis;

  @HiveField(10)
  String? konten;

  @HiveField(11)
  DateTime cachedAt;

  HajiCache({
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
    required this.cachedAt,
  });

  /// Convert dari model Haji → HajiCache
  factory HajiCache.fromHaji(Haji h) {
    return HajiCache(
      id: h.id,
      judul: h.judul,
      cover: h.cover,
      tipe: h.tipe,
      videoUrl: h.videoUrl,
      konten: h.konten,
      daftarGambar: h.daftarGambar,
      createdAt: h.createdAt,
      updatedAt: h.updatedAt,
      excerpt: h.excerpt,
      penulis: h.penulis,
      cachedAt: DateTime.now(),
    );
  }

  /// Convert dari HajiCache → Haji
  Haji toHaji() {
    return Haji(
      id: id,
      judul: judul,
      cover: cover,
      tipe: tipe,
      videoUrl: videoUrl,
      konten: konten,
      daftarGambar: daftarGambar,
      createdAt: createdAt,
      updatedAt: updatedAt,
      excerpt: excerpt,
      penulis: penulis,
    );
  }
}
