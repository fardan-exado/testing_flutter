import 'package:dio/dio.dart';
import 'package:test_flutter/core/utils/api_client.dart';

class PesananService {
  // Check status isPremium
  static Future<Map<String, dynamic>> checkStatusPremium() async {
    try {
      final response = await ApiClient.dio.get('/premium/pesanan/status');

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

  // Buy Package
  static Future<Map<String, dynamic>> buyPackage({
    required int paketId,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/premium/pesanan/beli-paket',
        data: {'paket_id': paketId},
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

  // Get Detail Pesanan
  static Future<Map<String, dynamic>> getDetailPesanan({
    required String pesananId,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/premium/pesanan/detail/$pesananId',
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

  // Get Riwayat Pesanan
  static Future<Map<String, dynamic>> getRiwayatPesanan() async {
    try {
      final response = await ApiClient.dio.get('/premium/pesanan/riwayat');

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
