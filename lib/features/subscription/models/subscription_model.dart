class SubscriptionModel {
  final String id;
  final String userId;
  final String planId;
  final String planName;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String status; // active, expired, cancelled

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.planId,
    required this.planName,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.status,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      planId: json['plan_id'] ?? '',
      planName: json['plan_name'] ?? '',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now(),
      isActive: json['is_active'] ?? false,
      status: json['status'] ?? 'expired',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_id': planId,
      'plan_name': planName,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'status': status,
    };
  }

  bool get isPremium => isActive && DateTime.now().isBefore(endDate);
  
  int get daysRemaining {
    if (!isPremium) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }
}
