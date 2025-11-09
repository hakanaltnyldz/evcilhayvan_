
// lib/features/connect/presentation/screens/connect_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvanmobil/core/http.dart';
import 'package:evcilhayvanmobil/core/theme/app_palette.dart';
import 'package:evcilhayvanmobil/core/widgets/modern_background.dart';
import 'package:evcilhayvanmobil/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvanmobil/features/messages/data/repositories/message_repository.dart';

class ConnectScreen extends ConsumerWidget {
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsyncValue = ref.watch(allUsersProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Topluluğu Keşfet'),
      ),
      body: ModernBackground(
        child: SafeArea(
          child: usersAsyncValue.when(
            data: (users) {
              if (users.isEmpty) {
                return const _EmptyConnectState();
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: users.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const _ConnectHero();
                  }

                  final user = users[index - 1];
                  return _UserCard(
                    name: user.name,
                    city: user.city,
                    about: user.about,
                    avatarUrl: _resolveAvatarUrl(user.avatarUrl),
                    onMessageTap: () async {
                      final currentUser = ref.read(authProvider);
                      if (currentUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Diğer kullanıcılarla sohbet için giriş yapın.'),
                          ),
                        );
                        return;
                      }

                      if (currentUser.id == user.id) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bu profil zaten sizin!'),
                          ),
                        );
                        return;
                      }

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const _ProgressDialog(),
                      );

                      try {
                        final repo = ref.read(messageRepositoryProvider);
                        final conversation = await repo.createOrGetConversation(
                          participantId: user.id,
                          currentUserId: currentUser.id,
                        );
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                          context.pushNamed(
                            'chat',
                            pathParameters: {'conversationId': conversation.id},
                            extra: {
                              'name': user.name,
                              'avatar': _resolveAvatarUrl(user.avatarUrl),
                            },
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      }
                    },
                  );
                },
              );
            },
            loading: () => const _LoadingList(),
            error: (error, stackTrace) {
              return _ErrorState(message: error.toString());
            },
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String name;
  final String? city;
  final String? about;
  final String? avatarUrl;
  final VoidCallback onMessageTap;

  const _UserCard({
    required this.name,
    required this.city,
    required this.about,
    required this.avatarUrl,
    required this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            AppPalette.heroGradient.first.withOpacity(0.12),
            AppPalette.heroGradient.last.withOpacity(0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.12),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.06),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -6,
            right: -6,
            child: Icon(
              Icons.pets,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.08),
            ),
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundImage:
                    avatarUrl != null ? CachedNetworkImageProvider(avatarUrl!) : null,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                child: avatarUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: theme.textTheme.titleLarge,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (city != null && city!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(city!, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    if (about != null && about!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        about!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onMessageTap,
                icon: const Icon(Icons.chat_bubble_rounded),
                label: const Text('Sohbet'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectHero extends StatelessWidget {
  const _ConnectHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [
            AppPalette.heroGradient.first.withOpacity(0.3),
            AppPalette.heroGradient.last.withOpacity(0.32),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Topluluğu keşfet',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hayvanseverlerle tanış, minik dostlarına yeni arkadaşlar bul. Sohbet başlatarak iletişime geç.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _HeroTag(icon: Icons.chat, label: 'Canlı sohbet'),
                    _HeroTag(icon: Icons.favorite, label: 'Güvenli eşleşme'),
                    _HeroTag(icon: Icons.pets, label: 'Mutlu patiler'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Image.network(
              'https://images.unsplash.com/photo-1583511655826-05700d52f4d9?auto=format&fit=crop&w=420&q=80',
              width: 110,
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 110,
                height: 140,
                color: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.pets,
                  size: 42,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppPalette.accentGradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppPalette.secondary.withOpacity(0.22),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyConnectState extends StatelessWidget {
  const _EmptyConnectState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sentiment_satisfied_alt,
              size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Henüz kimse burada değil',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'İlk bağlantıyı sen kur ve topluluğu hareketlendir.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 54, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            'Bağlanmak için giriş yap',
            style: theme.textTheme.titleMedium,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const _LoadingCard();
      },
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surface;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      height: 110,
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(26),
      ),
    );
  }
}

String? _resolveAvatarUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return '$apiBaseUrl$path';
}

class _ProgressDialog extends StatelessWidget {
  const _ProgressDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Sohbet hazırlanıyor...'),
          ],
        ),
      ),
    );
  }
}
