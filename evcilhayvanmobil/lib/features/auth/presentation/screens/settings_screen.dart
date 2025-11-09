// lib/features/auth/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evcilhayvanmobil/features/auth/data/repositories/auth_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        children: [
          // --- 1. PROFİLİ DÜZENLE (GÜNCELLENDİ) ---
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Profili Düzenle'),
            onTap: () {
              // Artık "edit-profile" rotasına gidiyoruz
              context.pushNamed('edit-profile');
            },
          ),
          // --- BİTTİ ---

          // --- 2. ŞİFREYİ DEĞİŞTİR ---
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Şifreyi Değiştir'),
            onTap: () {
              context.pushNamed('forgot-password');
            },
          ),

          const Divider(),

          // --- 3. ÇIKIŞ YAP ---
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.goNamed('login');
              }
            },
          ),
        ],
      ),
    );
  }
}