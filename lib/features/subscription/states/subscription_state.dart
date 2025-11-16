import 'package:test_flutter/features/subscription/models/paket.dart';

enum SubscriptionStatus { initial, loading, success, error }

class SubscriptionState {
  final SubscriptionStatus status;
  final List<Paket> pakets;
  final dynamic activeSubscription;
  final bool isPremium;
  final String? error;
  final String? message;

  SubscriptionState({
    this.status = SubscriptionStatus.initial,
    this.pakets = const [],
    this.activeSubscription,
    this.isPremium = false,
    this.error,
    this.message,
  });

  bool get isLoading => status == SubscriptionStatus.loading;

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    List<Paket>? pakets,
    dynamic activeSubscription,
    bool? isPremium,
    String? error,
    String? message,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      pakets: pakets ?? this.pakets,
      activeSubscription: activeSubscription ?? this.activeSubscription,
      isPremium: isPremium ?? this.isPremium,
      error: error,
      message: message,
    );
  }
}
