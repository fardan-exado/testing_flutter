import 'package:test_flutter/features/sholat/models/sholat/sholat.dart';

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
class SholatWajib {
  final int id;
  final String? iconPath;
  final String nama;
  final String slug;
  final String deskripsi;
  final DateTime createdAt;
  final DateTime updatedAt;

  SholatWajib({
    required this.id,
    this.iconPath,
    required this.nama,
    required this.slug,
    required this.deskripsi,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SholatWajib.fromJson(Map<String, dynamic> json) {
    return SholatWajib(
      id: json['id'] ?? 0,
      iconPath: json['iconPath'] ?? '',
      nama: json['nama'] ?? '',
      slug: json['slug'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'iconPath': iconPath,
      'nama': nama,
      'slug': slug,
      'deskripsi': deskripsi,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class RiwayatProgresWajib {
  final SholatWajib sholatWajib;
  final bool status;
  final ProgresWajibDetail? progress;

  RiwayatProgresWajib({
    required this.sholatWajib,
    required this.status,
    this.progress,
  });

  factory RiwayatProgresWajib.fromJson(Map<String, dynamic> json) {
    return RiwayatProgresWajib(
      sholatWajib: SholatWajib.fromJson(
        json['sholat_wajib'] as Map<String, dynamic>? ?? {},
      ),
      status: _parseBool(json['status']),
      progress: json['progress'] != null
          ? ProgresWajibDetail.fromJson(
              json['progress'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'sholat_wajib': sholatWajib.toJson(),
    'status': status,
    'progress': progress?.toJson(),
  };
}

class ProgresWajibDetail {
  final int id;
  final int userId;
  final int sholatWajibId;
  final String status;
  final bool? isJamaah;
  final String lokasi;
  final String? keterangan;
  final DateTime createdAt;

  ProgresWajibDetail({
    required this.id,
    required this.userId,
    required this.sholatWajibId,
    required this.status,
    this.isJamaah,
    required this.lokasi,
    this.keterangan,
    required this.createdAt,
  });

  factory ProgresWajibDetail.fromJson(Map<String, dynamic> json) {
    return ProgresWajibDetail(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      sholatWajibId: int.tryParse(json['sholat_wajib_id'].toString()) ?? 0,
      status: json['status']?.toString() ?? '',
      isJamaah: _parseBool(json['is_jamaah']),
      lokasi: json['lokasi']?.toString() ?? '',
      keterangan: json['keterangan']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'sholat_wajib_id': sholatWajibId,
    'status': status,
    'is_jamaah': isJamaah == true ? 1 : 0,
    'lokasi': lokasi,
    'keterangan': keterangan,
    'created_at': createdAt.toIso8601String(),
  };
}

// =====================================================
// PROGRES SHOLAT SUNNAH HARI INI
// =====================================================
class ProgresSunnahDetail {
  final int id;
  final int userId;
  final int sholatSunnahId;
  final bool isJamaah;
  final String lokasi;
  final String? keterangan;
  final DateTime createdAt;

  ProgresSunnahDetail({
    required this.id,
    required this.userId,
    required this.sholatSunnahId,
    required this.isJamaah,
    required this.lokasi,
    this.keterangan,
    required this.createdAt,
  });

  factory ProgresSunnahDetail.fromJson(Map<String, dynamic> json) {
    return ProgresSunnahDetail(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      sholatSunnahId: int.tryParse(json['sholat_sunnah_id'].toString()) ?? 0,
      isJamaah: _parseBool(json['is_jamaah']),
      lokasi: json['lokasi']?.toString() ?? '',
      keterangan: json['keterangan']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'sholat_sunnah_id': sholatSunnahId,
    'is_jamaah': isJamaah ? 1 : 0,
    'lokasi': lokasi,
    'keterangan': keterangan,
    'created_at': createdAt.toIso8601String(),
  };
}

// =====================================================
// RIWAYAT PROGRES SUNNAH
// =====================================================
class RiwayatProgresSunnah {
  final Sunnah sholatSunnah;
  final bool status;
  final ProgresSunnahDetail? progress;

  RiwayatProgresSunnah({
    required this.sholatSunnah,
    required this.status,
    this.progress,
  });

  factory RiwayatProgresSunnah.fromJson(Map<String, dynamic> json) {
    return RiwayatProgresSunnah(
      sholatSunnah: Sunnah.fromJson(
        json['sholat_sunnah'] as Map<String, dynamic>? ?? {},
      ),
      status: _parseBool(json['status']),
      progress: json['progress'] != null
          ? ProgresSunnahDetail.fromJson(
              json['progress'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'sholat_sunnah': sholatSunnah.toJson(),
    'status': status,
    'progress': progress?.toJson(),
  };
}
