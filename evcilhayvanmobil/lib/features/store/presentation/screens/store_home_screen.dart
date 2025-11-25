import 'package:characters/characters.dart';
import 'package:evcilhayvanmobil/core/theme/app_palette.dart';
import 'package:evcilhayvanmobil/core/widgets/modern_background.dart';
import 'package:evcilhayvanmobil/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvanmobil/features/store/data/store_repository.dart';
import 'package:evcilhayvanmobil/features/store/domain/models/product_model.dart';
import 'package:evcilhayvanmobil/features/store/domain/models/store_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StoreHomeScreen extends ConsumerWidget {
  const StoreHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider);
    final feedAsync = ref.watch(storeFeedProvider);
    final storesAsync = ref.watch(storeDiscoverProvider);
    final myStoreAsync = user != null ? ref.watch(myStoreProvider) : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Mağaza'),
        actions: [
          if (user?.role == 'seller')
            IconButton(
              icon: const Icon(Icons.add_box_outlined),
              tooltip: 'Ürün ekle',
              onPressed: () => context.pushNamed('store-add-product'),
            ),
        ],
      ),
      body: ModernBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.refresh(storeFeedProvider.future),
                ref.refresh(storeDiscoverProvider.future),
                if (myStoreAsync != null) ref.refresh(myStoreProvider.future),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                if (user == null || user.role != 'seller')
                  _SellerCallToAction(onTap: () {
                    if (user == null) {
                      context.goNamed('login');
                    } else {
                      context.pushNamed('store-apply');
                    }
                  })
                else if (myStoreAsync != null)
                  myStoreAsync.when(
                    data: (store) => _StoreHeader(store: store),
                    loading: () => const _SectionCard(
                      title: 'Mağaza',
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => _SectionCard(
                      title: 'Mağaza',
                      child: Text('Mağazanız getirilemedi: $error'),
                    ),
                  ),
                const SizedBox(height: 12),
                storesAsync.when(
                  data: (stores) => _StoreCarousel(stores: stores),
                  loading: () => const _ShimmerSection(title: 'Öne çıkan mağazalar'),
                  error: (e, _) => _SectionCard(
                    title: 'Öne çıkan mağazalar',
                    child: Text('Liste alınamadı: $e'),
                  ),
                ),
                const SizedBox(height: 16),
                feedAsync.when(
                  data: (products) => _ProductFeed(products: products),
                  loading: () => const _ShimmerSection(title: 'Ürünler yükleniyor'),
                  error: (e, _) => _SectionCard(
                    title: 'Mağaza ürünleri',
                    child: Text('Ürünler alınamadı: $e'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SellerCallToAction extends StatelessWidget {
  final VoidCallback onTap;
  const _SellerCallToAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: AppPalette.accentGradient
              .map((c) => c.withOpacity(0.9))
              .toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.store_mall_directory, color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Satıcı olmak ister misiniz?',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mağazanızı açın, ilanlarınızla gelir elde edin.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppPalette.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Hemen Başvur'),
          ),
        ],
      ),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  final StoreModel? store;
  const _StoreHeader({required this.store});

  @override
  Widget build(BuildContext context) {
    if (store == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return _SectionCard(
      title: 'Mağazam',
      trailing: TextButton(
        onPressed: () => context.pushNamed('store-detail', pathParameters: {'storeId': store!.id}),
        child: const Text('Mağazayı Gör'),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: store!.logoUrl != null
                ? Image.network(
                    store!.logoUrl!,
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _LogoFallback(name: store!.name),
                  )
                : _LogoFallback(name: store!.name),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store!.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if ((store!.description ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      store!.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
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

class _StoreCarousel extends StatelessWidget {
  final List<StoreModel> stores;
  const _StoreCarousel({required this.stores});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (stores.isEmpty) {
      return const _SectionCard(
        title: 'Öne çıkan mağazalar',
        child: Text('Henüz mağaza bulunmuyor'),
      );
    }

    return _SectionCard(
      title: 'Öne çıkan mağazalar',
      child: SizedBox(
        height: 130,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: stores.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final store = stores[index];
            return GestureDetector(
              onTap: () => context.pushNamed(
                'store-detail',
                pathParameters: {'storeId': store.id},
              ),
              child: Container(
                width: 220,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
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
                      child: store.logoUrl != null
                          ? Image.network(
                              store.logoUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _LogoFallback(name: store.name),
                            )
                          : _LogoFallback(name: store.name),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            store.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            store.description ?? 'Mağaza açıklaması eklenmemiş',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProductFeed extends StatelessWidget {
  final List<ProductModel> products;
  const _ProductFeed({required this.products});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (products.isEmpty) {
      return const _SectionCard(
        title: 'Mağaza ürünleri',
        child: Text('Henüz ekli bir ürün yok.'),
      );
    }

    return _SectionCard(
      title: 'Mağaza ürünleri',
      child: Column(
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
                              const SizedBox(width: 12),
                              if (p.store != null)
                                Text(
                                  p.store!.name,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: theme.colorScheme.secondary),
                                ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.child, this.trailing});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
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

class _LogoFallback extends StatelessWidget {
  final String name;
  const _LogoFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 68,
      height: 68,
      color: theme.colorScheme.surfaceVariant,
      alignment: Alignment.center,
      child: Text(name.characters.take(2).toString().toUpperCase()),
    );
  }
}

class _ShimmerSection extends StatelessWidget {
  final String title;
  const _ShimmerSection({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      title: title,
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 160,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
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
