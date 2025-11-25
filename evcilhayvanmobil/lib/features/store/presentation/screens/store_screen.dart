import 'package:evcilhayvanmobil/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvanmobil/features/store/data/store_repository.dart';
import 'package:evcilhayvanmobil/features/store/domain/store_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvanmobil/core/theme/app_palette.dart';
import 'package:evcilhayvanmobil/core/widgets/modern_background.dart';
import 'package:evcilhayvanmobil/features/auth/domain/user_model.dart';
import 'package:evcilhayvanmobil/features/store/domain/product_model.dart';

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final User? currentUser = ref.watch(authProvider);
    final storesAsync = ref.watch(storeListProvider);
    final isSeller = currentUser?.role == 'seller';
    final AsyncValue<StoreModel?> myStoreAsync =
        isSeller ? ref.watch(myStoreProvider) : const AsyncValue.data(null);
    final AsyncValue<List<StoreProduct>> myProductsAsync = isSeller
        ? ref.watch(myStoreProductsProvider)
        : const AsyncValue.data([]);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Mağaza'),
        backgroundColor: Colors.transparent,
      ),
      body: ModernBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(storeListProvider);
              ref.invalidate(myStoreProvider);
              ref.invalidate(myStoreProductsProvider);
              await Future.wait([
                ref.read(storeListProvider.future),
                ref.read(myStoreProvider.future),
                ref.read(myStoreProductsProvider.future),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _HeroBanner(user: currentUser),
                const SizedBox(height: 16),
                if (currentUser == null)
                  _LoginPrompt(theme: theme)
                else if (currentUser.role != 'seller')
                  _SellerCtaCard(theme: theme)
                else
                  _MyStoreSection(
                    myStoreAsync: myStoreAsync,
                    myProductsAsync: myProductsAsync,
                  ),
                const SizedBox(height: 12),
                Text(
                  'Mağazalar',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                storesAsync.when(
                  data: (stores) => Column(
                    children: stores
                        .map((store) => _StoreCard(store: store))
                        .toList(),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Mağazalar getirilemedi: $e'),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
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

class _HeroBanner extends StatelessWidget {
  final User? user;
  const _HeroBanner({this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: AppPalette.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.primary.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evcil Market',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user == null
                ? 'Özel ürünleri ve mağazaları görmek için giriş yapın.'
                : 'Mağazaları inceleyin, satıcı olun, ürünlerinizi ekleyin.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerCtaCard extends StatelessWidget {
  final ThemeData theme;
  const _SellerCtaCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Satıcı olmak ister misiniz?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mağazanı aç, ürünlerini ekle ve evcil hayvan sahiplerine ulaş.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.pushNamed('seller-apply'),
            child: const Text('Satıcı Başvurusu Yap'),
          ),
        ],
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  final ThemeData theme;
  const _LoginPrompt({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Giriş yapın', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Mağaza açmak ve ürünleri görmek için giriş yapmanız gerekiyor.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.goNamed('login'),
            child: const Text('Giriş Yap'),
          ),
        ],
      ),
    );
  }
}

class _MyStoreSection extends ConsumerWidget {
  final AsyncValue<StoreModel?> myStoreAsync;
  final AsyncValue<List<StoreProduct>> myProductsAsync;

  const _MyStoreSection({
    required this.myStoreAsync,
    required this.myProductsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mağazam',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.pushNamed('add-product'),
              icon: const Icon(Icons.add),
              label: const Text('Ürün Ekle'),
            ),
          ],
        ),
        myStoreAsync.when(
          data: (store) {
            if (store == null) {
              return const Text('Mağaza bulunamadı');
            }
            return _StoreCard(store: store, showExplore: false);
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Mağaza bilgisi alınamadı: $e'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ürünlerim',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        myProductsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Henüz ürün eklemediniz.'),
              );
            }
            return Column(
              children: products
                  .map((p) => _ProductTile(product: p))
                  .toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Ürünler alınamadı: $e'),
          ),
        ),
      ],
    );
  }
}

class _StoreCard extends StatelessWidget {
  final StoreModel store;
  final bool showExplore;
  const _StoreCard({required this.store, this.showExplore = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
            radius: 26,
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  store.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (store.owner != null)
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16),
                          const SizedBox(width: 4),
                          Text(store.owner!.name),
                        ],
                      ),
                    const SizedBox(width: 12),
                    Icon(Icons.inventory_2_outlined,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text('${store.productCount} ürün'),
                  ],
                ),
                if (showExplore)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        context.pushNamed(
                          'store-detail',
                          pathParameters: {'storeId': store.id},
                          extra: store,
                        );
                      },
                      child: const Text('Mağazayı Gör'),
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

class _ProductTile extends StatelessWidget {
  final StoreProduct product;
  const _ProductTile({required this.product});

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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.primary.withOpacity(0.08),
            ),
            child: const Icon(Icons.inventory_2_outlined),
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
                  '₺${product.price.toStringAsFixed(2)} • Stok: ${product.stock}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
