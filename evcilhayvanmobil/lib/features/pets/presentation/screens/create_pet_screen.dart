// lib/features/pets/presentation/screens/create_pet_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:evcilhayvanmobil/core/widgets/modern_background.dart';
import 'package:evcilhayvanmobil/core/theme/app_palette.dart';

import '../../data/repositories/pets_repository.dart';
import '../../domain/models/pet_model.dart';
import 'location_picker_screen.dart';

class CreatePetScreen extends ConsumerStatefulWidget {
  final Pet? petToEdit;
  const CreatePetScreen({super.key, this.petToEdit});

  @override
  ConsumerState<CreatePetScreen> createState() => _CreatePetScreenState();
}

class _CreatePetScreenState extends ConsumerState<CreatePetScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _ageController;
  late final TextEditingController _bioController; // Bu opsiyonel kalacak
  LatLng? _selectedLocation;

  String _selectedSpecies = 'cat';
  String _selectedGender = 'unknown';
  bool _isVaccinated = false;

  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditMode => widget.petToEdit != null;

  @override
  void initState() {
    super.initState();
    final pet = widget.petToEdit;
    if (pet != null) {
      // Güncelleme Modu
      _nameController = TextEditingController(text: pet.name);
      _breedController = TextEditingController(text: pet.breed);
      _ageController = TextEditingController(text: pet.ageMonths.toString());
      _bioController = TextEditingController(text: pet.bio);
      _selectedSpecies = pet.species;
      _selectedGender = pet.gender;
      _isVaccinated = pet.vaccinated;
      if (pet.latitude != null && pet.longitude != null) {
        _selectedLocation = LatLng(pet.latitude!, pet.longitude!);
      }
    } else {
      // Oluşturma Modu
      _nameController = TextEditingController();
      _breedController = TextEditingController();
      _ageController = TextEditingController();
      _bioController = TextEditingController();
      _selectedLocation = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _savePet() async {
    // Validator'lar (doğrulayıcılar) artık formu kontrol edecek
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    if (_selectedLocation == null) {
      setState(() {
        _errorMessage = 'Lütfen ilan için harita üzerinden bir konum seçin.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(petsRepositoryProvider);
      
      // --- GÜNCELLEME: Veriler artık 'parse' edilebilir, çünkü validator'lar boş olmadıklarını doğruladı ---
      
      // 'age' artık 0 olamaz
      final age = int.parse(_ageController.text);
      
      // 'breed' artık null olamaz
      final breed = _breedController.text;
      
      // 'bio' (Açıklama) opsiyonel kalmaya devam ediyor
      final bio = _bioController.text.isNotEmpty ? _bioController.text : null;
      
      // 'location' artık null olamaz
      final lat = _selectedLocation!.latitude;
      final lon = _selectedLocation!.longitude;

      Map<String, dynamic> locationData = {
        'type': 'Point',
        'coordinates': [lon, lat], // GeoJSON formatı [Boylam, Enlem]
      };
      // --- GÜNCELLEME BİTTİ ---

      if (_isEditMode) {
        // GÜNCELLEME MODU
        await repo.updatePet(
          widget.petToEdit!.id,
          name: _nameController.text,
          species: _selectedSpecies,
          breed: breed, // Artık zorunlu
          gender: _selectedGender,
          ageMonths: age, // Artık zorunlu
          bio: bio, // Opsiyonel
          vaccinated: _isVaccinated,
          location: locationData, // Artık zorunlu
        );
      } else {
        // OLUŞTURMA MODU
        await repo.createPet(
          name: _nameController.text,
          species: _selectedSpecies,
          breed: breed, // Artık zorunlu
          gender: _selectedGender,
          ageMonths: age, // Artık zorunlu
          bio: bio, // Opsiyonel
          vaccinated: _isVaccinated,
          location: locationData, // Artık zorunlu
        );
      }

      // Kilitlenme çözümü (Değişiklik yok)
      if (mounted) context.pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(myPetsProvider);
        ref.invalidate(petFeedProvider); 
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialPosition: _selectedLocation,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
        if (_errorMessage != null &&
            _errorMessage!.toLowerCase().contains('konum')) {
          _errorMessage = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const speciesOptions = <Map<String, String>>[
      {'label': 'Kedi', 'value': 'cat'},
      {'label': 'Köpek', 'value': 'dog'},
      {'label': 'Kuş', 'value': 'bird'},
      {'label': 'Diğer', 'value': 'other'},
    ];
    const genderOptions = <Map<String, String>>[
      {'label': 'Erkek', 'value': 'male'},
      {'label': 'Dişi', 'value': 'female'},
      {'label': 'Bilinmiyor', 'value': 'unknown'},
    ];

    InputDecoration inputDecoration({
      required String label,
      IconData? icon,
      String? hint,
      int lines = 1,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: lines > 1 ? 18 : 0,
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_isEditMode ? 'İlanı Düzenle' : 'Yeni İlan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ModernBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: AppPalette.heroGradient
                            .map((c) => c.withOpacity(0.9))
                            .toList(),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.18),
                          blurRadius: 32,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditMode
                              ? 'İlan bilgilerini güncelle'
                              : 'Yeni ilan oluştur',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dostunun karakterini, ihtiyaçlarını ve konumunu paylaş. Renkli kart tasarımı ile ilanların öne çıksın.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Temel Bilgiler',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: inputDecoration(
                            label: 'İsim',
                            icon: Icons.pets_outlined,
                          ),
                          validator: (value) =>
                              (value?.isEmpty ?? true) ? 'İsim zorunludur' : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tür',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: speciesOptions.map((option) {
                            return ChoiceChip(
                              label: Text(option['label']!),
                              selected: _selectedSpecies == option['value'],
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() =>
                                      _selectedSpecies = option['value']!);
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cinsiyet',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: genderOptions.map((option) {
                            return ChoiceChip(
                              label: Text(option['label']!),
                              selected: _selectedGender == option['value'],
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() =>
                                      _selectedGender = option['value']!);
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile.adaptive(
                          value: _isVaccinated,
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(Icons.vaccines),
                          title: const Text('Aşıları tam'),
                          subtitle: const Text(
                            'Aşı bilgileri ilanda rozet olarak gösterilir.',
                          ),
                          onChanged: (value) {
                            setState(() => _isVaccinated = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detaylar',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ageController,
                          decoration: inputDecoration(
                            label: 'Yaş (Ay)',
                            icon: Icons.cake_outlined,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) =>
                              (value?.isEmpty ?? true) ? 'Yaş zorunludur' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _breedController,
                          decoration: inputDecoration(
                            label: 'Cins',
                            icon: Icons.badge_outlined,
                          ),
                          validator: (value) =>
                              (value?.isEmpty ?? true) ? 'Cins zorunludur' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bioController,
                          maxLines: 4,
                          decoration: inputDecoration(
                            label: 'Açıklama',
                            icon: Icons.notes_outlined,
                            hint:
                                'Karakterini, günlük rutinini ve sahiplenme notlarını paylaş.',
                            lines: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konum',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _pickLocation,
                          icon: const Icon(Icons.map_rounded),
                          label: Text(
                            _selectedLocation == null
                                ? 'Konum Seç'
                                : 'Konumu Güncelle',
                          ),
                        ),
                        if (_selectedLocation != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: IgnorePointer(
                              child: SizedBox(
                                height: 200,
                                width: double.infinity,
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: _selectedLocation!,
                                    zoom: 14,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId('selected-location'),
                                      position: _selectedLocation!,
                                    ),
                                  },
                                  zoomControlsEnabled: false,
                                  liteModeEnabled: true,
                                  myLocationButtonEnabled: false,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Seçilen konum: '
                            '${_selectedLocation!.latitude.toStringAsFixed(5)}, '
                            '${_selectedLocation!.longitude.toStringAsFixed(5)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _savePet,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_isEditMode ? 'İlanı Güncelle' : 'İlanı Kaydet'),
                    ),
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