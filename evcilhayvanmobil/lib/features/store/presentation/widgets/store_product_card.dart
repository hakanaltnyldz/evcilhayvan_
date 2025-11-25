import 'package:flutter/material.dart';
import 'package:evcilhayvanmobil/features/store/domain/store_product.dart';

class StoreProductCard extends StatelessWidget {
  final StoreProduct product;
  const StoreProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.photos.isNotEmpty ? product.photos.first : null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 96,
                      height: 96,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: const Icon(Icons.image_not_supported),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (product.description?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        product.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    '${product.price.toStringAsFixed(2)} ₺',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                  if (product.storeName != null)
                    Text(
                      product.storeName!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
