import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:test_flutter/core/utils/connection/connection_provider.dart';
import 'package:test_flutter/core/utils/connection/connection_state.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/data/models/artikel/artikel.dart';
import 'package:test_flutter/features/sholat/models/sholat/sholat.dart';
import 'package:test_flutter/data/services/location/location_service.dart';
import 'package:test_flutter/features/artikel/services/artikel_service.dart';
import 'package:test_flutter/features/home/home_state.dart';
import 'package:test_flutter/features/home/services/home_cache_service.dart';
import 'package:test_flutter/features/home/services/home_service.dart';

class HomeProvider extends StateNotifier<HomeState> {
  HomeProvider(this._ref) : super(HomeState.initial()) {
    _loadCachedData();
    // Listen to connection changes
    _ref.listen<ConnectionStateX>(connectionProvider, (previous, next) {
      // Update isOffline state when connection changes
      if (previous?.isOnline != next.isOnline) {
        state = state.copyWith(isOffline: !next.isOnline);

        // Auto refresh data when back online
        if (next.isOnline && previous?.isOnline == false) {
          logger.info('Connection restored, refreshing data...');
          refreshAllData();
        }
      }
    });
  }

  final Ref _ref;

  // ...existing code...

  // Load cached data saat inisialisasi
  Future<void> _loadCachedData() async {
    try {
      final cachedJadwal = HomeCacheService.getCachedJadwalSholat();
      final cachedLocation = await LocationService.getLocation();
      final cachedArtikelTerbaru = HomeCacheService.getCachedArtikelTerbaru();

      logger.info('Loading cached data...');
      logger.info('cachedJadwal: ${cachedJadwal != Sholat.empty()}');
      logger.info('cachedLocation: ${cachedLocation != null}');
      logger.info('cachedArtikelTerbaru: ${cachedArtikelTerbaru.length}');

      // Always load cached articles if available
      if (cachedArtikelTerbaru.isNotEmpty) {
        logger.info(
          'Loading cached articles: ${cachedArtikelTerbaru.length} articles',
        );
      }

      if (cachedJadwal != Sholat.empty() &&
          cachedLocation != null &&
          cachedLocation.isNotEmpty) {
        // Update state dengan semua data dari cache
        state = state.copyWith(
          jadwalSholat: cachedJadwal,
          articles: cachedArtikelTerbaru,
          latitude: cachedLocation['lat'] as double?,
          longitude: cachedLocation['long'] as double?,
          locationName: cachedLocation['name'] as String?,
          localDate: cachedLocation['date'] as String?,
          localTime: cachedLocation['time'] as String?,
          status: HomeStatus.loaded,
        );
        logger.info('Successfully loaded all cached data');
      } else if (cachedLocation != null && cachedLocation.isNotEmpty) {
        // Jika ada lokasi tapi belum ada jadwal, set lokasi dan artikel
        state = state.copyWith(
          articles: cachedArtikelTerbaru,
          latitude: cachedLocation['lat'] as double?,
          longitude: cachedLocation['long'] as double?,
          locationName: cachedLocation['name'] as String?,
          localDate: cachedLocation['date'] as String?,
          localTime: cachedLocation['time'] as String?,
          status: cachedArtikelTerbaru.isNotEmpty
              ? HomeStatus.loaded
              : HomeStatus.initial,
        );
        logger.info('Successfully loaded cached location and articles');
      } else if (cachedArtikelTerbaru.isNotEmpty) {
        // Jika hanya ada artikel, load artikel saja
        state = state.copyWith(
          articles: cachedArtikelTerbaru,
          status: HomeStatus.loaded,
        );
        logger.info('Successfully loaded cached articles only');
      } else {
        logger.warning('No cached data available');
      }
    } catch (e) {
      logger.severe('Error loading cached data: $e');
    }
  }

  // ...existing code...
  // ...existing code...
  Future<void> checkIsJadwalSholatCacheExist() async {
    final cachedJadwal = HomeCacheService.getCachedJadwalSholat();

    final isCacheExist = cachedJadwal != Sholat.empty();

    state = state.copyWith(jadwalSholat: isCacheExist ? cachedJadwal : null);
  }

