import 'package:test_flutter/data/models/haji/haji.dart';

enum HajiStatus {
  initial,
  loading,
  loaded,
  error,
  success,
  loadingMore,
  refreshing,
  offline,
}

// Bagian 2: State Class (Model untuk UI)
// Class ini membungkus semua data yang dibutuhkan oleh UI menjadi satu objek yang aman (type-safe).
class HajiState {
  final HajiStatus status;
  final List<Haji> hajiList;
  final Haji? selectedHaji;
  final int currentPage;
  final int lastPage;
  final String? message;
  final bool isOffline;

  const HajiState({
    required this.status,
    required this.hajiList,
    this.selectedHaji,
    required this.currentPage,
    required this.lastPage,
    this.message,
    required this.isOffline,
  });

  // State awal saat provider pertama kali dibuat
  factory HajiState.initial() {
    return const HajiState(
      status: HajiStatus.initial,
      hajiList: [],
      selectedHaji: null,
      currentPage: 1,
      lastPage: 1,
      isOffline: false,
      message: null,
    );
  }

  // Helper method untuk membuat salinan state dengan beberapa perubahan.
  // Ini adalah cara standar untuk mengubah state di Riverpod/Notifier.
  HajiState copyWith({
    HajiStatus? status,
    List<Haji>? hajiList,
    Haji? selectedHaji,
    int? currentPage,
    int? lastPage,
    String? message,
    bool? isOffline,
    bool? clear,
  }) {
    return HajiState(
      status: clear == true ? HajiStatus.initial : (status ?? this.status),
      hajiList: hajiList ?? this.hajiList,
      selectedHaji: selectedHaji ?? this.selectedHaji,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      message: clear == true ? null : (message ?? this.message),
      isOffline: isOffline ?? this.isOffline,
    );
  }
}
