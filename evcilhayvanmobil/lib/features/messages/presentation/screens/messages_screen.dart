// lib/features/messages/presentation/screens/messages_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvanmobil/core/http.dart';
import 'package:evcilhayvanmobil/core/theme/app_palette.dart';
import 'package:evcilhayvanmobil/core/widgets/modern_background.dart';
import 'package:evcilhayvanmobil/features/messages/data/repositories/message_repository.dart';
import 'package:evcilhayvanmobil/features/pets/data/repositories/pets_repository.dart';
import 'package:evcilhayvanmobil/features/pets/domain/models/pet_model.dart';

final _conversationPetProvider =
    FutureProvider.autoDispose.family<Pet?, String>((ref, petId) async {
  final repo = ref.watch(petsRepositoryProvider);
  try {
    return await repo.getPetById(petId);
  } catch (_) {
    return null;
  }
});

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Sohbetler'),
      ),
      body: ModernBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const _Header(),
                Expanded(
                  child: conversationsAsync.when(
                    data: (conversations) {
                      if (conversations.isEmpty) {
                        return const _EmptyConversations();
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          await ref.refresh(conversationsProvider.future);
                        },
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: const EdgeInsets.only(bottom: 24, top: 12),
                          itemCount: conversations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final conv = conversations[index];
                            return _ConversationCard(
                              title: conv.otherParticipant.name,
                              subtitle: conv.lastMessage.isNotEmpty
                                  ? conv.lastMessage
                                  : 'Sohbete başla',
                              relatedPet: conv.relatedPet,
                              relatedPetId: conv.relatedPetId,
                              updatedAt: conv.updatedAt,
                              avatarUrl: _resolveAvatarUrl(
                                conv.otherParticipant.avatarUrl,
                              ),
                              onTap: () {
                                context.pushNamed(
                                  'chat',
                                  pathParameters: {'conversationId': conv.id},
                                  extra: {
                                    'name': conv.otherParticipant.name,
                                    'avatar': _resolveAvatarUrl(
                                      conv.otherParticipant.avatarUrl,
                                    ),
                                  },
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const _LoadingState(),
                    error: (error, stack) => _ErrorState(message: error.toString()),
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            AppPalette.heroGradient.first.withOpacity(0.26),
            AppPalette.heroGradient.last.withOpacity(0.24),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.primary.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sohbet kutunu renklendir',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sahiplendirme görüşmelerini, ilan sorularını ve yeni dostlukları burada yönet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&w=360&q=80',
              width: 90,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 90,
                height: 100,
                color: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.pets,
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

class _ConversationCard extends ConsumerWidget {
  final String title;
  final String subtitle;
  final Pet? relatedPet;
  final String? relatedPetId;
  final DateTime updatedAt;
  final String? avatarUrl;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.title,
    required this.subtitle,
    this.relatedPet,
    this.relatedPetId,
    required this.updatedAt,
    required this.avatarUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    AsyncValue<Pet?> petAsync;
    if (relatedPet != null) {
      petAsync = AsyncValue<Pet?>.data(relatedPet);
    } else if (relatedPetId != null && relatedPetId!.isNotEmpty) {
      petAsync = ref.watch(_conversationPetProvider(relatedPetId!));
    } else {
      petAsync = const AsyncData<Pet?>(null);
    }

    final petChipLabel = petAsync.when(
      data: (pet) => pet?.name ?? 'İlan bilgisi bulunamadı',
      loading: () => 'İlan yükleniyor...',
      error: (_, __) => 'İlan bilgisi alınamadı',
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppPalette.background,
              AppPalette.heroGradient.last.withOpacity(0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? Text(
                      title.isNotEmpty ? title[0].toUpperCase() : '?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
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
                      Text(
                        _formatUpdatedAt(updatedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppPalette.accentGradient,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.pets,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          petChipLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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

class _EmptyConversations extends StatelessWidget {
  const _EmptyConversations();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.network(
                'https://images.unsplash.com/photo-1507146426996-ef05306b995a?auto=format&fit=crop&w=420&q=80',
                height: 140,
                width: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  width: 200,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 38,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Henüz bir konuşma yok',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Evcil dostlar hakkında konuşmaya başlamak için ilanlardan birine göz at.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 32),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: ShimmerTile(index: index),
        );
      },
    );
  }
}

class ShimmerTile extends StatefulWidget {
  final int index;
  const ShimmerTile({super.key, required this.index});

  @override
  State<ShimmerTile> createState() => _ShimmerTileState();
}

class _ShimmerTileState extends State<ShimmerTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final baseColor = Theme.of(context).colorScheme.surface;
        final highlightColor =
            Theme.of(context).colorScheme.primary.withOpacity(0.12);
        final t = 0.5 + (_controller.value * 0.5);
        final color = Color.lerp(baseColor, highlightColor, t)!;

        return Container(
          height: 86,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
          ),
        );
      },
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
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            'Sohbetler yüklenemedi',
            style: theme.textTheme.titleMedium,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatUpdatedAt(DateTime time) {
  final hours = time.hour.toString().padLeft(2, '0');
  final minutes = time.minute.toString().padLeft(2, '0');
  return '$hours:$minutes';
}

String? _resolveAvatarUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return '$apiBaseUrl$path';
}