import 'package:test_flutter/features/puasa/models/progres_puasa.dart';
import 'package:test_flutter/features/puasa/models/puasa.dart';

enum PuasaStatus {
  initial,
  loading,
  loaded,
  error,
  success,
  refreshing,
  offline,
}

class PuasaState {
  final PuasaStatus status;
  final List<PuasaSunnah>? puasaSunnahList;
  final List<RiwayatProgresPuasaWajib>? riwayatPuasaWajib;
  final List<RiwayatProgresPuasaSunnah>? riwayatPuasaSunnah;
  final String? message;
  final bool isOffline;

  PuasaState({
    required this.status,
    this.puasaSunnahList,
    this.riwayatPuasaWajib,
    this.riwayatPuasaSunnah,
    this.message,
    required this.isOffline,
  });

  factory PuasaState.initial() {
    return PuasaState(
      status: PuasaStatus.initial,
      puasaSunnahList: [],
      riwayatPuasaWajib: [],
      riwayatPuasaSunnah: [],
      message: null,
      isOffline: false,
    );
  }

  PuasaState copyWith({
    PuasaStatus? status,
    List<RiwayatProgresPuasaWajib>? riwayatPuasaWajib,
    List<RiwayatProgresPuasaSunnah>? riwayatPuasaSunnah,
    String? message,
    bool? isOffline,
    List<PuasaSunnah>? puasaSunnahList,
  }) {
    return PuasaState(
      status: status ?? this.status,
      puasaSunnahList: puasaSunnahList ?? this.puasaSunnahList,
      riwayatPuasaWajib: riwayatPuasaWajib ?? this.riwayatPuasaWajib,
      riwayatPuasaSunnah: riwayatPuasaSunnah ?? this.riwayatPuasaSunnah,
      message: message ?? this.message,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}
