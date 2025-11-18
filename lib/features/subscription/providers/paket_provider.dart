import 'package:flutter_riverpod/legacy.dart';
import 'package:test_flutter/features/subscription/models/paket.dart';
import 'package:test_flutter/features/subscription/services/paket_service.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/features/subscription/states/paket_state.dart';

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

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear success message
  void clearMessage() {
    state = state.copyWith(message: null);
  }
}

final paketProvider=
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
      return SubscriptionNotifier();
    });
