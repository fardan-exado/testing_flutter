import 'package:hive/hive.dart';
import 'package:test_flutter/core/constants/hive_type_id.dart';
import 'package:test_flutter/features/sholat/models/progres_sholat/progress_sholat.dart';
import 'package:test_flutter/features/sholat/models/sholat/sholat.dart';

part 'progres_sholat_cache.g.dart';

// =====================================================
// WAJIB
// =====================================================

@HiveType(typeId: HiveTypeId.riwayatProgresWajib)
class RiwayatProgresWajibCache extends HiveObject {
  @HiveField(0)
  SholatWajib sholatWajib;

  @HiveField(1)
  bool status;

  @HiveField(2)
  ProgresWajibDetail? progress;

  @HiveField(3)
  DateTime cachedAt;

  RiwayatProgresWajibCache({
    required this.sholatWajib,
    required this.status,
    required this.progress,
    required this.cachedAt,
  });

  factory RiwayatProgresWajibCache.fromModel(RiwayatProgresWajib model) {
    return RiwayatProgresWajibCache(
      sholatWajib: model.sholatWajib,
      status: model.status,
      progress: model.progress,
      cachedAt: DateTime.now(),
    );
  }

  RiwayatProgresWajib toModel() {
    return RiwayatProgresWajib(
      sholatWajib: sholatWajib,
      status: status,
      progress: progress,
    );
  }
}

// =====================================================
// SUNNAH
// =====================================================

@HiveType(typeId: HiveTypeId.riwayatProgresSunnah)
class RiwayatProgresSunnahCache extends HiveObject {
  @HiveField(0)
  Sunnah sholatSunnah;

  @HiveField(1)
  bool status;

  @HiveField(2)
  ProgresSunnahDetail? progress;

  @HiveField(3)
  DateTime cachedAt;

  RiwayatProgresSunnahCache({
    required this.sholatSunnah,
    required this.status,
    required this.progress,
    required this.cachedAt,
  });

  factory RiwayatProgresSunnahCache.fromModel(RiwayatProgresSunnah model) {
    return RiwayatProgresSunnahCache(
      sholatSunnah: model.sholatSunnah,
      status: model.status,
      progress: model.progress,
      cachedAt: DateTime.now(),
    );
  }

  RiwayatProgresSunnah toModel() {
    return RiwayatProgresSunnah(
      sholatSunnah: sholatSunnah,
      status: status,
      progress: progress,
    );
  }
}
