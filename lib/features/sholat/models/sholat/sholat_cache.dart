import 'package:hive/hive.dart';
import 'package:test_flutter/core/constants/hive_type_id.dart';
import 'package:test_flutter/features/sholat/models/sholat/sholat.dart';

part 'sholat_cache.g.dart';

@HiveType(typeId: HiveTypeId.jadwalSholat)
class JadwalSholatCache extends HiveObject {
  @HiveField(0)
  late String tanggal;

  @HiveField(1)
  late Wajib wajib;

  @HiveField(2)
  late List<Sunnah> sunnah;

  @HiveField(3)
  late DateTime cachedAt;

  JadwalSholatCache({
    required this.tanggal,
    required this.wajib,
    required this.sunnah,
    required this.cachedAt,
  });

  factory JadwalSholatCache.fromSholat(JadwalSholatCache s) {
    return JadwalSholatCache(
      tanggal: s.tanggal,
      wajib: Wajib.fromJson(s.wajib.toJson()),
      sunnah: s.sunnah.map((item) => Sunnah.fromJson(item.toJson())).toList(),
      cachedAt: DateTime.now(),
    );
  }

  JadwalSholatCache toSholat() {
    return JadwalSholatCache(
      tanggal: tanggal,
      wajib: Wajib.fromJson(wajib.toJson()),
      sunnah: sunnah.map((item) => Sunnah.fromJson(item.toJson())).toList(),
      cachedAt: cachedAt,
    );
  }
}
