import 'package:test_flutter/features/tahajud/models/tahajud.dart';

enum TahajudStatus { initial, loading, loaded, success, error }

class TahajudState {
  final TahajudStatus status;
  final List<RiwayatTahajud> riwayatTahajud;
  final StatistikTahajud? statistikTahajud;
  final String? message;
  final String? error;
  final String currentMonth; // Format: YYYY-MM

  TahajudState({
    this.status = TahajudStatus.initial,
    this.riwayatTahajud = const [],
    this.statistikTahajud,
    this.message,
    this.error,
    this.currentMonth = '',
  });

  TahajudState copyWith({
    TahajudStatus? status,
    List<RiwayatTahajud>? riwayatTahajud,
    StatistikTahajud? statistikTahajud,
    String? message,
    String? error,
    String? currentMonth,
  }) {
    return TahajudState(
      status: status ?? this.status,
      riwayatTahajud: riwayatTahajud ?? this.riwayatTahajud,
      statistikTahajud: statistikTahajud ?? this.statistikTahajud,
      message: message ?? this.message,
      error: error ?? this.error,
      currentMonth: currentMonth ?? this.currentMonth,
    );
  }

  TahajudState.initial() {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return TahajudState(
      status: TahajudStatus.initial,
      riwayatTahajud: [],
      statistikTahajud: null,
      currentMonth: currentMonth,
    );
  }
}
