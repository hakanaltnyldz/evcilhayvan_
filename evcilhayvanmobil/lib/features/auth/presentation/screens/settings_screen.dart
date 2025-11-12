// lib/features/auth/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:evcilhayvanmobil/core/widgets/modern_background.dart';
import 'package:evcilhayvanmobil/features/auth/data/repositories/auth_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _notificationsKey = 'settings.notifications_enabled';
  static const _matchAlertsKey = 'settings.match_alerts_enabled';
  static const _autoStartChatKey = 'settings.auto_start_chat';
  static const _compactCardsKey = 'settings.compact_cards';

  SharedPreferences? _prefs;
  bool _isLoadingPrefs = true;
  bool _notificationsEnabled = true;
  bool _matchAlertsEnabled = true;
  bool _autoStartChat = true;
  bool _compactCards = false;

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _prefs = prefs;
      _notificationsEnabled =
          prefs.getBool(_notificationsKey) ?? _notificationsEnabled;
      _matchAlertsEnabled =
          prefs.getBool(_matchAlertsKey) ?? _matchAlertsEnabled;
      _autoStartChat = prefs.getBool(_autoStartChatKey) ?? _autoStartChat;
      _compactCards = prefs.getBool(_compactCardsKey) ?? _compactCards;
      _isLoadingPrefs = false;
    });
  }

  void _updatePreference(String key, bool value, void Function() apply) {
    setState(apply);
    _prefs?.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ModernBackground(
        child: SafeArea(
          child: _isLoadingPrefs
              ? const Center(child: CircularProgressIndicator())
              : ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _SettingsHeader(userName: user?.name, email: user?.email),
              const SizedBox(height: 20),
              _SettingsCard(
                title: 'Hesabım',
                subtitle: 'Profilini güncelle, güvenlik ayarlarını yönet.',
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Profili Düzenle'),
                    subtitle: const Text('Kişisel bilgilerini ve biyografini güncelle'),
                    onTap: () => context.pushNamed('edit-profile'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_reset),
                    title: const Text('Şifreyi Değiştir'),
                    subtitle: const Text('E-posta üzerinden yeni bir şifre oluştur'),
                    onTap: () => context.pushNamed('forgot-password'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SettingsCard(
                title: 'Bildirimler',
                subtitle: 'Topluluktan geri kalma, kontrol tamamen sende.',
                children: [
                  SwitchListTile.adaptive(
                    value: _notificationsEnabled,
                    title: const Text('Sohbet bildirimleri'),
                    subtitle: const Text('Yeni mesaj ve sohbet isteklerinden haberdar ol'),
                    onChanged: (value) {
                      _updatePreference(
                        _notificationsKey,
                        value,
                        () => _notificationsEnabled = value,
                      );
                    },
                  ),
                  SwitchListTile.adaptive(
                    value: _matchAlertsEnabled,
                    title: const Text('Eşleşme uyarıları'),
                    subtitle: const Text('Yeni eşleşmelerde anında bildirim al'),
                    onChanged: (value) {
                      _updatePreference(
                        _matchAlertsKey,
                        value,
                        () => _matchAlertsEnabled = value,
                      );
                    },
                  ),
                  SwitchListTile.adaptive(
                    value: _autoStartChat,
                    title: const Text('Eşleşmelerde sohbeti otomatik hazırla'),
                    subtitle:
                        const Text('Eşleşme oluştuğunda sohbet ekranını hızlıca aç'),
                    onChanged: (value) {
                      _updatePreference(
                        _autoStartChatKey,
                        value,
                        () => _autoStartChat = value,
                      );
                      if (!value) {
                        _showSnack('Sohbetler artık sadece manuel olarak açılacak.');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SettingsCard(
                title: 'Uygulama Deneyimi',
                subtitle: 'Görünüm ve kişisel tercihlerini özelleştir.',
                children: [
                  SwitchListTile.adaptive(
                    value: _compactCards,
                    title: const Text('Kartları kompakt göster'),
                    subtitle: const Text('Liste görünümünde daha fazla içerik gör'),
                    onChanged: (value) {
                      _updatePreference(
                        _compactCardsKey,
                        value,
                        () => _compactCards = value,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Tema önerileri'),
                    subtitle: const Text('Yakında: açık/koyu tema desteği'),
                    onTap: () => _showSnack('Tema özelleştirme yakında eklenecek.'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.download_outlined),
                    title: const Text('Verilerimi dışa aktar'),
                    subtitle: const Text('İlan ve sohbet geçmişini e-posta olarak iste'),
                    onTap: () => _showSnack('Veri dışa aktarma isteğiniz alındı.'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SettingsCard(
                title: 'Destek',
                subtitle: 'Yardıma mı ihtiyacın var? Sana yardımcı olalım.',
                children: [
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('SSS ve Yardım Merkezi'),
                    onTap: () => _showSnack('Yardım merkezi yakında yayında!'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.mail_outline),
                    title: const Text('Destek ile iletişime geç'),
                    onTap: () => _showSnack('support@evcildostum.app adresine yazabilirsiniz.'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.share_outlined),
                    title: const Text('Uygulamayı Paylaş'),
                    onTap: () => _showSnack('Paylaşım bağlantısı panoya kopyalandı.'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SettingsCard(
                title: 'Hesaptan Çık',
                subtitle: 'Hesabından güvenle çıkış yap.',
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text('Çıkış Yap'),
                    iconColor: Colors.redAccent,
                    textColor: Colors.redAccent,
                    onTap: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        context.goNamed('login');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'v1.0.0 · Topluluğunu sevgiyle büyüt',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final String? userName;
  final String? email;

  const _SettingsHeader({this.userName, this.email});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = (userName?.isNotEmpty ?? false)
        ? userName!.trim()[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.18),
            theme.colorScheme.secondary.withOpacity(0.14),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            child: Text(
              initials,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName ?? 'Misafir Kullanıcı',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email ?? 'Henüz bir e-posta eklenmedi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: theme.colorScheme.surface.withOpacity(0.94),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}