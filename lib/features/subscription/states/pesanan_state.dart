import 'package:test_flutter/features/subscription/models/pesanan.dart';

enum PesananStatus { initial, loading, success, error }

class PesananState {
  final PesananStatus status;
  final bool isPremium;
  final Pesanan? activeSubscription;
  final List<Pesanan> riwayatPesanan;
  final String? error;
  final String? message;

  PesananState({
    this.status = PesananStatus.initial,
    this.isPremium = false,
    this.activeSubscription,
    this.riwayatPesanan = const [],
    this.error,
    this.message,
  });

  bool get isLoading => status == PesananStatus.loading;

  PesananState copyWith({
    PesananStatus? status,
    bool? isPremium,
    Pesanan? activeSubscription,
    List<Pesanan>? riwayatPesanan,
    String? error,
    String? message,
  }) {
    return PesananState(
      status: status ?? this.status,
      isPremium: isPremium ?? this.isPremium,
      activeSubscription: activeSubscription ?? this.activeSubscription,
      riwayatPesanan: riwayatPesanan ?? this.riwayatPesanan,
      error: error,
      message: message,
    );
  }

  factory PesananState.initial() {
    return PesananState(
      status: PesananStatus.initial,
      isPremium: false,
      activeSubscription: null,
      riwayatPesanan: [],
      error: null,
      message: null,
    );
  }
}
