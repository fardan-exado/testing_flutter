import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static final _storage = FlutterSecureStorage();

  // Save user token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token.toString());
  }

  // Get saved token
  static Future<String?> getToken() async {
    final token = await _storage.read(key: 'auth_token');
    return token;
  }

  // Save user data
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(user);
    await prefs.setString('user', jsonString);
  }

  // Get saved user data
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('user');

    if (jsonString == null) return null;

    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  // Clear user data (logout)
  // Note: Tidak menghapus alarm storage agar pengaturan alarm tetap tersimpan
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // Hanya hapus data user, bukan semua data
    await prefs.remove('user');

    // Hapus token dari secure storage
    await _storage.delete(key: 'auth_token');
  }

  // Clear premium status and all related subscription data
  static Future<void> clearPremiumStatus() async {
    try {
      // Delete premium status flag
      await _storage.delete(key: 'is_premium');
      print('✓ Premium status cleared from secure storage');
    } catch (e) {
      print('Error clearing premium status: $e');
    }
  }

  // Clear all subscription data
  static Future<void> clearAllSubscriptionData() async {
    try {
      // Delete premium status flag
      await _storage.delete(key: 'is_premium');
      print('✓ All subscription data cleared');
    } catch (e) {
      print('Error clearing subscription data: $e');
    }
  }
}
