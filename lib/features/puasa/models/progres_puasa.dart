// WAJIB
import 'package:test_flutter/features/puasa/models/puasa.dart';

class ProgresPuasaWajib {
  final int id;
  final int userId;
  final int? puasaWajibId; // ⬅ nullable
  final int tanggalRamadhan; // ⬅ ambil dari API
  final String tahunHijriah;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProgresPuasaWajib({
    required this.id,
    required this.userId,
    required this.tanggalRamadhan,
    this.puasaWajibId,
    required this.tahunHijriah,
    this.createdAt,
    this.updatedAt,
  });

  factory ProgresPuasaWajib.fromJson(Map<String, dynamic> json) {
    return ProgresPuasaWajib(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      tanggalRamadhan: json['tanggal_ramadhan'] ?? 0,

      // API kadang gak kirim puasa_wajib_id → aman
      puasaWajibId: json['puasa_wajib_id'] as int?,

      // handle int → String
      tahunHijriah: json['tahun_hijriah']?.toString() ?? '',

      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'tanggal_ramadhan': tanggalRamadhan,
      'puasa_wajib_id': puasaWajibId,
      'tahun_hijriah': tahunHijriah,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class RiwayatProgresPuasaWajib {
  final int tanggalRamadhan;
  final bool status;
  final ProgresPuasaWajib? progres;

  RiwayatProgresPuasaWajib({
    required this.tanggalRamadhan,
    required this.status,
    this.progres,
  });

  factory RiwayatProgresPuasaWajib.fromJson(Map<String, dynamic> json) {
    return RiwayatProgresPuasaWajib(
      tanggalRamadhan: json['tanggal_ramadhan'] as int,
      status: json['status'] as bool,
      progres: json['progres'] != null
          ? ProgresPuasaWajib.fromJson(json['progres'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tanggal_ramadhan': tanggalRamadhan,
      'status': status,
      'progres': progres?.toJson(),
    };
  }
}

// SUNNAH
class ProgresPuasaSunnah {
  final int id;
  final int userId;
  final int puasaSunnahId;
  final String tahunHijriah;
  final DateTime? createdAt;

  ProgresPuasaSunnah({
    required this.id,
    required this.userId,
    required this.puasaSunnahId,
    required this.tahunHijriah,
    this.createdAt,
  });

  factory ProgresPuasaSunnah.fromJson(Map<String, dynamic> json) {
    return ProgresPuasaSunnah(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      puasaSunnahId: json['puasa_sunnah_id'] as int,
      tahunHijriah: json['tahun_hijriah'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'puasa_sunnah_id': puasaSunnahId,
      'tahun_hijriah': tahunHijriah,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class RiwayatProgresPuasaSunnah {
  final int id;
  final int userId;
  final int puasaSunnahId;
  final String tahunHijriah;
  final DateTime? createdAt;

  final PuasaSunnah puasaSunnah;

  RiwayatProgresPuasaSunnah({
    required this.id,
    required this.userId,
    required this.puasaSunnahId,
    required this.tahunHijriah,
    required this.createdAt,
    required this.puasaSunnah,
  });

  factory RiwayatProgresPuasaSunnah.fromJson(Map<String, dynamic> json) {
    return RiwayatProgresPuasaSunnah(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      puasaSunnahId: json['puasa_sunnah_id'] as int,
      tahunHijriah: json['tahun_hijriah'].toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      puasaSunnah: PuasaSunnah.fromJson(json['puasa_sunnah']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'puasa_sunnah_id': puasaSunnahId,
      'tahun_hijriah': tahunHijriah,
      'created_at': createdAt?.toIso8601String(),
      'puasa_sunnah': puasaSunnah.toJson(),
    };
  }
}
