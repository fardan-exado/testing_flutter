import 'package:dio/dio.dart';
import 'package:test_flutter/core/utils/api_client.dart';
import 'package:test_flutter/features/artikel/models/artikel/artikel.dart';

class HomeService {
  static Future<Map<String, dynamic>> getLatestArticle() async {
    try {
      final response = await ApiClient.dio.get('/artikel/blog/terbaru');

      final responseData = response.data as Map<String, dynamic>;
      final articles = (responseData['data'] as List<dynamic>)
          .map((json) => Artikel.fromJson(json as Map<String, dynamic>))
          .toList();
      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': articles,
      };
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Get Jadwal Sholat
  static Future<Map<String, dynamic>> getJadwalSholat({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final now = DateTime.now();

      final response = await ApiClient.dio.get(
        '/sholat/jadwal',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'start_date': now,
          'end_date': now,
        },
      );

      final responseData = response.data as Map<String, dynamic>;
      final sholat = responseData['data'] as List<dynamic>? ?? [];
      final data = sholat.isEmpty ? null : sholat.first;
      final sholatData = data as Map<String, dynamic>?;

      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': sholatData,
      };
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }
}
