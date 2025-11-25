import 'store_model.dart';

class ProductModel {
  final String id;
  final String title;
  final String? description;
  final double price;
  final List<String> photos;
  final int stock;
  final bool isActive;
  final StoreModel? store;

  ProductModel({
    required this.id,
    required this.title,
    required this.price,
    this.description,
    this.photos = const [],
    this.stock = 0,
    this.isActive = true,
    this.store,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawPhotos =
        (json['photos'] as List<dynamic>?) ?? const <dynamic>[];

    return ProductModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Ürün',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      photos: rawPhotos.whereType<String>().toList(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] != null ? json['isActive'] as bool : true,
      store: json['store'] != null && json['store'] is Map<String, dynamic>
          ? StoreModel.fromJson(json['store'] as Map<String, dynamic>)
          : null,
    );
  }
}
