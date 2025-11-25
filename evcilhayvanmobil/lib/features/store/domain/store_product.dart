class StoreProduct {
  final String id;
  final String title;
  final String? description;
  final double price;
  final List<String> photos;
  final int stock;
  final bool isActive;
  final String? storeId;
  final String? storeName;
  final String? storeLogo;

  StoreProduct({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    required this.photos,
    required this.stock,
    this.isActive = true,
    this.storeId,
    this.storeName,
    this.storeLogo,
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    final storeData = json['store'];
    String? resolvedStoreId;
    String? resolvedStoreName;
    String? resolvedStoreLogo;

    if (storeData is Map<String, dynamic>) {
      resolvedStoreId = storeData['_id']?.toString();
      resolvedStoreName = storeData['name']?.toString();
      resolvedStoreLogo = storeData['logoUrl']?.toString();
    } else if (storeData is String) {
      resolvedStoreId = storeData;
    }

    final List<String> photoList = (json['photos'] as List?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const [];

    return StoreProduct(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Ürün',
      description: json['description']?.toString(),
      price: _parseDouble(json['price']) ?? 0,
      photos: photoList,
      stock: _parseInt(json['stock']) ?? 0,
      isActive: json['isActive'] != false,
      storeId: resolvedStoreId,
      storeName: resolvedStoreName,
      storeLogo: resolvedStoreLogo,
    );
  }
}

double? _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