  Future<void> checkIsArtikelCacheExist() async {
    final cachedArtikel = HomeCacheService.getCachedArtikelTerbaru();

    final isCacheExist = cachedArtikel.isNotEmpty;

    state = state.copyWith(articles: isCacheExist ? cachedArtikel : null);
  }

  Future<void> fetchJadwalSholat({
    double? latitude,
    double? longitude,
    String? locationName,
    String? localDate,
    String? localTime,
    bool forceRefresh = false,
    bool useCurrentLocation = false,
  }) async {
    try {
      // Jika useCurrentLocation = true, ambil lokasi real-time
      if (useCurrentLocation) {
        logger.info('Fetching current location...');
        state = state.copyWith(status: HomeStatus.loading);

        try {
          Map<String, dynamic> locationData;
          if (forceRefresh) {
            locationData = await LocationService.getCurrentLocation(
              forceRefresh: true,
            );
          } else {
            locationData = await LocationService.getCurrentLocation();
          }

          latitude = locationData['lat'] as double?;
          longitude = locationData['long'] as double?;
          locationName = locationData['name'] as String?;
          localDate = locationData['date'] as String?;
          localTime = locationData['time'] as String?;

          logger.info(
            'Location obtained: $locationName ($latitude, $longitude) | $localDate $localTime',
          );
        } catch (e) {
          logger.warning('Failed to get current location: $e');
          // Fallback ke cache location
          final cachedLocation = await LocationService.getLocation();
          if (cachedLocation != null && cachedLocation.isNotEmpty) {
            latitude = cachedLocation['lat'] as double?;
            longitude = cachedLocation['long'] as double?;
            locationName = cachedLocation['name'] as String?;
            localDate = cachedLocation['date'] as String?;
            localTime = cachedLocation['time'] as String?;
            logger.info('Using cached location due to error');
          } else {
            throw Exception('No location data available');
          }
        }
      } else {
        // Jika tidak ada parameter, gunakan dari state atau cache
        latitude ??= state.latitude;
        longitude ??= state.longitude;
        locationName ??= state.locationName;
        localDate ??= state.localDate;
        localTime ??= state.localTime;

        // Jika masih null, ambil dari cache
        if (latitude == null || longitude == null) {
          final cachedLocation = await LocationService.getLocation();
          if (cachedLocation != null && cachedLocation.isNotEmpty) {
            latitude = cachedLocation['lat'] as double?;
            longitude = cachedLocation['long'] as double?;
            locationName = cachedLocation['name'] as String?;
            localDate = cachedLocation['date'] as String?;
            localTime = cachedLocation['time'] as String?;
            logger.info('Using cached location');
          }
        }

        // Jika masih null, ambil lokasi saat ini
        if (latitude == null || longitude == null) {
          logger.info('No location available, fetching current location...');
          try {
            final locationData = await LocationService.getCurrentLocation();
            latitude = locationData['lat'] as double?;
            longitude = locationData['long'] as double?;
            locationName = locationData['name'] as String?;
            localDate = locationData['date'] as String?;
            localTime = locationData['time'] as String?;
          } catch (e) {
            logger.severe('Failed to get any location: $e');
            // Jika gagal total, gunakan data cache yang ada di state
            final cachedJadwal = HomeCacheService.getCachedJadwalSholat();
            if (cachedJadwal != Sholat.empty()) {
              state = state.copyWith(
                status: HomeStatus.offline,
                jadwalSholat: cachedJadwal,
                message: 'Using offline data',
              );
              return;
            } else {
              throw Exception('No location or cached data available');
            }
          }
        }
      }

      // Validasi bahwa kita punya koordinat
      if (latitude == null || longitude == null) {
        throw Exception('Location coordinates not available');
      }

      // Cek cache terlebih dahulu
      final cachedJadwal = HomeCacheService.getCachedJadwalSholat();

      // Jika ada cache dan bukan force refresh, gunakan cache
      if (cachedJadwal != Sholat.empty() && !forceRefresh) {
        logger.info('Using cached jadwal sholat data');
        state = state.copyWith(
          status: HomeStatus.loaded,
          jadwalSholat: cachedJadwal,
          latitude: latitude,
          longitude: longitude,
          locationName: locationName ?? 'Unknown Location',
          localDate: localDate ?? DateTime.now().toString().split(' ')[0],
          localTime:
              localTime ?? TimeOfDay.now().format(NavigatorState().context),
          message: 'Jadwal sholat dimuat dari cache',
        );
        return;
      }

      // Jika tidak ada cache atau force refresh, fetch dari network
      state = state.copyWith(
        status: forceRefresh ? HomeStatus.refreshing : HomeStatus.loading,
      );

      // 1. Fetch dari network
      final response = await HomeService.getJadwalSholat(
        latitude: latitude,
        longitude: longitude,
      );

      // 2. Parse response data ke Sholat object
      final sholatData = response['data'] as Map<String, dynamic>?;

      if (sholatData == null) {
        throw Exception('No jadwal sholat data available');
      }

      final sholatList = Sholat.fromJson(sholatData);

      logger.fine('Jadwal sholat fetched from network: $sholatList');

      // 3. Cache the fetched data
      await HomeCacheService.cacheJadwalSholat(sholatList);

      // 4. Update state dengan network data
      state = state.copyWith(
        status: HomeStatus.loaded,
        jadwalSholat: sholatList,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName ?? 'Unknown Location',
        localDate: localDate ?? DateTime.now().toString().split(' ')[0],
        localTime:
            localTime ?? TimeOfDay.now().format(NavigatorState().context),
        message: 'Jadwal sholat berhasil diperbarui',
      );

      logger.info('Successfully fetched and cached jadwal sholat from network');
    } catch (e) {
      logger.severe('Error fetching jadwal sholat: $e');

      // 5. Jika gagal, gunakan cache
      final cachedJadwal = HomeCacheService.getCachedJadwalSholat();
      final cachedLocation = await LocationService.getLocation();

      if (cachedJadwal != Sholat.empty() ||
          (cachedLocation != null && cachedLocation.isNotEmpty)) {
        logger.info('Using cached data due to network error');

        state = state.copyWith(
          status: HomeStatus.offline,
          jadwalSholat: cachedJadwal != Sholat.empty()
              ? cachedJadwal
              : state.jadwalSholat,
          latitude: cachedLocation != null
              ? (cachedLocation['lat'] as double?)
              : state.latitude,
          longitude: cachedLocation != null
              ? (cachedLocation['long'] as double?)
              : state.longitude,
          locationName: cachedLocation != null
              ? (cachedLocation['name'] as String?)
              : state.locationName ?? 'Unknown Location',
          localDate: cachedLocation != null
              ? (cachedLocation['date'] as String?)
              : state.localDate ?? DateTime.now().toString().split(' ')[0],
          localTime: cachedLocation != null
              ? (cachedLocation['time'] as String?)
              : state.localTime ??
                    TimeOfDay.now().format(NavigatorState().context),
          message: 'Menggunakan data offline',
        );
      } else {
        logger.warning('No cached data available');
        state = state.copyWith(
          status: HomeStatus.error,
          locationName: state.locationName ?? 'Unknown Location',
          localDate: state.localDate ?? DateTime.now().toString().split(' ')[0],
          localTime:
              state.localTime ??
              TimeOfDay.now().format(NavigatorState().context),
          message: 'Gagal mengambil jadwal sholat: $e',
        );
      }
    }
  }

