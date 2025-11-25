class StoreOwner {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? city;

  StoreOwner({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.city,
  });

  factory StoreOwner.fromJson(Map<String, dynamic> json) {
    return StoreOwner(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Satıcı',
      avatarUrl: json['avatarUrl'] as String?,
      city: json['city'] as String?,
    );
  }
}

class StoreModel {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final bool isActive;
  final StoreOwner? owner;

  StoreModel({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.owner,
    this.isActive = true,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Mağaza',
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      isActive: json['isActive'] != null ? json['isActive'] as bool : true,
      owner: json['owner'] != null && json['owner'] is Map<String, dynamic>
          ? StoreOwner.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
    );
  }
}
