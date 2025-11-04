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
