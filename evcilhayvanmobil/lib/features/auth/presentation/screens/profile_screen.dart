// lib/features/auth/presentation/screens/profile_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvanmobil/core/http.dart';
import 'package:evcilhayvanmobil/core/theme/app_palette.dart';
import 'package:evcilhayvanmobil/core/widgets/modern_background.dart';
import 'package:evcilhayvanmobil/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvanmobil/features/pets/data/repositories/pets_repository.dart';
import 'package:evcilhayvanmobil/features/pets/domain/models/pet_model.dart';
import '../../domain/user_model.dart';

import '../../../pets/presentation/screens/widgets/pet_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String petId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('İlanı Sil'),
          content: const Text(
            'Bu ilanı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Sil'),
              onPressed: () async {
                try {
                  await ref.read(petsRepositoryProvider).deletePet(petId);
                  ref.invalidate(myPetsProvider);
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('İlan başarıyla silindi.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);
    final myPetsAsyncValue = ref.watch(myPetsProvider);

    if (currentUser == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        ),
        body: ModernBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 64, color: Colors.white70),
                  const SizedBox(height: 16),
                  Text(
                    'Profili görmek için giriş yapmalısınız.',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.goNamed('login'),
                    child: const Text('Giriş Yap'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final petCount = myPetsAsyncValue.maybeWhen(
      data: (pets) => pets.length,
      orElse: () => null,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.pushNamed('settings'),
          ),
        ],
      ),
      body: ModernBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ProfileHeader(
                  user: currentUser,
                  petCount: petCount,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _StatChip(
                        icon: Icons.pets,
                        label: 'İlanlarım',
                        value: petCount?.toString() ?? '...',
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.star_outline,
                        label: 'Beğeniler',
                        value: 'Yeni',
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.pushNamed('create-pet'),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Yeni ilan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              myPetsAsyncValue.when(
                data: (pets) {
                  if (pets.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _NoPetsCard(),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final pet = pets[index];
                          if (pet.owner == null) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Stack(
                              children: [
                                PetCard(
                                  pet: pet,
                                  onTap: () {
                                    context.pushNamed(
                                      'pet-detail',
                                      pathParameters: {'id': pet.id},
                                    );
                                  },
                                ),
                                Positioned(
                                  top: 16,
                                  right: 24,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.white),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black.withOpacity(0.5),
                                        ),
                                        onPressed: () {
                                          context.pushNamed('create-pet', extra: pet);
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.white),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black.withOpacity(0.5),
                                        ),
                                        onPressed: () =>
                                            _showDeleteDialog(context, ref, pet.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: pets.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, s) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('İlanlar yüklenemedi: $e'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User user;
  final int? petCount;

  const _ProfileHeader({required this.user, required this.petCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = user.avatarUrl != null ? '${apiBaseUrl}${user.avatarUrl}' : null;

    final onPrimary = theme.colorScheme.onPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            colors: [
              AppPalette.heroGradient.first.withOpacity(0.95),
              AppPalette.heroGradient.last.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppPalette.primary.withOpacity(0.24),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 42,
                backgroundImage:
                    avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                backgroundColor: Colors.white.withOpacity(0.18),
                child: avatarUrl == null
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: theme.textTheme.bodyMedium?.copyWith(color: onPrimary.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Şehir: ${user.city ?? 'Belirtilmemiş'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onPrimary.withOpacity(0.8),
                    ),
                  ),
                  if (user.about != null && user.about!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      user.about!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onPrimary.withOpacity(0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  petCount?.toString() ?? '-',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: onPrimary,
                  ),
                ),
                Text(
                  'İlan',
                  style: theme.textTheme.bodySmall?.copyWith(color: onPrimary.withOpacity(0.9)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: AppPalette.accentGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.secondary.withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPetsCard extends StatelessWidget {
  const _NoPetsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              AppPalette.heroGradient.first.withOpacity(0.1),
              AppPalette.heroGradient.last.withOpacity(0.18),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.1),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets_outlined, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Henüz hiç ilanınız yok.',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'İlk ilanınızı oluşturarak topluluğa yeni bir dost kazandırabilirsiniz.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.pushNamed('create-pet'),
              icon: const Icon(Icons.add),
              label: const Text('İlan Oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}