// lib/features/store/domain/product_model.dart

class StoreProduct {
  final String id;
  final String title;
  final String? description;
  final double price;
  final List<String> photos;
  final int stock;

  StoreProduct({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    required this.photos,
    required this.stock,
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    return StoreProduct(
      id: json['_id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      photos: (json['photos'] as List<dynamic>? ?? []).cast<String>(),
      stock: json['stock'] as int? ?? 0,
    );
  }
}
