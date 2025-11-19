import 'package:test_flutter/features/profile/models/anak.dart';
import 'package:test_flutter/features/profile/models/relasi_orang_tua_anak.dart';

enum FamilyStatus { initial, loading, loaded, error, success }

class FamilyState {
  final FamilyStatus status;
  final List<Anak> anakAktif;
  final List<RelasiOrangTuaAnak> pengajuanAnak;
  final String? message;

  const FamilyState({
    required this.status,
    required this.anakAktif,
    required this.pengajuanAnak,
    this.message,
  });

  factory FamilyState.initial() {
    return const FamilyState(
      status: FamilyStatus.initial,
      anakAktif: [],
      pengajuanAnak: [],
      message: null,
    );
  }

  FamilyState copyWith({
    FamilyStatus? status,
    List<Anak>? anakAktif,
    List<RelasiOrangTuaAnak>? pengajuanAnak,
    String? message,
    bool clearMessage = false,
  }) {
    return FamilyState(
      status: status ?? this.status,
      anakAktif: anakAktif ?? this.anakAktif,
      pengajuanAnak: pengajuanAnak ?? this.pengajuanAnak,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}
