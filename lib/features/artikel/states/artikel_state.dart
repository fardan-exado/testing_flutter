import 'package:test_flutter/features/artikel/models/artikel/artikel.dart';
import 'package:test_flutter/features/artikel/models/kategori/kategori_artikel.dart';

enum ArtikelStatus {
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
class ArtikelState {
  final ArtikelStatus status;
  final List<Artikel> artikelList;
  final Artikel? selectedArtikel;
  final List<KategoriArtikel> kategori;
  final int currentPage;
  final int lastPage;
  final String? message;
  final bool isOffline;

  const ArtikelState({
    required this.status,
    required this.artikelList,
    this.selectedArtikel,
    required this.kategori,
    required this.currentPage,
    required this.lastPage,
    this.message,
    required this.isOffline,
  });

  // State awal saat provider pertama kali dibuat
  factory ArtikelState.initial() {
    return const ArtikelState(
      status: ArtikelStatus.initial,
      artikelList: [],
      kategori: [],
      selectedArtikel: null,
      currentPage: 1,
      lastPage: 1,
      isOffline: false,
      message: null,
    );
  }

  // Helper method untuk membuat salinan state dengan beberapa perubahan.
  // Ini adalah cara standar untuk mengubah state di Riverpod/Notifier.
  ArtikelState copyWith({
    ArtikelStatus? status,
    List<Artikel>? artikelList,
    Artikel? selectedArtikel,
    List<KategoriArtikel>? kategori,
    int? currentPage,
    int? lastPage,
    String? message,
    bool? isOffline,
    bool? clear,
  }) {
    return ArtikelState(
      status: clear == true ? ArtikelStatus.initial : (status ?? this.status),
      artikelList: artikelList ?? this.artikelList,
      selectedArtikel: selectedArtikel ?? this.selectedArtikel,
      kategori: kategori ?? this.kategori,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      message: clear == true ? null : (message ?? this.message),
      isOffline: isOffline ?? this.isOffline,
    );
  }
}
