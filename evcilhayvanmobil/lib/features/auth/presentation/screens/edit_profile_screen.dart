// lib/features/auth/presentation/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evcilhayvanmobil/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvanmobil/features/auth/domain/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:evcilhayvanmobil/core/http.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  late final TextEditingController _aboutController;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 1. O anki kullanıcıyı global state'ten (authProvider) oku
    final currentUser = ref.read(authProvider);

    // 2. Controller'ları o kullanıcının mevcut bilgileriyle doldur
    _nameController = TextEditingController(text: currentUser?.name ?? '');
    _cityController = TextEditingController(text: currentUser?.city ?? '');
    _aboutController = TextEditingController(text: currentUser?.about ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  // Profil Fotoğrafı Yükleme Fonksiyonu
  Future<void> _uploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return; // Kullanıcı iptal etti

    setState(() => _isLoading = true);
    try {
      // 1. Resmi yükle
      final updatedUser = await ref.read(authRepositoryProvider).uploadAvatar(image);
      
      // 2. Başarılıysa, global state'i (authProvider) yeni user ile güncelle
      ref.read(authProvider.notifier).loginSuccess(updatedUser);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil fotoğrafı güncellendi!'))
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Profil Bilgilerini Kaydetme Fonksiyonu
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      // 1. Repository'deki updateProfile metodunu çağır
      final updatedUser = await ref.read(authRepositoryProvider).updateProfile(
        name: _nameController.text,
        city: _cityController.text,
        about: _aboutController.text,
      );
      
      // 2. Başarılıysa, global state'i güncelle
      ref.read(authProvider.notifier).loginSuccess(updatedUser);

      // 3. Bir önceki ekrana (Ayarlar) geri dön
      if (mounted) context.pop();

    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // build metodu içinde 'watch' kullanarak state'i izle
    final currentUser = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // --- Profil Fotoğrafı Alanı ---
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        child: (currentUser?.avatarUrl != null)
                          ? ClipOval( 
                              child: CachedNetworkImage(
                                imageUrl: '${apiBaseUrl}${currentUser!.avatarUrl}', 
                                placeholder: (context, url) => const CircularProgressIndicator(),
                                errorWidget: (context, url, error) => const Icon(Icons.person, size: 60),
                                fit: BoxFit.cover, width: 120, height: 120,
                              ),
                            )
                          : Text( 
                              (currentUser?.name.isNotEmpty ?? false) 
                                ? currentUser!.name.substring(0, 1).toUpperCase() 
                                : '?',
                              style: const TextStyle(fontSize: 50),
                            ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _isLoading ? null : _uploadAvatar,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // --- Bilgi Formları ---
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'İsim Soyisim'),
                  validator: (value) => (value?.isEmpty ?? true) ? 'İsim boş olamaz' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'Şehir'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _aboutController,
                  decoration: const InputDecoration(labelText: 'Hakkımda', alignLabelWithHint: true),
                  maxLines: 5,
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null)
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),

                // --- Kaydet Butonu ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Değişiklikleri Kaydet'),
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