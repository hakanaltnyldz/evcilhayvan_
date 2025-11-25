import 'package:characters/characters.dart';
import 'package:evcilhayvanmobil/core/widgets/modern_background.dart';
import 'package:evcilhayvanmobil/features/store/data/store_repository.dart';
import 'package:evcilhayvanmobil/features/store/domain/models/product_model.dart';
import 'package:evcilhayvanmobil/features/store/domain/models/store_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StoreDetailScreen extends ConsumerWidget {
  final String storeId;
  const StoreDetailScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeAsync = ref.watch(_storeProvider(storeId));
    final productsAsync = ref.watch(_storeProductsProvider(storeId));

    return Scaffold(
      appBar: AppBar(title: const Text('Mağaza Detayı')),
      body: ModernBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              storeAsync.when(
                data: (store) => _StoreHeader(store: store),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Mağaza yüklenemedi: $e'),
              ),
              const SizedBox(height: 16),
              productsAsync.when(
                data: (products) => _ProductList(products: products),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Ürünler alınamadı: $e'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

final _storeProvider = FutureProvider.family<StoreModel, String>((ref, id) async {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.getStore(id);
});

final _storeProductsProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, id) async {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.getStoreProducts(id);
});

class _StoreHeader extends StatelessWidget {
  final StoreModel store;
  const _StoreHeader({required this.store});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: store.logoUrl != null
                ? Image.network(
                    store.logoUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _LogoFallback(name: store.name),
                  )
                : _LogoFallback(name: store.name),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if ((store.description ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      store.description!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                if (store.owner != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 18),
                        const SizedBox(width: 6),
                        Text(store.owner!.name),
                        if ((store.owner!.city ?? '').isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on_outlined, size: 16),
                          Text(store.owner!.city!),
                        ],
                      ],
                    ),
                  )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final List<ProductModel> products;
  const _ProductList({required this.products});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (products.isEmpty) {
      return const Text('Bu mağazada henüz ürün yok.');
    }

    return Column(
      children: products
          .map(
            (p) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (p.photos.isNotEmpty)
                        ? Image.network(
                            p.photos.first,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _PlaceholderBox(title: p.title),
                          )
                        : _PlaceholderBox(title: p.title),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if ((p.description ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              p.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '₺${p.price.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('Stok: ${p.stock}'),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  final String name;
  const _LogoFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 80,
      height: 80,
      color: theme.colorScheme.surfaceVariant,
      alignment: Alignment.center,
      child: Text(name.characters.take(2).toString().toUpperCase()),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  final String title;
  const _PlaceholderBox({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 76,
      height: 76,
      color: theme.colorScheme.surfaceVariant,
      alignment: Alignment.center,
      child: Text(title.characters.take(2).toString().toUpperCase()),
    );
  }
}
