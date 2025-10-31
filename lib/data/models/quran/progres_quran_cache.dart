import 'package:hive/hive.dart';
import 'package:test_flutter/core/constants/hive_type_id.dart';
import 'package:test_flutter/data/models/quran/progres_quran.dart';

part 'progres_quran_cache.g.dart';

@HiveType(typeId: HiveTypeId.progresQuran)
class ProgresBacaQuranCache extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  int userId;

  @HiveField(2)
  int suratId;

  @HiveField(3)
  int ayat;

  @HiveField(4)
  String? createdAt;

  @HiveField(5)
  Map<String, dynamic>? surat;

  @HiveField(6)
  DateTime cachedAt;

  ProgresBacaQuranCache({
    required this.id,
    required this.userId,
    required this.suratId,
    required this.ayat,
    this.createdAt,
    this.surat,
    required this.cachedAt,
  });

  factory ProgresBacaQuranCache.fromModel(ProgresBacaQuran m) {
    return ProgresBacaQuranCache(
      id: m.id,
      userId: m.userId,
      suratId: m.suratId,
      ayat: m.ayat,
      createdAt: m.createdAt,
      surat: m.surat,
      cachedAt: DateTime.now(),
    );
  }

  ProgresBacaQuran toModel() {
    return ProgresBacaQuran(
      id: id,
      userId: userId,
      suratId: suratId,
      ayat: ayat,
      createdAt: createdAt,
      surat: surat,
    );
  }
}
