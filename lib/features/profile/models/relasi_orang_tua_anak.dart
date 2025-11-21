import 'package:test_flutter/features/profile/models/anak.dart';
import 'package:test_flutter/features/profile/models/orang_tua.dart';

class RelasiOrangTuaAnak {
  final int id;
  final int orangTuaId;
  final int anakId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Anak? anak;
  final OrangTua? orangTua;

  RelasiOrangTuaAnak({
    required this.id,
    required this.orangTuaId,
    required this.anakId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.anak,
    this.orangTua,
  });

  factory RelasiOrangTuaAnak.fromJson(Map<String, dynamic> json) {
    return RelasiOrangTuaAnak(
      id: json['id'],
      orangTuaId: json['orang_tua_id'],
      anakId: json['anak_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      anak: json['anak'] != null ? Anak.fromJson(json['anak']) : null,
      orangTua: json['orang_tua'] != null
          ? OrangTua.fromJson(json['orang_tua'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orang_tua_id': orangTuaId,
      'anak_id': anakId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'anak': anak?.toJson(),
      'orang_tua': orangTua?.toJson(),
    };
  }
}
