import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvanmobil/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvanmobil/features/store/data/repositories/store_repository.dart';
import 'package:evcilhayvanmobil/features/store/domain/store_model.dart';
import 'package:evcilhayvanmobil/features/store/domain/store_product.dart';
import 'package:evcilhayvanmobil/features/store/presentation/widgets/store_product_card.dart';
import 'package:evcilhayvanmobil/features/store/presentation/widgets/store_tile.dart';

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storeListProvider);
    final productsAsync = ref.watch(storeProductsProvider);
    final currentUser = ref.watch(authProvider);
    final myStoreAsync = currentUser?.role == 'seller' ? ref.watch(myStoreProvider) : null;
    final bool requiresLogin = currentUser == null;

    Future<void> refresh() async {
      ref.invalidate(storeListProvider);
      ref.invalidate(storeProductsProvider);
      if (currentUser?.role == 'seller') {
        ref.invalidate(myStoreProvider);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mağaza'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => refresh(),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (currentUser == null || currentUser.role != 'seller')
              _SellerInviteCard(
                onTap: () {
                  if (requiresLogin) {
                    context.goNamed('login');
                  } else {
                    _openSellerSheet(context, ref);
                  }
                },
              )
            else if (myStoreAsync != null)
              myStoreAsync.when(
                data: (store) => _MyStoreBanner(
                  store: store,
                  onAddProduct: () => _openAddProductSheet(context, ref),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Mağaza bilgisi alınamadı: $error'),
                ),
              ),
            const SizedBox(height: 12),
            _SectionHeader(title: 'Öne Çıkan Mağazalar'),
            storesAsync.when(
              data: (stores) => _StoreStrip(stores: stores),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Mağazalar yüklenemedi: $err'),
              ),
            ),
            const SizedBox(height: 16),
            _SectionHeader(title: 'Mağaza Ürünleri'),
            productsAsync.when(
              data: (products) => _ProductFeed(products: products),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Ürünler yüklenemedi: $err'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSellerSheet(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final logoCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Satıcı Ol',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Mağaza Adı'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Açıklama'),
                maxLines: 2,
              ),
              TextField(
                controller: logoCtrl,
                decoration: const InputDecoration(labelText: 'Logo URL (isteğe bağlı)'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  try {
                    final result = await ref
                        .read(storeRepositoryProvider)
                        .applySeller(
                          storeName: nameCtrl.text.trim(),
                          description: descCtrl.text.trim().isEmpty
                              ? null
                              : descCtrl.text.trim(),
                          logoUrl: logoCtrl.text.trim().isEmpty
                              ? null
                              : logoCtrl.text.trim(),
                        );

                    ref.read(authProvider.notifier).loginSuccess(result.user);
                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mağaza oluşturuldu.')),
                      );
                      ref.invalidate(myStoreProvider);
                      ref.invalidate(storeListProvider);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Başvuru başarısız: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.store_mall_directory),
                label: const Text('Satıcı Ol'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAddProductSheet(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final photosCtrl = TextEditingController();
    final stockCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Yeni Ürün',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Başlık'),
                ),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Fiyat'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                  maxLines: 2,
                ),
                TextField(
                  controller: photosCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Fotoğraf URLleri (virgülle ayırın)',
                  ),
                ),
                TextField(
                  controller: stockCtrl,
                  decoration: const InputDecoration(labelText: 'Stok (opsiyonel)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text.replaceAll(',', '.'));
                    if (title.isEmpty || price == null) return;

                    List<String>? photos;
                    final parts = photosCtrl.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                    if (parts.isNotEmpty) {
                      photos = parts;
                    }

                    try {
                      await ref.read(storeRepositoryProvider).addProduct(
                            title: title,
                            price: price,
                            description: descCtrl.text.trim().isEmpty
                                ? null
                                : descCtrl.text.trim(),
                            photos: photos,
                            stock: int.tryParse(stockCtrl.text.trim()),
                          );
                      if (context.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ürün eklendi')),
                        );
                        ref.invalidate(storeProductsProvider);
                        ref.invalidate(myStoreProvider);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ürün eklenemedi: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Kaydet'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SellerInviteCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SellerInviteCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Satıcı olmak ister misiniz?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Mağazanızı oluşturun ve ürünlerinizi binlerce kullanıcıya sunun.',
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.store_mall_directory),
              label: const Text('Mağaza Başvurusu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyStoreBanner extends StatelessWidget {
  final StoreModel? store;
  final VoidCallback onAddProduct;

  const _MyStoreBanner({required this.store, required this.onAddProduct});

  @override
  Widget build(BuildContext context) {
    if (store == null) {
      return const SizedBox.shrink();
    }
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: (store!.logoUrl != null && store!.logoUrl!.isNotEmpty)
                  ? NetworkImage(store!.logoUrl!)
                  : null,
              child: (store!.logoUrl == null || store!.logoUrl!.isEmpty)
                  ? const Icon(Icons.store)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store!.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (store!.description?.isNotEmpty == true)
                    Text(
                      store!.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onAddProduct,
              child: const Text('Ürün Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _StoreStrip extends StatelessWidget {
  final List<StoreModel> stores;
  const _StoreStrip({required this.stores});

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Henüz mağaza yok'),
      );
    }
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stores.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final store = stores[index];
          return StoreTile(store: store);
        },
      ),
    );
  }
}

class _ProductFeed extends StatelessWidget {
  final List<StoreProduct> products;
  const _ProductFeed({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Henüz ürün yok'),
      );
    }
    return Column(
      children: products
          .map((product) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: StoreProductCard(product: product),
              ))
          .toList(),
    );
  }
}
