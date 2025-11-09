// lib/features/pets/presentation/screens/create_pet_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../data/repositories/pets_repository.dart';
import '../../domain/models/pet_model.dart';

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
  late final TextEditingController _latController;
  late final TextEditingController _lonController;

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
      _latController = TextEditingController(text: pet.location['coordinates'][1].toString());
      _lonController = TextEditingController(text: pet.location['coordinates'][0].toString());
    } else {
      // Oluşturma Modu
      _nameController = TextEditingController();
      _breedController = TextEditingController();
      _ageController = TextEditingController();
      _bioController = TextEditingController();
      _latController = TextEditingController();
      _lonController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _savePet() async {
    // Validator'lar (doğrulayıcılar) artık formu kontrol edecek
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    
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
      final lat = double.parse(_latController.text);
      final lon = double.parse(_lonController.text);
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'İlanı Düzenle' : 'Yeni İlan Oluştur'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'İsim'),
                  validator: (value) => (value?.isEmpty ?? true) ? 'İsim zorunludur' : null,
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: _selectedSpecies,
                  decoration: const InputDecoration(labelText: 'Tür'),
                  items: ['cat', 'dog', 'bird', 'other'].map((species) {
                    return DropdownMenuItem(value: species, child: Text(species));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedSpecies = value!),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(labelText: 'Cinsiyet'),
                  items: ['male', 'female', 'unknown'].map((gender) {
                    return DropdownMenuItem(value: gender, child: Text(gender));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedGender = value!),
                ),
                const SizedBox(height: 16),
                
                SwitchListTile(
                  title: const Text('Aşılı'),
                  value: _isVaccinated,
                  onChanged: (bool value) {
                    setState(() {
                      _isVaccinated = value;
                    });
                  },
                  secondary: const Icon(Icons.vaccines),
                  contentPadding: EdgeInsets.zero,
                ),
                
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Yaş (Ay Olarak)'), // "hintText: 0" kaldırıldı
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  // --- GÜNCELLEME: Validator eklendi ---
                  validator: (value) => (value?.isEmpty ?? true) ? 'Yaş zorunludur' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _breedController,
                  decoration: const InputDecoration(labelText: 'Cins'), // "Opsiyonel" kaldırıldı
                  // --- GÜNCELLEME: Validator eklendi ---
                  validator: (value) => (value?.isEmpty ?? true) ? 'Cins zorunludur' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(labelText: 'Açıklama (Opsiyonel)', alignLabelWithHint: true),
                  maxLines: 4,
                  // --- GÜNCELLEME: Validator yok, çünkü bu opsiyonel ---
                ),
                const SizedBox(height: 16),

                // --- GÜNCELLEME: "Opsiyonel" kaldırıldı ---
                const Text('Konum', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        decoration: const InputDecoration(labelText: 'Enlem (Lat)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        // --- GÜNCELLEME: Validator eklendi ---
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Enlem zorunlu';
                          if (double.tryParse(value!) == null) return 'Geçersiz sayı';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lonController,
                        decoration: const InputDecoration(labelText: 'Boylam (Lon)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        // --- GÜNCELLEME: Validator eklendi ---
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Boylam zorunlu';
                          if (double.tryParse(value!) == null) return 'Geçersiz sayı';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                if (_errorMessage != null)
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePet,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_isEditMode ? 'Güncelle' : 'İlanı Kaydet'),
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