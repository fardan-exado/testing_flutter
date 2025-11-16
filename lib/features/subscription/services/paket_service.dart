import 'package:dio/dio.dart';
import 'package:test_flutter/core/utils/api_client.dart';

class PaketService {
  static Future<Map<String, dynamic>> getPaket() async {
    try {
      final response = await ApiClient.dio.get('/premium/paket');

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
