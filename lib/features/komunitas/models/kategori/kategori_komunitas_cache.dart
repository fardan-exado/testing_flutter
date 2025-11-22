import 'package:hive/hive.dart';
import 'package:test_flutter/core/constants/hive_type_id.dart';
import 'package:test_flutter/features/komunitas/models/kategori/kategori_komunitas.dart';

part 'kategori_komunitas_cache.g.dart';

@HiveType(typeId: HiveTypeId.kategoriKomunitas)
class KategoriKomunitasCache extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String nama;

  @HiveField(2)
  String? iconPath;

  @HiveField(3)
  String? icon;

  @HiveField(4)
  DateTime? createdAt;

  @HiveField(5)
  DateTime? updatedAt;

  @HiveField(6)
  DateTime cachedAt;

  KategoriKomunitasCache({
    required this.id,
    required this.nama,
    this.iconPath,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
    required this.cachedAt,
  });

  factory KategoriKomunitasCache.fromKategoriKomunitas(KategoriKomunitas k) {
    return KategoriKomunitasCache(
      id: k.id,
      nama: k.nama,
      iconPath: k.iconPath,
      icon: k.icon,
      createdAt: k.createdAt,
      updatedAt: k.updatedAt,
      cachedAt: DateTime.now(),
    );
  }

  KategoriKomunitas toKategoriKomunitas() {
    return KategoriKomunitas(
      id: id,
      nama: nama,
      iconPath: iconPath,
      icon: icon,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
