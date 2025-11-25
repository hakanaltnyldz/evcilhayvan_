// lib/features/store/domain/store_model.dart

class StoreModel {
  final String id;
  final String name;
  final String description;
  final String? logoUrl;
  final bool isActive;
  final int productCount;
  final StoreOwner? owner;

  StoreModel({
    required this.id,
    required this.name,
    required this.description,
    required this.logoUrl,
    required this.isActive,
    required this.productCount,
    required this.owner,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['_id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      productCount: json['productCount'] as int? ?? 0,
      owner: json['owner'] != null
          ? StoreOwner.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
    );
  }
}

class StoreOwner {
  final String id;
  final String name;
  final String? city;
  final String? avatarUrl;

  StoreOwner({
    required this.id,
    required this.name,
    this.city,
    this.avatarUrl,
  });

  factory StoreOwner.fromJson(Map<String, dynamic> json) {
    return StoreOwner(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      city: json['city'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