  Future<void> fetchArtikelTerbaru({bool forceRefresh = false}) async {
    try {
      // Cek cache terlebih dahulu
      final cachedArtikel = HomeCacheService.getCachedArtikelTerbaru();

      // Jika ada cache dan bukan force refresh, gunakan cache
      if (cachedArtikel.isNotEmpty && !forceRefresh) {
        logger.info('Using cached artikel terbaru data');
        state = state.copyWith(
          status: HomeStatus.loaded,
          articles: cachedArtikel,
          message: 'Artikel dimuat dari cache',
        );
        return;
      }

      // Set loading/refreshing state
      state = state.copyWith(
        status: forceRefresh ? HomeStatus.refreshing : HomeStatus.loading,
      );

      // 1. Try network first
      final response = await HomeService.getLatestArticle();
      final artikelList = response['data'] as List<Artikel>;

      // 2. Cache the fetched data
      await HomeCacheService.cacheArtikelTerbaru(artikelList);

      // 3. Update state with network data
      state = state.copyWith(
        status: HomeStatus.loaded,
        articles: artikelList,
        message: 'Artikel terbaru berhasil diperbarui',
      );

      logger.info('Successfully fetched and cached artikel terbaru');
    } catch (e) {
      logger.severe('Error fetching artikel terbaru: $e');

      // 4. Fallback to cache if network fails
      final cachedArtikel = HomeCacheService.getCachedArtikelTerbaru();

      if (cachedArtikel.isNotEmpty) {
        logger.info('Using cached artikel terbaru due to network error');
        state = state.copyWith(
          status: HomeStatus.offline,
          articles: cachedArtikel,
          message: 'Menggunakan data artikel offline',
        );
      } else {
        logger.warning('No cached artikel data available');
        // Keep existing articles if any, otherwise set to empty
        state = state.copyWith(
          status: HomeStatus.error,
          articles: state.articles.isEmpty ? [] : state.articles,
          message: 'Gagal mengambil artikel terbaru: ${e.toString()}',
        );
      }
    }
  }

