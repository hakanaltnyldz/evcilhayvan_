import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:evcilhayvanmobil/core/http.dart';
import 'package:evcilhayvanmobil/features/auth/domain/user_model.dart';
import 'package:evcilhayvanmobil/features/store/domain/store_model.dart';
import 'package:evcilhayvanmobil/features/store/domain/store_product.dart';

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  final dio = HttpClient().dio;
  return StoreRepository(dio);
});

final storeListProvider = FutureProvider.autoDispose<List<StoreModel>>((ref) async {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.fetchStores();
});

final storeProductsProvider =
    FutureProvider.autoDispose<List<StoreProduct>>((ref) async {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.fetchAllProducts();
});

final myStoreProvider = FutureProvider<StoreModel?>((ref) async {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.getMyStore();
});

final storeDetailProvider =
    FutureProvider.family<StoreDetail, String>((ref, storeId) async {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.getStoreDetail(storeId);
});

class StoreDetail {
  final StoreModel store;
  final List<StoreProduct> products;

  StoreDetail({required this.store, required this.products});
}

class SellerApplicationResult {
  final User user;
  final StoreModel store;
  final String token;

  SellerApplicationResult({
    required this.user,
    required this.store,
    required this.token,
  });
}

class StoreRepository {
  final Dio _dio;
  StoreRepository(this._dio);

  Future<List<StoreModel>> fetchStores() async {
    final response = await _dio.get('/api/store');
    final List<dynamic> list =
        (response.data['stores'] as List?) ?? (response.data['data'] as List?) ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => StoreModel.fromJson(e))
        .toList();
  }

  Future<List<StoreProduct>> fetchAllProducts() async {
    final response = await _dio.get('/api/store/products');
    final List<dynamic> list =
        (response.data['products'] as List?) ?? (response.data['data'] as List?) ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => StoreProduct.fromJson(e))
        .toList();
  }

  Future<StoreModel?> getMyStore() async {
    try {
      final response = await _dio.get('/api/store/me');
      final data = response.data['store'] as Map<String, dynamic>?;
      if (data == null) return null;
      return StoreModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<SellerApplicationResult> applySeller({
    required String storeName,
    String? description,
    String? logoUrl,
  }) async {
    final response = await _dio.post(
      '/api/store/apply',
      data: {
        'storeName': storeName,
        if (description != null) 'description': description,
        if (logoUrl != null) 'logoUrl': logoUrl,
      },
    );

    final token = response.data['token'] as String? ?? '';
    if (token.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
    }

    final userJson =
        (response.data['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final storeJson =
        (response.data['store'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return SellerApplicationResult(
      user: User.fromJson(userJson),
      store: StoreModel.fromJson(storeJson),
      token: token,
    );
  }

  Future<StoreProduct> addProduct({
    required String title,
    required double price,
    String? description,
    List<String>? photos,
    int? stock,
  }) async {
    final response = await _dio.post(
      '/api/store/me/products',
      data: {
        'title': title,
        'price': price,
        if (description != null) 'description': description,
        if (photos != null) 'photos': photos,
        if (stock != null) 'stock': stock,
      },
    );

    final productJson =
        (response.data['product'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return StoreProduct.fromJson(productJson);
  }

  Future<List<StoreProduct>> getStoreProducts(String storeId) async {
    final response = await _dio.get('/api/store/$storeId/products');
    final List<dynamic> list =
        (response.data['products'] as List?) ?? (response.data['data'] as List?) ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => StoreProduct.fromJson(e))
        .toList();
  }

  Future<StoreModel> getStoreProfile(String storeId) async {
    final response = await _dio.get('/api/store/$storeId');
    final data = (response.data['store'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return StoreModel.fromJson(data);
  }

  Future<StoreDetail> getStoreDetail(String storeId) async {
    final store = await getStoreProfile(storeId);
    final products = await getStoreProducts(storeId);
    return StoreDetail(store: store, products: products);
  }
}
