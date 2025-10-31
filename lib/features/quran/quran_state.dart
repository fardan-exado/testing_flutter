import 'package:test_flutter/data/models/quran/progres_quran.dart';

enum QuranStatus { initial, loading, loaded, error, success, refreshing }

class QuranState {
  final QuranStatus status;
  final List<ProgresBacaQuran> riwayatProgres;
  final String? message;
  final bool isOffline;

  const QuranState({
    required this.status,
    this.riwayatProgres = const [],
    this.message,
    this.isOffline = false,
  });

  factory QuranState.initial() {
    return const QuranState(
      status: QuranStatus.initial,
      riwayatProgres: [],
      message: null,
      isOffline: false,
    );
  }

  QuranState copyWith({
    QuranStatus? status,
    List<ProgresBacaQuran>? riwayatProgres,
    String? message,
    bool? isOffline,
    bool clearMessage = false,
  }) {
    return QuranState(
      status: status ?? this.status,
      riwayatProgres: riwayatProgres ?? this.riwayatProgres,
      message: clearMessage ? null : (message ?? this.message),
      isOffline: isOffline ?? this.isOffline,
    );
  }
}