  // Ambil Detail Artikel berdasarkan ID
  Future<void> fetchArtikelById(int id, {bool forceRefresh = false}) async {
    // Cek apakah artikel sudah ada di state dan bukan force refresh
    if (!forceRefresh &&
        state.selectedArticle != null &&
        state.selectedArticle!.id == id) {
      logger.info('Using existing artikel detail data for id: $id');
      return;
    }

    state = state.copyWith(
      status: forceRefresh ? HomeStatus.refreshing : HomeStatus.loading,
    );

    try {
      // 1. Try network first
      final response = await ArtikelService.getArtikelById(id);
      final artikel = Artikel.fromJson(response['data']);

      // 2. Cache the fetched artikel detail
      await HomeCacheService.cacheArtikelDetail(artikel);

      // 3. Update state with network data
      state = state.copyWith(
        status: HomeStatus.loaded,
        selectedArticle: artikel,
        message: 'Detail artikel berhasil dimuat',
      );

      logger.info('Successfully fetched and cached artikel detail for id: $id');
    } catch (e) {
      logger.severe('Error fetching artikel by id: $e');

      // 4. Fallback to cache if network fails
      final cachedArtikel = HomeCacheService.getCachedArtikelDetail(id);

      if (cachedArtikel != null) {
        logger.info(
          'Using cached artikel detail due to network error for id: $id',
        );
        state = state.copyWith(
          status: HomeStatus.offline,
          selectedArticle: cachedArtikel,
          message: 'Menggunakan data offline',
        );
      } else {
        logger.warning('No cached artikel detail available for id: $id');
        state = state.copyWith(
          status: HomeStatus.error,
          message: 'Gagal mengambil detail artikel: $e',
        );
      }
    }
  }

  // Method untuk refresh semua data sekaligus
  Future<void> refreshAllData({bool useCurrentLocation = false}) async {
    state = state.copyWith(status: HomeStatus.refreshing);

    await Future.wait([
      fetchJadwalSholat(
        forceRefresh: true,
        useCurrentLocation: useCurrentLocation,
      ),
      fetchArtikelTerbaru(forceRefresh: true),
    ]);
  }

  // ========== PRAYER TIME HELPERS (drop-in) ==========

  // ========== PRAYER TIME HELPER METHODS ==========
  /// Dapatkan waktu sholat yang akan datang (next prayer)
  String? getCurrentPrayerTime() {
    final sholat = state.jadwalSholat;
    if (sholat == null || sholat == Sholat.empty()) return null;

    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    // Konversi waktu sholat ke TimeOfDay
    final fajr = _tryParse(sholat.wajib.shubuh);
    final dzuhr = _tryParse(sholat.wajib.dzuhur);
    final asr = _tryParse(sholat.wajib.ashar);
    final maghrib = _tryParse(sholat.wajib.maghrib);
    final isha = _tryParse(sholat.wajib.isya);

    // Check if any time is null
    if (fajr == null ||
        dzuhr == null ||
        asr == null ||
        maghrib == null ||
        isha == null) {
      return null;
    }

    // Tentukan waktu sholat berikutnya
    if (_isBefore(currentTime, fajr)) {
      return sholat.wajib.shubuh;
    } else if (_isBefore(currentTime, dzuhr)) {
      return sholat.wajib.dzuhur;
    } else if (_isBefore(currentTime, asr)) {
      return sholat.wajib.ashar;
    } else if (_isBefore(currentTime, maghrib)) {
      return sholat.wajib.maghrib;
    } else if (_isBefore(currentTime, isha)) {
      return sholat.wajib.isya;
    } else {
      // Setelah Isya, tampilkan waktu Subuh besok
      return sholat.wajib.shubuh;
    }
  }

