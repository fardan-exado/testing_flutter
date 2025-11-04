import 'package:flutter_riverpod/legacy.dart';

import './models/plan_model.dart';
import './models/transaction_model.dart';
import './models/subscription_model.dart';

class SubscriptionState {
  final List<PlanModel> plans;
  final List<TransactionModel> transactions;
  final SubscriptionModel? activeSubscription;
  final bool isLoading;
  final String? error;
  final String? message;

  SubscriptionState({
    this.plans = const [],
    this.transactions = const [],
    this.activeSubscription,
    this.isLoading = false,
    this.error,
    this.message,
  });

  SubscriptionState copyWith({
    List<PlanModel>? plans,
    List<TransactionModel>? transactions,
    SubscriptionModel? activeSubscription,
    bool? isLoading,
    String? error,
    String? message,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return SubscriptionState(
      plans: plans ?? this.plans,
      transactions: transactions ?? this.transactions,
      activeSubscription: activeSubscription ?? this.activeSubscription,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  bool get isPremium =>
      activeSubscription?.isPremium ?? false;
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(SubscriptionState());

  // Load available plans
  Future<void> loadPlans() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data
      final plans = [
        PlanModel(
          id: '1',
          name: 'Basic',
          description: 'Akses fitur dasar selama 1 bulan',
          price: 29000,
          durationDays: 30,
          features: [
            'Akses Tahajud Tracker',
            'Monitoring Anak (Max 2 anak)',
            'Notifikasi Basic',
            'Support Email',
          ],
        ),
        PlanModel(
          id: '2',
          name: 'Premium',
          description: 'Akses lengkap selama 3 bulan',
          price: 79000,
          durationDays: 90,
          isPopular: true,
          discount: 'Hemat 10%',
          features: [
            'Akses Tahajud Tracker',
            'Monitoring Anak (Unlimited)',
            'Notifikasi Premium',
            'Laporan Detail',
            'Priority Support',
            'Export Data',
          ],
        ),
        PlanModel(
          id: '3',
          name: 'Family',
          description: 'Paket keluarga selama 1 tahun',
          price: 299000,
          durationDays: 365,
          discount: 'Hemat 20%',
          features: [
            'Semua Fitur Premium',
            'Multi Device (5 device)',
            'Family Dashboard',
            'Custom Reports',
            'Dedicated Support',
            'Free Updates',
          ],
        ),
      ];

      state = state.copyWith(
        plans: plans,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat paket: ${e.toString()}',
      );
    }
  }

  // Load active subscription
  Future<void> loadActiveSubscription() async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock data - uncomment to test premium state
      // final subscription = SubscriptionModel(
      //   id: '1',
      //   userId: 'user123',
      //   planId: '2',
      //   planName: 'Premium',
      //   startDate: DateTime.now().subtract(const Duration(days: 10)),
      //   endDate: DateTime.now().add(const Duration(days: 80)),
      //   isActive: true,
      //   status: 'active',
      // );

      state = state.copyWith(
        activeSubscription: null, // or subscription for testing
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Gagal memuat subscription: ${e.toString()}',
      );
    }
  }

  // Create transaction and get payment URL
  Future<String?> createTransaction(String planId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // TODO: Replace with actual API call to create Midtrans transaction
      await Future.delayed(const Duration(seconds: 2));

      // Mock response
      final snapUrl = 'https://app.sandbox.midtrans.com/snap/v2/vtweb/mock-token';

      state = state.copyWith(
        isLoading: false,
        message: 'Transaksi berhasil dibuat',
      );

      return snapUrl;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal membuat transaksi: ${e.toString()}',
      );
      return null;
    }
  }

  // Load transaction history
  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data
      final transactions = [
        TransactionModel(
          id: '1',
          orderId: 'ORD-2024-001',
          userId: 'user123',
          planId: '2',
          planName: 'Premium',
          amount: 79000,
          status: 'success',
          paymentType: 'bank_transfer',
          vaNumber: '8277123456789012',
          bankName: 'BCA',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          paidAt: DateTime.now().subtract(const Duration(days: 5)),
          expiredAt: DateTime.now().add(const Duration(hours: 24)),
        ),
        TransactionModel(
          id: '2',
          orderId: 'ORD-2024-002',
          userId: 'user123',
          planId: '1',
          planName: 'Basic',
          amount: 29000,
          status: 'pending',
          paymentType: 'bank_transfer',
          vaNumber: '8277123456789013',
          bankName: 'BNI',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          expiredAt: DateTime.now().add(const Duration(hours: 22)),
        ),
      ];

      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat riwayat transaksi: ${e.toString()}',
      );
    }
  }

  // Check transaction status
  Future<void> checkTransactionStatus(String orderId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // TODO: Replace with actual API call to check Midtrans status
      await Future.delayed(const Duration(seconds: 1));

      // Reload transactions and subscription
      await loadTransactions();
      await loadActiveSubscription();

      state = state.copyWith(
        isLoading: false,
        message: 'Status transaksi berhasil diperbarui',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memeriksa status: ${e.toString()}',
      );
    }
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});
