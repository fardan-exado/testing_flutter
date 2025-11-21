import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:test_flutter/core/constants/hive_type_id.dart';
import 'package:test_flutter/features/sholat/models/progres_sholat/progress_sholat.dart';

part 'progres_sholat_cache.g.dart';

/// 1) PROGRES WAJIB HARI INI
///
/// simpen: json + cachedAt
@HiveType(typeId: HiveTypeId.progresWajibHariIni)
class ProgresWajibHariIniCache extends HiveObject {
  @HiveField(0)
  String dataJson;

  @HiveField(1)
  DateTime cachedAt;

  ProgresWajibHariIniCache({required this.dataJson, required this.cachedAt});

  factory ProgresWajibHariIniCache.fromModel(ProgresWajibHariIni model) {
    return ProgresWajibHariIniCache(
      dataJson: jsonEncode(model.toJson()),
      cachedAt: DateTime.now(),
    );
  }

  ProgresWajibHariIni toModel() {
    final map = jsonDecode(dataJson) as Map<String, dynamic>;
    return ProgresWajibHariIni.fromJson(map);
  }
}

/// 2) RIWAYAT PROGRES WAJIB
///
/// bentuk API: { "2025-11-02": [ ... ] }
@HiveType(typeId: HiveTypeId.riwayatProgresWajib)
class RiwayatProgresWajibCache extends HiveObject {
  @HiveField(0)
  String dataJson;

  @HiveField(1)
  DateTime cachedAt;

  RiwayatProgresWajibCache({required this.dataJson, required this.cachedAt});

  factory RiwayatProgresWajibCache.fromModel(RiwayatProgresWajib model) {
    return RiwayatProgresWajibCache(
      dataJson: jsonEncode(model.toJson()),
      cachedAt: DateTime.now(),
    );
  }

  RiwayatProgresWajib toModel() {
    final map = jsonDecode(dataJson) as Map<String, dynamic>;
    return RiwayatProgresWajib.fromJson(map);
  }
}

/// 3) PROGRES SUNNAH HARI INI
///
/// API lo: data: [ { sholat_sunnah: {...}, progres: false }, ... ]
/// kita simpen langsung list itu
@HiveType(typeId: HiveTypeId.progresSunnahHariIni)
class ProgresSunnahHariIniCache extends HiveObject {
  @HiveField(0)
  String dataJson;

  @HiveField(1)
  DateTime cachedAt;

  ProgresSunnahHariIniCache({required this.dataJson, required this.cachedAt});

  factory ProgresSunnahHariIniCache.fromModel(ProgresSunnahHariIni model) {
    // model.toJson() sebenernya return List<Map<String, dynamic>>
    return ProgresSunnahHariIniCache(
      dataJson: jsonEncode(model.toJson()),
      cachedAt: DateTime.now(),
    );
  }

  ProgresSunnahHariIni toModel() {
    final list = jsonDecode(dataJson) as List<dynamic>;
    return ProgresSunnahHariIni.fromJson(list);
  }
}

/// 4) RIWAYAT PROGRES SUNNAH
///
/// API lo: { "2025-11-01": [ {...}, {...} ] }
@HiveType(typeId: HiveTypeId.riwayatProgresSunnah)
class RiwayatProgresSunnahCache extends HiveObject {
  @HiveField(0)
  String dataJson;

  @HiveField(1)
  DateTime cachedAt;

  RiwayatProgresSunnahCache({required this.dataJson, required this.cachedAt});

  factory RiwayatProgresSunnahCache.fromModel(RiwayatProgresSunnah model) {
    return RiwayatProgresSunnahCache(
      dataJson: jsonEncode(model.toJson()),
      cachedAt: DateTime.now(),
    );
  }

  RiwayatProgresSunnah toModel() {
    final map = jsonDecode(dataJson) as Map<String, dynamic>;
    return RiwayatProgresSunnah.fromJson(map);
  }
}
