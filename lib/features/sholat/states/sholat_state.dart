import 'package:test_flutter/features/sholat/models/sholat/sholat.dart';

enum SholatStatus { initial, loading, loaded, error, refreshing, offline }

class SholatState {
  final SholatStatus status;
  final List<JadwalSholat> sholatList;
  // Location & Time Info
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? localDate;
  final String? localTime;
  final String? message;
  final bool isOffline;

  // PROGRES SHOLAT WAJIB BY DATE
  final Map<String, dynamic> progressWajibRiwayat;
  final Map<String, dynamic> progressSunnahRiwayat;

  const SholatState({
    required this.status,
    required this.sholatList,
    this.latitude,
    this.longitude,
    this.locationName,
    this.localDate,
    this.localTime,
    this.message,
    required this.isOffline,
    required this.progressWajibRiwayat,
    required this.progressSunnahRiwayat,
  });

  factory SholatState.initial() {
    return const SholatState(
      status: SholatStatus.initial,
      sholatList: [],
      isOffline: false,
      latitude: null,
      longitude: null,
      locationName: null,
      localDate: null,
      localTime: null,
      message: null,
      progressWajibRiwayat: {},
      progressSunnahRiwayat: {},
    );
  }

  SholatState copyWith({
    SholatStatus? status,
    List<JadwalSholat>? sholatList,
    double? latitude,
    double? longitude,
    String? locationName,
    String? localDate,
    String? localTime,
    String? message,
    bool? isOffline,
    Map<String, dynamic>? progressWajibRiwayat,
    Map<String, dynamic>? progressSunnahRiwayat,
  }) {
    return SholatState(
      status: status ?? this.status,
      sholatList: sholatList ?? this.sholatList,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      localDate: localDate ?? this.localDate,
      localTime: localTime ?? this.localTime,
      message: message ?? this.message,
      isOffline: isOffline ?? this.isOffline,
      progressWajibRiwayat: progressWajibRiwayat ?? this.progressWajibRiwayat,
      progressSunnahRiwayat:
          progressSunnahRiwayat ?? this.progressSunnahRiwayat,
    );
  }
}
