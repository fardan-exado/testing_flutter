class Paket{
  final int id;
  final String nama;
  final String coverPath;
  final String deskripsi;
  final double harga;
  final int durasi;

  Paket({
    required this.id,
    required this.nama,
    required this.coverPath,
    required this.deskripsi,
    required this.harga,
    required this.durasi,
  });

  factory Paket.fromJson(Map<String, dynamic> json) {
    return Paket(
      id: json['id'],
      nama: json['nama'],
      coverPath: json['cover_path'],
      deskripsi: json['deskripsi'],
      harga: json['harga'].toDouble(),
      durasi: json['durasi'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'cover_path': coverPath,
      'deskripsi': deskripsi,
      'harga': harga,
      'durasi': durasi,
    };
  }
}

class PlanModel {
  final String id;
  final String name;
  final String description;
  final int price;
  final int durationDays;
  final List<String> features;
  final bool isPopular;
  final String? discount;

  PlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    required this.features,
    this.isPopular = false,
    this.discount,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? 0,
      durationDays: json['duration_days'] ?? 0,
      features: List<String>.from(json['features'] ?? []),
      isPopular: json['is_popular'] ?? false,
      discount: json['discount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'duration_days': durationDays,
      'features': features,
      'is_popular': isPopular,
      'discount': discount,
    };
  }
}
