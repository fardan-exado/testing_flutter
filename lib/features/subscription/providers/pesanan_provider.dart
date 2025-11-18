import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_flutter/features/subscription/models/pesanan.dart';
import 'package:test_flutter/features/subscription/services/pesanan_service.dart';
import 'package:test_flutter/features/subscription/states/pesanan_state.dart';
import 'package:test_flutter/core/utils/logger.dart';

class PesananNotifier extends StateNotifier<PesananState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _isPremiumKey = 'is_premium';

  PesananNotifier() : super(PesananState()) {
    _loadPremiumStatus();
  }

  /// Load premium status from local storage
  Future<void> _loadPremiumStatus() async {
    try {
      final isPremiumStr = await _storage.read(key: _isPremiumKey);
      final isPremium = isPremiumStr == 'true';
      state = state.copyWith(isPremium: isPremium);
    } catch (e) {
      // logger.warning('Error loading premium status: $e');
    }
  }

  /// Save premium status to local storage
  Future<void> _savePremiumStatus(bool isPremium) async {
    try {
      await _storage.write(key: _isPremiumKey, value: isPremium.toString());
      state = state.copyWith(isPremium: isPremium);
    } catch (e) {
      // logger.warning('Error saving premium status: $e');
    }
  }

  /// Check status premium from server
  Future<void> checkStatusPremium() async {
    try {
      state = state.copyWith(status: PesananStatus.loading);

      final response = await PesananService.checkStatusPremium();

      if (response['status'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        final isPremium = data != null && data['premium_paket'] != null;

        // Parse active subscription if premium
        Pesanan? activeSubscription;
        if (isPremium) {
          activeSubscription = Pesanan.fromJson(data);
        }

        await _savePremiumStatus(isPremium);

        state = state.copyWith(
          status: PesananStatus.success,
          isPremium: isPremium,
          activeSubscription: activeSubscription,
          error: null,
        );

        logger.info('Premium status checked: $isPremium');
      } else {
        state = state.copyWith(isPremium: false, status: PesananStatus.error);
      }
    } catch (e) {
      // logger.warning('Error checking premium status: $e');
      // state = state.copyWith(status: PesananStatus.error, error: e.toString());
    }
  }

  /// Buy package and get snap token
  Future<String?> buyPackage(int paketId) async {
    try {
      state = state.copyWith(status: PesananStatus.loading);

      final response = await PesananService.buyPackage(paketId: paketId);

      logger.info('BuyPackage Response: $response');

      if (response['status'] == true && response['data'] != null) {
        final data = response['data'];

        // Handle different response structures
        String? snapToken;

        // Try to get snap_token directly from data
        if (data is Map<String, dynamic>) {
          // Option 2: inside pesanan object
          // ignore: unnecessary_null_comparison
          if ((snapToken == null || snapToken.isEmpty) &&
              data['pesanan'] != null) {
            final pesananData = data['pesanan'];
            // ignore: unnecessary_null_comparison
            if ((snapToken == null || snapToken.isEmpty)) {
              snapToken = pesananData['midtrans_id'] as String?;
            }
          }
        }

        if (snapToken != null && snapToken.isNotEmpty) {
          state = state.copyWith(
            status: PesananStatus.success,
            message: 'Pesanan berhasil dibuat',
            error: null,
          );

          logger.info(
            '✓ Package purchased successfully, snap token: $snapToken',
          );
          return snapToken;
        } else {
          logger.warning('⚠️ Snap token / midtrans_id not found in response');
          logger.info('Full response data: $response');

          state = state.copyWith(
            status: PesananStatus.error,
            error: 'Gagal mendapatkan snap token. Silakan coba lagi.',
          );
          return null;
        }
      } else {
        state = state.copyWith(
          status: PesananStatus.error,
          error: response['message'] ?? 'Gagal saat melakukan pembayaran.',
        );
        return null;
      }
    } catch (e) {
      logger.warning('Error buying package: $e');
      state = state.copyWith(status: PesananStatus.error, error: e.toString());
      return null;
    }
  }

  /// Get riwayat pesanan
  Future<void> getRiwayatPesanan() async {
    try {
      state = state.copyWith(status: PesananStatus.loading);

      final response = await PesananService.getRiwayatPesanan();

      if (response['status'] == true && response['data'] != null) {
        final List<dynamic> pesananData = response['data'] as List<dynamic>;
        final riwayat = pesananData
            .map((p) => Pesanan.fromJson(p as Map<String, dynamic>))
            .toList();

        state = state.copyWith(
          status: PesananStatus.success,
          riwayatPesanan: riwayat,
          error: null,
        );

        logger.info('Riwayat pesanan loaded: ${riwayat.length} items');
      } else {
        state = state.copyWith(
          status: PesananStatus.error,
          error: response['message'] ?? 'Gagal memuat riwayat pesanan',
        );
      }
    } catch (e) {
      logger.warning('Error loading riwayat pesanan: $e');
      state = state.copyWith(status: PesananStatus.error, error: e.toString());
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear success message
  void clearMessage() {
    state = state.copyWith(message: null);
  }

  /// Clear premium status (on logout)
  Future<void> clearPremiumStatus() async {
    try {
      // Clear from storage
      await _storage.delete(key: _isPremiumKey);

      // Reset state completely
      state = PesananState(); // Reset to fresh state

      logger.info(
        '✓ Premium status cleared from provider and reset to initial state',
      );
    } catch (e) {
      logger.warning('Error clearing premium status in provider: $e');
    }
  }

  /// Reset provider to initial state (called after logout)
  Future<void> resetToInitialState() async {
    try {
      // Clear from storage
      await _storage.delete(key: _isPremiumKey);

      // Reset state to fresh PesananState
      state = PesananState();

      logger.info('✓ PesananNotifier reset to initial state');
    } catch (e) {
      logger.warning('Error resetting pesanan provider: $e');
    }
  }

  /// Refresh premium status after payment
  Future<void> refreshAfterPayment() async {
    await checkStatusPremium();
  }
}

final pesananProvider = StateNotifierProvider<PesananNotifier, PesananState>((
  ref,
) {
  return PesananNotifier();
});
