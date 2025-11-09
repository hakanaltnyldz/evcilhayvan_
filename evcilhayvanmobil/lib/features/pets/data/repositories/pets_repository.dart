// lib/features/pets/data/repositories/pets_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcilhayvanmobil/core/http.dart';
import 'package:evcilhayvanmobil/features/pets/domain/models/pet_model.dart';
import 'package:image_picker/image_picker.dart';

// Eşleşme sonucu için yardımcı sınıf (Değişiklik yok)
class LikeResult {
  final bool didMatch;
  final PetOwner? matchedUser;
  LikeResult({required this.didMatch, this.matchedUser});
}

// 1. PetsRepository Provider'ı (Değişiklik yok)
final petsRepositoryProvider = Provider<PetsRepository>((ref) {
  final dio = HttpClient().dio; 
  return PetsRepository(dio);
});

// 2. Repository Sınıfı
class PetsRepository {
  final Dio _dio;
  PetsRepository(this._dio);

  // --- YENİ EKLENEN getPetFeed METODU ---
  /**
   * (AUTH) Kullanıcının "Akıllı Akış"ını (feed) getirir.
   * Sadece etkileşime girilmemiş ve sahip olunmayan ilanları çeker.
   * Backend: GET /api/pets/feed
   */
Future<List<Pet>> getPetFeed() async {
  try {
    final response = await _dio.get('/api/pets/feed');
    print('📡 FEED RESPONSE: ${response.data}');

    final List<dynamic> petListJson = (response.data['items'] ?? []) as List<dynamic>;
    final List<Pet> petList = petListJson.map((json) => Pet.fromJson(json)).toList();
    print('🐶 FEED PET COUNT: ${petList.length}');
    return petList;

  } on DioException catch (e) {
    print('❌ Error fetching pet feed: ${e.response?.data}');
    if (e.response?.statusCode == 401) {
      print("⚠️ Misafir kullanıcı — public feed'e geçiliyor.");
      return getPets();
    }
    rethrow;
  }
}

  // --- YENİ METOD BİTTİ ---

  // (PUBLIC) Tüm pet ilanlarını getirir
  Future<List<Pet>> getPets() async {
    try {
      final response = await _dio.get('/api/pets');
      final List<dynamic> petListJson = response.data['items'];
      final List<Pet> petList = petListJson.map((json) => Pet.fromJson(json)).toList();
      return petList;
    } on DioException catch (e) {
      print('Error fetching pets: $e');
      rethrow;
    }
  }

  // (AUTH) Sadece kullanıcının kendi ilanlarını getirir
  Future<List<Pet>> getMyPets() async {
    try {
      final response = await _dio.get('/api/pets/me'); 
      final List<dynamic> petListJson = response.data['pets'];
      final List<Pet> petList = petListJson.map((json) => Pet.fromJson(json)).toList();
      return petList;
    } on DioException catch (e) {
      print('Error fetching my pets: $e');
      rethrow;
    }
  }

  // (PUBLIC) ID'ye göre tek bir pet ilanını getirir
  Future<Pet> getPetById(String petId) async {
    try {
      final response = await _dio.get('/api/pets/$petId');
      return Pet.fromJson(response.data['pet']);
    } on DioException catch (e) {
      print('Error fetching pet by ID ($petId): $e');
      throw Exception('İlan detayı alınamadı: ${e.response?.data['message']}');
    }
  }

  // (AUTH) Yeni bir pet ilanı oluşturur
  Future<Pet> createPet({
    required String name, required String species, String? breed,
    required String gender, required int ageMonths, String? bio,
    required bool vaccinated, Map<String, dynamic>? location,
  }) async {
    try {
      final response = await _dio.post(
        '/api/pets',
        data: {
          'name': name, 'species': species, 'breed': breed,
          'gender': gender, 'ageMonths': ageMonths, 'bio': bio,
          'vaccinated': vaccinated, 'location': location,
        },
      );
      return Pet.fromJson(response.data['pet']);
    } on DioException catch (e) {
      print('Error creating pet: $e');
      throw Exception('İlan oluşturulamadı: ${e.response?.data['message']}');
    }
  }
  
