import 'package:flutter_riverpod/legacy.dart';
import 'package:test_flutter/features/subscription/models/paket.dart';
import 'package:test_flutter/features/subscription/services/paket_service.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/features/subscription/states/subscription_state.dart';

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(SubscriptionState());

  /// Load pakets
  Future<void> loadPakets() async {
    try {
      state = state.copyWith(status: SubscriptionStatus.loading);

      final response = await PaketService.getPaket();

      if (response['status'] == true && response['data'] != null) {
        final List<dynamic> paketsData = response['data'] as List<dynamic>;
        final pakets = paketsData
            .map((paket) => Paket.fromJson(paket as Map<String, dynamic>))
            .toList();

        state = state.copyWith(
          status: SubscriptionStatus.success,
          pakets: pakets,
          error: null,
        );

        logger.info('Pakets loaded successfully: ${pakets.length} pakets');
      } else {
        state = state.copyWith(
          status: SubscriptionStatus.error,
          error: response['message'] ?? 'Gagal memuat paket',
        );
      }
    } catch (e) {
      logger.warning('Error loading pakets: $e');
      state = state.copyWith(
        status: SubscriptionStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Load active subscription for current user
  Future<void> loadActiveSubscription() async {
    try {
      // TODO: Implement API call to get active subscription
      // For now, we'll just set isPremium to false
      state = state.copyWith(isPremium: false, activeSubscription: null);
    } catch (e) {
      logger.warning('Error loading active subscription: $e');
    }
  }

  /// Create transaction for plan purchase
  Future<String?> createTransaction(String planId) async {
    try {
      state = state.copyWith(status: SubscriptionStatus.loading);

      // TODO: Implement API call to create transaction
      // This should return Midtrans payment URL

      state = state.copyWith(
        status: SubscriptionStatus.success,
        message: 'Transaksi berhasil dibuat',
      );

      return null; // Return payment URL from API
    } catch (e) {
      logger.warning('Error creating transaction: $e');
      state = state.copyWith(
        status: SubscriptionStatus.error,
        error: e.toString(),
      );
      return null;
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
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
      return SubscriptionNotifier();
    });
