import 'package:evcilhayvanmobil/features/store/data/store_repository.dart';
import 'package:evcilhayvanmobil/features/store/domain/store_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:evcilhayvanmobil/features/store/domain/product_model.dart';

class StoreDetailScreen extends ConsumerWidget {
  final String storeId;
  final StoreModel? store;
  const StoreDetailScreen({super.key, required this.storeId, this.store});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(storeProductsProvider(storeId));

    return Scaffold(
      appBar: AppBar(title: Text(store?.name ?? 'Mağaza')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (store != null) _StoreHeader(store: store!),
            const SizedBox(height: 12),
            Text(
              'Ürünler',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Bu mağazada henüz ürün yok.'),
                  );
                }
                return Column(
                  children: products
                      .map((p) => _ProductCard(product: p))
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(8),
                child: Text('Ürünler alınamadı: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  final StoreModel store;
  const _StoreHeader({required this.store});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage:
                store.logoUrl != null ? NetworkImage(store.logoUrl!) : null,
            child: store.logoUrl == null
                ? Icon(Icons.storefront, color: theme.colorScheme.primary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  store.description,
                  style: theme.textTheme.bodyMedium,
                ),
                if (store.owner != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16),
                      const SizedBox(width: 4),
                      Text(store.owner!.name),
                      if ((store.owner!.city ?? '').isNotEmpty) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.location_on_outlined, size: 16),
                        Text(store.owner!.city!),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final StoreProduct product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.primary.withOpacity(0.08),
              image: product.photos.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(product.photos.first),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: product.photos.isEmpty
                ? const Icon(Icons.image_not_supported_outlined)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  product.description ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '₺${product.price.toStringAsFixed(2)} • Stok: ${product.stock}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
