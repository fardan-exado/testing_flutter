import 'package:hive/hive.dart';
import 'package:test_flutter/core/constants/hive_type_id.dart';
import 'package:test_flutter/data/models/sholat/sholat.dart';

part 'sholat_cache.g.dart';

@HiveType(typeId: HiveTypeId.sholat)
class SholatCache extends HiveObject {
  @HiveField(0)
  String tanggal;

  @HiveField(1)
  SholatWajib wajib;

  @HiveField(2)
  List<SholatSunnah> sunnah;

  @HiveField(3)
  DateTime cachedAt;

  SholatCache({
    required this.tanggal,
    required this.wajib,
    required this.sunnah,
    required this.cachedAt,
  });

  factory SholatCache.fromSholat(Sholat s) {
    return SholatCache(
      tanggal: s.tanggal,
      wajib: SholatWajib.fromJson(s.wajib.toJson()),
      sunnah: s.sunnah
          .map((item) => SholatSunnah.fromJson(item.toJson()))
          .toList(),
      cachedAt: DateTime.now(),
    );
  }

  Sholat toSholat() {
    return Sholat(
      tanggal: tanggal,
      wajib: SholatWajib.fromJson(wajib.toJson()),
      sunnah: sunnah
          .map((item) => SholatSunnah.fromJson(item.toJson()))
          .toList(),
    );
  }
}

// @HiveType(typeId: HiveTypeId.sholatWajib)
// class SholatWajibCache extends HiveObject {
//   @HiveField(0)
//   String shubuh;

//   @HiveField(1)
//   String dzuhur;

//   @HiveField(2)
//   String ashar;

//   @HiveField(3)
//   String maghrib;

//   @HiveField(4)
//   String isya;

//   @HiveField(5)
//   String imsak;

//   @HiveField(6)
//   String sunrise;

//   SholatWajibCache({
//     required this.imsak,
//     required this.sunrise,
//     required this.shubuh,
//     required this.dzuhur,
//     required this.ashar,
//     required this.maghrib,
//     required this.isya,
//   });

//   factory SholatWajibCache.fromSholatWajib(SholatWajib s) {
//     return SholatWajibCache(
//       imsak: s.imsak,
//       sunrise: s.sunrise,
//       shubuh: s.shubuh,
//       dzuhur: s.dzuhur,
//       ashar: s.ashar,
//       maghrib: s.maghrib,
//       isya: s.isya,
//     );
//   }

//   SholatWajib toSholatWajib() {
//     return SholatWajib(
//       imsak: imsak,
//       sunrise: sunrise,
//       shubuh: shubuh,
//       dzuhur: dzuhur,
//       ashar: ashar,
//       maghrib: maghrib,
//       isya: isya,
//     );
//   }
// }

// @HiveType(typeId: HiveTypeId.sholatSunnah)
// class SholatSunnahCache extends HiveObject {
//   @HiveField(0)
//   String tahajud;

//   @HiveField(1)
//   String witir;

//   @HiveField(2)
//   String dhuha;

//   @HiveField(3)
//   String qabliyahSubuh;

//   @HiveField(4)
//   String qabliyahDzuhur;

//   @HiveField(5)
//   String baDiyahDzuhur;

//   @HiveField(6)
//   String qabliyahAshar;

//   @HiveField(7)
//   String baDiyahMaghrib;

//   @HiveField(8)
//   String qabliyahIsya;

//   @HiveField(9)
//   String baDiyahIsya;

//   SholatSunnahCache({
//     required this.tahajud,
//     required this.witir,
//     required this.dhuha,
//     required this.qabliyahSubuh,
//     required this.qabliyahDzuhur,
//     required this.baDiyahDzuhur,
//     required this.qabliyahAshar,
//     required this.baDiyahMaghrib,
//     required this.qabliyahIsya,
//     required this.baDiyahIsya,
//   });

//   factory SholatSunnahCache.fromSholatSunnah(SholatSunnah s) {
//     return SholatSunnahCache(
//       tahajud: s.tahajud,
//       witir: s.witir,
//       dhuha: s.dhuha,
//       qabliyahSubuh: s.qabliyahSubuh,
//       qabliyahDzuhur: s.qabliyahDzuhur,
//       baDiyahDzuhur: s.baDiyahDzuhur,
//       qabliyahAshar: s.qabliyahAshar,
//       baDiyahMaghrib: s.baDiyahMaghrib,
//       qabliyahIsya: s.qabliyahIsya,
//       baDiyahIsya: s.baDiyahIsya,
//     );
//   }

//   SholatSunnah toSholatSunnah() {
//     return SholatSunnah(
//       tahajud: tahajud,
//       witir: witir,
//       dhuha: dhuha,
//       qabliyahSubuh: qabliyahSubuh,
//       qabliyahDzuhur: qabliyahDzuhur,
//       baDiyahDzuhur: baDiyahDzuhur,
//       qabliyahAshar: qabliyahAshar,
//       baDiyahMaghrib: baDiyahMaghrib,
//       qabliyahIsya: qabliyahIsya,
//       baDiyahIsya: baDiyahIsya,
//     );
//   }
// }
