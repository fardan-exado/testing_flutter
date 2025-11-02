import 'package:test_flutter/data/models/sholat/sholat.dart';

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final v = value.toLowerCase();
    return v == '1' || v == 'true';
  }
  return false;
}

// =====================================================
// PROGRES SHOLAT WAJIB HARI INI
// =====================================================
class ProgresWajibHariIni {
  final int total;
  final StatistikSholatWajib statistik;
  final List<ProgresWajibDetail> detail;

  ProgresWajibHariIni({
    required this.total,
    required this.statistik,
    required this.detail,
  });

  factory ProgresWajibHariIni.fromJson(Map<String, dynamic> json) {
    final detailList = (json['detail'] as List? ?? [])
        .map((e) => ProgresWajibDetail.fromJson(e))
        .toList();

    return ProgresWajibHariIni(
      total: json['total'] is int
          ? json['total']
          : int.tryParse(json['total']?.toString() ?? '') ?? 0,
      statistik: StatistikSholatWajib.fromJson(
        json['statistik'] as Map<String, dynamic>? ?? {},
      ),
      detail: detailList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'statistik': statistik.toJson(),
      'detail': detail.map((e) => e.toJson()).toList(),
    };
  }
}

class StatistikSholatWajib {
  final bool shubuh;
  final bool dzuhur;
  final bool ashar;
  final bool maghrib;
  final bool isya;

  StatistikSholatWajib({
    required this.shubuh,
    required this.dzuhur,
    required this.ashar,
    required this.maghrib,
    required this.isya,
  });

  factory StatistikSholatWajib.fromJson(Map<String, dynamic> json) {
    return StatistikSholatWajib(
      shubuh: _parseBool(json['shubuh'] ?? json['subuh'] ?? false),
      dzuhur: _parseBool(json['dzuhur']),
      ashar: _parseBool(json['ashar']),
      maghrib: _parseBool(json['maghrib']),
      isya: _parseBool(json['isya']),
    );
  }

  Map<String, dynamic> toJson() => {
    'shubuh': shubuh,
    'dzuhur': dzuhur,
    'ashar': ashar,
    'maghrib': maghrib,
    'isya': isya,
  };
}

class ProgresWajibDetail {
  final int id;
  final int userId;
  final int sholatWajibId;
  final String status;
  final bool isJamaah;
  final String lokasi;
  final String tanggal;
  final String? keterangan;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProgresWajibDetail({
    required this.id,
    required this.userId,
    required this.sholatWajibId,
    required this.status,
    required this.isJamaah,
    required this.lokasi,
    required this.tanggal,
    this.keterangan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProgresWajibDetail.fromJson(Map<String, dynamic> json) {
    return ProgresWajibDetail(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      sholatWajibId: int.tryParse(json['sholat_wajib_id'].toString()) ?? 0,
      status: json['status']?.toString() ?? '',
      isJamaah: _parseBool(json['is_jamaah']),
      lokasi: json['lokasi']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? '',
      keterangan: json['keterangan']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'sholat_wajib_id': sholatWajibId,
    'status': status,
    'is_jamaah': isJamaah ? 1 : 0,
    'lokasi': lokasi,
    'tanggal': tanggal,
    'keterangan': keterangan,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

// =====================================================
// RIWAYAT PROGRES WAJIB
// =====================================================
class RiwayatProgresWajib {
  final Map<String, List<ProgresWajibDetail>> data;

  RiwayatProgresWajib({required this.data});

  factory RiwayatProgresWajib.fromJson(Map<String, dynamic> json) {
    final Map<String, List<ProgresWajibDetail>> riwayat = {};
    json.forEach((tanggal, list) {
      if (list is List) {
        riwayat[tanggal] = list
            .map((item) => ProgresWajibDetail.fromJson(item))
            .toList();
      }
    });
    return RiwayatProgresWajib(data: riwayat);
  }

  Map<String, dynamic> toJson() => data.map(
    (tgl, list) => MapEntry(tgl, list.map((e) => e.toJson()).toList()),
  );
}

// =====================================================
// PROGRES SHOLAT SUNNAH HARI INI
// =====================================================
class ProgresSunnahHariIni {
  final List<ProgresSunnahItem> data;

  ProgresSunnahHariIni({required this.data});

  factory ProgresSunnahHariIni.fromJson(List<dynamic> json) {
    return ProgresSunnahHariIni(
      data: json.map((e) => ProgresSunnahItem.fromJson(e)).toList(),
    );
  }

  List<Map<String, dynamic>> toJson() => data.map((e) => e.toJson()).toList();
}

class ProgresSunnahItem {
  final SholatSunnah sholatSunnah;
  final bool progres;

  ProgresSunnahItem({required this.sholatSunnah, required this.progres});

  factory ProgresSunnahItem.fromJson(Map<String, dynamic> json) {
    return ProgresSunnahItem(
      sholatSunnah: SholatSunnah.fromJson(json['sholat_sunnah']),
      progres: _parseBool(json['progres']),
    );
  }

  Map<String, dynamic> toJson() => {
    'sholat_sunnah': sholatSunnah.toJson(),
    'progres': progres,
  };
}

class ProgresSunnahDetail {
  final int id;
  final int userId;
  final int sholatSunnahId;
  final String status;
  final bool isJamaah;
  final String lokasi;
  final String tanggal;
  final String? keterangan;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProgresSunnahDetail({
    required this.id,
    required this.userId,
    required this.sholatSunnahId,
    required this.status,
    required this.isJamaah,
    required this.lokasi,
    required this.tanggal,
    this.keterangan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProgresSunnahDetail.fromJson(Map<String, dynamic> json) {
    return ProgresSunnahDetail(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      sholatSunnahId: int.tryParse(json['sholat_sunnah_id'].toString()) ?? 0,
      status: json['status']?.toString() ?? '',
      isJamaah: _parseBool(json['is_jamaah']),
      lokasi: json['lokasi']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? '',
      keterangan: json['keterangan']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'sholat_sunnah_id': sholatSunnahId,
    'status': status,
    'is_jamaah': isJamaah ? 1 : 0,
    'lokasi': lokasi,
    'tanggal': tanggal,
    'keterangan': keterangan,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

// =====================================================
// RIWAYAT PROGRES SUNNAH
// =====================================================
class RiwayatProgresSunnah {
  final Map<String, List<ProgresSunnahDetail>> data;

  RiwayatProgresSunnah({required this.data});

  factory RiwayatProgresSunnah.fromJson(Map<String, dynamic> json) {
    final Map<String, List<ProgresSunnahDetail>> riwayat = {};
    json.forEach((tanggal, list) {
      if (list is List) {
        riwayat[tanggal] = list
            .map((item) => ProgresSunnahDetail.fromJson(item))
            .toList();
      }
    });
    return RiwayatProgresSunnah(data: riwayat);
  }

  Map<String, dynamic> toJson() => data.map(
    (tgl, list) => MapEntry(tgl, list.map((e) => e.toJson()).toList()),
  );
}
