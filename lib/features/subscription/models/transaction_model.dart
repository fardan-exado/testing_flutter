class TransactionModel {
  final String id;
  final String orderId;
  final String userId;
  final String planId;
  final String planName;
  final int amount;
  final String status; // pending, success, failed, expired
  final String? paymentType;
  final String? vaNumber;
  final String? bankName;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? expiredAt;
  final String? snapToken;
  final String? snapUrl;

  TransactionModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.planId,
    required this.planName,
    required this.amount,
    required this.status,
    this.paymentType,
    this.vaNumber,
    this.bankName,
    required this.createdAt,
    this.paidAt,
    this.expiredAt,
    this.snapToken,
    this.snapUrl,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      userId: json['user_id'] ?? '',
      planId: json['plan_id'] ?? '',
      planName: json['plan_name'] ?? '',
      amount: json['amount'] ?? 0,
      status: json['status'] ?? 'pending',
      paymentType: json['payment_type'],
      vaNumber: json['va_number'],
      bankName: json['bank_name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      paidAt:
          json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      expiredAt: json['expired_at'] != null
          ? DateTime.parse(json['expired_at'])
          : null,
      snapToken: json['snap_token'],
      snapUrl: json['snap_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'user_id': userId,
      'plan_id': planId,
      'plan_name': planName,
      'amount': amount,
      'status': status,
      'payment_type': paymentType,
      'va_number': vaNumber,
      'bank_name': bankName,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'expired_at': expiredAt?.toIso8601String(),
      'snap_token': snapToken,
      'snap_url': snapUrl,
    };
  }

  String getStatusText() {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'success':
        return 'Berhasil';
      case 'failed':
        return 'Gagal';
      case 'expired':
        return 'Kadaluarsa';
      default:
        return status;
    }
  }
}
