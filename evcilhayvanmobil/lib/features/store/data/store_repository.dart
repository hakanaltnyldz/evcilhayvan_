import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:evcilhayvanmobil/core/http.dart';
import 'package:evcilhayvanmobil/features/auth/domain/user_model.dart';
import 'package:evcilhayvanmobil/features/store/domain/models/product_model.dart';
import 'package:evcilhayvanmobil/features/store/domain/models/store_model.dart';

class SellerApplicationResult {
  final User user;
  final StoreModel store;
  SellerApplicationResult({required this.user, required this.store});
}

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  final dio = HttpClient().dio;
  return StoreRepository(dio);
});

final storeFeedProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.getProductFeed();
});

final storeDiscoverProvider =
    FutureProvider.autoDispose<List<StoreModel>>((ref) {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.getStores();
});

final myStoreProvider = FutureProvider.autoDispose<StoreModel?>((ref) async {
  final repo = ref.watch(storeRepositoryProvider);
  try {
    return await repo.getMyStore();
  } catch (_) {
    return null;
  }
});

final myProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.getMyProducts();
});

class StoreRepository {
  final Dio _dio;
  StoreRepository(this._dio);

  Future<List<StoreModel>> getStores() async {
    final response = await _dio.get('/api/store/discover');
    final List<dynamic> storeJson =
        (response.data['stores'] as List?) ?? const <dynamic>[];
    return storeJson
        .whereType<Map<String, dynamic>>()
        .map(StoreModel.fromJson)
        .toList();
  }

  Future<List<ProductModel>> getProductFeed() async {
    final response = await _dio.get('/api/store/feed');
    final List<dynamic> productJson =
        (response.data['products'] as List?) ?? const <dynamic>[];
    return productJson
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }

  Future<StoreModel?> getMyStore() async {
    final response = await _dio.get('/api/store/me');
    if (response.data['store'] == null) return null;
    return StoreModel.fromJson(response.data['store']);
  }

  Future<List<ProductModel>> getMyProducts() async {
    final response = await _dio.get('/api/store/me/products');
    final List<dynamic> productJson =
        (response.data['products'] as List?) ?? const <dynamic>[];
    return productJson
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }

  Future<StoreModel> getStore(String storeId) async {
    final response = await _dio.get('/api/store/$storeId');
    return StoreModel.fromJson(response.data['store']);
  }

  Future<List<ProductModel>> getStoreProducts(String storeId) async {
    final response = await _dio.get('/api/store/$storeId/products');
    final List<dynamic> productJson =
        (response.data['products'] as List?) ?? const <dynamic>[];
    return productJson
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }

  Future<SellerApplicationResult> applySeller({
    required String storeName,
    String? description,
    String? logoUrl,
  }) async {
    final response = await _dio.post('/api/store/apply', data: {
      'storeName': storeName,
      if (description != null) 'description': description,
      if (logoUrl != null && logoUrl.isNotEmpty) 'logoUrl': logoUrl,
    });

    final prefs = await SharedPreferences.getInstance();
    final token = response.data['token'] as String?;
    if (token != null) {
      await prefs.setString('token', token);
    }

    final user = User.fromJson(response.data['user'] as Map<String, dynamic>);
    final store = StoreModel.fromJson(response.data['store']);
    return SellerApplicationResult(user: user, store: store);
  }

  Future<ProductModel> addProduct({
    required String title,
    required double price,
    String? description,
    List<String>? photos,
    int? stock,
  }) async {
    final response = await _dio.post('/api/store/me/products', data: {
      'title': title,
      'price': price,
      if (description != null) 'description': description,
      if (photos != null) 'photos': photos,
      if (stock != null) 'stock': stock,
    });

    return ProductModel.fromJson(response.data['product']);
  }
}
