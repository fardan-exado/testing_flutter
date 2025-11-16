import 'package:test_flutter/features/subscription/models/paket.dart';

class Pesanan {
  final int id;
  final String orderId;
  final int userId;
  final int paketId;
  final double hargaTotal;
  final String status;
  final String midtransId;
  final String dibayarPada;
  final String kadaluarsaPada;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Paket premiumPaket;

  Pesanan({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.paketId,
    required this.hargaTotal,
    required this.status,
    required this.midtransId,
    required this.dibayarPada,
    required this.kadaluarsaPada,
    required this.createdAt,
    required this.updatedAt,
    required this.premiumPaket,
  });

  factory Pesanan.fromJson(Map<String, dynamic> json) {
    return Pesanan(
      id: json['id'],
      orderId: json['order_id'],
      userId: json['user_id'],
      paketId: json['paket_id'],
      hargaTotal: (json['harga_total'] as num).toDouble(),
      status: json['status'],
      midtransId: json['midtrans_id'],
      dibayarPada: json['dibayar_pada'],
      kadaluarsaPada: json['kadaluarsa_pada'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      premiumPaket: Paket.fromJson(json['premium_paket']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'user_id': userId,
      'paket_id': paketId,
      'harga_total': hargaTotal,
      'status': status,
      'midtrans_id': midtransId,
      'dibayar_pada': dibayarPada,
      'kadaluarsa_pada': kadaluarsaPada,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'premium_paket': premiumPaket.toJson(),
    };
  }
}
