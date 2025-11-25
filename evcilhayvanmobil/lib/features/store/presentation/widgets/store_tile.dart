import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvanmobil/features/store/domain/store_model.dart';

class StoreTile extends StatelessWidget {
  final StoreModel store;
  const StoreTile({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.pushNamed('store-detail', pathParameters: {'id': store.id}),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      (store.logoUrl != null && store.logoUrl!.isNotEmpty)
                          ? NetworkImage(store.logoUrl!)
                          : null,
                  child: (store.logoUrl == null || store.logoUrl!.isEmpty)
                      ? const Icon(Icons.storefront)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    store.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (store.description?.isNotEmpty == true)
              Text(
                store.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const Spacer(),
            Text(
              '${store.productCount} ürün',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
