import 'package:dio/dio.dart';
import 'package:test_flutter/core/utils/api_client.dart';

class SedekahService {
  // Fetch sedekah
  static Future<Map<String, dynamic>> loadStats() async {
    try {
      final response = await ApiClient.dio.get('/sedekah/progres/statistik');
      final responseData = response.data as Map<String, dynamic>;

      final statsData = responseData['data'] as Map<String, dynamic>;

      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': statsData,
      };
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Add sedekah
  static Future<Map<String, dynamic>> addSedekah({
    required String jenisSedekah,
    required String tanggal,
    required int jumlah,
    String? keterangan,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/sedekah/progres',
        data: {
          'jenis_sedekah': jenisSedekah,
          'tanggal': tanggal,
          'jumlah': jumlah,
          if (keterangan != null && keterangan.isNotEmpty)
            'keterangan': keterangan,
        },
      );

      final responseData = response.data as Map<String, dynamic>;
      final sedekah = responseData['data'] as Map<String, dynamic>;

      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': sedekah,
      };
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Delete Sedekah
  static Future<Map<String, dynamic>> deleteSedekah(int id) async {
    try {
      final response = await ApiClient.dio.delete('/sedekah/progres/$id');

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
}
