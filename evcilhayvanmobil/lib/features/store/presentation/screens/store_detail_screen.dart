import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:evcilhayvanmobil/features/store/data/repositories/store_repository.dart';
import 'package:evcilhayvanmobil/features/store/presentation/widgets/store_product_card.dart';

class StoreDetailScreen extends ConsumerWidget {
  final String storeId;
  const StoreDetailScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(storeDetailProvider(storeId));

    return Scaffold(
      appBar: AppBar(title: const Text('Mağaza Detayı')),
      body: detailAsync.when(
        data: (detail) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: (detail.store.logoUrl != null &&
                          detail.store.logoUrl!.isNotEmpty)
                      ? NetworkImage(detail.store.logoUrl!)
                      : null,
                  child: (detail.store.logoUrl == null ||
                          detail.store.logoUrl!.isEmpty)
                      ? const Icon(Icons.store)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.store.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (detail.store.owner != null)
                        Text(
                          'Satıcı: ${detail.store.owner!.name}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (detail.store.description?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(detail.store.description!),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Ürünler',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (detail.products.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Bu mağazada henüz ürün yok.'),
              )
            else
              ...detail.products.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: StoreProductCard(product: p),
                ),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Mağaza yüklenemedi: $err'),
          ),
        ),
      ),
    );
  }
}
