// lib/features/store/data/store_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:evcilhayvanmobil/core/http.dart';
import 'package:evcilhayvanmobil/features/auth/domain/user_model.dart';
import 'package:evcilhayvanmobil/features/store/domain/product_model.dart';
import 'package:evcilhayvanmobil/features/store/domain/store_model.dart';

class StoreApplicationResult {
  final User user;
  final StoreModel store;

  StoreApplicationResult({required this.user, required this.store});
}

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  final dio = HttpClient().dio;
  return StoreRepository(dio);
});

class StoreRepository {
  final Dio _dio;
  StoreRepository(this._dio);

  Future<List<StoreModel>> getStores() async {
    final response = await _dio.get('/api/store');
    final List<dynamic> list = response.data['stores'] ?? [];
    return list.map((json) => StoreModel.fromJson(json)).toList();
  }

  Future<StoreModel> getMyStore() async {
    final response = await _dio.get('/api/store/me');
    return StoreModel.fromJson(response.data['store']);
  }

  Future<List<StoreProduct>> getMyProducts() async {
    final response = await _dio.get('/api/store/me/products');
    final List<dynamic> list = response.data['products'] ?? [];
    return list.map((json) => StoreProduct.fromJson(json)).toList();
  }

  Future<List<StoreProduct>> getStoreProducts(String storeId) async {
    final response = await _dio.get('/api/store/$storeId/products');
    final List<dynamic> list = response.data['products'] ?? [];
    return list.map((json) => StoreProduct.fromJson(json)).toList();
  }

  Future<StoreProduct> addProduct({
    required String title,
    required double price,
    String? description,
    int? stock,
  }) async {
    final response = await _dio.post('/api/store/me/products', data: {
      'title': title,
      'price': price,
      'description': description,
      'stock': stock,
    });

    return StoreProduct.fromJson(response.data['product']);
  }

  Future<StoreApplicationResult> applyForSeller({
    required String storeName,
    String? description,
    String? logoUrl,
  }) async {
    final response = await _dio.post('/api/store/apply', data: {
      'storeName': storeName,
      'description': description,
      'logoUrl': logoUrl,
    });

    final prefs = await SharedPreferences.getInstance();
    final token = response.data['token'] as String?;
    if (token != null) {
      await prefs.setString('token', token);
    }

    final user = User.fromJson(response.data['user']);
    final store = StoreModel.fromJson(response.data['store']);

    return StoreApplicationResult(user: user, store: store);
  }
}

final storeListProvider = FutureProvider<List<StoreModel>>((ref) {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.getStores();
});

final myStoreProvider = FutureProvider<StoreModel?>((ref) async {
  final repo = ref.watch(storeRepositoryProvider);
  try {
    return await repo.getMyStore();
  } catch (_) {
    return null;
  }
});

final myStoreProductsProvider = FutureProvider<List<StoreProduct>>((ref) {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.getMyProducts();
});

final storeProductsProvider =
    FutureProvider.family<List<StoreProduct>, String>((ref, storeId) {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.getStoreProducts(storeId);
});
