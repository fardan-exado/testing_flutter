import 'package:dio/dio.dart';
import 'package:test_flutter/core/utils/api_client.dart';

class TahajudService {
  // Add Tahajud Challenge
  static Future<Map<String, dynamic>> addTahajud({
    DateTime? waktuSholat,
    int? jumlahRakaat,
    DateTime? waktuMakanTerakhir,
    DateTime? waktuTidur,
    String? keterangan,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/premium/tahajud-challenge',
        data: {
          if (waktuSholat != null)
            'waktu_sholat': waktuSholat.toIso8601String(),
          if (jumlahRakaat != null) 'jumlah_rakaat': jumlahRakaat,
          if (waktuMakanTerakhir != null)
            'waktu_makan_terakhir': waktuMakanTerakhir.toIso8601String(),
          if (waktuTidur != null) 'waktu_tidur': waktuTidur.toIso8601String(),
          if (keterangan != null) 'keterangan': keterangan,
        },
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

  // Get Detail Tahajud Challenge
  static Future<Map<String, dynamic>> getDetailTahajudChallenge({
    required String tahajudId,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/premium/tahajud-challenge/$tahajudId',
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

  // Delete Tahajud Challenge
  static Future<Map<String, dynamic>> deleteTahajudChallenge({
    required String tahajudId,
  }) async {
    try {
      final response = await ApiClient.dio.delete(
        '/premium/tahajud-challenge/$tahajudId',
      );

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

  // Get Riwayat Tahajud Challenge per Bulan
  static Future<Map<String, dynamic>> getRiwayatTahajudChallenge({
    required String month,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/premium/tahajud-challenge/riwayat-perbulan',
        queryParameters: {'bulan': month},
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

  // Get Statistik Tahajud Challenge
  static Future<Map<String, dynamic>> getStatistikTahajudChallenge({
    required String month,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/premium/tahajud-challenge/statistik',
        queryParameters: {'bulan': month},
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
