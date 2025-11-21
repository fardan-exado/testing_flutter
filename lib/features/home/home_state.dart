import 'package:test_flutter/data/models/artikel/artikel.dart';
import 'package:test_flutter/features/sholat/models/sholat.dart';

enum HomeStatus { initial, loading, loaded, error, refreshing, offline }

class HomeState {
  final HomeStatus status;
  final Sholat? jadwalSholat;
  final List<Artikel> articles;
  final Artikel? selectedArticle;
  final String? message;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? localDate;
  final String? localTime;
  final bool isOffline;

  const HomeState({
    required this.status,
    this.jadwalSholat,
    this.articles = const [],
    this.selectedArticle,
    this.message,
    this.latitude,
    this.longitude,
    this.locationName,
    this.localDate,
    this.localTime,
    required this.isOffline,
  });

  factory HomeState.initial() {
    return const HomeState(
      status: HomeStatus.initial,
      articles: [],
      selectedArticle: null,
      jadwalSholat: null,
      message: null,
      latitude: null,
      longitude: null,
      locationName: null,
      localDate: null,
      localTime: null,
      isOffline: false,
    );
  }

  HomeState copyWith({
    HomeStatus? status,
    Sholat? jadwalSholat,
    List<Artikel>? articles,
    Artikel? selectedArticle,
    String? message,
    double? latitude,
    double? longitude,
    String? locationName,
    String? localDate,
    String? localTime,
    bool? isOffline,
    bool clearmessage = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      jadwalSholat: jadwalSholat ?? this.jadwalSholat,
      articles: articles ?? this.articles,
      selectedArticle: selectedArticle ?? this.selectedArticle,
      message: clearmessage ? null : (message ?? this.message),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      localDate: localDate ?? this.localDate,
      localTime: localTime ?? this.localTime,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}
