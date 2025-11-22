import 'package:hive/hive.dart';
import 'package:test_flutter/features/artikel/models/kategori/kategori_artikel.dart';
import 'package:test_flutter/core/constants/hive_type_id.dart';

part 'kategori_artikel_cache.g.dart';

@HiveType(typeId: HiveTypeId.kategoriArtikel)
class KategoriArtikelCache extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String nama;

  @HiveField(2)
  String? iconPath;

  @HiveField(3)
  String? icon;

  @HiveField(5)
  DateTime? createdAt;

  @HiveField(6)
  DateTime? updatedAt;

  @HiveField(7)
  DateTime cachedAt;

  KategoriArtikelCache({
    required this.id,
    required this.nama,
    this.iconPath,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
    required this.cachedAt,
  });

  factory KategoriArtikelCache.fromKategoriArtikel(KategoriArtikel k) {
    return KategoriArtikelCache(
      id: k.id,
      nama: k.nama,
      iconPath: k.iconPath,
      icon: k.icon,
      createdAt: k.createdAt,
      updatedAt: k.updatedAt,
      cachedAt: DateTime.now(),
    );
  }

  KategoriArtikel toKategoriArtikel() {
    return KategoriArtikel(
      id: id,
      nama: nama,
      iconPath: iconPath,
      icon: icon,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