  // (AUTH) Bir pet ilanını günceller
  Future<Pet> updatePet(String petId, {
    required String name, required String species, String? breed,
    required String gender, required int ageMonths, String? bio,
    required bool vaccinated, Map<String, dynamic>? location,
  }) async {
    try {
      final response = await _dio.put(
        '/api/pets/$petId',
        data: {
          'name': name, 'species': species, 'breed': breed,
          'gender': gender, 'ageMonths': ageMonths, 'bio': bio,
          'vaccinated': vaccinated, 'location': location,
        },
      );
      return Pet.fromJson(response.data['pet']);
    } on DioException catch (e) {
      print('Error updating pet: $e');
      throw Exception('İlan güncellenemedi: ${e.response?.data['message']}');
    }
  }
  
  // (AUTH) Bir ilana fotoğraf yükler
  Future<String> uploadPetImage(String petId, XFile imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });
      final response = await _dio.post(
        '/api/pets/$petId/images',
        data: formData,
      );
      return response.data['url'];
    } on DioException catch (e) {
      print('Error uploading image: $e');
      throw Exception('Resim yüklenemedi: ${e.response?.data['message']}');
    }
  }

  // (AUTH) Bir pet ilanını siler
  Future<void> deletePet(String petId) async {
    try {
      await _dio.delete('/api/pets/$petId');
      return;
    } on DioException catch (e) {
      print('Error deleting pet: $e');
      throw Exception('İlan silinemedi: ${e.response?.data['message']}');
    }
  }

  // (AUTH) Bir pet ilanını "beğenir"
  Future<LikeResult> likePet(String petId) async {
    try {
      final response = await _dio.post('/api/interactions/like/$petId');
      final bool didMatch = response.data['match'] ?? false;
      PetOwner? matchedUser;
      if (didMatch && response.data['matchedWith'] != null) {
        matchedUser = PetOwner.fromJson(response.data['matchedWith']);
      }
      return LikeResult(didMatch: didMatch, matchedUser: matchedUser);
    } on DioException catch (e) {
      print('Error liking pet: $e');
      throw Exception('Beğenme işlemi başarısız: ${e.response?.data['message']}');
    }
  }

  // (AUTH) Bir pet ilanını "geçer"
  Future<void> passPet(String petId) async {
    try {
      await _dio.post('/api/interactions/pass/$petId');
      return;
    } on DioException catch (e) {
      print('Error passing pet: $e');
      throw Exception('Geçme işlemi başarısız: ${e.response?.data['message']}');
    }
  }
} // --- PetsRepository Sınıfının Sonu ---


// --- PROVIDER'LAR GÜNCELLENDİ ---

// (PUBLIC) Tüm Pet İlanları İçin Provider
// (Artık 'petsProvider' olarak değil, 'allPetsProvider' olarak adlandıralım)
final allPetsProvider = FutureProvider<List<Pet>>((ref) {
  final repository = ref.watch(petsRepositoryProvider);
  return repository.getPets(); // getPets'i çağırır
});

// (AUTH) "Benim İlanlarım" İçin Provider (Değişiklik yok)
final myPetsProvider = FutureProvider<List<Pet>>((ref) {
  final repository = ref.watch(petsRepositoryProvider);
  return repository.getMyPets();
});

// (AUTH / AKILLI) Ana Sayfa "Akışı" İçin Provider
// HomeScreen artık bunu kullanacak.
final petFeedProvider = FutureProvider<List<Pet>>((ref) {
  final repository = ref.watch(petsRepositoryProvider);
  return repository.getPetFeed(); // Yeni getPetFeed'i çağırır
});
// --- GÜNCELLEME BİTTİ ---