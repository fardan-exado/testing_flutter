import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:test_flutter/core/utils/api_client.dart';
import 'package:test_flutter/data/models/sholat/sholat.dart';

class SholatService {
  /// Get Jadwal Sholat from Kemenag API
  ///
  /// Mengambil jadwal waktu sholat dari API Kementerian Agama RI
  /// berdasarkan koordinat lokasi (latitude & longitude).
  ///
  /// Backend akan mengintegrasikan dengan API resmi Kemenag untuk
  /// mendapatkan waktu sholat yang akurat sesuai dengan lokasi pengguna.
  ///
  /// Parameters:
  /// - [latitude]: Koordinat lintang lokasi
  /// - [longitude]: Koordinat bujur lokasi
  /// - [startDate]: Tanggal mulai (default: hari ini)
  /// - [endDate]: Tanggal akhir (default: 3 hari ke depan)
  static Future<Map<String, dynamic>> getJadwalSholat({
    required double latitude,
    required double longitude,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      startDate ??= now;
      endDate ??= now.add(const Duration(days: 3));

      final formatter = DateFormat('yyyy-MM-dd');
      final startDateStr = formatter.format(startDate);
      final endDateStr = formatter.format(endDate);

      final response = await ApiClient.dio.get(
        '/sholat/jadwal',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'start_date': startDateStr,
          'end_date': endDateStr,
        },
      );

      final responseData = response.data as Map<String, dynamic>;
      final kategoriPostingan = responseData['data'] as List<dynamic>? ?? [];
      final sholatList = kategoriPostingan
          .map((e) => Sholat.fromJson(e as Map<String, dynamic>))
          .toList();

      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': sholatList,
      };
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Add Progress Sholat (Universal untuk Wajib dan Sunnah)
  static Future<Map<String, dynamic>> addProgressSholat({
    required String jenis,
    required String sholat,
    required String status,
    bool? isJamaah,
    String? lokasi,
    String? keterangan,
  }) async {
    try {
      final endpoint = jenis.toLowerCase() == 'wajib'
          ? '/sholat/wajib/progres'
          : '/sholat/sunnah/progres';

      final data = jenis.toLowerCase() == 'wajib'
          ? {
              'sholat': sholat,
              'status': status, // tepat_waktu, terlambat, tidak_sholat
              'is_jamaah': isJamaah == true ? 1 : 0,
              'lokasi': lokasi ?? '',
              'keterangan': keterangan ?? '',
            }
          : {
              'sholat': sholat,
              'status': status, // tepat_waktu, terlambat, tidak_sholat
            };

      final response = await ApiClient.dio.post(endpoint, data: data);

      final responseData = response.data as Map<String, dynamic>;

      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': responseData['data'],
      };
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Delete Progress Sholat (Universal untuk Wajib dan Sunnah)
  static Future<Map<String, dynamic>> deleteProgressSholat({
    required int id,
    String jenis = 'wajib',
  }) async {
    try {
      final endpoint = jenis.toLowerCase() == 'wajib'
          ? '/sholat/wajib/progres/$id'
          : '/sholat/sunnah/progres/$id';

      final response = await ApiClient.dio.delete(endpoint);

      final responseData = response.data as Map<String, dynamic>;

      return {
        'status': responseData['status'],
        'message': responseData['message'],
      };
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Get Progress Sholat Wajib Hari Ini
  static Future<Map<String, dynamic>> getProgressSholatWajibHariIni() async {
    try {
      final response = await ApiClient.dio.get(
        '/sholat/wajib/hari-ini',
      );

      final responseData = response.data as Map<String, dynamic>;

      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': responseData['data'],
      };
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Get Progress Sholat Sunnah Hari Ini
  static Future<Map<String, dynamic>> getProgressSholatSunnahHariIni() async {
    try {
      final response = await ApiClient.dio.get(
        '/sholat/sunnah/hari-ini',
      );

      final responseData = response.data as Map<String, dynamic>;

      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': responseData['data'],
      };
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Get Progress Wajib Riwayat
  static Future<Map<String, dynamic>> getProgressSholatWajibRiwayat() async {
    try {
      final response = await ApiClient.dio.get('/sholat/wajib/riwayat');

      final responseData = response.data as Map<String, dynamic>;

      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': responseData['data'],
      };
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Get Progress Sunnah Riwayat
  static Future<Map<String, dynamic>> getProgressSholatSunnahRiwayat() async {
    try {
      final response = await ApiClient.dio.get(
        '/sholat/sunnah/riwayat',
      );

      final responseData = response.data as Map<String, dynamic>;

      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': responseData['data'],
      };
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }
}
