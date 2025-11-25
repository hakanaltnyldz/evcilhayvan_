import 'package:evcilhayvanmobil/features/store/data/store_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvanmobil/features/auth/data/repositories/auth_repository.dart';

class SellerApplicationScreen extends ConsumerStatefulWidget {
  const SellerApplicationScreen({super.key});

  @override
  ConsumerState<SellerApplicationScreen> createState() => _SellerApplicationScreenState();
}

class _SellerApplicationScreenState extends ConsumerState<SellerApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final result = await ref.read(storeRepositoryProvider).applyForSeller(
            storeName: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
          );

      ref.read(authProvider.notifier).loginSuccess(result.user);
      ref.invalidate(myStoreProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mağaza oluşturuldu!')),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Başvuru başarısız: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Satıcı Başvurusu')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Mağaza adı',
                    prefixIcon: Icon(Icons.store_mall_directory),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Mağaza adı gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_submitting ? 'Gönderiliyor' : 'Başvuruyu Gönder'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Başvurunuz onaylandığında rolünüz "seller" olacak ve ürün ekleyebileceksiniz.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