  /// Dapatkan nama sholat yang akan datang (next prayer)
  String? getCurrentPrayerName() {
    final sholat = state.jadwalSholat;
    if (sholat == null || sholat == Sholat.empty()) return null;

    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    // Konversi waktu sholat ke TimeOfDay
    final fajr = _tryParse(sholat.wajib.shubuh);
    final dzuhr = _tryParse(sholat.wajib.dzuhur);
    final asr = _tryParse(sholat.wajib.ashar);
    final maghrib = _tryParse(sholat.wajib.maghrib);
    final isha = _tryParse(sholat.wajib.isya);

    // Check if any time is null
    if (fajr == null ||
        dzuhr == null ||
        asr == null ||
        maghrib == null ||
        isha == null) {
      logger.warning('Some prayer times are null or invalid');
      return null;
    }

    // Tentukan sholat berikutnya
    if (_isBefore(currentTime, fajr)) {
      return 'Shubuh';
    } else if (_isBefore(currentTime, dzuhr)) {
      return 'Dzuhur';
    } else if (_isBefore(currentTime, asr)) {
      return 'Ashar';
    } else if (_isBefore(currentTime, maghrib)) {
      return 'Maghrib';
    } else if (_isBefore(currentTime, isha)) {
      return 'Isya';
    } else {
      // Setelah Isya, sholat berikutnya adalah Subuh besok
      return 'Shubuh (Besok)';
    }
  }

  /// Dapatkan nama sholat yang sedang aktif sekarang
  /// Mengembalikan nama sholat yang waktunya sudah lewat (sedang berjalan)
  String? getActivePrayerName() {
    final sholat = state.jadwalSholat;
    if (sholat == null || sholat == Sholat.empty()) return null;

    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    // Konversi waktu sholat ke TimeOfDay
    final fajr = _tryParse(sholat.wajib.shubuh);
    final dzuhr = _tryParse(sholat.wajib.dzuhur);
    final asr = _tryParse(sholat.wajib.ashar);
    final maghrib = _tryParse(sholat.wajib.maghrib);
    final isha = _tryParse(sholat.wajib.isya);

    // Check if any time is null
    if (fajr == null ||
        dzuhr == null ||
        asr == null ||
        maghrib == null ||
        isha == null) {
      return null;
    }

    // Logika: Sholat aktif adalah sholat yang waktunya sudah lewat
    // Cek dari belakang (Isya ke Shubuh)

    // Cek apakah sudah lewat waktu Isya
    if (!_isBefore(currentTime, isha)) {
      // Sudah lewat Isya
      return 'Isya';
    }

    // Cek apakah sudah lewat waktu Maghrib
    if (!_isBefore(currentTime, maghrib)) {
      // Sudah lewat Maghrib tapi belum Isya
      return 'Maghrib';
    }

    // Cek apakah sudah lewat waktu Ashar
    if (!_isBefore(currentTime, asr)) {
      // Sudah lewat Ashar tapi belum Maghrib
      return 'Ashar';
    }

    // Cek apakah sudah lewat waktu Dzuhur
    if (!_isBefore(currentTime, dzuhr)) {
      // Sudah lewat Dzuhur tapi belum Ashar
      return 'Dzuhur';
    }

    // Cek apakah sudah lewat waktu Shubuh
    if (!_isBefore(currentTime, fajr)) {
      // Sudah lewat Shubuh tapi belum Dzuhur
      return 'Shubuh';
    }

    // Belum ada waktu sholat yang lewat
    // Cek apakah ini dini hari (00:00 - sebelum Shubuh)
    if (currentTime.hour >= 0 && currentTime.hour < 4) {
      // Dini hari, anggap Shubuh sebagai sholat berikutnya
      return 'Shubuh';
    }

    return null;
  }

