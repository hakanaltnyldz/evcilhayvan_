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
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Bilinmeyen Kullanıcı',
      avatarUrl: json['avatarUrl']?.toString(),
      city: json['city']?.toString(),
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
  final int productCount;

  StoreModel({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.owner,
    this.isActive = true,
    this.productCount = 0,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    final ownerData = json['owner'];
    return StoreModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Mağaza',
      description: json['description']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
      isActive: json['isActive'] != false,
      owner:
          ownerData is Map<String, dynamic> ? StoreOwner.fromJson(ownerData) : null,
      productCount: json['productCount'] is int
          ? json['productCount'] as int
          : int.tryParse(json['productCount']?.toString() ?? '') ?? 0,
    );
  }
}
