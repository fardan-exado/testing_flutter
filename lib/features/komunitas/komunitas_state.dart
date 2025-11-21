// Bagian 1: Enum untuk Status UI
// Ini mendefinisikan semua kemungkinan status yang bisa dimiliki oleh UI.

import 'package:test_flutter/features/komunitas/models/kategori/kategori_komunitas.dart';
import 'package:test_flutter/features/komunitas/models/komunitas/komunitas.dart';

enum KomunitasStatus {
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
class KomunitasState {
  final KomunitasStatus status;
  final List<KomunitasPostingan> postinganList;
  final KomunitasPostingan? postingan;
  final List<KategoriKomunitas> kategori;
  final int currentPage;
  final int lastPage;
  final String? message;
  final bool isOffline;

  const KomunitasState({
    required this.status,
    required this.postinganList,
    this.postingan,
    required this.kategori,
    required this.currentPage,
    required this.lastPage,
    this.message,
    required this.isOffline,
  });

  // State awal saat provider pertama kali dibuat
  factory KomunitasState.initial() {
    return const KomunitasState(
      status: KomunitasStatus.initial,
      postinganList: [],
      kategori: [],
      postingan: null,
      currentPage: 1,
      lastPage: 1,
      isOffline: false,
      message: null,
    );
  }

  // Helper method untuk membuat salinan state dengan beberapa perubahan.
  // Ini adalah cara standar untuk mengubah state di Riverpod/Notifier.
  KomunitasState copyWith({
    KomunitasStatus? status,
    List<KomunitasPostingan>? postinganList,
    KomunitasPostingan? postingan,
    List<KategoriKomunitas>? kategori,
    int? currentPage,
    int? lastPage,
    String? message,
    bool? isOffline,
    bool? clear,
  }) {
    return KomunitasState(
      status: clear == true ? KomunitasStatus.initial : (status ?? this.status),
      postinganList: postinganList ?? this.postinganList,
      postingan: postingan ?? this.postingan,
      kategori: kategori ?? this.kategori,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      message: clear == true ? null : (message ?? this.message),
      isOffline: isOffline ?? this.isOffline,
    );
  }
}