  /// Cek apakah sudah lewat semua waktu sholat hari ini (setelah Isya)
  bool isAfterAllPrayers() {
    final sholat = state.jadwalSholat;
    if (sholat == null || sholat == Sholat.empty()) return false;

    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    final isha = _tryParse(sholat.wajib.isya);
    if (isha == null) return false;

    // Cek apakah sudah lewat Isya DAN masih di hari yang sama (belum lewat tengah malam)
    final isAfterIsha = !_isBefore(currentTime, isha);
    final isBeforeMidnight = currentTime.hour >= 18 || currentTime.hour < 4;

    return isAfterIsha && isBeforeMidnight;
  }

  /// Dapatkan sisa waktu hingga sholat berikutnya
  String? getTimeUntilNextPrayer() {
    final sholat = state.jadwalSholat;
    if (sholat == null || sholat == Sholat.empty()) return null;

    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    // Konversi waktu sholat ke TimeOfDay
    final fajr = _tryParse(sholat.wajib.shubuh);
    final dzuhr = _tryParse(sholat.wajib.dzuhur);
    final asr = _tryParse(sholat.wajib.ashar);
    final maghrib = _tryParse(sholat.wajib.maghrib);
    final isha = _tryParse(sholat.wajib.isya);

    // Check if any time is null
    if (fajr == null ||
        dzuhr == null ||
        asr == null ||
        maghrib == null ||
        isha == null) {
      return null;
    }

    TimeOfDay? nextPrayer;

    // Tentukan waktu sholat berikutnya
    if (_isBefore(currentTime, fajr)) {
      nextPrayer = fajr;
    } else if (_isBefore(currentTime, dzuhr)) {
      nextPrayer = dzuhr;
    } else if (_isBefore(currentTime, asr)) {
      nextPrayer = asr;
    } else if (_isBefore(currentTime, maghrib)) {
      nextPrayer = maghrib;
    } else if (_isBefore(currentTime, isha)) {
      nextPrayer = isha;
    } else {
      // Setelah Isya, hitung waktu hingga Subuh besok
      nextPrayer = fajr;
    }

    // Hitung selisih waktu
    final difference = _timeDifference(currentTime, nextPrayer);

    if (difference.inHours > 0) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      final seconds = difference.inSeconds % 60;
      return '${hours} jam ${minutes} menit ${seconds} detik lagi';
    } else if (difference.inMinutes > 0) {
      final minutes = difference.inMinutes;
      final seconds = difference.inSeconds % 60;
      return '${minutes} menit ${seconds} detik lagi';
    } else {
      final seconds = difference.inSeconds;
      return '${seconds} detik lagi';
    }
  }
  // ...existing code...
  // ------------------ PRIVATE HELPERS ------------------

  /// Parsers yang aman: null/empty → return null, invalid → null.
  TimeOfDay? _tryParse(String? time) {
    if (time == null || time.trim().isEmpty) return null;
    try {
      final sanitized = time.replaceAll(RegExp(r'[^\d:]'), '').trim();
      final parts = sanitized.split(':');
      if (parts.length < 2) return null;

      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) return null;
      if (h < 0 || h > 23 || m < 0 || m > 59) return null;

      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return null;
    }
  }

  /// true bila a < b (sebelum).
  bool _isBefore(TimeOfDay a, TimeOfDay b) {
    if (a.hour != b.hour) return a.hour < b.hour;
    return a.minute < b.minute;
  }

  /// Selisih waktu dari 'from' ke 'to' (autoforward ke hari berikutnya jika perlu).
  Duration _timeDifference(TimeOfDay from, TimeOfDay to) {
    final now = DateTime.now();
    final fromDate = DateTime(
      now.year,
      now.month,
      now.day,
      from.hour,
      from.minute,
    );
    var toDate = DateTime(now.year, now.month, now.day, to.hour, to.minute);

    if (toDate.isBefore(fromDate)) {
      toDate = toDate.add(const Duration(days: 1));
    }
    return toDate.difference(fromDate);
  }
}

final homeProvider = StateNotifierProvider<HomeProvider, HomeState>((ref) {
  return HomeProvider(ref);
});
