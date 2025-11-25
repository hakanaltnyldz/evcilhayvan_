import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:evcilhayvanmobil/core/http.dart';
import 'package:evcilhayvanmobil/core/theme/app_palette.dart';
import 'package:evcilhayvanmobil/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvanmobil/features/auth/domain/user_model.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

  static const List<String?> _routeNames = [
    'messages', // 0: Sohbetler
    'home', // 1: Sahiplen
    'store', // 2: Mağaza
    null, // 3: FAB alanı
    'mating', // 4: Çiftleştir
    'profile', // 5: Profil
  ];

  void _onItemTapped(int index, BuildContext context) {
    final currentUser = ref.read(authProvider);
    if (index == 3) return;

    if (currentUser == null && (index == 0 || index == 4 || index == 5)) {
      context.goNamed('login');
      return;
    }

    final routeName = _routeNames[index];
    if (routeName != null) {
      context.goNamed(routeName);
    }
  }

  void _updateCurrentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    if (location.startsWith('/messages')) {
      _selectedIndex = 0;
    } else if (location == '/' || location.startsWith('/home')) {
      _selectedIndex = 1;
    } else if (location.startsWith('/store')) {
      _selectedIndex = 2;
    } else if (location.startsWith('/mating')) {
      _selectedIndex = 4;
    } else if (location.startsWith('/profile')) {
      _selectedIndex = 5;
    } else {
      _selectedIndex = 1; // Varsayılan: Sahiplen
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateCurrentIndex(context);
    final currentUser = ref.watch(authProvider);
    final theme = Theme.of(context);

    return SafeArea( // ✅ taşma önleyen katman
      child: Scaffold(
        resizeToAvoidBottomInset: false, // 🔧 alt taşma uyarılarını da susturur
        body: widget.child,
        floatingActionButton: (currentUser != null)
            ? DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppPalette.accentGradient,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.secondary.withOpacity(0.32),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    context.pushNamed('create-pet');
                  },
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni İlan'),
                  elevation: 0,
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppPalette.background.withOpacity(0.94),
                  theme.colorScheme.surfaceVariant.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                currentIndex: _selectedIndex,
                onTap: (index) => _onItemTapped(index, context),
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: true,
                showUnselectedLabels: false,
                selectedItemColor: theme.colorScheme.primary,
                unselectedItemColor: theme.colorScheme.onSurfaceVariant,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: _MessagesNavIcon(isActive: false),
                    activeIcon: _MessagesNavIcon(isActive: true),
                    label: 'Sohbetler',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.pets_outlined),
                    activeIcon: Icon(Icons.pets),
                    label: 'Sahiplen',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.storefront_outlined),
                    activeIcon: Icon(Icons.storefront),
                    label: 'Mağaza',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.add, color: Colors.transparent),
                    label: 'Yeniden', // boşluk için
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite_border),
                    activeIcon: Icon(Icons.favorite),
                    label: 'Çiftleştir',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profil',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessagesNavIcon extends ConsumerWidget {
  final bool isActive;

  const _MessagesNavIcon({required this.isActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final User? user = ref.watch(authProvider);
    final avatarUrl = _resolveAvatarUrl(user?.avatarUrl);
    final hasInitial = (user?.name ?? '').isNotEmpty;
    final initial = hasInitial ? user!.name[0].toUpperCase() : null;

    final borderColor = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withOpacity(0.2);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        color: theme.colorScheme.surface,
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _NavIconFallback(
                  isActive: isActive,
                  initial: initial,
                ),
              )
            : _NavIconFallback(
                isActive: isActive,
                initial: initial,
              ),
      ),
    );
  }
}

class _NavIconFallback extends StatelessWidget {
  final bool isActive;
  final String? initial;

  const _NavIconFallback({required this.isActive, this.initial});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (initial != null) {
      return Center(
        child: Text(
          initial!,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Icon(
      isActive ? Icons.chat_bubble : Icons.chat_bubble_outline,
      color: isActive
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurfaceVariant,
      size: 20,
    );
  }
}

String? _resolveAvatarUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return '$apiBaseUrl$path';
}